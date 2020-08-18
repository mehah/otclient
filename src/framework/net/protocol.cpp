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

#include "protocol.h"
#include "connection.h"
#include <framework/core/application.h>
#include <random>

Protocol::Protocol()
{
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
    m_connection->setXtea(&xtea);
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

void Protocol::send(const OutputMessagePtr& outputMessage, bool skipXtea)
{
    // send
    if(m_connection)
        m_connection->write(outputMessage->getBuffer(), outputMessage->getMessageSize(), skipXtea);

    // reset message to allow reuse
    outputMessage->reset();
}

void Protocol::recv()
{
    wrapper.reset();
    // read the first 2 bytes which contain the message size
    if(m_connection)
        m_connection->read(2, std::bind(&Protocol::internalRecvHeader, asProtocol(), std::placeholders::_1,  std::placeholders::_2));
}

void Protocol::internalRecvHeader(uint8* buffer, uint16 size)
{
    uint16_t remaining = wrapper.loadSizeFromBuffer(buffer);

    // read remaining message data
    if(m_connection)
        m_connection->read(remaining, std::bind(&Protocol::internalRecvData, asProtocol(), std::placeholders::_1,  std::placeholders::_2));
}

void Protocol::internalRecvData(uint8* buffer, uint16 size)
{
    // process data only if really connected
    if(!isConnected()) {
        g_logger.traceError("received data while disconnected");
        return;
    }

    wrapper.copy(buffer, size);

    if(!wrapper.readChecksum()) {
      g_logger.traceError("got a network message with invalid checksum");
      return;
    }

    auto enc_msg = wrapper.getEncryptedMessage();
    auto header = enc_msg->header();
    uint8_t *body_buffer = (uint8_t *) enc_msg->body()->Data();
    
    if (xtea.isEnabled() && header->encrypted()) {
      xtea.decrypt(header->message_size(), body_buffer);
    }

    m_inputMessage->reset();
    parseContentMessage(CanaryLib::GetContentMessage(body_buffer));
}

std::vector<uint32> Protocol::generateXteaKey()
{
  xtea.generateKey();
  return getXteaKey();
}

void Protocol::setXteaKey(uint32 a, uint32 b, uint32 c, uint32 d)
{
  uint32_t key[4] = { a, b, c, d };
  xtea.setKey(key);
}

std::vector<uint32> Protocol::getXteaKey()
{
  std::vector<uint32> xteaKey;
  xteaKey.resize(4);
  for(int i = 0; i < 4; ++i)
    xteaKey[i] = xtea.getKey()[i];
  return xteaKey;
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
    spdlog::error("{}", err.message());
    callLuaField("onError", err.message(), err.value());
    disconnect();
}

void Protocol::onMessageError(const CanaryLib::ErrorData *err) {
    spdlog::error("{}", err->message()->str());
}
