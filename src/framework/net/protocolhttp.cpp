#include <framework/core/eventdispatcher.h>

#include "protocolhttp.h"

#include <zlib.h>

#include <boost/asio.hpp>
#include <boost/bind.hpp>

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
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, timeout, result, [&](HttpResult_ptr result) {
            bool finished = result->finished;
            g_dispatcher.addEvent([result, finished] {
                if (!finished) {
                    g_lua.callGlobalField("g_http", "onGetProgress", result->operationId, result->url, result->progress);
                    return;
                }
                g_lua.callGlobalField("g_http", "onGet", result->operationId, result->url, result->error, std::string(result->response.begin(), result->response.end()));
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
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, timeout, result, [&](HttpResult_ptr result) {
            bool finished = result->finished;
            g_dispatcher.addEvent([result, finished] {
                if (!finished) {
                    g_lua.callGlobalField("g_http", "onPostProgress", result->operationId, result->url, result->progress);
                    return;
                }
                g_lua.callGlobalField("g_http", "onPost", result->operationId, result->url, result->error, std::string(result->response.begin(), result->response.end()));
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
        auto session = std::make_shared<HttpSession>(m_ios, url, m_userAgent, timeout, result, [&, path](HttpResult_ptr result) {
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
            std::string str_result = std::string(result->response.begin(), result->response.end());
            unsigned long checksum = crc32(crc, (const unsigned char*)str_result.c_str(), str_result.size());

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
    m_domain = instance_uri.domain;
    boost::asio::ip::tcp::resolver::query query_resolver(instance_uri.domain, instance_uri.port);

    std::unique_lock<std::mutex>
        cancel_lock(m_cancel_mux);

    if (m_was_cancelled) {
        cancel_lock.unlock();
        on_finish(boost::system::error_code(
            boost::asio::error::operation_aborted));
        return;
    }

	m_resolver.async_resolve(
		query_resolver,
		boost::bind(&HttpSession::on_resolve,
			shared_from_this(),
			boost::asio::placeholders::error,
            boost::asio::placeholders::iterator));
}

void HttpSession::on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::iterator iterator){
    if (ec) {
        std::cout << "Unable to resolve " << m_url << ": "
            << ec.message() << std::endl;
        return;
    }

    std::ostream request_stream(&m_request);
    request_stream << "GET " << instance_uri.query << " HTTP/1.0\r\n";
    request_stream << "Host: " << iterator->endpoint().address().to_string()  << "\r\n";
    request_stream << "Accept: */*\r\n";
    request_stream << "Connection: close\r\n\r\n";
        
      // Attempt a connection to each endpoint in the list until we
      // successfully establish a connection.
      boost::asio::async_connect(m_socket, iterator,
          boost::bind(&HttpSession::on_connect, 
            shared_from_this(),
            boost::asio::placeholders::error));
}

void HttpSession::on_connect(const boost::system::error_code& ec){
    if (ec) {
        std::cout << "Unable to resolve " << m_url << ": "
            << ec.message() << std::endl;
        return;
    } 
    
    // The connection was successful. Send the request.
    boost::asio::async_write(m_socket, m_request,
        boost::bind(&HttpSession::on_request_sent,
        shared_from_this(),
        boost::asio::placeholders::error));    
}

void HttpSession::on_request_sent(const boost::system::error_code& ec)
{
    if (ec) {
        std::cout << "on_request_sent " << ec.message() << std::endl;
        return;
    }

    boost::asio::async_read_until(m_socket, m_response, "\r\n",
        boost::bind(&HttpSession::on_read_header, 
        shared_from_this(),
        boost::asio::placeholders::error));
}

void HttpSession::on_read_header(const boost::system::error_code& ec) {
    if (ec) {
        std::cout << "on_read_header " << ec.message() << std::endl;
        return;
    }
    // Check that response is OK.
    std::istream response_stream(&m_response);
    std::string http_version;
    response_stream >> http_version;
    unsigned int status_code;
    response_stream >> status_code;
    std::string status_message;
    std::getline(response_stream, status_message);
    if (!response_stream || http_version.substr(0, 5) != "HTTP/")
    {
        std::cout << "Invalid response\n";
        return;
    }
    if (status_code != 200)
    {
        std::cout << "Response returned with status code ";
        std::cout << status_code << "\n";
        return;
    }

    // Read the response headers, which are terminated by a blank line.
    boost::asio::async_read_until(m_socket, m_response, "\r\n\r\n",
        boost::bind(&HttpSession::handle_read_headers, 
        shared_from_this(),
        boost::asio::placeholders::error));
}
void HttpSession::handle_read_headers(const boost::system::error_code& ec){
    if (ec) {
        std::cout << "handle_read_headers " << ec.message() << std::endl;
        return;
    }

    // Process the response headers.
    std::istream response_stream(&m_response);
    std::string header;
    while (std::getline(response_stream, header) && header != "\r")
    std::cout << header << "\n";
    std::cout << "\n";

    // Write whatever content we already have to output.
    if (m_response.size() > 0)
    std::cout << &m_response;

    // Start reading remaining data until EOF.
    boost::asio::async_read(m_socket, m_response,
        boost::asio::transfer_at_least(1),
        boost::bind(&HttpSession::on_read,
        shared_from_this(),
        boost::asio::placeholders::error));
}

void HttpSession::on_read(const boost::system::error_code& ec) {

    if (!ec) {
    // if(ec == boost::asio::error::eof) {
    //     m_callback(m_result);
    //     std::cout << m_result->_response;
    // } else {
        // Write all of the data that has been read so far.
        // std::cout << &m_response;
        m_result->_response.append(boost::beast::buffers_to_string(m_response.data()));

        // Continue reading remaining data until EOF.
        boost::asio::async_read(m_socket, m_response,
            boost::asio::transfer_at_least(1),
            boost::bind(&HttpSession::on_read,
            shared_from_this(),
            boost::asio::placeholders::error));
    }
    else if (ec != boost::asio::error::eof) {
        std::cout << "on_read " << ec.message() << std::endl;
        return;
    }
    else if (ec == boost::asio::error::eof) {
        std::cout << m_result->_response;
    }    
}

void HttpSession::onTimeout(const boost::system::error_code& error){
  if (error != boost::asio::error::operation_aborted)
  {
    std::cout << "Timeout, url: " << m_url << std::endl;
  }    
}

void HttpSession::onError(const std::string& error, const std::string& details) {
    g_logger.error(stdext::format("HttpSession error %s", error));
}

void HttpSession::on_finish(const boost::system::error_code& ec)
{
    if (ec) {
        std::cout << "Error occured! Error code = "
            << ec.value()
            << ". Message: " << ec.message();
    }

    // m_callback(*this, m_response, ec);

    return;
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
