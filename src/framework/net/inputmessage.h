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
    uint8 getU8() { return readByte(); }
    uint16 getU16() { return read<uint16_t>(); }
    uint32 getU32() { return read<uint32_t>(); }
    uint64 getU64() { return read<uint64_t>(); }
    std::string getString() { return readString(); }

    uint8 peekU8() { return readByte(CanaryLib::MESSAGE_OPERATION_PEEK); }
    uint16 peekU16() { return read<uint16>(CanaryLib::MESSAGE_OPERATION_PEEK); }
    uint32 peekU32() { return read<uint32>(CanaryLib::MESSAGE_OPERATION_PEEK); }
    uint64 peekU64() { return read<uint64>(CanaryLib::MESSAGE_OPERATION_PEEK); }

    uint16 getMessageSize() { return getLength(); }

    double getDouble();
    bool eof() { return CanaryLib::NetworkMessage::eof(); }

protected:
    friend class Protocol;
};

#endif
