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

#ifndef OUTPUTMESSAGE_H
#define OUTPUTMESSAGE_H

#include "declarations.h"
#include <framework/luaengine/luaobject.h>

// @bindclass
class OutputMessage : public LuaObject, public CanaryLib::NetworkMessage
{
public:
    OutputMessage() {
      reset(); 
    }

    void addU8(uint8 value) { writeByte(value); }
    void addU16(uint16 value) { write<uint16>(value); }
    void addU32(uint32 value) { write<uint32>(value); }
    void addU64(uint64 value) { write<uint64>(value); }
    void addString(const std::string& buffer) { writeString(buffer); }
    void addPaddingBytes(int bytes) { writePaddingBytes(bytes); };

    void encryptRsa();

    uint16 getWritePos() { return getBufferPosition(); }
    uint16 getMessageSize() { return getLength(); }

    void setWritePos(uint16 writePos) { setBufferPosition(writePos); }
    void setMessageSize(uint16 messageSize) { setLength(messageSize); }

protected:
    friend class Protocol;
};

#endif
