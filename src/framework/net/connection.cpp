/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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
#ifndef __EMSCRIPTEN__

#include "connection.h"

#include "framework/core/graphicalapplication.h"

asio::io_context g_ioContext;
std::list<std::shared_ptr<asio::streambuf>> Connection::m_outputStreams;

Connection::Connection() :
    m_readTimer(g_ioContext),
    m_writeTimer(g_ioContext),
    m_delayedWriteTimer(g_ioContext),
    m_resolver(g_ioContext),
    m_socket(g_ioContext)
{
}

Connection::~Connection()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
    close();
}

void Connection::poll()
{
    // restart must always be called prior to poll
    g_ioContext.restart();
    g_ioContext.poll();
}

void Connection::terminate()
{
    g_ioContext.stop();
    m_outputStreams.clear();
}

void Connection::close()
{
    if (!m_connected && !m_connecting)
        return;

    // flush send data before disconnecting on clean connections
    if (m_connected && !m_error && m_outputStream)
        internal_write();

    m_connecting = false;
    m_connected = false;
    m_connectCallback = nullptr;
    m_errorCallback = nullptr;
    m_recvCallback = nullptr;

    m_resolver.cancel();
    m_readTimer.cancel();
    m_writeTimer.cancel();
    m_delayedWriteTimer.cancel();

    if (m_socket.is_open()) {
        std::error_code ec;
        m_socket.shutdown(asio::ip::tcp::socket::shutdown_both, ec);
        m_socket.close();
    }
}

void Connection::connect(const std::string_view host, const uint16_t port, const std::function<void()>& connectCallback)
{
    m_connected = false;
    m_connecting = true;
    m_error.clear();
    m_connectCallback = connectCallback;

    m_resolver.async_resolve(
        host.data(),
        stdext::unsafe_cast<std::string>(port),
        [this](
            auto&& error,
            auto&& endpointIterator
        ) {
            onResolve(std::move(error), std::move(endpointIterator));
        }
    );

    m_readTimer.cancel();
    m_readTimer.expires_after(std::chrono::seconds(static_cast<uint32_t>(READ_TIMEOUT)));
    m_readTimer.async_wait([this](auto&& error) {
        onTimeout(std::move(error));
    });
}

void Connection::internal_connect(const asio::ip::tcp::resolver::results_type& endpoints)
{
    auto endpoint = *endpoints.begin();

    m_socket.async_connect(endpoint, [capture0 = asConnection()](auto&& ec) {
        capture0->onConnect(std::forward<decltype(ec)>(ec));
    });

    m_readTimer.cancel();
    m_readTimer.expires_after(asio::chrono::seconds(static_cast<uint32_t>(READ_TIMEOUT)));
    m_readTimer.async_wait([capture0 = asConnection()](auto&& ec) {
        capture0->onTimeout(std::forward<decltype(ec)>(ec));
    });
}

void Connection::write(const uint8_t* buffer, const size_t size)
{
    if (!m_connected)
        return;

    // we can't send the data right away, otherwise we could create tcp congestion
    if (!m_outputStream) {
        if (!m_outputStreams.empty()) {
            m_outputStream = m_outputStreams.front();
            m_outputStreams.pop_front();
        } else
            m_outputStream = std::make_shared<asio::streambuf>();

        m_delayedWriteTimer.cancel();
        m_delayedWriteTimer.expires_after(asio::chrono::milliseconds(0));
        m_delayedWriteTimer.async_wait([capture0 = asConnection()](auto&& PH1) {
            capture0->onCanWrite(std::forward<decltype(PH1)>(PH1));
        });
    }

    std::ostream os(m_outputStream.get());
    os.write((const char*)buffer, size);
    os.flush();
}

void Connection::internal_write()
{
    if (!m_connected)
        return;

    std::shared_ptr<asio::streambuf> outputStream = m_outputStream;
    m_outputStream = nullptr;

    async_write(m_socket,
                *outputStream,
                [capture0 = asConnection(), outputStream](auto&& PH1, auto&& PH2) {
        capture0->onWrite(std::forward<decltype(PH1)>(PH1), std::forward<decltype(PH2)>(PH2), outputStream);
    });

    m_writeTimer.cancel();
    m_writeTimer.expires_after(asio::chrono::seconds(static_cast<uint32_t>(WRITE_TIMEOUT)));
    m_writeTimer.async_wait([capture0 = asConnection()](auto&& PH1) {
        capture0->onTimeout(std::forward<decltype(PH1)>(PH1));
    });
}

void Connection::read(const uint16_t bytes, const RecvCallback& callback)
{
    if (!m_connected)
        return;

    m_recvCallback = callback;

    async_read(m_socket,
               m_inputStream.prepare(bytes),
               [capture0 = asConnection()](auto&& PH1, auto&& PH2) {
        capture0->onRecv(std::forward<decltype(PH1)>(PH1), std::forward<decltype(PH2)>(PH2));
    });

    m_readTimer.cancel();
    m_readTimer.expires_after(asio::chrono::seconds(static_cast<uint32_t>(READ_TIMEOUT)));
    m_readTimer.async_wait([capture0 = asConnection()](auto&& PH1) {
        capture0->onTimeout(std::forward<decltype(PH1)>(PH1));
    });
}

void Connection::read_until(const std::string_view what, const RecvCallback& callback)
{
    if (!m_connected)
        return;

    m_recvCallback = callback;

    async_read_until(m_socket,
                     m_inputStream,
                     what,
                     [capture0 = asConnection()](auto&& PH1, auto&& PH2) {
        capture0->onRecv(std::forward<decltype(PH1)>(PH1), std::forward<decltype(PH2)>(PH2));
    });

    m_readTimer.cancel();
    m_readTimer.expires_after(asio::chrono::seconds(static_cast<uint32_t>(READ_TIMEOUT)));
    m_readTimer.async_wait([capture0 = asConnection()](auto&& PH1) {
        capture0->onTimeout(std::forward<decltype(PH1)>(PH1));
    });
}

void Connection::read_some(const RecvCallback& callback)
{
    if (!m_connected)
        return;

    m_recvCallback = callback;

    m_socket.async_read_some(m_inputStream.prepare(RECV_BUFFER_SIZE),
                             [capture0 = asConnection()](auto&& PH1, auto&& PH2) {
        capture0->onRecv(std::forward<decltype(PH1)>(PH1), std::forward<decltype(PH2)>(PH2));
    });

    m_readTimer.cancel();
    m_readTimer.expires_after(asio::chrono::seconds(static_cast<uint32_t>(READ_TIMEOUT)));
    m_readTimer.async_wait([capture0 = asConnection()](auto&& PH1) {
        capture0->onTimeout(std::forward<decltype(PH1)>(PH1));
    });
}

void Connection::onResolve(const std::error_code& error, const asio::ip::tcp::resolver::results_type& endpoints)
{
    m_readTimer.cancel();

    if (error == asio::error::operation_aborted)
        return;

    if (!error)
        internal_connect(endpoints);
    else
        handleError(error);
}

void Connection::onConnect(const std::error_code& error)
{
    m_readTimer.cancel();
    m_activityTimer.restart();

    if (error == asio::error::operation_aborted)
        return;

    if (!error) {
        m_connected = true;

        // disable nagle's algorithm, this make the game play smoother
        const asio::ip::tcp::no_delay option(true);
        m_socket.set_option(option);

        if (m_connectCallback)
            m_connectCallback();
    } else
        handleError(error);

    m_connecting = false;
}

void Connection::onCanWrite(const std::error_code& error)
{
    m_delayedWriteTimer.cancel();

    if (error == asio::error::operation_aborted)
        return;

    if (m_connected)
        internal_write();
}

void Connection::onWrite(const std::error_code& error, size_t, const std::shared_ptr<asio::streambuf>&
                         outputStream)
{
    m_writeTimer.cancel();

    if (error == asio::error::operation_aborted)
        return;

    // free output stream and store for using it again later
    outputStream->consume(outputStream->size());
    m_outputStreams.emplace_back(outputStream);

    if (m_connected && error)
        handleError(error);
}

void Connection::onRecv(const std::error_code& error, const size_t recvSize)
{
    m_readTimer.cancel();
    m_activityTimer.restart();

    if (error == asio::error::operation_aborted)
        return;

    if (m_connected) {
        if (!error) {
            if (m_recvCallback) {
                const auto* header =
                    static_cast<const char*>(
                        asio::buffer(m_inputStream.data()).data());

                m_recvCallback(reinterpret_cast<uint8_t*>(const_cast<char*>(header)), recvSize);
            }
        } else
            handleError(error);
    }

    if (!error)
        m_inputStream.consume(recvSize);
}

void Connection::onTimeout(const std::error_code& error)
{
    if (error == asio::error::operation_aborted)
        return;

    handleError(asio::error::timed_out);
}

void Connection::handleError(const std::error_code& error)
{
    if (error == asio::error::operation_aborted)
        return;

    m_error = error;
    if (m_errorCallback)
        m_errorCallback(error);
    if (m_connected || m_connecting)
        close();
}

int Connection::getIp()
{
    std::error_code error;
    const asio::ip::tcp::endpoint ip = m_socket.remote_endpoint(error);
    if (!error)
        return asio::detail::socket_ops::host_to_network_long(ip.address().to_v4().to_uint());

    g_logger.error("Getting remote ip");
    return 0;
}

#endif
