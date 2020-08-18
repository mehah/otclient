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
