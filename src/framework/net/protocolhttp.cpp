#include <framework/core/eventdispatcher.h>

#include "protocolhttp.h"

#include <zlib.h>
#include <boost/asio/ssl.hpp>
#include <boost/beast/websocket.hpp>

Http g_http;

void Http::init() {
    m_working = true;
    m_thread = std::thread([&] {
        m_ios.run();
    });
}

void Http::terminate() {
    if (!m_working)
        return;
    m_working = false;
    for (auto& ws : m_websockets) {
        ws.second->close();
    }
    for (auto& op : m_operations) {
        op.second->canceled = true;
    }
    m_guard.reset();
    if (!m_thread.joinable()) {
        stdext::millisleep(100);
        m_ios.stop();
    }
    m_thread.join();
}

int Http::get(const std::string& url, int timeout) {
    if (!timeout) // lua is not working with default values
        timeout = 5;
    int operationId = m_operationId++;

    boost::asio::post(m_ios, [&, url, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_custom_header, timeout, result, [&](HttpResult_ptr result) {
            bool finished = result->finished;
            g_dispatcher.addEvent([result, finished] {
                if (!finished) {
                    g_lua.callGlobalField("g_http", "onGetProgress", result->operationId, result->url, result->progress);
                    return;
                }
                g_lua.callGlobalField("g_http", "onGet", result->operationId, result->url, result->error, result->_response);
            });
            if (finished) {
                m_operations.erase(operationId);
            }
        });
        session->start();
    });

    return operationId;
}

int Http::post(const std::string& url, const std::string& data, int timeout) {
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
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_custom_header, timeout, result, [&](HttpResult_ptr result) {
            bool finished = result->finished;
            g_dispatcher.addEvent([result, finished] {
                if (!finished) {
                    g_lua.callGlobalField("g_http", "onPostProgress", result->operationId, result->url, result->progress);
                    return;
                }
                g_lua.callGlobalField("g_http", "onPost", result->operationId, result->url, result->error, result->_response);
            });
            if (finished) {
                m_operations.erase(operationId);
            }
        });
        session->start();
    });
    return operationId;
}

int Http::download(const std::string& url, std::string path, int timeout) {
    if (!timeout) // lua is not working with default values
        timeout = 5;

    int operationId = m_operationId++;
    boost::asio::post(m_ios, [&, url, path, timeout, operationId] {
        auto result = std::make_shared<HttpResult>();
        result->url = url;
        result->operationId = operationId;
        m_operations[operationId] = result;
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, m_custom_header, timeout, result, [&, path](HttpResult_ptr result) {
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
            unsigned long checksum = crc32(crc, (const unsigned char*)result->_response.c_str(), result->_response.size());

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
        auto session = std::make_shared<WebsocketSession>(m_ios, url, m_userAgent, timeout, result, [&, result](WebsocketCallbackType type, std::string message) {
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

bool Http::cancel(int id) {
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
        it->second->canceled = true;
    });
    return true;
}

void HttpSession::start() {
    
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
		boost::beast::bind_front_handler(&HttpSession::on_resolve,
			shared_from_this()));
}

void HttpSession::on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type results){
    if (ec) {
        onError("HttpSession unable to resolve " + m_url + ": " + ec.message());
        return;
    }

    if(instance_uri.port == "443") {
        // Set a timeout on the operation
        boost::beast::get_lowest_layer(m_ssl).expires_after(std::chrono::seconds(m_timeout));

        // Make the connection on the IP address we get from a lookup
        boost::beast::get_lowest_layer(m_ssl).async_connect(
            results,
            boost::beast::bind_front_handler(
                &HttpSession::on_connect,
                shared_from_this()));
    } else {
        // Set a timeout on the operation
        m_socket.expires_after(std::chrono::seconds(m_timeout));

        m_socket.async_connect(results,
            boost::beast::bind_front_handler(&HttpSession::on_connect, 
            shared_from_this()));
    }
}

void HttpSession::on_connect(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type){
    if (ec) {
        onError("HttpSession unable to connect " + m_url + ": " + ec.message());
        return;
    } 

    if(instance_uri.port == "443") {
        // Perform the SSL handshake
        m_ssl.async_handshake(
            boost::asio::ssl::stream_base::client,
            boost::beast::bind_front_handler(
                &HttpSession::on_handshake,
                shared_from_this()));        
    } else {
        m_socket.expires_after(std::chrono::seconds(m_timeout));

        // The connection was successful. Send the request.
        boost::beast::http::async_write(m_socket, m_request,
            boost::beast::bind_front_handler(&HttpSession::on_write,
            shared_from_this()));
    }
}

void HttpSession::on_handshake(const boost::system::error_code& ec)
{
    if (ec) {
        onError("HttpSession unable to handshake " + m_url + ": " + ec.message());
        return;
    }

    // Set a timeout on the operation
    boost::beast::get_lowest_layer(m_ssl).expires_after(std::chrono::seconds(m_timeout));

    // Send the HTTP request to the remote host
    boost::beast::http::async_write(m_ssl, m_request,
        boost::beast::bind_front_handler(
            &HttpSession::on_write,
            shared_from_this()));
}

void HttpSession::on_write(const boost::system::error_code& ec, size_t bytes_transferred){
    if (ec) {
        onError("HttpSession unable to on_write " + m_url + ": " + ec.message());
        return;
    }

    boost::ignore_unused(bytes_transferred);

    if(instance_uri.port == "443") {
        // Receive the HTTP response
        boost::beast::http::async_read(m_ssl, m_streambuf, m_response,
            boost::beast::bind_front_handler(
                &HttpSession::on_read,
                shared_from_this()));        
    } else {
        // Receive the HTTP response
        boost::beast::http::async_read(m_socket, m_streambuf, m_response,
            boost::beast::bind_front_handler(
                &HttpSession::on_read,
                shared_from_this()));
    }
}

void HttpSession::on_read(const boost::system::error_code& ec, size_t bytes_transferred) {

    if (ec) {
        onError("HttpSession unable to on_read " + m_url + ": " + ec.message());
        return;
    }

    boost::ignore_unused(bytes_transferred);

    m_result->_response = boost::beast::buffers_to_string(m_response.get().body().data());

    // not_connected happens sometimes so don't bother reporting it.
    if(ec && ec != boost::beast::errc::not_connected){
        std::cout << "shutdown " << m_url << ": "
            << ec.message() << std::endl;    
        return;
    }

    m_result->finished = true;
    m_callback(m_result);
}

void HttpSession::onError(const std::string& error, const std::string& details) {
    g_logger.error(stdext::format("%s", error));
}

void WebsocketSession::start(){
    instance_uri = parseURI(m_url);
    boost::asio::ip::tcp::resolver::query query_resolver(instance_uri.domain, instance_uri.port);
    m_domain = instance_uri.domain;

	m_resolver.async_resolve(
		query_resolver,
		boost::beast::bind_front_handler(&WebsocketSession::on_resolve,
			shared_from_this()));
}

void WebsocketSession::on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type results) {
    if (ec) {
        onError("WebsocketSession unable to resolve " + m_url + ": " + ec.message());
        return;
    }

    if(instance_uri.port == "443") {
        // Set a timeout on the operation
        boost::beast::get_lowest_layer(m_ssl).expires_after(std::chrono::seconds(m_timeout));

        // Make the connection on the IP address we get from a lookup
        boost::beast::get_lowest_layer(m_ssl).async_connect(
            results,
            boost::beast::bind_front_handler(
                &WebsocketSession::on_connect,
                shared_from_this()));        
    } else {
        // Set the timeout for the operation
        boost::beast::get_lowest_layer(m_socket).expires_after(std::chrono::seconds(m_timeout));

        // Make the connection on the IP address we get from a lookup
        boost::beast::get_lowest_layer(m_socket).async_connect(
            results,
            boost::beast::bind_front_handler(
                &WebsocketSession::on_connect,
                shared_from_this()));
    }
}

void WebsocketSession::on_connect(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type) {
    if (ec) {
        onError("WebsocketSession unable to on_connect " + m_url + ": " + ec.message());
        return;
    }

    if(instance_uri.port == "443") {
        // Set a timeout on the operation
        boost::beast::get_lowest_layer(m_ssl).expires_after(std::chrono::seconds(m_timeout));

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
            boost::beast::bind_front_handler(
                &WebsocketSession::on_ssl_handshake,
                shared_from_this()));        
    } else {
        // Turn off the timeout on the tcp_stream, because
        // the websocket stream has its own timeout system.
        boost::beast::get_lowest_layer(m_socket).expires_never();

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

        // Update the host_ string. This will provide the value of the
        // Host HTTP header during the WebSocket handshake.
        // See https://tools.ietf.org/html/rfc7230#section-5.4
        m_domain += ':' + instance_uri.port;

        // Perform the websocket handshake
        m_socket.async_handshake(m_domain, instance_uri.query,
            boost::beast::bind_front_handler(
                &WebsocketSession::on_handshake,
                shared_from_this()));
    }
}

void WebsocketSession::on_ssl_handshake(const boost::system::error_code& ec) {
    if (ec) {
        onError("WebsocketSession unable to ssl_handshake " + m_url + ": " + ec.message());
        return;
    }

    // Turn off the timeout on the tcp_stream, because
    // the websocket stream has its own timeout system.
    boost::beast::get_lowest_layer(m_ssl).expires_never();

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
    m_ssl.async_handshake(m_domain, instance_uri.query,
        boost::beast::bind_front_handler(
            &WebsocketSession::on_handshake,
            shared_from_this()));
}

void WebsocketSession::on_handshake(const boost::system::error_code& ec)
{
    if (ec) {
        onError("WebsocketSession unable to handshake " + m_url + ": " + ec.message());
        return;
    }

    m_closed = false;
    m_callback(WEBSOCKET_OPEN, "open::normal");

    if(instance_uri.port == "443") {
        // Send the message
        m_ssl.async_write(
            boost::asio::buffer(m_sendQueue.front()),
            boost::beast::bind_front_handler(
                &WebsocketSession::on_write,
                shared_from_this()));     
    } else {
        // Send the message
        m_socket.async_write(
            boost::asio::buffer(m_sendQueue.front()),
            boost::beast::bind_front_handler(
                &WebsocketSession::on_write,
                shared_from_this()));
    }
}

void WebsocketSession::on_write(const boost::system::error_code& ec, size_t bytes_transferred){
    if (ec) {
        onError("WebsocketSession unable to on_write " + m_url + ": " + ec.message());
        return;
    }

    boost::ignore_unused(bytes_transferred);

    if(m_sendQueue.size() > 0 ) {
        m_sendQueue.pop();
    }

    if(instance_uri.port == "443") {
        // Read a message into our buffer
        m_ssl.async_read(
            m_streambuf,
            boost::beast::bind_front_handler(
                &WebsocketSession::on_read,
                shared_from_this()));
    } else {
        // Read a message into our buffer
        m_socket.async_read(
            m_streambuf,
            boost::beast::bind_front_handler(
                &WebsocketSession::on_read,
                shared_from_this()));
    }
}

void WebsocketSession::on_read(const boost::system::error_code& ec, size_t bytes_transferred) {
    if (ec) {
        onError("WebsocketSession unable to on_read " + m_url + ": " + ec.message());
        return;
    }

    boost::ignore_unused(bytes_transferred);
    m_callback(WEBSOCKET_MESSAGE, boost::beast::buffers_to_string(m_streambuf.data())); 
    // m_streambuf.consume(m_streambuf.size());
    m_streambuf.clear();

    stdext::millisleep(100);
    if(instance_uri.port == "443") {
        m_ssl.async_read(
            m_streambuf,
            boost::beast::bind_front_handler(
                &WebsocketSession::on_read,
                shared_from_this()));        
    } else {
        m_socket.async_read(
            m_streambuf,
            boost::beast::bind_front_handler(
                &WebsocketSession::on_read,
                shared_from_this()));
    }
}

void WebsocketSession::on_close(const boost::system::error_code& ec) {
    if (ec) {
        onError("WebsocketSession unable to on_close " + m_url + ": " + ec.message());
        return;
    }
    m_closed = true;
    m_callback(WEBSOCKET_CLOSE, "close_code::normal");
}

void WebsocketSession::onError(const std::string& error, const std::string& details) {
    g_logger.error(stdext::format("WebsocketSession error %s", error));
    m_closed = true;
    m_callback(WEBSOCKET_ERROR, "close_code::error " + error);
}

void WebsocketSession::send(std::string data){
    if(instance_uri.port == "443") {
        if(m_ssl.is_open() && !m_closed) {
            m_sendQueue.push(data);
            m_ssl.write(boost::asio::buffer(m_sendQueue.front()));
            m_sendQueue.pop();
        } else {
            //  connect again
            start();
        }        
    } else {
        if(m_socket.is_open() && !m_closed) {
            m_sendQueue.push(data);
            m_socket.write(boost::asio::buffer(m_sendQueue.front()));
            m_sendQueue.pop();
        } else {
            //  connect again
            start();
        }
    }
}

void WebsocketSession::close(){
    if(instance_uri.port == "443") {
        // Close the WebSocket connection
        if(m_ssl.is_open()) {
            m_ssl.async_close(boost::beast::websocket::close_code::normal,
                boost::beast::bind_front_handler(
                    &WebsocketSession::on_close,
                    shared_from_this()));
        }
    } else {
        // Close the WebSocket connection
        if(m_socket.is_open()) {
            m_socket.async_close(boost::beast::websocket::close_code::normal,
                boost::beast::bind_front_handler(
                    &WebsocketSession::on_close,
                    shared_from_this()));
        }
    }
}