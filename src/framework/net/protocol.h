/*
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

#pragma once

#include "connection.h"
#include "declarations.h"
#include "inputmessage.h"
#include "outputmessage.h"

#include <framework/luaengine/luaobject.h>
#include <zlib.h>

 // @bindclass
class Protocol : public LuaObject
{
public:
    Protocol();
    ~Protocol() override;

    void connect(const std::string_view host, uint16_t port);
    void disconnect();

    bool isConnected() { return m_connection && m_connection->isConnected(); }
    bool isConnecting() { return m_connection && m_connection->isConnecting(); }
    ticks_t getElapsedTicksSinceLastRead() const { return m_connection ? m_connection->getElapsedTicksSinceLastRead() : -1; }

    ConnectionPtr getConnection() { return m_connection; }
    void setConnection(const ConnectionPtr& connection) { m_connection = connection; }

    void generateXteaKey();
    void setXteaKey(uint32_t a, uint32_t b, uint32_t c, uint32_t d) { m_xteaKey = { a, b, c, d }; }
    std::vector<uint32_t > getXteaKey() { return { m_xteaKey.begin(), m_xteaKey.end() }; }
    void enableXteaEncryption() { m_xteaEncryptionEnabled = true; }

    void enableChecksum() { m_checksumEnabled = true; }
    void enabledSequencedPackets() { m_sequencedPackets = true; }

    virtual void send(const OutputMessagePtr& outputMessage);
    virtual void recv();

    ProtocolPtr asProtocol() { return static_self_cast<Protocol>(); }

protected:
    virtual void onConnect();
    virtual void onRecv(const InputMessagePtr& inputMessage);
    virtual void onError(const std::error_code& err);

    std::array<uint32_t, 4> m_xteaKey{};
    uint32_t m_packetNumber{ 0 };

private:
    void internalRecvHeader(uint8_t* buffer, uint16_t size);
    void internalRecvData(uint8_t* buffer, uint16_t size);

    bool xteaDecrypt(const InputMessagePtr& inputMessage) const;
    void xteaEncrypt(const OutputMessagePtr& outputMessage) const;

    bool m_checksumEnabled{ false };
    bool m_sequencedPackets{ false };
    bool m_xteaEncryptionEnabled{ false };

    ConnectionPtr m_connection;
    InputMessagePtr m_inputMessage;

    z_stream m_zstream{};
};
