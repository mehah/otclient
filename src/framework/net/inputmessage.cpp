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

#include "inputmessage.h"
#include <framework/util/crypt.h>

void InputMessage::reset()
{
    m_messageSize = 0;
    m_readPos = MAX_HEADER_SIZE;
    m_headerPos = MAX_HEADER_SIZE;
}

void InputMessage::setBuffer(const std::string& buffer)
{
    const int len = buffer.size();
    reset();
    checkWrite(len);
    memcpy(m_buffer + m_readPos, buffer.data(), len);
    m_readPos += len;
    m_messageSize += len;
}

uint8_t InputMessage::getU8()
{
    checkRead(1);
    const uint8_t v = m_buffer[m_readPos];
    m_readPos += 1;
    return v;
}

uint16_t InputMessage::getU16()
{
    checkRead(2);
    const uint16_t v = stdext::readULE16(m_buffer + m_readPos);
    m_readPos += 2;
    return v;
}

uint32_t InputMessage::getU32()
{
    checkRead(4);
    const uint32_t v = stdext::readULE32(m_buffer + m_readPos);
    m_readPos += 4;
    return v;
}

uint64_t InputMessage::getU64()
{
    checkRead(8);
    const uint64_t v = stdext::readULE64(m_buffer + m_readPos);
    m_readPos += 8;
    return v;
}

int64_t InputMessage::get64()
{
    checkRead(8);
    const int64_t v = stdext::readSLE64(m_buffer + m_readPos);
    m_readPos += 8;
    return v;
}

std::string InputMessage::getString()
{
    const uint16_t stringLength = getU16();
    checkRead(stringLength);
    const char* v = (char*)(m_buffer + m_readPos);
    m_readPos += stringLength;
    return std::string(v, stringLength);
}

double InputMessage::getDouble()
{
    const uint8_t precision = getU8();
    const int32_t v = getU32() - INT_MAX;
    return (v / std::pow(10.f, precision));
}

bool InputMessage::decryptRsa(int size)
{
    checkRead(size);
    g_crypt.rsaDecrypt(static_cast<uint8_t*>(m_buffer) + m_readPos, size);
    return (getU8() == 0x00);
}

void InputMessage::fillBuffer(uint8_t* buffer, uint16_t size)
{
    checkWrite(m_readPos + size);
    memcpy(m_buffer + m_readPos, buffer, size);
    m_messageSize += size;
}

void InputMessage::setHeaderSize(uint16_t size)
{
    assert(MAX_HEADER_SIZE - size >= 0);
    m_headerPos = MAX_HEADER_SIZE - size;
    m_readPos = m_headerPos;
}

bool InputMessage::readChecksum()
{
    const uint32_t receivedCheck = getU32();
    const uint32_t checksum = stdext::adler32(m_buffer + m_readPos, getUnreadSize());
    return receivedCheck == checksum;
}

bool InputMessage::canRead(int bytes) const
{
    if ((m_readPos - m_headerPos + bytes > m_messageSize) || (m_readPos + bytes > BUFFER_MAXSIZE))
        return false;
    return true;
}
void InputMessage::checkRead(int bytes)
{
    if (!canRead(bytes))
        throw stdext::exception("InputMessage eof reached");
}

void InputMessage::checkWrite(int bytes)
{
    if (bytes > BUFFER_MAXSIZE)
        throw stdext::exception("InputMessage max buffer size reached");
}