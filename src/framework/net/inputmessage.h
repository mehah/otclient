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

#ifndef INPUTMESSAGE_H
#define INPUTMESSAGE_H

#include "declarations.h"
#include <framework/luaengine/luaobject.h>

// @bindclass
class InputMessage : public LuaObject, public CanaryLib::NetworkMessage
{
public:
    InputMessage() { reset(); }

    void skipBytes(uint16 bytes) { skip(bytes); }
    void setReadPos(uint16 readPos) { setBufferPosition(readPos); }
    uint8 getU8() { return readByte(); }
    uint16 getU16() { return read<uint16_t>(); }
    uint32 getU32() { return read<uint32_t>(); }
    uint64 getU64() { return read<uint64_t>(); }
    std::string getString() { return readString(); }

    uint8 peekU8() { return readByte(CanaryLib::MESSAGE_OPERATION_PEEK); }
    uint16 peekU16() { return read<uint16>(CanaryLib::MESSAGE_OPERATION_PEEK); }
    uint32 peekU32() { return read<uint32>(CanaryLib::MESSAGE_OPERATION_PEEK); }
    uint64 peekU64() { return read<uint64>(CanaryLib::MESSAGE_OPERATION_PEEK); }

    int getReadPos() { return getBufferPosition(); }
    uint16 getMessageSize() { return getLength(); }

    int getReadSize() { return m_info.m_bufferPos - m_info.m_headerPos; }
    int getUnreadSize() { return getLength() - getReadSize(); }

    double getDouble();
    bool decryptRsa(int size);
    bool eof() { return (m_info.m_bufferPos - m_info.m_headerPos) >= m_info.m_messageSize; }

protected:
    void fillBuffer(uint8 *buffer, uint16 size) { write(buffer, size, CanaryLib::MESSAGE_OPERATION_PEEK); }

    void setHeaderSize(uint16 size);
    void setMessageSize(uint16 size) { setLength(size); }

    uint16 readSize() { return getU16(); }

    friend class Protocol;
};

#endif
