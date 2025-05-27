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

#pragma once

#include <framework/global.h>
#include <framework/stdext/uri.h>

#include <queue>

#include <zlib.h>

 //  result
class HttpSession;

struct HttpResult
{
    std::string url;
    int operationId = 0;
    int status = 0;
    int size = 0;
    int progress = 0; // from 0 to 100
    int speed = 0;
    int redirects = 0; // redirect
    bool connected = false;
    bool finished = false;
    bool canceled = false;
    std::string postData;
    std::string response;
    std::string error;
    std::weak_ptr<HttpSession> session;
};

using HttpResult_ptr = std::shared_ptr<HttpResult>;
using HttpResult_cb = std::function<void(HttpResult_ptr)>;

//  session

class HttpSession : public std::enable_shared_from_this<HttpSession>
{
public:

    HttpSession(const std::string& url, const std::string& agent,
                int timeout, bool isJson, HttpResult_ptr result, HttpResult_cb callback)
        : m_url(url), m_agent(agent), m_timeout(timeout), m_isJson(isJson),
          m_result(result), m_callback(callback)
    {
        assert(m_callback != nullptr);
        assert(m_result != nullptr);
    }
    void start();
    void cancel() {
        onError("canceled");
    }

private:
    std::string m_url;
    std::string m_agent;
    bool m_enable_time_out_on_read_write;
    int m_timeout;
    bool m_isJson;
    bool m_checkContentLength;

    int sum_bytes_response = 0;
    int sum_bytes_speed_response = 0;
    ticks_t m_last_progress_update = stdext::millis();

    HttpResult_ptr m_result;
    HttpResult_cb m_callback;
    std::unordered_map<std::string, std::string> m_custom_header;
    std::shared_ptr<ix::HttpClient> m_client;

    void onError(const std::string& ec, const std::string& details = "");
};

//  web socket
enum class WebsocketCallbackType { OPEN, MESSAGE, ERROR_, CLOSE };
using WebsocketSession_cb = std::function<void(WebsocketCallbackType, const std::string& message)>;

class WebsocketSession : public std::enable_shared_from_this<WebsocketSession>
{
public:

    WebsocketSession(std::string url, std::string agent, int timeout, HttpResult_ptr result, WebsocketSession_cb callback)
        : m_url(std::move(url)),
          m_agent(std::move(agent)),
          m_timeout(timeout),
          m_result(std::move(result)),
          m_callback(std::move(callback))
    {
        assert(m_callback != nullptr);
        assert(m_result != nullptr);
    };

    void start();
    void send(const std::string& data, uint8_t ws_opcode = 0);
    void close();

private:
    std::string m_url;
    std::string m_agent;
    int m_timeout;
    bool m_closed{ false };

    HttpResult_ptr m_result;
    WebsocketSession_cb m_callback;

    ix::WebSocket m_ws;
};

class Http
{
public:
    void init();
    void terminate();

    int get(const std::string& url, int timeout = 5);
    int post(const std::string& url, const std::string& data, int timeout = 5, bool isJson = false, bool checkContentLength = true);
    int download(const std::string& url, const std::string& path, int timeout = 5);
    int ws(const std::string& url, int timeout = 5);
    bool wsSend(int operationId, const std::string& message);
    bool wsClose(int operationId);
    bool cancel(int id);

    const std::unordered_map<std::string, HttpResult_ptr>& downloads() const { return m_downloads; }

    void clearDownloads() { m_downloads.clear(); }

    HttpResult_ptr getFile(std::string path)
    {
        if (!path.empty() && path[0] == '/')
            path = path.substr(1);
        const auto it = m_downloads.find(path);
        if (it == m_downloads.end())
            return nullptr;
        return it->second;
    }

    void setUserAgent(const std::string& userAgent) { m_userAgent = userAgent; }

    void addCustomHeader(const std::string& name, const std::string& value) { m_custom_header[name] = value; }

    void setEnableTimeOutOnReadWrite(const bool enable_time_out_on_read_write) { m_enable_time_out_on_read_write = enable_time_out_on_read_write; }

private:
    bool m_working = false;
    bool m_enable_time_out_on_read_write = false;
    int m_operationId = 1;
    std::unordered_map<int, HttpResult_ptr> m_operations;
    std::unordered_map<int, std::shared_ptr<ix::WebSocket>> m_websockets;
    std::unordered_map<std::string, HttpResult_ptr> m_downloads;
    std::string m_userAgent = "Mozilla/5.0";
    std::unordered_map<std::string, std::string> m_custom_header;
};

extern Http g_http;

inline std::shared_ptr<ix::HttpClient> g_ixHttpClient;

