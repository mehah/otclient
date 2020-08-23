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

#ifndef PROTOCOL_H
#define PROTOCOL_H

#include "../pch.h"

#include "declarations.h"
#include "inputmessage.h"
#include "outputmessage.h"
#include "connection.h"

#include <framework/luaengine/luaobject.h>

// @bindclass
class Protocol : public LuaObject, public CanaryLib::FlatbuffersParser
{
public:
    Protocol();
    virtual ~Protocol();

    void connect(const std::string& host, uint16 port);
    void disconnect();

    bool isConnected();
    bool isConnecting();
    ticks_t getElapsedTicksSinceLastRead() { return m_connection ? m_connection->getElapsedTicksSinceLastRead() : -1; }

    ConnectionPtr getConnection() { return m_connection; }
    void setConnection(const ConnectionPtr& connection) { m_connection = connection; }

    std::vector<uint32> generateXteaKey();
    std::vector<uint32> getXteaKey();

    virtual void send(const OutputMessagePtr& outputMessage, bool skipXtea = false);
    virtual void recv();

    ProtocolPtr asProtocol() { return static_self_cast<Protocol>(); }

protected:
    virtual void onConnect();
    virtual void onRecv(const InputMessagePtr& inputMessage);
    virtual void onError(const boost::system::error_code& err);

    // Flatbuffer Parsers Override
    void parseRawData(const CanaryLib::RawData *raw_data) override;

private:
    void internalRecvHeader(uint8* buffer, uint16 size);
    void internalRecvData(uint8* buffer, uint16 size);

    ConnectionPtr m_connection;
    InputMessagePtr m_inputMessage;

    CanaryLib::XTEA xtea;
    CanaryLib::FlatbuffersWrapper wrapper;
};

#endif
