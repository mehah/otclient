#include <framework/core/eventdispatcher.h>

#include "protocolhttp.h"

#include <zlib.h>

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
    m_port = stoi(instance_uri.port);
    boost::asio::ip::tcp::resolver::query query_resolver(instance_uri.domain, instance_uri.port);

    m_response.body_limit((std::numeric_limits<std::uint64_t>::max)());

	m_resolver.async_resolve(
		query_resolver,
		boost::beast::bind_front_handler(&HttpSession::on_resolve,
			shared_from_this()));
}

void HttpSession::on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type results){
    if (ec) {
        std::cout << "Unable to resolve " << m_url << ": "
            << ec.message() << std::endl;
        return;
    }

    // Set a timeout on the operation
    m_socket.expires_after(std::chrono::seconds(m_timeout));

    m_socket.async_connect(results,
        boost::beast::bind_front_handler(&HttpSession::on_connect, 
        shared_from_this()));
}

void HttpSession::on_connect(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type){
    if (ec) {
        std::cout << "Unable to connect " << m_url << ": "
            << ec.message() << std::endl;
        return;
    } 

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

    m_socket.expires_after(std::chrono::seconds(m_timeout));

    // The connection was successful. Send the request.
    boost::beast::http::async_write(m_socket, m_request,
        boost::beast::bind_front_handler(&HttpSession::on_write,
        shared_from_this()));    
}

void HttpSession::on_write(const boost::system::error_code& ec, size_t bytes_transferred){
    if (ec) {
        std::cout << "Unable to on_write " << m_url << ": "
            << ec.message() << std::endl;
        return;
    }
    boost::ignore_unused(bytes_transferred);

    // Receive the HTTP response
    boost::beast::http::async_read(m_socket, m_streambuf, m_response,
        boost::beast::bind_front_handler(
            &HttpSession::on_read,
            shared_from_this()));
}

void HttpSession::on_read(const boost::system::error_code& ec, size_t bytes_transferred) {

    if (ec) {
        std::cout << "Unable to on_read " << m_url << ": "
            << ec.message() << std::endl;
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
    g_logger.error(stdext::format("HttpSession error %s", error));
}

void WebsocketSession::start(){
    std::cout << "WebsocketSession::start\n";
}

void WebsocketSession::send(std::string data){
    std::cout << "WebsocketSession::send\n";
}

void WebsocketSession::close(){
    std::cout << "WebsocketSession::close\n";
}
