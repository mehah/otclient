/*
 * Copyright (c) 2024 OTArchive <https://otarchive.com>
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
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
#ifdef __EMSCRIPTEN__

#include "webconnection.h"

#include <framework/core/application.h>
#include <client/game.h>

#include <utility>
#include <asio/read.hpp>
#include <asio/read_until.hpp>
#include <framework/core/eventdispatcher.h>


asio::io_service g_ioService;
std::list<std::shared_ptr<asio::streambuf>> WebConnection::m_outputStreams;
WebConnection::WebConnection() :
    m_readTimer(g_ioService),
    m_readRetryTimer(g_ioService),
    m_writeTimer(g_ioService)
{
    mWebSocket = 0;
}

WebConnection::~WebConnection()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
    close();
}

void WebConnection::poll()
{
    // reset must always be called prior to poll
    g_ioService.reset();
    g_ioService.poll();
}

void WebConnection::terminate()
{
    g_ioService.stop();
    m_outputStreams.clear();
    emscripten_websocket_deinitialize();
}

void WebConnection::close()
{
    if (!m_connected && !m_connecting)
        return;

    // flush send data before disconnecting on clean connections
    // if (m_connected && !m_error && m_outputStream)
    //     internal_write();

    m_connecting = false;
    m_connected = false;
    m_connectCallback = nullptr;
    m_errorCallback = nullptr;
    m_recvCallback = nullptr;

    m_readTimer.cancel();
    m_readRetryTimer.cancel();
    m_writeTimer.cancel();

    // clear();

    if (mWebSocket != 0) {
        // emscripten_websocket_close(mWebSocket, 1000, "Connection cleared");
        // emscripten_websocket_delete(mWebSocket);
        emscripten_websocket_deinitialize();
        mWebSocket = 0;
    }

    while (!m_messages.empty()) {
        m_messages.pop();
    }

    //Workaround for the abrupt termination of the websocket
    g_dispatcher.addEvent([] { 
        g_game.forceLogout();
    });
}

void WebConnection::connect(const std::string_view host, uint16_t port, const std::function<void()>& connectCallback)
{
    m_connected = false;
    m_connecting = true;
    m_error.clear();
    m_connectCallback = connectCallback;
    
    std::string ip = host.data();
    ip.length() == 0 ? ip = "localhost" : ip;

#ifdef WEBPORT
    const std::string webPort = WEBPORT;
#else
    const std::string webPort = "7979";
#endif

#ifndef NDEBUG
    const std::string prefix = "ws://";
#else
    const std::string prefix = "wss://";
#endif

    const std::string url =  prefix + ip + ":" + webPort;

    EmscriptenWebSocketCreateAttributes attributes =
    {
        url.c_str(),
        "binary",
        EM_FALSE // createOnMainThread
    };

    mWebSocket = emscripten_websocket_new(&attributes);

    emscripten_websocket_set_onopen_callback(mWebSocket, this, ([](int eventType, const EmscriptenWebSocketOpenEvent* event, void* userData) -> EM_BOOL {
        static_cast<WebConnection*>(userData)->onConnect();
        return EM_TRUE;
    }));
    emscripten_websocket_set_onerror_callback(mWebSocket, this, ([](int eventType, const EmscriptenWebSocketErrorEvent* event, void* userData) -> EM_BOOL {
        static_cast<WebConnection*>(userData)->handleError();
        return EM_TRUE;
    }));
    emscripten_websocket_set_onclose_callback(mWebSocket, this, ([](int eventType, const EmscriptenWebSocketCloseEvent* event, void* userData) -> EM_BOOL {
        static_cast<WebConnection*>(userData)->close();
        return EM_TRUE;
    }));
    emscripten_websocket_set_onmessage_callback(mWebSocket, this, ([](int eventType, const EmscriptenWebSocketMessageEvent* event, void* userData) -> EM_BOOL {
        static_cast<WebConnection*>(userData)->onWebSocketMessage(event);
        return EM_TRUE;
    }));
    m_readTimer.cancel();
    m_readTimer.expires_after(std::chrono::seconds(static_cast<uint32_t>(READ_TIMEOUT)));
    m_readTimer.async_wait([this](auto&& error) {
        onTimeout(std::move(error));
    });
}

bool WebConnection::sendPacket(uint8_t* buffer, uint16_t size)
{
    if (mWebSocket == 0)
        return false;

    const EMSCRIPTEN_RESULT result = emscripten_websocket_send_binary(mWebSocket, buffer, size);
    return (result == EMSCRIPTEN_RESULT_SUCCESS);
}

void WebConnection::write(uint8_t* buffer, size_t size)
{
    if (!m_connected)
        return;

    if (!m_outputStream) {
        if (!m_outputStreams.empty()) {
            m_outputStream = m_outputStreams.front();
            m_outputStreams.pop_front();
        } else
            m_outputStream = std::make_shared<asio::streambuf>();
    }

    std::ostream os(m_outputStream.get());
    os.write((const char*)buffer, size);
    os.flush();

    internal_write();
}

void WebConnection::internal_write()
{
    if (!m_connected)
        return;

    std::shared_ptr<asio::streambuf> outputStream = m_outputStream;
    m_outputStream = nullptr;

    m_writeTimer.cancel();
    m_writeTimer.expires_from_now(asio::chrono::seconds(static_cast<uint32_t>(WRITE_TIMEOUT)));
    m_writeTimer.async_wait([capture0 = asWebConnection()](auto&& PH1) {
        capture0->onTimeout(std::forward<decltype(PH1)>(PH1));
    });

    const auto* data = asio::buffer_cast<const uint8_t*>(outputStream->data());
    bool write = sendPacket((uint8_t*)data, outputStream->size());
    if (write) {
        onWrite(outputStream);
    }
}


bool WebConnection::onWebSocketMessage(const EmscriptenWebSocketMessageEvent* webSocketEvent)
{
    uint32_t numBytes = webSocketEvent->numBytes;
    if (numBytes == 0)
        return true;
    if (webSocketEvent->isText)
        return true;

    static std::vector<uint8_t> buffer;
    buffer.resize((size_t)numBytes);
    memcpy(&buffer[0], webSocketEvent->data, numBytes);
    m_messages.push(buffer);

    return true;
}

void WebConnection::read(const RecvCallback& callback, int tries)
{
    if (!m_connected)
        return;

    m_recvCallback = callback;

    if (tries == 0) {
        m_readTimer.cancel();
        m_readTimer.expires_from_now(asio::chrono::seconds(static_cast<uint32_t>(READ_TIMEOUT)));
        m_readTimer.async_wait([capture0 = asWebConnection()](auto&& PH1) {
            capture0->onTimeout(std::forward<decltype(PH1)>(PH1));
        });
    }

    if (!m_messages.empty()) {
        onRecv();
    } else {
        m_readRetryTimer.cancel();
        m_readRetryTimer.expires_from_now(asio::chrono::milliseconds(10));
        m_readRetryTimer.async_wait([capture0 = asWebConnection(), callback, &tries](auto&& error) {
            capture0->read(callback, tries++);
        });
    }

}

bool WebConnection::onConnect()
{
    m_readTimer.cancel();
    m_activityTimer.restart();
    m_connected = true;

    if (m_connectCallback)
        m_connectCallback();

    m_connecting = false;

    return true;
}

void WebConnection::onWrite(const std::shared_ptr<asio::streambuf>&
                         outputStream)
{
    m_writeTimer.cancel();

    // free output stream and store for using it again later
    outputStream->consume(outputStream->size());
    m_outputStreams.emplace_back(outputStream);
}

void WebConnection::onRecv()
{
    m_readTimer.cancel();
    m_activityTimer.restart();

    if (m_connected) {
        if (m_recvCallback) {
            static std::vector<uint8_t> buffer;
            buffer.resize((size_t)m_messages.front().size());
            memcpy(&buffer[0], &m_messages.front()[0], m_messages.front().size());
            m_messages.pop();
            m_recvCallback(&buffer[0], buffer.size());
        }
    }
}

void WebConnection::onTimeout(const std::error_code& error)
{
    if (error == asio::error::operation_aborted)
        return;

    if (m_errorCallback)
        m_errorCallback(error);

    if (m_connected || m_connecting)
        close();
}

bool WebConnection::handleError()
{
    // if (m_errorCallback)
    //     m_errorCallback(std::error_code());

    if (m_connected || m_connecting)
        close();

    return true;
}

int WebConnection::getIp()
{
    g_logger.error("Getting remote ip");
    return 0;
}

#endif