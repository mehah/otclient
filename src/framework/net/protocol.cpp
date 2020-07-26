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

#include "protocol.h"
#include "connection.h"
#include <framework/core/application.h>
#include <random>

Protocol::Protocol()
{
    m_xteaEncryptionEnabled = false;
    m_checksumEnabled = false;
    m_inputMessage = InputMessagePtr(new InputMessage);
}

Protocol::~Protocol()
{
#ifndef NDEBUG
    assert(!g_app.isTerminated());
#endif
    disconnect();
}

void Protocol::connect(const std::string& host, uint16 port)
{
    m_connection = ConnectionPtr(new Connection);
    m_connection->setErrorCallback(std::bind(&Protocol::onError, asProtocol(), std::placeholders::_1));
    m_connection->connect(host, port, std::bind(&Protocol::onConnect, asProtocol()));
}

void Protocol::disconnect()
{
    if(m_connection) {
        m_connection->close();
        m_connection.reset();
    }
}

bool Protocol::isConnected()
{
    if(m_connection && m_connection->isConnected())
        return true;
    return false;
}

bool Protocol::isConnecting()
{
    if(m_connection && m_connection->isConnecting())
        return true;
    return false;
}

void Protocol::send(const OutputMessagePtr& outputMessage)
{
    // encrypt
    if(m_xteaEncryptionEnabled) {
      outputMessage->writeMessageLength();
      outputMessage->encryptXTEA();
    }

    // write checksum
    if(m_checksumEnabled)
        outputMessage->addCryptoHeader();

    // send
    if(m_connection)
        m_connection->write(outputMessage->getOutputBuffer(), outputMessage->getMessageSize());

    // reset message to allow reuse
    outputMessage->reset();
}

void Protocol::recv()
{
    m_inputMessage->reset();

    // first update message header size
    int headerSize = 2; // 2 bytes for message size
    if(m_checksumEnabled)
        headerSize += 4; // 4 bytes for checksum
    if(m_xteaEncryptionEnabled)
        headerSize += 2; // 2 bytes for XTEA encrypted message size
    m_inputMessage->setHeaderSize(headerSize);

    // read the first 2 bytes which contain the message size
    if(m_connection)
        m_connection->read(2, std::bind(&Protocol::internalRecvHeader, asProtocol(), std::placeholders::_1,  std::placeholders::_2));
}

void Protocol::internalRecvHeader(uint8* buffer, uint16 size)
{
    // read message size
    m_inputMessage->fillBuffer(buffer, size);
    uint16 remainingSize = m_inputMessage->readSize();

    // read remaining message data
    if(m_connection)
        m_connection->read(remainingSize, std::bind(&Protocol::internalRecvData, asProtocol(), std::placeholders::_1,  std::placeholders::_2));
}

void Protocol::internalRecvData(uint8* buffer, uint16 size)
{
    // process data only if really connected
    if(!isConnected()) {
        g_logger.traceError("received data while disconnected");
        return;
    }

    m_inputMessage->fillBuffer(buffer, size);

    if(m_checksumEnabled && !m_inputMessage->readChecksum()) {
        g_logger.traceError("got a network message with invalid checksum");
        return;
    }

    if(m_xteaEncryptionEnabled) {
        if(!xteaDecrypt(m_inputMessage)) {
            g_logger.traceError("failed to decrypt message");
            return;
        }
    }
    onRecv(m_inputMessage);
}

void Protocol::generateXteaKey()
{
  CanaryLib::XTEA().generateKey();
}

void Protocol::setXteaKey(uint32 a, uint32 b, uint32 c, uint32 d)
{
  uint32_t key[4] = { a, b, c, d };
  CanaryLib::XTEA().setKey(key);
}

std::vector<uint32> Protocol::getXteaKey()
{
  std::vector<uint32> xteaKey;
  xteaKey.resize(4);
  for(int i = 0; i < 4; ++i)
    xteaKey[i] = CanaryLib::XTEA().getKey()[i];
  return xteaKey;
}

bool Protocol::xteaDecrypt(const InputMessagePtr& inputMessage)
{
  bool decrypted = inputMessage->decryptXTEA(m_checksumEnabled ? CanaryLib::CHECKSUM_METHOD_SEQUENCE : CanaryLib::CHECKSUM_METHOD_NONE);
  inputMessage->setLength(inputMessage->getLength() + (m_checksumEnabled ? 2 : 0));
  return decrypted;
}

void Protocol::onConnect()
{
    callLuaField("onConnect");
}

void Protocol::onRecv(const InputMessagePtr& inputMessage)
{
    callLuaField("onRecv", inputMessage);
}

void Protocol::onError(const boost::system::error_code& err)
{
    callLuaField("onError", err.message(), err.value());
    disconnect();
}
