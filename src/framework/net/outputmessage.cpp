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

#include <framework/net/outputmessage.h>
#include <framework/util/crypt.h>

void OutputMessage::encryptRsa()
{
    int size = g_crypt.rsaGetSize();
    if(m_info.m_messageSize < size)
        throw stdext::exception("insufficient bytes in buffer to encrypt");

    if(!g_crypt.rsaEncrypt(static_cast<unsigned char*>(m_buffer) + m_info.m_bufferPos - size, size))
        throw stdext::exception("rsa encryption failed");
}

void OutputMessage::writeChecksum()
{
    assert(m_info.m_headerPos - 4 >= 0);
    uint32 checksum = getChecksum(m_buffer + m_info.m_headerPos, m_info.m_messageSize);
    m_info.m_headerPos -= 4;
    m_info.m_messageSize += 4;

    stdext::writeULE32(m_buffer + m_info.m_headerPos, checksum);
}

void OutputMessage::writeMessageSize()
{
    assert(m_info.m_headerPos - 2 >= 0);
    m_info.m_headerPos -= 2;
    stdext::writeULE16(m_buffer + m_info.m_headerPos, m_info.m_messageSize);
    m_info.m_messageSize += 2;
}