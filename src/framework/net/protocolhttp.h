#ifndef  PROTOCOLHTTP_H
#define PROTOCOLHTTP_H

#include <framework/global.h>
#include <framework/stdext/uri.h>

#include <vector>
#include <iostream>
#include <string>
#include <memory>
#include <functional>
#include <future>
#include <queue>

#include <boost/asio.hpp>
#include <boost/beast.hpp>
#include <boost/beast/ssl/ssl_stream.hpp>
#include <boost/asio/io_service.hpp>
#include <boost/asio/ssl.hpp>

//  result
class HttpSession;

struct HttpResult {
    std::string url;
    int operationId = 0;
    int status = 0;
    int size = 0;
    int progress = 0; // from 0 to 100
    int redirects = 0; // redirect
    bool connected = false;
    bool finished = false;
    bool canceled = false;
    std::string postData;
    std::vector<uint8_t> response;
    std::string error;
    std::weak_ptr<HttpSession> session;
    std::string _response;
};


using HttpResult_ptr = std::shared_ptr<HttpResult>;
using HttpResult_cb = std::function<void(HttpResult_ptr)>;


//  session

class HttpSession : public std::enable_shared_from_this<HttpSession>
{
public:

    HttpSession(boost::asio::io_service& service, const std::string& url, const std::string& agent, 
            const std::map<std::string, std::string>& custom_header,
            int timeout, HttpResult_ptr result, HttpResult_cb callback) :
                m_service(service),
                m_url(url),
                m_agent(agent),
                m_custom_header(custom_header),
                m_timeout(timeout),
                m_result(result),
                m_callback(callback),
                m_socket(service),
                m_resolver(service),
                m_timer(service)
    {
        assert(m_callback != nullptr);
        assert(m_result != nullptr);
        m_ssl.set_verify_mode(boost::asio::ssl::verify_none);
    };
    void start();
    void cancel() { onError("canceled"); }
    
private:
    boost::asio::io_service& m_service;
    std::string m_url;
    std::string m_agent;
    std::map<std::string, std::string> m_custom_header;
    int m_timeout;
    HttpResult_ptr m_result;
    HttpResult_cb m_callback;
    boost::beast::tcp_stream m_socket;    
    boost::asio::ip::tcp::resolver m_resolver;
    boost::asio::steady_timer m_timer;
    ParsedURI instance_uri;

    boost::asio::ssl::context m_context{ boost::asio::ssl::context::sslv23_client };
    boost::asio::ssl::stream<boost::beast::tcp_stream> m_ssl{ m_service, m_context };

    boost::beast::flat_buffer m_streambuf{ 512 * 1024 * 1024 }; // (Must persist between reads)
    boost::beast::http::request<boost::beast::http::string_body> m_request;
    boost::beast::http::response_parser<boost::beast::http::dynamic_body> m_response;

    void on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type iterator);
    void on_connect(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type);

    void on_handshake(const boost::system::error_code& ec);

    void on_write(const boost::system::error_code& ec, size_t bytes_transferred);
    void on_read(const boost::system::error_code& ec, size_t bytes_transferred);

    void close();
    void onError(const std::string& error, const std::string& details = "");
};

//  web socket
enum WebsocketCallbackType {
    WEBSOCKET_OPEN,
    WEBSOCKET_MESSAGE,
    WEBSOCKET_ERROR,
    WEBSOCKET_CLOSE
};

using WebsocketSession_cb = std::function<void(WebsocketCallbackType, std::string message)>;

class WebsocketSession : public std::enable_shared_from_this<WebsocketSession>
{
public:

    WebsocketSession(boost::asio::io_service& service, const std::string& url, const std::string& agent, int timeout, HttpResult_ptr result, WebsocketSession_cb callback) :
            m_service(service),
            m_url(url),
            m_agent(agent),
            m_timeout(timeout),
            m_result(result),
            m_callback(callback),
            m_timer(service),
            m_resolver(service)
    {
        assert(m_callback != nullptr);
        assert(m_result != nullptr);
    };

    void start();
    void send(std::string data);
    void close();

private:
    boost::asio::io_service& m_service;
    std::string m_url;
    std::string m_agent;
    int m_timeout;
    HttpResult_ptr m_result;
    WebsocketSession_cb m_callback;
    boost::asio::steady_timer m_timer;
    boost::asio::ip::tcp::resolver m_resolver;
    bool m_closed;
    ParsedURI instance_uri;
    std::string m_domain;

    boost::beast::websocket::stream<boost::beast::tcp_stream> m_socket{m_service};
    boost::asio::ssl::context m_context{ boost::asio::ssl::context::sslv23_client };
    boost::beast::websocket::stream<boost::beast::ssl_stream<boost::beast::tcp_stream>> m_ssl{ m_service, m_context };

    boost::beast::flat_buffer m_streambuf{ 16 * 1024 * 1024 }; // limited to 16MB
    std::queue<std::string> m_sendQueue;

    void on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type results);
    void on_connect(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::results_type::endpoint_type);
    void on_ssl_handshake(const boost::system::error_code& ec);
    void on_handshake(const boost::system::error_code& ec);

    void on_write(const boost::system::error_code& ec, size_t bytes_transferred);
    void on_read(const boost::system::error_code& ec, size_t bytes_transferred);

    void on_close(const boost::system::error_code& ec);
    void onTimeout(const boost::system::error_code& error);
    void onError(const std::string& error, const std::string& details = "");
};

class Http {
public:
    Http() : m_ios(), m_guard(boost::asio::make_work_guard(m_ios)) {}

    void init();
    void terminate();

    int get(const std::string& url, int timeout = 5);
    int post(const std::string& url, const std::string& data, int timeout = 5);
    int download(const std::string& url, std::string path, int timeout = 5);
    int ws(const std::string& url, int timeout = 5);
    bool wsSend(int operationId, std::string message);
    bool wsClose(int operationId);

    bool cancel(int id);

    const std::map<std::string, HttpResult_ptr>& downloads() {
        return m_downloads;
    }
    void clearDownloads() {
        m_downloads.clear();
    }
    HttpResult_ptr getFile(std::string path) {
        if (!path.empty() && path[0] == '/')
            path = path.substr(1);
        auto it = m_downloads.find(path);
        if (it == m_downloads.end())
            return nullptr;
        return it->second;
    }

    void setUserAgent(const std::string& userAgent)
    {
        m_userAgent = userAgent;
    }

    void addCustomHeader(std::string name, std::string value) {
        m_custom_header[name] = value;
    }

private:
    bool m_working = false;
    int m_operationId = 1;
    int m_speed = 0;
    size_t m_lastSpeedUpdate = 0;
    std::thread m_thread;
    boost::asio::io_context m_ios;
    boost::asio::executor_work_guard<boost::asio::io_context::executor_type> m_guard;
    std::map<int, HttpResult_ptr> m_operations;
    std::map<int, std::shared_ptr<WebsocketSession>> m_websockets;
    std::map<std::string, HttpResult_ptr> m_downloads;
    std::string m_userAgent = "Mozilla/5.0";
    std::map<std::string, std::string> m_custom_header;
};

extern Http g_http;

#endif // ! PROTOCOLHTTP_H
