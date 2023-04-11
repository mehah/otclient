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

#include <algorithm>

template<class T>
class DataBuffer
{
public:
    DataBuffer(uint32_t res = 64) : m_capacity(res), m_buffer(new T[m_capacity]) {}
    ~DataBuffer() { delete[] m_buffer; }

    void reset() { m_size = 0; }

    void clear()
    {
        m_size = 0;
        m_capacity = 0;
        delete[] m_buffer;
        m_buffer = nullptr;
    }

    bool empty() const { return m_size == 0; }
    uint32_t size() const { return m_size; }
    T* data() const { return m_buffer; }

    const T& at(uint32_t i) const { return m_buffer[i]; }
    const T& last() const { return m_buffer[m_size - 1]; }
    const T& first() const { return m_buffer[0]; }
    const T& operator[](uint32_t i) const { return m_buffer[i]; }
    T& operator[](uint32_t i) { return m_buffer[i]; }

    void reserve(uint32_t n)
    {
        if (n > m_capacity) {
            T* buffer = new T[n];

            std::copy(m_buffer, m_buffer + m_size, buffer);

            delete[] m_buffer;
            m_buffer = buffer;
            m_capacity = n;
        }
    }

    void resize(uint32_t n, T def = T())
    {
        if (n == m_size)
            return;
        reserve(n);
        for (uint32_t i = m_size; i < n; ++i)
            m_buffer[i] = def;
        m_size = n;
    }

    void grow(uint32_t n)
    {
        if (n <= m_size)
            return;
        if (n > m_capacity) {
            uint32_t newcapacity = m_capacity;
            do { newcapacity *= 2; } while (newcapacity < n);
            reserve(newcapacity);
        }
        m_size = n;
    }

    void add(const T& v)
    {
        grow(m_size + 1);
        m_buffer[m_size - 1] = v;
    }

    void append(const DataBuffer<T>* v)
    {
        const uint32_t sumSize = m_size + v->m_size;
        if (sumSize > m_capacity) {
            m_capacity = sumSize * 2;
            T* buffer = new T[m_capacity];

            std::copy(v->m_buffer, v->m_buffer + v->m_size,
                      std::copy(m_buffer, m_buffer + m_size, buffer));

            delete[] m_buffer;
            m_buffer = buffer;
        } else {
            std::copy(v->m_buffer, v->m_buffer + v->m_size, m_buffer + m_size);
        }
        m_size = sumSize;
    }

    DataBuffer& operator<<(const T& t) { add(t); return *this; }

private:
    uint32_t m_size{ 0 };
    uint32_t m_capacity;
    T* m_buffer;
};
