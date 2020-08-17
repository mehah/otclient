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

void Protocol::parseContentMessage(const CanaryLib::ContentMessage *content_msg) {
  for (int i = 0; i < content_msg->data()->size(); i++) {
    switch (content_msg->data_type()->GetEnum<CanaryLib::DataType>(i)) {
      case CanaryLib::DataType_RawData:
        parseRawData(content_msg->data()->GetAs<CanaryLib::RawData>(i));
        break;

      case CanaryLib::DataType_WeaponData: {
        auto weapon = content_msg->data()->GetAs<CanaryLib::WeaponData>(i);
        spdlog::critical("You see a weapon \"{}\" {} dmg, id {} ", weapon->name()->str(), weapon->damage(), weapon->id());
        break;
      }
      
      default:
        break;
    }
  }

  if (m_connection && m_connection->isConnected()) recv();
}

void Protocol::parseRawData(const CanaryLib::RawData *raw_data) {
  m_inputMessage->write(raw_data->body()->data(), raw_data->size(), CanaryLib::MESSAGE_OPERATION_PEEK);
  onRecv(m_inputMessage);
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
