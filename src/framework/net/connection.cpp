/**
 * Canary Lib - Canary Project a free 2D game platform
 * Copyright (C) 2020  Lucas Grossi <lucas.ggrossi@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "connection.h"

#include <framework/core/application.h>
#include <framework/core/eventdispatcher.h>

#include <boost/asio.hpp>
#include <memory>

asio::io_service g_ioService;

Connection::Connection() :
    m_readTimer(g_ioService),
    m_writeTimer(g_ioService),
    m_delayedWriteTimer(g_ioService),
    m_resolver(g_ioService),
    m_socket(g_ioService)
{
    m_connected = false;
    m_connecting = false;
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
    // reset must always be called prior to poll
    g_ioService.reset();
    g_ioService.poll();
}

void Connection::terminate()
{
    g_ioService.stop();
}

void Connection::close()
{
    if (!m_connected && !m_connecting)
        return;

    // flush send data before disconnecting on clean connections
    if (!m_error)
      internalSend();

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
        boost::system::error_code ec;
        m_socket.shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);
        m_socket.close();
    }
}

void Connection::connect(const std::string& host, uint16 port, const std::function<void()>& connectCallback)
{
    m_connected = false;
    m_connecting = true;
    m_error.clear();
    m_connectCallback = connectCallback;

    asio::ip::tcp::resolver::query query(host, stdext::unsafe_cast<std::string>(port));
    m_resolver.async_resolve(query, std::bind(&Connection::onResolve, asConnection(), std::placeholders::_1, std::placeholders::_2));

    m_readTimer.cancel();
    m_readTimer.expires_from_now(boost::posix_time::seconds(static_cast<uint32>(READ_TIMEOUT)));
    m_readTimer.async_wait(std::bind(&Connection::onTimeout, asConnection(), std::placeholders::_1));
}

void Connection::internal_connect(asio::ip::basic_resolver<asio::ip::tcp>::iterator endpointIterator)
{
    m_socket.async_connect(*endpointIterator, std::bind(&Connection::onConnect, asConnection(), std::placeholders::_1));

    m_readTimer.cancel();
    m_readTimer.expires_from_now(boost::posix_time::seconds(static_cast<uint32>(READ_TIMEOUT)));
    m_readTimer.async_wait(std::bind(&Connection::onTimeout, asConnection(), std::placeholders::_1));
}

void Connection::write(uint8* buffer, size_t size, bool skipXtea)
{
    if (!m_connected)
        return;

    Wrapper_ptr wrapper;
    if (!wrapperList.empty()) {
      wrapper = wrapperList.front();
    }

    // we can't send the data right away, otherwise we could create tcp congestion
    if (!wrapper || wrapper->isWriteLocked()) {
        wrapper = std::make_shared<Wrapper>();
        wrapperList.emplace_back(wrapper);

        m_delayedWriteTimer.cancel();
        m_delayedWriteTimer.expires_from_now(boost::posix_time::milliseconds(0));
        m_delayedWriteTimer.async_wait(std::bind(&Connection::onCanWrite, asConnection(), std::placeholders::_1));
    }

    if (skipXtea) {
      wrapper->disableEncryption();
    }

    flatbuffers::FlatBufferBuilder &fbb = wrapper->Builder();
    auto fbuffer = fbb.CreateVector(buffer, size);
    auto raw_data = CanaryLib::CreateRawData(fbb, fbuffer, size);
    wrapper->add(raw_data.Union(), CanaryLib::DataType_RawData);
}

void Connection::internalSend()
{
    if (!m_connected || wrapperList.empty())
        return;

    Wrapper_ptr wrapper = wrapperList.front();
    
    wrapper->Finish(xtea);

    asio::async_write(m_socket,
        boost::asio::buffer(wrapper->Buffer(), wrapper->Size() + CanaryLib::WRAPPER_HEADER_SIZE),
        std::bind(&Connection::onWrite, asConnection(), std::placeholders::_1, std::placeholders::_2));

    m_writeTimer.cancel();
    m_writeTimer.expires_from_now(boost::posix_time::seconds(static_cast<uint32>(WRITE_TIMEOUT)));
    m_writeTimer.async_wait(std::bind(&Connection::onTimeout, asConnection(), std::placeholders::_1));
}

void Connection::read(uint16 bytes, const RecvCallback& callback)
{
    if (!m_connected)
        return;

    m_recvCallback = callback; 
    asio::async_read(m_socket,
        asio::buffer(m_inputStream.prepare(bytes)),
        std::bind(&Connection::onRecv, asConnection(), std::placeholders::_1, std::placeholders::_2));

    m_readTimer.cancel();
    m_readTimer.expires_from_now(boost::posix_time::seconds(static_cast<uint32>(READ_TIMEOUT)));
    m_readTimer.async_wait(std::bind(&Connection::onTimeout, asConnection(), std::placeholders::_1));
}

void Connection::read_until(const std::string& what, const RecvCallback& callback)
{
    if (!m_connected)
        return;

    m_recvCallback = callback;

    asio::async_read_until(m_socket,
        m_inputStream,
        what,
        std::bind(&Connection::onRecv, asConnection(), std::placeholders::_1, std::placeholders::_2));

    m_readTimer.cancel();
    m_readTimer.expires_from_now(boost::posix_time::seconds(static_cast<uint32>(READ_TIMEOUT)));
    m_readTimer.async_wait(std::bind(&Connection::onTimeout, asConnection(), std::placeholders::_1));
}

void Connection::onResolve(const boost::system::error_code& error, asio::ip::basic_resolver<asio::ip::tcp>::iterator endpointIterator)
{
    m_readTimer.cancel();

    if (error == asio::error::operation_aborted)
        return;

    if (!error)
        internal_connect(endpointIterator);
    else
        handleError(error);
}

void Connection::onConnect(const boost::system::error_code& error)
{
    m_readTimer.cancel();
    m_activityTimer.restart();

    if (error == asio::error::operation_aborted)
        return;

    if (!error) {
        m_connected = true;

        // disable nagle's algorithm, this make the game play smoother
        boost::asio::ip::tcp::no_delay option(true);
        m_socket.set_option(option);

        if (m_connectCallback)
            m_connectCallback();
    }
    else
        handleError(error);

    m_connecting = false;
}

void Connection::onCanWrite(const boost::system::error_code& error)
{
    m_delayedWriteTimer.cancel();

    if (error == asio::error::operation_aborted)
        return;

    if (m_connected)
        internalSend();
}

void Connection::onWrite(const boost::system::error_code& error, size_t)
{
    m_writeTimer.cancel();

    if (error == asio::error::operation_aborted)
        return;

    if (!wrapperList.empty()) {
      wrapperList.pop_front();
    }

    if (m_connected && error)
        handleError(error);
}

void Connection::onRecv(const boost::system::error_code& error, size_t recvSize)
{
    m_readTimer.cancel();
    m_activityTimer.restart();

    if (error == asio::error::operation_aborted)
        return;

    if (m_connected) {
        if (!error) {
            if (m_recvCallback) {
                const char* header = boost::asio::buffer_cast<const char*>(m_inputStream.data());
                m_recvCallback((uint8*)header, recvSize);
            }
        }
        else
            handleError(error);
    }

    if (!error)
        m_inputStream.consume(recvSize);
}

void Connection::onTimeout(const boost::system::error_code& error)
{
    if (error == asio::error::operation_aborted)
        return;

    handleError(asio::error::timed_out);
}

void Connection::handleError(const boost::system::error_code& error)
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
    boost::system::error_code error;
    const boost::asio::ip::tcp::endpoint ip = m_socket.remote_endpoint(error);
    if (!error)
        return boost::asio::detail::socket_ops::host_to_network_long(ip.address().to_v4().to_ulong());

    g_logger.error("Getting remote ip");
    return 0;
}
