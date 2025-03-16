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

#include "../stdext/cast.h"
#include "../stdext/types.h"

class Color
{
public:
    Color(std::string_view coltext);

    constexpr Color() { m_hash = white.hash(); };
    constexpr Color(const uint32_t rgba) { setRGBA(rgba); }
    constexpr Color(const int r, const int g, const int b, const int a = 0xFF) : m_r(r / 255.f), m_g(g / 255.f), m_b(b / 255.f), m_a(a / 255.f), m_hash(rgba()) {}
    constexpr Color(const float r, const float g, const float b, const float a = 1.0f) : m_r(r), m_g(g), m_b(b), m_a(a), m_hash(rgba()) {}
    constexpr Color(const uint8_t r, const uint8_t g, const uint8_t b, const uint8_t a = 0xFF) : m_r(r / 255.f), m_g(g / 255.f), m_b(b / 255.f), m_a(a / 255.f), m_hash(rgba()) {}

    constexpr  Color(const uint8_t byteColor, const uint8_t intensity, const float formule = 0.5f)
    {
        const float brightness = formule + (intensity / 8.f) * formule;
        const auto& colorMap = from8bit(byteColor);

        m_a = colorMap.aF();
        m_b = colorMap.bF() * brightness;
        m_g = colorMap.gF() * brightness;
        m_r = colorMap.rF() * brightness;
        update();
    }

    constexpr Color(const Color& color) = default;
    constexpr Color(const Color& color, const float a) {
        m_r = color.m_r;
        m_g = color.m_g;
        m_b = color.m_b;
        m_a = a;
        update();
    }

    constexpr uint8_t a() const { return static_cast<uint8_t>(m_a * 255.f); }
    constexpr uint8_t b() const { return static_cast<uint8_t>(m_b * 255.f); }
    constexpr uint8_t g() const { return static_cast<uint8_t>(m_g * 255.f); }
    constexpr  uint8_t r() const { return static_cast<uint8_t>(m_r * 255.f); }

    constexpr float aF() const { return m_a; }
    constexpr float bF() const { return m_b; }
    constexpr float gF() const { return m_g; }
    constexpr float rF() const { return m_r; }

    constexpr uint32_t rgba() const { return static_cast<uint32_t>(a() << 24 | b() << 16 | g() << 8 | r()); }
    constexpr size_t hash() const { return m_hash; }

    constexpr void setRed(const int r) { m_r = static_cast<uint8_t>(r) / 255.f; update(); }
    constexpr void setGreen(const int g) { m_g = static_cast<uint8_t>(g) / 255.f; update(); }
    constexpr void setBlue(const int b) { m_b = static_cast<uint8_t>(b) / 255.f; update(); }
    constexpr void setAlpha(const int a) { m_a = static_cast<uint8_t>(a) / 255.f; update(); }

    constexpr void setRed(const float r) { m_r = r; update(); }
    constexpr void setGreen(const float g) { m_g = g; update(); }
    constexpr void setBlue(const float b) { m_b = b; update(); }
    constexpr void setAlpha(const float a) { m_a = a; update(); }

    constexpr void setRGBA(const uint8_t r, const uint8_t g, const uint8_t b, const uint8_t a = 0xFF) { m_r = r / 255.f; m_g = g / 255.f; m_b = b / 255.f; m_a = a / 255.f; update(); }
    constexpr void setRGBA(const uint32_t rgba) { setRGBA((rgba >> 0) & 0xff, (rgba >> 8) & 0xff, (rgba >> 16) & 0xff, (rgba >> 24) & 0xff); }

    constexpr Color operator+(const Color& other) const { return Color(m_r + other.m_r, m_g + other.m_g, m_b + other.m_b, m_a + other.m_a); }
    constexpr Color operator-(const Color& other) const { return Color(m_r - other.m_r, m_g - other.m_g, m_b - other.m_b, m_a - other.m_a); }

    constexpr Color operator*(const float v) const { return Color(m_r * v, m_g * v, m_b * v, m_a * v); }
    constexpr Color operator/(const float v) const { return Color(m_r / v, m_g / v, m_b / v, m_a / v); }

    constexpr Color& operator=(const uint32_t rgba) { setRGBA(rgba); return *this; }
    constexpr bool operator==(const uint32_t rgba) const { return this->rgba() == rgba; }

    constexpr Color& operator=(const Color& other) = default;
    constexpr bool operator==(const Color& other) const { return other.hash() == hash(); }
    constexpr bool operator!=(const Color& other) const { return other.hash() != hash(); }

    constexpr void blend(const Color& color)
    {
        m_r *= (1 - color.m_a) + color.m_r * color.m_a;
        m_g *= (1 - color.m_a) + color.m_g * color.m_a;
        m_b *= (1 - color.m_a) + color.m_b * color.m_a;
        update();
    }

    constexpr static uint8_t to8bit(const Color& color)
    {
        uint8_t c = 0;
        c += (color.r() / 51) * 36;
        c += (color.g() / 51) * 6;
        c += (color.b() / 51);

        return c;
    }

    constexpr static Color from8bit(const int color, const float brightness = 1.0f)
    {
        if (color >= 216 || color <= 0)
            return alpha;

        const int r = static_cast<int>((color / 36 % 6 * 51) * brightness);
        const int g = static_cast<int>((color / 6 % 6 * 51) * brightness);
        const int b = static_cast<int>((color % 6 * 51) * brightness);

        return Color(r, g, b);
    }

    static const Color
        alpha, white, black, red, darkRed,
        green, darkGreen, blue, darkBlue,
        pink, darkPink, yellow, darkYellow,
        teal, darkTeal, gray, darkGray,
        lightGray, orange;

    friend std::ostream& operator<<(std::ostream& out, const Color& color);
    friend std::istream& operator>>(std::istream& in, Color& color);

private:
    constexpr void update();

    float m_r{ 1.f };
    float m_g{ 1.f };
    float m_b{ 1.f };
    float m_a{ 1.f };

    size_t m_hash{ 0 };
};
