/*
 * Copyright (c) 2010-2017 OTClient <https://github.com/edubart/otclient>
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

#ifndef COLORARRAY_H
#define COLORARRAY_H

#include "declarations.h"
#include <framework/util/databuffer.h>

class ColorArray
{
public:
    inline void addColor(float r, float g, float b, float a) { m_buffer << r << g << b << a; }
    inline void addColor(const Color& c) { addColor(c.rF(), c.gF(), c.bF(), c.aF()); }

    void clear() { m_buffer.reset(); }
    float *colors() const { return m_buffer.data(); }
    float *data() const { return m_buffer.data(); }
    int colorCount() const { return m_buffer.size() / 4; }
    int count() const { return m_buffer.size() / 4; }
    int size() const { return m_buffer.size(); }

private:
    DataBuffer<float> m_buffer;
};

#endif
