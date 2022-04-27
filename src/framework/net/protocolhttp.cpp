/*
 * Copyright (c) 2010-2020 OTClient <https://github.com/edubart/otclient>
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

#include "protocolhttp.h"

Http g_http;

void Http::init() 
{
    m_working = true;
    m_thread = std::thread([&] {
        m_ios.run();
    });
}

void Http::terminate() 
{
    if (!m_working)
        return;
    #ifdef FW_WEBSOCKET
    m_working = false;
    for (auto& ws : m_websockets) {
        ws.second->close();
    }
    #endif
    for (auto& op : m_operations) {
        auto session = op.second->session.lock();
        if(session)
            session->close();
    }
    m_guard.reset();
    if (!m_thread.joinable()) {
        stdext::millisleep(100);
        m_ios.stop();
    }
    m_thread.join();
}

int Http::get(const std::string& url, int timeout) 
{
    if (!timeout) // lua is not working with default values
        timeout = 5;
    int operationId = m_operationId++;

    asio::post(m_ios, [&, url, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_enable_time_out_on_read_write, m_custom_header, timeout,
                                                    false, result, [&](HttpResult_ptr result) {
            bool finished = result->finished;
            g_dispatcher.addEvent([result, finished] {
                if (!finished) {
                    g_lua.callGlobalField("g_http", "onGetProgress", result->operationId, result->url, result->progress);
                    return;
                }
                g_lua.callGlobalField("g_http", "onGet", result->operationId, result->url, result->error, result->response);
            });
            if (finished) {
                m_operations.erase(operationId);
            }
        });
        result->session = session;
        session->start();
    });

    return operationId;
}

int Http::post(const std::string& url, const std::string& data, int timeout, bool isJson) 
{
    if (!timeout) // lua is not working with default values
        timeout = 5;
    if (data.empty()) {
        g_logger.error(stdext::format("Invalid post request for %s, empty data, use get instead", url));
        return -1;
    }

    int operationId = m_operationId++;
    asio::post(m_ios, [&, url, data, timeout, isJson, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        result->postData = data;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_enable_time_out_on_read_write, m_custom_header, timeout,
                                                    isJson, result, [&](HttpResult_ptr result) {
            bool finished = result->finished;
            g_dispatcher.addEvent([result, finished] {
                if (!finished) {
                    g_lua.callGlobalField("g_http", "onPostProgress", result->operationId, result->url, result->progress);
                    return;
                }
                g_lua.callGlobalField("g_http", "onPost", result->operationId, result->url, result->error, result->response);
            });
            if (finished) {
                m_operations.erase(operationId);
            }
        });
        result->session = session;
        session->start();
    });
    return operationId;
}

int Http::download(const std::string& url, std::string path, int timeout) 
{
    if (!timeout) // lua is not working with default values
        timeout = 5;

    int operationId = m_operationId++;
    asio::post(m_ios, [&, url, path, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_enable_time_out_on_read_write, m_custom_header, timeout,
                                                    false, result, [&, path](HttpResult_ptr result) {

            if (!result->finished) {
                g_dispatcher.addEvent([result] {
                    g_lua.callGlobalField("g_http", "onDownloadProgress", result->operationId, result->url, result->progress, result->speed);
                });
                return;
            }

            unsigned long  crc = crc32(0L, Z_NULL, 0);
            unsigned long checksum = crc32(crc, (const unsigned char*)result->response.c_str(), result->response.size());

            g_dispatcher.addEvent([&, result, path, checksum] {
                if (result->error.empty()) {
                    if (!path.empty() && path[0] == '/')
                        m_downloads[path.substr(1)] = result;
                    else
                        m_downloads[path] = result;
                }
                g_lua.callGlobalField("g_http", "onDownload", result->operationId, result->url, result->error, path, checksum);
            });
            m_operations.erase(operationId);
        });
        result->session = session;
        session->start();
    });
    return operationId;
}

#ifdef FW_WEBSOCKET
int Http::ws(const std::string& url, int timeout)
{
    if (!timeout) // lua is not working with default values
        timeout = 5;
    int operationId = m_operationId++;

    asio::post(m_ios, [&, url, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        m_operations[operationId] = result;
        auto session = std::make_shared<WebsocketSession>(m_ios, url, m_userAgent, m_enable_time_out_on_read_write, timeout, result, [&, result](WebsocketCallbackType type, std::string message) {
            g_dispatcher.addEvent([result, type, message]() {
                if (type == WEBSOCKET_OPEN) {
                    g_lua.callGlobalField("g_http", "onWsOpen", result->operationId, message);
                } else if (type == WEBSOCKET_MESSAGE) {
                    g_lua.callGlobalField("g_http", "onWsMessage", result->operationId, message);
                } else if (type == WEBSOCKET_CLOSE) {
                    g_lua.callGlobalField("g_http", "onWsClose", result->operationId, message);
                } else if (type == WEBSOCKET_ERROR) {
                    g_lua.callGlobalField("g_http", "onWsError", result->operationId, message);
                }
            });
            if (type == WEBSOCKET_CLOSE) {
                m_websockets.erase(result->operationId);
            }
        });
        m_websockets[result->operationId] = session;
        session->start();
    });

    return operationId;
}

bool Http::wsSend(int operationId, std::string message)
{
    asio::post(m_ios, [&, operationId, message] {
        auto wit = m_websockets.find(operationId);
        if (wit == m_websockets.end()) {
            return;
        }
        wit->second->send(message);
    });
    return true;
}

bool Http::wsClose(int operationId)
{
    cancel(operationId);
    return true;
}
#endif

bool Http::cancel(int id) 
{
    // asio::post(m_ios, [&, id] {
        #ifdef FW_WEBSOCKET
        auto wit = m_websockets.find(id);
        if (wit != m_websockets.end()) {
            wit->second->close();
        }
        #endif
        auto it = m_operations.find(id);
        if (it == m_operations.end())
            return false;
        if (it->second->canceled)
            return false;
        auto session = it->second->session.lock();
        if(session)
            session->close();
    // });
    return true;
}

void HttpSession::start() 
{
    
    instance_uri = parseURI(m_url);
    asio::ip::tcp::resolver::query query_resolver(instance_uri.domain, instance_uri.port);

    if(m_result->postData == "") {
        m_request.append("GET " + instance_uri.query + " HTTP/1.0\r\n");
        m_request.append("Host: " + instance_uri.domain + "\r\n");
        m_request.append("User-Agent: " + m_agent + "\r\n");
        m_request.append("Accept: */*\r\n");
    } else {
        m_request.append("POST " + instance_uri.query + " HTTP/1.0\r\n");
        m_request.append("Host: " + instance_uri.domain + "\r\n");
        m_request.append("User-Agent: " + m_agent + "\r\n");
        m_request.append("Accept: */*\r\n");
        if(m_isJson){
            m_request.append("Content-Type: application/json\r\n");
        } else {
            m_request.append("Content-Type: application/x-www-form-urlencoded\r\n");
        }
        m_request.append("Content-Length: " + std::to_string(m_result->postData.size()) + "\r\n");
        m_request.append("\r\n");
        m_request.append(m_result->postData + "\r\n");
    }

    for (auto& ch : m_custom_header) {
        m_request.append(ch.first + ch.second + "\r\n");
    }

    m_request.append("\r\n\r\n");

    m_resolver.async_resolve(
		query_resolver,
            [sft = shared_from_this()](
                const std::error_code& ec, const asio::ip::tcp::resolver::results_type& iterator)
            {
                sft->on_resolve(ec, iterator);
            });
}

void HttpSession::on_resolve(const std::error_code& ec, const asio::ip::tcp::resolver::results_type& iterator)
{
    if (ec) {
        onError("HttpSession unable to resolve " + m_url + ": " + ec.message());
        return;
    }

    // Make the connection on the IP address we get from a lookup
    if(instance_uri.port == "443") {
        std::error_code _ec;
        m_ssl.lowest_layer().connect(*iterator, _ec);
        if (_ec) {
            onError("HttpSession unable to connect " + m_url + ": " + _ec.message());
            return;
        }
        std::error_code __ec;
        on_connect(__ec);
    } else {
        m_socket.async_connect(
            *iterator,
                [sft = shared_from_this()](
                    const std::error_code& ec)
                {
                    sft->on_connect(ec);
                });
    }

    m_timer.cancel();
    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});    
}

void HttpSession::on_connect(const std::error_code& ec)
{
    if (ec) {
        onError("HttpSession unable to connect " + m_url + ": " + ec.message());
        return;
    }

    if(instance_uri.port == "443") {
        std::error_code _ec;
        m_ssl.handshake(asio::ssl::stream_base::client, _ec);
        if (_ec) {
            onError("HttpSession unable to handshake " + m_url + ": " + _ec.message());
            return;
        }
        on_write();
    } else {
        on_write();
    }

    m_timer.cancel();
    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});    
}

void HttpSession::on_write()
{
    if(instance_uri.port == "443") {
        asio::async_write(
            m_ssl, asio::buffer(m_request),
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_request_sent(ec, bytes);
                });        
    } else {
        asio::async_write(
            m_socket, asio::buffer(m_request),
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_request_sent(ec, bytes);
                });        
    }

    m_timer.cancel();
    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});    
}

void HttpSession::on_request_sent(const std::error_code& ec, size_t bytes_transferred)
{
    if (ec) {
        onError("HttpSession error on sending request " + m_url + ": " + ec.message());
        return;
    }
        
    if(instance_uri.port == "443") {
        asio::async_read_until(
            m_ssl, m_response, "\r\n\r\n",
            [this](const std::error_code& ec, size_t size) {
                if (ec) {
                    onError("HttpSession error receiving header " + m_url + ": " + ec.message());
                    return;
                }
                std::string header(
                    asio::buffers_begin(m_response.data()),
                    asio::buffers_begin(m_response.data()) + size);
                m_response.consume(size);

                size_t pos = header.find("Content-Length: ");
                if (pos != std::string::npos) {
                    size_t len = std::strtoul(
                        header.c_str() + pos + sizeof("Content-Length: ") - 1,
                        nullptr, 10);
                    m_result->size = len - m_response.size();
                }

                asio::async_read(m_ssl, m_response,
                    asio::transfer_at_least(1),
                        [sft = shared_from_this()](
                            const std::error_code& ec, size_t bytes)
                        {
                            sft->on_read(ec, bytes);
                        });
            });        
    } else {
        asio::async_read_until(
            m_socket, m_response, "\r\n\r\n",
            [this](const std::error_code& ec, size_t size) {
                if (ec) {
                    onError("HttpSession error receiving header " + m_url + ": " + ec.message());
                    return;
                }
                std::string header(
                    asio::buffers_begin(m_response.data()),
                    asio::buffers_begin(m_response.data()) + size);
                m_response.consume(size);

                size_t pos = header.find("Content-Length: ");
                if (pos != std::string::npos) {
                    size_t len = std::strtoul(
                        header.c_str() + pos + sizeof("Content-Length: ") - 1,
                        nullptr, 10);
                    m_result->size = len - m_response.size();
                }

                asio::async_read(m_socket, m_response,
                    asio::transfer_at_least(1),
                        [sft = shared_from_this()](
                            const std::error_code& ec, size_t bytes)
                        {
                            sft->on_read(ec, bytes);
                        });
            });
    }

    m_timer.cancel();
    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});    
}

void HttpSession::on_read(const std::error_code& ec, size_t bytes_transferred)
{
    if(ec && ec !=  asio::error::eof) {
        onError("HttpSession unable to on_read " + m_url + ": " + ec.message());
        return;
    } else if (!ec && ec !=  asio::error::eof) {
        // to transfer is chuncked
        // if(m_result->size == 0) {
        //     m_result->size = m_result->size + bytes_transferred;
        // }
        sum_bytes_response += bytes_transferred;
        sum_bytes_speed_response += bytes_transferred;

        if(stdext::millis() > m_last_progress_update) {
            m_result->speed = (sum_bytes_speed_response) / ((stdext::millis() - (m_last_progress_update - 100)));

            m_result->progress = ((double)sum_bytes_response/m_result->size) * 100;            
            m_last_progress_update = stdext::millis() + 100;
            sum_bytes_speed_response = 0;
            m_callback(m_result);
        }

        // if(m_result->canceled) {
        //     break;
        // }

        if(m_enable_time_out_on_read_write) {
            m_timer.expires_after(std::chrono::seconds(m_timeout));
            m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});
        } else {
            m_timer.cancel();
        }

    if(instance_uri.port == "443") {
        asio::async_read(m_ssl, m_response,
            asio::transfer_at_least(1),
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });        
    } else {
        asio::async_read(m_socket, m_response,
            asio::transfer_at_least(1),
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });
    }
    } else if(ec ==  asio::error::eof) {
        m_timer.cancel();
        const auto& data = m_response.data();
        m_result->response.append(asio::buffers_begin(data), asio::buffers_end(data));
        m_result->finished = true;
        m_callback(m_result);
    }
}

void HttpSession::close()
{
    m_result->canceled = true;
    g_logger.error(stdext::format("HttpSession close"));
    if(instance_uri.port == "443") {    
        m_ssl.async_shutdown(
            [sft = shared_from_this()](
                std::error_code ec)
            {
                if(ec ==  asio::error::eof){
                    ec = {};
                }

                if(ec){
                    sft->onError("shutdown " + sft->m_url + ": " + ec.message());
                    return;
                }
            });
    } else {
        std::error_code ec;
        m_socket.shutdown(asio::ip::tcp::socket::shutdown_both, ec);

        // not_connected happens sometimes so don't bother reporting it.
        if(ec && ec != asio::error::not_connected){
            onError("shutdown " + m_url + ": " + ec.message());
            return;
        }
    }
}

void HttpSession::onTimeout(const std::error_code& ec)
{
    if (!ec){
        g_logger.error(stdext::format("HttpSession ontimeout %s", ec.message()));
    }
}

void HttpSession::onError(const std::string& ec, const std::string& details)
{
    g_logger.error(stdext::format("%s", ec));
}

#ifdef FW_WEBSOCKET
void WebsocketSession::start()
{
    instance_uri = parseURI(m_url);
    asio::ip::tcp::resolver::query query_resolver(instance_uri.domain, instance_uri.port);
    m_domain = instance_uri.domain;

	// m_resolver.async_resolve(
	// 	query_resolver,
    //         [sft = shared_from_this()](
    //             const std::error_code& ec, asio::ip::tcp::resolver::results_type results)
    //         {
    //             sft->on_resolve(ec, results);
    //         });
}

void WebsocketSession::on_resolve(const std::error_code& ec, asio::ip::tcp::resolver::results_type results)
{
    if (ec) {
        onError("WebsocketSession unable to resolve " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    // // Make the connection on the IP address we get from a lookup
    // if(instance_uri.port == "443") {
    //     beast::get_lowest_layer(m_ssl).async_connect(
    //         results,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec, asio::ip::tcp::resolver::results_type::endpoint_type et)
    //             {
    //                 sft->on_connect(ec, et);
    //             });     
    // } else {
    //     beast::get_lowest_layer(m_socket).async_connect(
    //         results,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec, asio::ip::tcp::resolver::results_type::endpoint_type et)
    //             {
    //                 sft->on_connect(ec, et);
    //             });
    // }
}

void WebsocketSession::on_connect(const std::error_code& ec, asio::ip::tcp::resolver::results_type::endpoint_type)
{
    if (ec) {
        onError("WebsocketSession unable to on_connect " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    // if(instance_uri.port == "443") {
    //     // Set SNI Hostname (many hosts need this to handshake successfully)
    //     if(! SSL_set_tlsext_host_name(
    //             m_ssl.next_layer().native_handle(),
    //             m_domain.c_str()))
    //     {
    //         auto _ec = beast::error_code(static_cast<int>(::ERR_get_error()),
    //             asio::error::get_ssl_category());
    //          onError("WebsocketSession unable to ssl connect" + _ec.message());
    //          return;
    //     }

    //     // Update the host_ string. This will provide the value of the
    //     // Host HTTP header during the WebSocket handshake.
    //     // See https://tools.ietf.org/html/rfc7230#section-5.4
    //     m_domain += ':' + instance_uri.port;
        
    //     // Perform the SSL handshake
    //     m_ssl.next_layer().async_handshake(
    //         asio::ssl::stream_base::client,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec)
    //             {
    //                 sft->on_ssl_handshake(ec);
    //             }); 
    // } else {
    //     // Set suggested timeout settings for the websocket
    //     m_socket.set_option(
    //         beast::websocket::stream_base::timeout::suggested(
    //             beast::role_type::client));

    //     // Set a decorator to change the User-Agent of the handshake
    //     m_socket.set_option(beast::websocket::stream_base::decorator(
    //         [](beast::websocket::request_type& req)
    //         {
    //             req.set(beast::http::field::user_agent,
    //                 std::string(BOOST_BEAST_VERSION_STRING) +
    //                     " websocket-client-otclient");
    //         }));

    //     m_domain += ':' + instance_uri.port;

    //     m_socket.async_handshake(
    //         m_domain, instance_uri.query,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec)
    //             {
    //                 sft->on_handshake(ec);
    //             });
    // }
}

void WebsocketSession::on_ssl_handshake(const std::error_code& ec)
{
    if (ec) {
        onError("WebsocketSession unable to ssl_handshake " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    // // Set suggested timeout settings for the websocket
    // m_ssl.set_option(
    //     beast::websocket::stream_base::timeout::suggested(
    //         beast::role_type::client));

    // // Set a decorator to change the User-Agent of the handshake
    // m_ssl.set_option(beast::websocket::stream_base::decorator(
    //     [](beast::websocket::request_type& req)
    //     {
    //         req.set(beast::http::field::user_agent,
    //             std::string(BOOST_BEAST_VERSION_STRING) +
    //                 " websocket-client-otclient-async-ssl");
    //     }));

    // // Perform the websocket handshake
    // m_ssl.async_handshake(
    //     m_domain, instance_uri.query,
    //         [sft = shared_from_this()](
    //             const std::error_code& ec)
    //         {
    //             sft->on_handshake(ec);
    //         });
}

void WebsocketSession::on_handshake(const std::error_code& ec)
{
    if (ec) {
        onError("WebsocketSession unable to handshake " + m_url + ": " + ec.message());
        return;
    }

    if(m_enable_time_out_on_read_write){
        m_timer.expires_after(std::chrono::seconds(m_timeout));
        m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});
    } else {
        m_timer.cancel();
    }

    // m_closed = false;
    // m_callback(WEBSOCKET_OPEN, "open::normal");

    // if(instance_uri.port == "443") {
    //     // Read a message
    //     m_ssl.async_read(
    //         m_streambuf,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec, size_t bytes)
    //             {
    //                 sft->on_read(ec, bytes);
    //             });         
    // } else {
    //     // Read a message
    //     m_socket.async_read(
    //         m_streambuf,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec, size_t bytes)
    //             {
    //                 sft->on_read(ec, bytes);
    //             });        
    // }
}

void WebsocketSession::on_write(const std::error_code& ec, size_t bytes_transferred)
{
    if (ec) {
        onError("WebsocketSession unable to on_write " + m_url + ": " + ec.message());
        return;
    }

    if(m_enable_time_out_on_read_write){
        m_timer.expires_after(std::chrono::seconds(m_timeout));
        m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});
    } else {
        m_timer.cancel();
    }

    // if(m_sendQueue.size() > 0 ) {
    //     m_sendQueue.pop();
    // }

    // // Send the next message if any
    // if(instance_uri.port == "443") {
    //     if(! m_sendQueue.empty())
    //         m_ssl.async_write(
    //             asio::buffer(m_sendQueue.front()),
    //                 [sft = shared_from_this()](
    //                     const std::error_code& ec, size_t bytes)
    //                 {
    //                     sft->on_write(ec, bytes);
    //                 });
    // } else {
    //     if(! m_sendQueue.empty())
    //         m_socket.async_write(
    //             asio::buffer(m_sendQueue.front()),
    //                 [sft = shared_from_this()](
    //                     const std::error_code& ec, size_t bytes)
    //                 {
    //                     sft->on_write(ec, bytes);
    //                 });
    // }
}

void WebsocketSession::on_read(const std::error_code& ec, size_t bytes_transferred)
{
    if (ec) {
        onError("WebsocketSession unable to on_read " + m_url + ": " + ec.message());
        return;
    }

    if(m_enable_time_out_on_read_write){
        m_timer.expires_after(std::chrono::seconds(m_timeout));
        m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});
    } else {
        m_timer.cancel();
    }

    // m_callback(WEBSOCKET_MESSAGE, beast::buffers_to_string(m_streambuf.data()));
    // m_streambuf.consume(m_streambuf.size());

    // stdext::millisleep(100);
    // // Read a message
    // if(instance_uri.port == "443") {
    //     m_ssl.async_read(
    //         m_streambuf,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec, size_t bytes)
    //             {
    //                 sft->on_read(ec, bytes);
    //             });         
    // } else {
    //     m_socket.async_read(
    //         m_streambuf,
    //             [sft = shared_from_this()](
    //                 const std::error_code& ec, size_t bytes)
    //             {
    //                 sft->on_read(ec, bytes);
    //             });        
    // }
}

void WebsocketSession::on_close(const std::error_code& ec)
{
    if (ec) {
        onError("WebsocketSession unable to on_close " + m_url + ": " + ec.message());
        return;
    }
    m_closed = true;
    m_callback(WEBSOCKET_CLOSE, "close_code::normal");
}

void WebsocketSession::onError(const std::string& ec, const std::string& details)
{
    g_logger.error(stdext::format("WebsocketSession error %s", ec));
    m_closed = true;
    m_callback(WEBSOCKET_ERROR, "close_code::error " + ec);
}

void WebsocketSession::onTimeout(const std::error_code& ec)
{
    if (!ec){
        g_logger.error(stdext::format("WebsocketSession ontimeout %s", ec.message()));
        m_closed = true;
        m_callback(WEBSOCKET_ERROR, "close_code::ontimeout " + ec.message());  
        close();
    }    
}

void WebsocketSession::send(std::string data)
{
    // if(instance_uri.port == "443") {
    //     if(m_ssl.is_open() && !m_closed) {
    //         m_sendQueue.push(data);
    //         if(m_sendQueue.size() > 1)
    //             return;

    //         m_ssl.async_write(
    //             asio::buffer(m_sendQueue.front()),
    //                 [sft = shared_from_this()](
    //                     const std::error_code& ec, size_t bytes)
    //                 {
    //                     sft->on_write(ec, bytes);
    //                 });
    //     } else if(!m_ssl.is_open() && m_closed) {
    //         start();
    //         m_closed = false;
    //     }        
    // } else {
    //     if(m_socket.is_open() && !m_closed) {
    //         m_sendQueue.push(data);
    //         if(m_sendQueue.size() > 1)
    //             return;

    //         m_socket.async_write(
    //             asio::buffer(m_sendQueue.front()),
    //                 [sft = shared_from_this()](
    //                     const std::error_code& ec, size_t bytes)
    //                 {
    //                     sft->on_write(ec, bytes);
    //                 });
    //     } else if(!m_socket.is_open() && m_closed) {
    //         start();
    //         m_closed = false;
    //     }
    // }
}

void WebsocketSession::close()
{
    // if(instance_uri.port == "443") {
    //     if(m_ssl.is_open()) {
    //         m_ssl.async_close(
    //             beast::websocket::close_code::normal,
    //                 [sft = shared_from_this()](
    //                     const std::error_code& ec)
    //                 {
    //                     sft->on_close(ec);
    //                 });
    //     }
    // } else {
    //     if(m_socket.is_open()) {
    //         m_socket.async_close(
    //             beast::websocket::close_code::normal,
    //                 [sft = shared_from_this()](
    //                     const std::error_code& ec)
    //                 {
    //                     sft->on_close(ec);
    //                 });
    //     }
    // }
}
#endif