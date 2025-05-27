/*
 * Copyright (c) 2010-2024 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <framework/core/eventdispatcher.h>
#include <framework/util/crypt.h>

#include <utility>

#include "protocolhttp.h"

Http g_http;

void Http::init()
{
    m_working = true;
    g_ixHttpClient = std::make_shared<ix::HttpClient>(true);
}

void Http::terminate()
{
    if (!m_working)
        return;

    m_working = false;

    for (auto& [_, ws] : m_websockets) {
        ws->close();
    }

    for (auto& [_, op] : m_operations) {
        op->canceled = true;
        if (auto session = op->session.lock()) {
            session->cancel();
        }
    }

    m_websockets.clear();
    m_operations.clear();
    m_downloads.clear();

    g_ixHttpClient.reset();
}

int Http::get(const std::string& url, int timeout)
{
    if (!timeout)
        timeout = 5;

    const int operationId = m_operationId++;
    auto result = std::make_shared<HttpResult>();
    result->url = url;
    result->operationId = operationId;
    m_operations[operationId] = result;

    auto request = g_ixHttpClient->createRequest();
    request->url = url;
    request->connectTimeout = timeout;
    request->followRedirects = true;

    request->extraHeaders["User-Agent"] = m_userAgent;
    for (const auto& [key, value] : m_custom_header) {
        request->extraHeaders[key] = value;
    }

    g_ixHttpClient->performRequest(
        request,
        [this, operationId, result](const ix::HttpResponsePtr& response) {
            result->finished = true;
            result->status = response->statusCode;

            if (response->statusCode != 200) {
                result->error = stdext::format("HTTP %d: %s", response->statusCode, response->errorMsg);
            } else {
                result->response = response->body;
                result->size = static_cast<int>(result->response.size());
                result->progress = 100;
            }

            g_dispatcher.addEvent([result] {
                g_lua.callGlobalField("g_http", "onGet", result->operationId, result->url, result->error, result->response);
            });

            m_operations.erase(operationId);
        }
    );

    return operationId;
}

int Http::post(const std::string& url, const std::string& data, int timeout, bool isJson, bool /*checkContentLength*/)
{
    if (!timeout) // lua is not working with default values
        timeout = 5;

    if (data.empty()) {
        g_logger.error(stdext::format("Invalid post request for %s, empty data, use get instead", url));
        return -1;
    }

    const int operationId = m_operationId++;
    auto result = std::make_shared<HttpResult>();
    result->url = url;
    result->operationId = operationId;
    result->postData = data;

    m_operations[operationId] = result;

    auto request = std::make_shared<ix::HttpRequestArgs>();
    request->url = url;
    request->verb = "POST";
    request->connectTimeout = timeout;
    request->followRedirects = true;
    request->body = data;

    request->extraHeaders["User-Agent"] = m_userAgent;
    request->extraHeaders["Accept"] = "*/*";
    request->extraHeaders["Connection"] = "close";

    if (isJson) {
        request->extraHeaders["Content-Type"] = "application/json";
    } else {
        request->extraHeaders["Content-Type"] = "application/x-www-form-urlencoded";
    }

    for (const auto& [key, value] : m_custom_header) {
        request->extraHeaders[key] = value;
    }

    g_ixHttpClient->performRequest(
        request,
        [this, operationId, result](const ix::HttpResponsePtr& response) {
            result->finished = true;
            result->status = response->statusCode;

            if (response->statusCode != 200) {
                result->error = stdext::format("HTTP %d: %s", response->statusCode, response->errorMsg);
            } else {
                result->response = response->body;
                result->size = static_cast<int>(result->response.size());
                result->progress = 100;
            }

            g_dispatcher.addEvent([result] {
                g_lua.callGlobalField("g_http", "onPost", result->operationId, result->url, result->error, result->response);
            });

            m_operations.erase(operationId);
        }
    );

    return operationId;
}

int Http::download(const std::string& url, const std::string& path, int timeout)
{
    if (!timeout) // lua is not working with default values
        timeout = 5;

    const int operationId = m_operationId++;
    auto result = std::make_shared<HttpResult>();
    result->url = url;
    result->operationId = operationId;

    m_operations[operationId] = result;

    auto request = std::make_shared<ix::HttpRequestArgs>();
    request->url = url;
    request->verb = "GET";
    request->connectTimeout = timeout;
    request->followRedirects = true;

    request->extraHeaders["User-Agent"] = m_userAgent;
    for (const auto& [key, value] : m_custom_header) {
        request->extraHeaders[key] = value;
    }

    // Progress callback (optional)
    request->onProgressCallback = [result](int downloaded, int total) -> bool {
        if (total > 0) {
            result->progress = static_cast<int>((100 * downloaded) / total);
        }
        return true;
    };

    g_ixHttpClient->performRequest(
        request,
        [this, result, path, operationId](const ix::HttpResponsePtr& response) {
            result->finished = true;
            result->status = response->statusCode;

            if (response->statusCode != 200) {
                result->error = stdext::format("HTTP %d: %s", response->statusCode, response->errorMsg);
            } else {
                result->response = response->body;
                result->size = static_cast<int>(response->body.size());
                result->progress = 100;
            }

            g_dispatcher.addEvent([this, result, path] {
                const auto checksum = g_crypt.crc32(result->response, false);
                if (result->error.empty()) {
                    const std::string normalizedPath = (path.size() > 0 && path[0] == '/') ? path.substr(1) : path;
                    m_downloads[normalizedPath] = result;
                }
                g_lua.callGlobalField("g_http", "onDownload", result->operationId, result->url, result->error, path, checksum);
            });

            m_operations.erase(operationId);
        }
    );

    return operationId;
}

int Http::ws(const std::string& url, int timeout)
{
    if (!timeout)
        timeout = 5;

    const int operationId = m_operationId++;
    auto result = std::make_shared<HttpResult>();
    result->url = url;
    result->operationId = operationId;
    m_operations[operationId] = result;

    auto session = std::make_shared<ix::WebSocket>();
    session->setUrl(url);
    session->disableAutomaticReconnection();
    session->setPingInterval(10);
    session->setExtraHeaders({ { "User-Agent", m_userAgent } });

    // onMessage callback
    session->setOnMessageCallback([this, operationId, result](const ix::WebSocketMessagePtr& msg) {
        auto msgCopy = std::make_shared<ix::WebSocketMessage>(*msg);  // Faz uma cópia segura
        g_dispatcher.addEvent([msgCopy, this, operationId, result]() {
            switch (msgCopy->type) {
                case ix::WebSocketMessageType::Open:
                    result->connected = true;
                    g_lua.callGlobalField("g_http", "onWsOpen", operationId, "connected");
                    break;
                case ix::WebSocketMessageType::Message:
                    g_lua.callGlobalField("g_http", "onWsMessage", operationId, msgCopy->str);
                    break;
                case ix::WebSocketMessageType::Error:
                    result->finished = true;
                    result->connected = false;
                    result->error = msgCopy->errorInfo.reason;
                    g_lua.callGlobalField("g_http", "onWsError", operationId, result->error);
                    break;
                case ix::WebSocketMessageType::Close:
                    g_lua.callGlobalField("g_http", "onWsClose", operationId, msgCopy->closeInfo.reason);
                    m_websockets.erase(operationId);
                    break;
                default:
                    break;
            }
        });
    });

    session->start();
    m_websockets[operationId] = session;

    return operationId;
}

bool Http::wsSend(int operationId, const std::string& message)
{
    const auto it = m_websockets.find(operationId);
    if (it != m_websockets.end()) {
        it->second->send(message); // ix::WebSocket::send is thread-safe
        return true;
    }
    return false;
}

bool Http::wsClose(const int operationId)
{
    cancel(operationId);
    return true;
}

bool Http::cancel(int id)
{
    auto wit = m_websockets.find(id);
    if (wit != m_websockets.end()) {
        wit->second->stop();
        m_websockets.erase(wit);
    }

    auto it = m_operations.find(id);
    if (it == m_operations.end())
        return false;

    if (it->second->canceled)
        return false;

    it->second->canceled = true;
    m_operations.erase(it);

    return true;
}

void HttpSession::start() {
    auto args = std::make_shared<ix::HttpRequestArgs>();
    args->url = m_url;
    args->verb = m_result->postData.empty() ? ix::HttpClient::kGet : ix::HttpClient::kPost;
    args->followRedirects = true;
    args->connectTimeout = m_timeout;
    args->transferTimeout = m_timeout;

    args->extraHeaders["User-Agent"] = m_agent;
    for (const auto& [key, value] : m_custom_header) {
        args->extraHeaders[key] = value;
    }

    if (!m_result->postData.empty()) {
        args->body = m_result->postData;
        const auto contentType = m_isJson ? "application/json" : "application/x-www-form-urlencoded";
        args->extraHeaders["Content-Type"] = contentType;
    }

    auto self = shared_from_this();
    g_ixHttpClient->performRequest(args, [self](const ix::HttpResponsePtr& response) {
        if (response->statusCode != 200) {
            auto error = std::to_string(response->statusCode);
            self->onError("HTTP error", error);
            return;
        }

        self->m_result->response.assign(response->body.begin(), response->body.end());
        self->m_result->size = static_cast<uint32_t>(response->body.size());
        self->m_result->finished = true;

        g_logger.debug("HttpSession::response -> Received {} bytes", self->m_result->size);
        self->m_callback(self->m_result);
    });
}

void HttpSession::onError(const std::string& error, const std::string& details) {
    std::string fullError = error;
    if (!details.empty()) {
        fullError += " (" + details + ")";
    }

    g_logger.error("HttpSession::onError -> {}", fullError);

    if (!m_result->finished) {
        m_result->finished = true;
        m_result->error = fullError;
        m_callback(m_result);
    }
}

void WebsocketSession::start()
{
    m_ws.setUrl(m_url);
    m_ws.setExtraHeaders({
        { "User-Agent", m_agent }
    });

    m_ws.setOnMessageCallback([sft = shared_from_this()](const ix::WebSocketMessagePtr& msg) {
        if (msg->type == ix::WebSocketMessageType::Open) {
            sft->m_callback(WebsocketCallbackType::OPEN, "connected");
        } else if (msg->type == ix::WebSocketMessageType::Message) {
            sft->m_callback(WebsocketCallbackType::MESSAGE, msg->str);
        } else if (msg->type == ix::WebSocketMessageType::Close) {
            sft->m_callback(WebsocketCallbackType::CLOSE, msg->closeInfo.reason);
        } else if (msg->type == ix::WebSocketMessageType::Error) {
            sft->m_callback(WebsocketCallbackType::ERROR_, msg->errorInfo.reason);
        }
    });

    m_ws.disableAutomaticReconnection();
    m_ws.setPingInterval(10);
    m_ws.start();
}

void WebsocketSession::send(const std::string& data, uint8_t)
{
    m_ws.send(data);
}

void WebsocketSession::close()
{
    m_closed = true;
    m_ws.stop();
}
