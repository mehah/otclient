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
#ifndef CONNECTION_H
#define CONNECTION_H

#include "declarations.h"
#include <framework/luaengine/luaobject.h>
#include <framework/core/timer.h>
#include <framework/core/declarations.h>

class Connection : public LuaObject
{
    typedef std::function<void(const boost::system::error_code&)> ErrorCallback;
    typedef std::function<void(uint8*, uint16)> RecvCallback;

    enum {
        READ_TIMEOUT = 30,
        WRITE_TIMEOUT = 30,
        SEND_BUFFER_SIZE = 65536,
        RECV_BUFFER_SIZE = 65536
    };

public:
    Connection();
    ~Connection();

    static void poll();
    static void terminate();

    void connect(const std::string& host, uint16 port, const std::function<void()>& connectCallback);
    void close();

    void write(uint8* buffer, size_t size, bool skipXtea);
    void read(uint16 bytes, const RecvCallback& callback);
    void read_until(const std::string& what, const RecvCallback& callback);

    void setErrorCallback(const ErrorCallback& errorCallback) { m_errorCallback = errorCallback; }

    int getIp();
    boost::system::error_code getError() { return m_error; }
    bool isConnecting() { return m_connecting; }
    bool isConnected() { return m_connected; }
    ticks_t getElapsedTicksSinceLastRead() { return m_connected ? m_activityTimer.elapsed_millis() : -1; }

    ConnectionPtr asConnection() { return static_self_cast<Connection>(); }
    void setXtea(CanaryLib::XTEA *_xtea) { xtea = _xtea; }

protected:
    void internal_connect(asio::ip::basic_resolver<asio::ip::tcp>::iterator endpointIterator);
    void internalSend();
    void onResolve(const boost::system::error_code& error, asio::ip::tcp::resolver::iterator endpointIterator);
    void onConnect(const boost::system::error_code& error);
    void onCanWrite(const boost::system::error_code& error);
    void onWrite(const boost::system::error_code& error, size_t writeSize);
    void onRecv(const boost::system::error_code& error, size_t recvSize);
    void onTimeout(const boost::system::error_code& error);
    void handleError(const boost::system::error_code& error);

    std::function<void()> m_connectCallback;
    ErrorCallback m_errorCallback;
    RecvCallback m_recvCallback;

    asio::deadline_timer m_readTimer;
    asio::deadline_timer m_writeTimer;
    asio::deadline_timer m_delayedWriteTimer;
    asio::ip::tcp::resolver m_resolver;
    asio::ip::tcp::socket m_socket;

    asio::streambuf m_inputStream;
    bool m_connected;
    bool m_connecting;
    boost::system::error_code m_error;
    stdext::timer m_activityTimer;

    CanaryLib::XTEA *xtea = nullptr;
    std::list<Wrapper_ptr> wrapperList;

    friend class Server;
};

#endif
