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

#include <framework/net/outputmessage.h>
#include <framework/util/crypt.h>

void OutputMessage::reset()
{
    m_writePos = MAX_HEADER_SIZE;
    m_headerPos = MAX_HEADER_SIZE;
    m_messageSize = 0;
}

void OutputMessage::setBuffer(const std::string& buffer)
{
    const int len = buffer.size();
    reset();
    checkWrite(len);
    memcpy(m_buffer + m_writePos, buffer.data(), len);
    m_writePos += len;
    m_messageSize += len;
}

void OutputMessage::addU8(uint8_t value)
{
    checkWrite(1);
    m_buffer[m_writePos] = value;
    m_writePos += 1;
    m_messageSize += 1;
}

void OutputMessage::addU16(uint16_t value)
{
    checkWrite(2);
    stdext::writeULE16(m_buffer + m_writePos, value);
    m_writePos += 2;
    m_messageSize += 2;
}

void OutputMessage::addU32(uint32_t value)
{
    checkWrite(4);
    stdext::writeULE32(m_buffer + m_writePos, value);
    m_writePos += 4;
    m_messageSize += 4;
}

void OutputMessage::addU64(uint64_t value)
{
    checkWrite(8);
    stdext::writeULE64(m_buffer + m_writePos, value);
    m_writePos += 8;
    m_messageSize += 8;
}

void OutputMessage::addString(const std::string_view buffer)
{
    const int len = buffer.length();
    if (len > MAX_STRING_LENGTH)
        throw stdext::exception(stdext::format("string length > %d", MAX_STRING_LENGTH));
    checkWrite(len + 2);
    addU16(len);
    memcpy(m_buffer + m_writePos, buffer.data(), len);
    m_writePos += len;
    m_messageSize += len;
}

void OutputMessage::addPaddingBytes(int bytes, uint8_t byte)
{
    if (bytes <= 0)
        return;
    checkWrite(bytes);
    memset(&m_buffer[m_writePos], byte, bytes);
    m_writePos += bytes;
    m_messageSize += bytes;
}

void OutputMessage::encryptRsa()
{
    const int size = g_crypt.rsaGetSize();
    if (m_messageSize < size)
        throw stdext::exception("insufficient bytes in buffer to encrypt");

    if (!g_crypt.rsaEncrypt(static_cast<uint8_t*>(m_buffer) + m_writePos - size, size))
        throw stdext::exception("rsa encryption failed");
}

void OutputMessage::writeChecksum()
{
    const uint32_t checksum = stdext::adler32(m_buffer + m_headerPos, m_messageSize);
    assert(m_headerPos - 4 >= 0);
    m_headerPos -= 4;
    stdext::writeULE32(m_buffer + m_headerPos, checksum);
    m_messageSize += 4;
}

void OutputMessage::writeSequence(uint32_t sequence)
{
    assert(m_headerPos >= 4);
    m_headerPos -= 4;
    stdext::writeULE32(m_buffer + m_headerPos, sequence);
    m_messageSize += 4;
}

void OutputMessage::writeMessageSize()
{
    assert(m_headerPos - 2 >= 0);
    m_headerPos -= 2;
    stdext::writeULE16(m_buffer + m_headerPos, m_messageSize);
    m_messageSize += 2;
}

bool OutputMessage::canWrite(int bytes) const
{
    return m_writePos + bytes <= BUFFER_MAXSIZE;
}

void OutputMessage::checkWrite(int bytes)
{
    if (!canWrite(bytes))
        throw stdext::exception("OutputMessage max buffer size reached");
}