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

#pragma once

#include "declarations.h"

class HardwareBuffer
{
public:
    enum class Type
    {
        VERTEX_BUFFER = GL_ARRAY_BUFFER,
        INDEX_BUFFER = GL_ELEMENT_ARRAY_BUFFER
    };

    enum class UsagePattern
    {
        STREAM_DRAW = GL_STREAM_DRAW,
        STATIC_DRAW = GL_STATIC_DRAW,
        DYNAMIC_DRAW = GL_DYNAMIC_DRAW
    };

    HardwareBuffer(Type type);
    ~HardwareBuffer();

    void bind() const { glBindBuffer(static_cast<GLenum>(m_type), m_id); }
    static void unbind(Type type) { glBindBuffer(static_cast<GLenum>(type), 0); }
    void write(void const* data, int count, UsagePattern usage) const { glBufferData(static_cast<GLenum>(m_type), count, data, static_cast<GLenum>(usage)); }

private:
    Type m_type;
    uint32_t m_id;
};
