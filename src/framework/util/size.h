/*
 * Copyright (c) 2010-2024 OTClient <https://github.com/edubart/otclient>
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

#include "../const.h"
#include "point.h"

template<class T>
class TSize
{
public:
    TSize() : wd(-1), ht(-1) {};
    TSize(T widthHeight) : wd(widthHeight), ht(widthHeight) {};
    TSize(T width, T height) : wd(width), ht(height) {};
    TSize(const TSize& other) : wd(other.wd), ht(other.ht) {};

    TPoint<T> toPoint() const { return TPoint<T>(wd, ht); }

    bool isNull() const { return wd == 0 && ht == 0; }
    bool isEmpty() const { return wd < 1 || ht < 1; }
    bool isValid() const { return wd >= 0 && ht >= 0; }
    bool isUnset() const { return wd == -1 && ht == -1; }

    int width() const { return wd; }
    int height() const { return ht; }

    void resize(T w, T h) { wd = w; ht = h; }
    void setWidth(T w) { wd = w; }
    void setHeight(T h) { ht = h; }

    TSize operator-() const { return TSize(-wd, -ht); }
    TSize operator+(const TSize& other) const { return TSize(wd + other.wd, ht + other.ht); }
    TSize& operator+=(const TSize& other) { wd += other.wd; ht += other.ht; return *this; }
    TSize operator-(const TSize& other) const { return TSize(wd - other.wd, ht - other.ht); }
    TSize& operator-=(const TSize& other) { wd -= other.wd; ht -= other.ht; return *this; }
    TSize operator*(const TSize& other) const { return TSize(static_cast<T>(other.wd) * wd, static_cast<T>(ht) * other.ht); }
    TSize& operator*=(const TSize& other) { wd = static_cast<T>(other.wd) * wd; ht = static_cast<T>(ht) * other.ht; return *this; }
    TSize operator/(const TSize& other) const { return TSize(static_cast<T>(wd) / other.wd, static_cast<T>(ht) / other.ht); }
    TSize& operator/=(const TSize& other) { static_cast<T>(wd) /= other.wd; static_cast<T>(ht) /= other.ht; return *this; }
    TSize operator*(const float v) const { return TSize(static_cast<T>(wd) * v, static_cast<T>(ht) * v); }
    TSize& operator*=(const float v) { wd = static_cast<T>(wd) * v; ht = static_cast<T>(ht) * v; return *this; }
    TSize operator/(const float v) const { return TSize(static_cast<T>(wd) / v, static_cast<T>(ht) / v); }
    TSize& operator/=(const float v) { wd /= v; ht /= v; return *this; }

    bool operator<=(const TSize& other) const { return wd <= other.wd || ht <= other.ht; }
    bool operator>=(const TSize& other) const { return wd >= other.wd || ht >= other.ht; }
    bool operator<(const TSize& other) const { return wd < other.wd || ht < other.ht; }
    bool operator>(const TSize& other) const { return wd > other.wd || ht > other.ht; }

    TSize& operator=(const TSize& other) = default;
    bool operator==(const TSize& other) const { return other.wd == wd && other.ht == ht; }
    bool operator!=(const TSize& other) const { return other.wd != wd || other.ht != ht; }

    bool operator<=(const T other) const { return wd <= other || ht <= other; }
    bool operator>=(const T other) const { return wd >= other || ht >= other; }
    bool operator<(const T other) const { return wd < other || ht < other; }
    bool operator>(const T other) const { return wd > other || ht > other; }

    TSize& operator=(const T other) { wd = other; ht = other; return *this; }
    bool operator==(const T other) const { return other == wd && other == ht; }
    bool operator!=(const T other) const { return other != wd || other != ht; }

    TSize expandedTo(const TSize& other) const { return TSize(std::max<T>(wd, other.wd), std::max<T>(ht, other.ht)); }
    TSize boundedTo(const TSize& other) const { return TSize(std::min<T>(wd, other.wd), std::min<T>(ht, other.ht)); }

    void scale(const TSize& s, const Fw::AspectRatioMode mode)
    {
        if (mode == Fw::IgnoreAspectRatio || wd == 0 || ht == 0) {
            wd = s.wd;
            ht = s.ht;
        } else {
            bool useHeight;
            T rw = (s.ht * wd) / ht;

            if (mode == Fw::KeepAspectRatio)
                useHeight = (rw <= s.wd);
            else // mode == Fw::KeepAspectRatioByExpanding
                useHeight = (rw >= s.wd);

            if (useHeight) {
                wd = rw;
                ht = s.ht;
            } else {
                ht = (s.wd * ht) / wd;
                wd = s.wd;
            }
        }
    }

    void scale(int w, int h, const Fw::AspectRatioMode mode) { scale(TSize(w, h), mode); }

    T smaller() const { return std::min<T>(ht, wd); }
    T bigger() const { return std::max<T>(ht, wd); }

    float ratio() const { return static_cast<float>(wd) / ht; }
    T area() const { return wd * ht; }
    T dimension() const { return wd + ht; }

private:
    T wd, ht;
};

using Size = TSize<int>;
using SizeF = TSize<float>;

template<class T>
std::ostream& operator<<(std::ostream& out, const TSize<T>& size)
{
    out << size.width() << " " << size.height();
    return out;
}

template<class T>
std::istream& operator>>(std::istream& in, TSize<T>& size)
{
    T w, h;
    in >> w >> h;
    size.resize(w, h);
    return in;
}
