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

#ifndef  PROTOCOLHTTP_H
#define PROTOCOLHTTP_H

#include <framework/global.h>
#include <framework/stdext/uri.h>

#include <queue>

#include <asio.hpp>
#include <asio/ssl.hpp>

#ifdef FW_WEBSOCKET
    #include <boost/beast.hpp>
    #include <boost/beast/ssl/ssl_stream.hpp>
    namespace beast = boost::beast;
#endif

#include <zlib.h>

//  result
class HttpSession;

struct HttpResult {
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

    HttpSession(asio::io_service& service, const std::string& url, const std::string& agent, 
            const bool& enable_time_out_on_read_write,
            const std::map<std::string, std::string>& custom_header,
            int timeout, bool isJson, HttpResult_ptr result, HttpResult_cb callback) :
                m_service(service),
                m_url(url),
                m_agent(agent),
                m_enable_time_out_on_read_write(enable_time_out_on_read_write),
                m_custom_header(custom_header),
                m_timeout(timeout),
                m_isJson(isJson),
                m_result(result),
                m_callback(callback),
                m_socket(service),
                m_resolver(service),
                m_timer(service)
    {
        assert(m_callback != nullptr);
        assert(m_result != nullptr);
        m_ssl.set_verify_mode(asio::ssl::verify_none);
    };
    void start();
    void cancel() { onError("canceled"); }
    void close();
    
private:
    asio::io_service& m_service;
    std::string m_url;
    std::string m_agent;
    bool m_enable_time_out_on_read_write;
    std::map<std::string, std::string> m_custom_header;
    int m_timeout;
    bool m_isJson;
    HttpResult_ptr m_result;
    HttpResult_cb m_callback;
    asio::ip::tcp::socket m_socket;    
    asio::ip::tcp::resolver m_resolver;
    asio::steady_timer m_timer;
    ParsedURI instance_uri;

    asio::ssl::context m_context{ asio::ssl::context::sslv23_client };
    asio::ssl::stream<asio::ip::tcp::socket> m_ssl{ m_service, m_context };

    std::string m_request;
    asio::streambuf m_response;
    int sum_bytes_response = 0;
    int sum_bytes_speed_response = 0;
    ticks_t m_last_progress_update = stdext::millis();    

    void on_resolve(const std::error_code& ec, const asio::ip::tcp::resolver::results_type& iterator);
    void on_connect(const std::error_code& ec);

    void on_request_sent(const std::error_code& ec, size_t bytes_transferred);

    void on_write();
    void on_read(const std::error_code& ec, size_t bytes_transferred);

    void onTimeout(const std::error_code& ec);
    void onError(const std::string& ec, const std::string& details = "");
};

#ifdef FW_WEBSOCKET
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

    WebsocketSession(asio::io_service& service, const std::string& url, const std::string& agent, 
                    const bool& enable_time_out_on_read_write, int timeout, HttpResult_ptr result, WebsocketSession_cb callback) :
            m_service(service),
            m_url(url),
            m_agent(agent),
            m_enable_time_out_on_read_write(enable_time_out_on_read_write),
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
    asio::io_service& m_service;
    std::string m_url;
    std::string m_agent;
    bool m_enable_time_out_on_read_write;
    int m_timeout;
    HttpResult_ptr m_result;
    WebsocketSession_cb m_callback;
    asio::steady_timer m_timer;
    asio::ip::tcp::resolver m_resolver;
    bool m_closed;
    ParsedURI instance_uri;
    std::string m_domain;

    beast::websocket::stream<beast::tcp_stream> m_socket{m_service};
    asio::ssl::context m_context{ asio::ssl::context::sslv23_client };
    beast::websocket::stream<beast::ssl_stream<beast::tcp_stream>> m_ssl{ m_service, m_context };

    beast::flat_buffer m_streambuf{ 16 * 1024 * 1024 }; // limited to 16MB
    std::queue<std::string> m_sendQueue;

    void on_resolve(const std::error_code& ec, asio::ip::tcp::resolver::results_type results);
    void on_connect(const std::error_code& ec, asio::ip::tcp::resolver::results_type::endpoint_type);
    void on_ssl_handshake(const std::error_code& ec);
    void on_handshake(const std::error_code& ec);

    void on_write(const std::error_code& ec, size_t bytes_transferred);
    void on_read(const std::error_code& ec, size_t bytes_transferred);

    void on_close(const std::error_code& ec);
    void onTimeout(const std::error_code& ec);
    void onError(const std::string& ec, const std::string& details = "");
};
#endif

class Http {
public:
    Http() : m_ios(), m_guard(asio::make_work_guard(m_ios)) {}

    void init();
    void terminate();

    int get(const std::string& url, int timeout = 5);
    int post(const std::string& url, const std::string& data, int timeout = 5, bool isJson = false);
    int download(const std::string& url, std::string path, int timeout = 5);
    #ifdef FW_WEBSOCKET
    int ws(const std::string& url, int timeout = 5);
    bool wsSend(int operationId, std::string message);
    bool wsClose(int operationId);
    #endif
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

    void setEnableTimeOutOnReadWrite(bool enable_time_out_on_read_write){
        m_enable_time_out_on_read_write = enable_time_out_on_read_write;
    }

private:
    bool m_working = false;
    bool m_enable_time_out_on_read_write = false;
    int m_operationId = 1;
    std::thread m_thread;
    asio::io_context m_ios;
    asio::executor_work_guard<asio::io_context::executor_type> m_guard;
    std::map<int, HttpResult_ptr> m_operations;
    #ifdef FW_WEBSOCKET
    std::map<int, std::shared_ptr<WebsocketSession>> m_websockets;
    #endif
    std::map<std::string, HttpResult_ptr> m_downloads;
    std::string m_userAgent = "Mozilla/5.0";
    std::map<std::string, std::string> m_custom_header;
};

extern Http g_http;

#endif // ! PROTOCOLHTTP_H
