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
    m_working = false;
    for (auto& ws : m_websockets) {
        ws.second->close();
    }
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

    boost::asio::post(m_ios, [&, url, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_enable_time_out_on_read_write, m_custom_header, timeout, result, [&](HttpResult_ptr result) {
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

int Http::post(const std::string& url, const std::string& data, int timeout) 
{
    if (!timeout) // lua is not working with default values
        timeout = 5;
    if (data.empty()) {
        g_logger.error(stdext::format("Invalid post request for %s, empty data, use get instead", url));
        return -1;
    }

    int operationId = m_operationId++;
    boost::asio::post(m_ios, [&, url, data, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        result->postData = data;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_enable_time_out_on_read_write, m_custom_header, timeout, result, [&](HttpResult_ptr result) {
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
    boost::asio::post(m_ios, [&, url, path, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_enable_time_out_on_read_write, m_custom_header, timeout, result, [&, path](HttpResult_ptr result) {
            m_speed = ((result->size) * 10) / (1 + stdext::micros() - m_lastSpeedUpdate);
            m_lastSpeedUpdate = stdext::micros();

            if (!result->finished) {
                int speed = m_speed;
                g_dispatcher.addEvent([result, speed] {
                    g_lua.callGlobalField("g_http", "onDownloadProgress", result->operationId, result->url, result->progress, speed);
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

int Http::ws(const std::string& url, int timeout)
{
    if (!timeout) // lua is not working with default values
        timeout = 5;
    int operationId = m_operationId++;

    boost::asio::post(m_ios, [&, url, timeout, operationId] {
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
    boost::asio::post(m_ios, [&, operationId, message] {
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

bool Http::cancel(int id) 
{
    boost::asio::post(m_ios, [&, id] {
        auto wit = m_websockets.find(id);
        if (wit != m_websockets.end()) {
            wit->second->close();
        }        
        auto it = m_operations.find(id);
        if (it == m_operations.end())
            return;
        if (it->second->canceled)
            return;
        auto session = it->second->session.lock();
        if(session)
            session->close();
    });
    return true;
}

void HttpSession::start() 
{
    
    instance_uri = parseURI(m_url);
    boost::asio::ip::tcp::resolver::query query_resolver(instance_uri.domain, instance_uri.port);

    m_response.body_limit((std::numeric_limits<std::uint64_t>::max)());

    m_request.version(11);
    m_request.target(instance_uri.query);
    m_request.set(boost::beast::http::field::host, instance_uri.domain);
    m_request.set(boost::beast::http::field::user_agent, m_agent);    
    if(m_result->postData == "") {
        m_request.method(boost::beast::http::verb::get);
    } else {
        m_request.method(boost::beast::http::verb::post);
        m_request.set(boost::beast::http::field::accept, "*/*");
        m_request.set(boost::beast::http::field::content_type, "application/json");
        m_request.set(boost::beast::http::field::content_length, std::to_string(m_result->postData.size()));
        m_request.body() = m_result->postData;
    }

    for (auto& ch : m_custom_header) {
        m_request.insert(ch.first, ch.second);
    }

	m_resolver.async_resolve(
		query_resolver,
            [sft = shared_from_this()](
                const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type results)
            {
                sft->on_resolve(ec, results);
            });
}

void HttpSession::on_resolve(const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type results)
{
    if (ec) {
        onError("HttpSession unable to resolve " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    // Make the connection on the IP address we get from a lookup
    if(instance_uri.port == "443") {
        boost::beast::get_lowest_layer(m_ssl).async_connect(
            results,
                [sft = shared_from_this()](
                    const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type et)
                {
                    sft->on_connect(ec, et);
                });
    } else {
        m_socket.async_connect(
            results,
                [sft = shared_from_this()](
                    const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type et)
                {
                    sft->on_connect(ec, et);
                });
    }
}

void HttpSession::on_connect(const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type)
{
    if (ec) {
        onError("HttpSession unable to connect " + m_url + ": " + ec.message());
        return;
    } 

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    if(instance_uri.port == "443") {
        m_ssl.async_handshake(
            boost::asio::ssl::stream_base::client,
                [sft = shared_from_this()](
                    const std::error_code& ec)
                {
                    sft->on_handshake(ec);
                });
    } else {
        boost::beast::http::async_write(
            m_socket, m_request,
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_write(ec, bytes);
                });
    }
}

void HttpSession::on_handshake(const std::error_code& ec)
{
    if (ec) {
        onError("HttpSession unable to handshake " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    // Send the HTTP request to the remote host
    boost::beast::http::async_write(
        m_ssl, m_request,
            [sft = shared_from_this()](
                const std::error_code& ec, size_t bytes)
            {
                sft->on_write(ec, bytes);
            });
}

void HttpSession::on_write(const std::error_code& ec, size_t bytes_transferred)
{
    if (ec) {
        onError("HttpSession unable to on_write " + m_url + ": " + ec.message());
        return;
    }

    if(m_enable_time_out_on_read_write){
        m_timer.expires_after(std::chrono::seconds(m_timeout));
        m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});
    } else {
        m_timer.cancel();
    }

    boost::ignore_unused(bytes_transferred);

        // Receive the HTTP response
    if(instance_uri.port == "443") {
        boost::beast::http::async_read(
            m_ssl, m_streambuf, m_response,
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });
    } else {
        boost::beast::http::async_read(
            m_socket, m_streambuf, m_response,
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });
    }
}

void HttpSession::on_read(const std::error_code& ec, size_t bytes_transferred)
{
    if (ec) {
        onError("HttpSession unable to on_read " + m_url + ": " + ec.message());
        return;
    }

    if(m_enable_time_out_on_read_write){
        m_timer.expires_after(std::chrono::seconds(m_timeout));
        m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});
    } else {
        m_timer.cancel();
    }

    boost::ignore_unused(bytes_transferred);

    m_result->response = boost::beast::buffers_to_string(m_response.get().body().data());

    // not_connected happens sometimes so don't bother reporting it.
    if(ec && ec != make_error_code(boost::beast::errc::not_connected)){
        std::cout << "shutdown " << m_url << ": " << ec.message() << std::endl;
        return;
    }

    m_result->finished = true;
    m_callback(m_result);
}

void HttpSession::close()
{
    m_result->canceled = true;
    g_logger.error(stdext::format("HttpSession close"));
    if(instance_uri.port == "443") {    
        m_ssl.async_shutdown(
            [sft = shared_from_this()](
                boost::beast::error_code ec)
            {
                if(ec ==  boost::asio::error::eof){
                    ec = {};
                }

                if(ec){
                    sft->onError("shutdown " + sft->m_url + ": " + ec.message());
                    return;
                }
            });
    } else {
        boost::beast::error_code ec;
        m_socket.socket().shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);

        // not_connected happens sometimes so don't bother reporting it.
        if(ec && ec != boost::beast::errc::not_connected){
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

void WebsocketSession::start()
{
    instance_uri = parseURI(m_url);
    boost::asio::ip::tcp::resolver::query query_resolver(instance_uri.domain, instance_uri.port);
    m_domain = instance_uri.domain;

	m_resolver.async_resolve(
		query_resolver,
            [sft = shared_from_this()](
                const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type results)
            {
                sft->on_resolve(ec, results);
            });
}

void WebsocketSession::on_resolve(const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type results)
{
    if (ec) {
        onError("WebsocketSession unable to resolve " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    // Make the connection on the IP address we get from a lookup
    if(instance_uri.port == "443") {
        boost::beast::get_lowest_layer(m_ssl).async_connect(
            results,
                [sft = shared_from_this()](
                    const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type et)
                {
                    sft->on_connect(ec, et);
                });     
    } else {
        boost::beast::get_lowest_layer(m_socket).async_connect(
            results,
                [sft = shared_from_this()](
                    const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type et)
                {
                    sft->on_connect(ec, et);
                });
    }
}

void WebsocketSession::on_connect(const std::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type)
{
    if (ec) {
        onError("WebsocketSession unable to on_connect " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    if(instance_uri.port == "443") {
        // Set SNI Hostname (many hosts need this to handshake successfully)
        if(! SSL_set_tlsext_host_name(
                m_ssl.next_layer().native_handle(),
                m_domain.c_str()))
        {
            auto _ec = boost::beast::error_code(static_cast<int>(::ERR_get_error()),
                boost::asio::error::get_ssl_category());
             onError("WebsocketSession unable to ssl connect" + _ec.message());
             return;
        }

        // Update the host_ string. This will provide the value of the
        // Host HTTP header during the WebSocket handshake.
        // See https://tools.ietf.org/html/rfc7230#section-5.4
        m_domain += ':' + instance_uri.port;
        
        // Perform the SSL handshake
        m_ssl.next_layer().async_handshake(
            boost::asio::ssl::stream_base::client,
                [sft = shared_from_this()](
                    const std::error_code& ec)
                {
                    sft->on_ssl_handshake(ec);
                }); 
    } else {
        // Set suggested timeout settings for the websocket
        m_socket.set_option(
            boost::beast::websocket::stream_base::timeout::suggested(
                boost::beast::role_type::client));

        // Set a decorator to change the User-Agent of the handshake
        m_socket.set_option(boost::beast::websocket::stream_base::decorator(
            [](boost::beast::websocket::request_type& req)
            {
                req.set(boost::beast::http::field::user_agent,
                    std::string(BOOST_BEAST_VERSION_STRING) +
                        " websocket-client-otclient");
            }));

        m_domain += ':' + instance_uri.port;

        m_socket.async_handshake(
            m_domain, instance_uri.query,
                [sft = shared_from_this()](
                    const std::error_code& ec)
                {
                    sft->on_handshake(ec);
                });
    }
}

void WebsocketSession::on_ssl_handshake(const std::error_code& ec)
{
    if (ec) {
        onError("WebsocketSession unable to ssl_handshake " + m_url + ": " + ec.message());
        return;
    }

    m_timer.expires_after(std::chrono::seconds(m_timeout));
    m_timer.async_wait([sft = shared_from_this()](const std::error_code& ec){sft->onTimeout(ec);});

    // Set suggested timeout settings for the websocket
    m_ssl.set_option(
        boost::beast::websocket::stream_base::timeout::suggested(
            boost::beast::role_type::client));

    // Set a decorator to change the User-Agent of the handshake
    m_ssl.set_option(boost::beast::websocket::stream_base::decorator(
        [](boost::beast::websocket::request_type& req)
        {
            req.set(boost::beast::http::field::user_agent,
                std::string(BOOST_BEAST_VERSION_STRING) +
                    " websocket-client-otclient-async-ssl");
        }));

    // Perform the websocket handshake
    m_ssl.async_handshake(
        m_domain, instance_uri.query,
            [sft = shared_from_this()](
                const std::error_code& ec)
            {
                sft->on_handshake(ec);
            });
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

    m_closed = false;
    m_callback(WEBSOCKET_OPEN, "open::normal");

    if(instance_uri.port == "443") {
        // Read a message
        m_ssl.async_read(
            m_streambuf,
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });         
    } else {
        // Read a message
        m_socket.async_read(
            m_streambuf,
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });        
    }
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

    boost::ignore_unused(bytes_transferred);

    if(m_sendQueue.size() > 0 ) {
        m_sendQueue.pop();
    }

    // Send the next message if any
    if(instance_uri.port == "443") {
        if(! m_sendQueue.empty())
            m_ssl.async_write(
                boost::asio::buffer(m_sendQueue.front()),
                    [sft = shared_from_this()](
                        const std::error_code& ec, size_t bytes)
                    {
                        sft->on_write(ec, bytes);
                    });
    } else {
        if(! m_sendQueue.empty())
            m_socket.async_write(
                boost::asio::buffer(m_sendQueue.front()),
                    [sft = shared_from_this()](
                        const std::error_code& ec, size_t bytes)
                    {
                        sft->on_write(ec, bytes);
                    });
    }
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

    boost::ignore_unused(bytes_transferred);
    m_callback(WEBSOCKET_MESSAGE, boost::beast::buffers_to_string(m_streambuf.data()));
    m_streambuf.consume(m_streambuf.size());

    stdext::millisleep(100);
    // Read a message
    if(instance_uri.port == "443") {
        m_ssl.async_read(
            m_streambuf,
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });         
    } else {
        m_socket.async_read(
            m_streambuf,
                [sft = shared_from_this()](
                    const std::error_code& ec, size_t bytes)
                {
                    sft->on_read(ec, bytes);
                });        
    }
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
    if(instance_uri.port == "443") {
        if(m_ssl.is_open() && !m_closed) {
            m_sendQueue.push(data);
            if(m_sendQueue.size() > 1)
                return;

            m_ssl.async_write(
                boost::asio::buffer(m_sendQueue.front()),
                    [sft = shared_from_this()](
                        const std::error_code& ec, size_t bytes)
                    {
                        sft->on_write(ec, bytes);
                    });
        } else if(!m_ssl.is_open() && m_closed) {
            start();
            m_closed = false;
        }        
    } else {
        if(m_socket.is_open() && !m_closed) {
            m_sendQueue.push(data);
            if(m_sendQueue.size() > 1)
                return;

            m_socket.async_write(
                boost::asio::buffer(m_sendQueue.front()),
                    [sft = shared_from_this()](
                        const std::error_code& ec, size_t bytes)
                    {
                        sft->on_write(ec, bytes);
                    });
        } else if(!m_socket.is_open() && m_closed) {
            start();
            m_closed = false;
        }
    }
}

void WebsocketSession::close()
{
    if(instance_uri.port == "443") {
        if(m_ssl.is_open()) {
            m_ssl.async_close(
                boost::beast::websocket::close_code::normal,
                    [sft = shared_from_this()](
                        const std::error_code& ec)
                    {
                        sft->on_close(ec);
                    });
        }
    } else {
        if(m_socket.is_open()) {
            m_socket.async_close(
                boost::beast::websocket::close_code::normal,
                    [sft = shared_from_this()](
                        const std::error_code& ec)
                    {
                        sft->on_close(ec);
                    });
        }
    }
}