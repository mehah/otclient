#ifndef  HTTP_H
#define HTTP_H

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

// error handling
// #if defined(NDEBUG)
// #define VALIDATE(expression) ((void)0)
// #else
// extern void fatalError(const char* error, const char* file, int line);
// #define VALIDATE(expression) { if(!(expression)) fatalError(#expression, __FILE__, __LINE__); };
// #endif

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
                int timeout, HttpResult_ptr result, HttpResult_cb callback) :
        m_service(service), m_url(url), m_agent(agent), m_socket(service), m_resolver(service), 
        m_callback(callback), m_result(result), m_timer(service), m_timeout(timeout)
    {
        // VALIDATE(m_callback);
        // VALIDATE(m_result);
    };

    void start();
    void cancel() { onError("canceled"); }
    
private:
    boost::asio::io_service& m_service;
    std::string m_url;
    std::string m_agent;
    int m_port;
    boost::asio::ip::tcp::socket m_socket;
    boost::asio::ip::tcp::resolver m_resolver;
    HttpResult_cb m_callback;
    HttpResult_ptr m_result;
    boost::asio::steady_timer m_timer;
    int m_timeout;
    ParsedURI instance_uri;

    std::string m_domain;
    std::shared_ptr<boost::asio::ssl::stream<boost::asio::ip::tcp::socket&>> m_ssl;
    std::shared_ptr<boost::asio::ssl::context> m_context;

    boost::asio::streambuf m_streambuf;
    boost::asio::streambuf m_request;
    boost::asio::streambuf m_response;

	bool m_was_cancelled;
	std::mutex m_cancel_mux;    
    // boost::beast::flat_buffer m_streambuf{ 512 * 1024 * 1024 }; // limited to 512MB
    // boost::beast::http::request<boost::beast::http::string_body> m_request;
    // boost::beast::http::response_parser<boost::beast::http::dynamic_body> m_response;

    void on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::iterator iterator);
    void on_connect(const boost::system::error_code& ec);
    void on_request_sent(const boost::system::error_code& ec);
    void on_read_header(const boost::system::error_code& ec);
    void handle_read_headers(const boost::system::error_code& ec);
    void on_read(const boost::system::error_code& ec);
    void close();
    void onTimeout(const boost::system::error_code& error);
    void onError(const std::string& error, const std::string& details = "");
    void on_finish(const boost::system::error_code& ec);
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
        m_service(service), m_url(url), m_agent(agent), m_resolver(service), m_callback(callback), m_result(result), m_timer(service), m_timeout(timeout)
    {
        // VALIDATE(m_callback);
        // VALIDATE(m_result);
    };

    void start();
    void send(std::string data);
    void close();

private:
    boost::asio::io_service& m_service;
    std::string m_url;
    std::string m_agent;
    boost::asio::ip::tcp::resolver m_resolver;
    WebsocketSession_cb m_callback;
    HttpResult_ptr m_result;
    boost::asio::steady_timer m_timer;
    int m_timeout;
    bool m_closed;
    std::string m_domain;
    int m_port;

    std::shared_ptr<boost::beast::websocket::stream<boost::beast::tcp_stream>> m_socket;
    std::shared_ptr<boost::beast::websocket::stream<boost::beast::ssl_stream<boost::beast::tcp_stream>>> m_ssl;
    std::shared_ptr<boost::asio::ssl::context> m_context;

    boost::beast::flat_buffer m_streambuf{ 16 * 1024 * 1024 }; // limited to 16MB
    std::queue<std::string> m_sendQueue;

    void on_resolve(const boost::system::error_code& ec, boost::asio::ip::tcp::resolver::iterator iterator);
    void on_connect(const boost::system::error_code& ec);
    void on_handshake(const boost::system::error_code& ec);
    void on_send(const boost::system::error_code& ec);
    void on_read(const boost::system::error_code& ec, size_t bytes_transferred);
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
};

extern Http g_http;

#endif // ! HTTP_H
