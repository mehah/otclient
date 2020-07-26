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

#include "inputmessage.h"
#include <framework/util/crypt.h>

double InputMessage::getDouble()
{
    uint8 precision = getU8();
    int32 v = getU32() - INT_MAX;
    return (v / std::pow(static_cast<float>(10), precision));
}

bool InputMessage::decryptRsa(int size)
{
    if (canRead(size)) {
      g_crypt.rsaDecrypt(static_cast<unsigned char*>(m_buffer) + m_info.m_bufferPos, size);
      return (getU8() == 0x00);
    }
    return false;
}

void InputMessage::setHeaderSize(uint16 size)
{
    assert(CanaryLib::MAX_HEADER_SIZE - size >= 0);
    m_info.m_headerPos = CanaryLib::MAX_HEADER_SIZE - size;
    m_info.m_bufferPos = m_info.m_headerPos;
}
