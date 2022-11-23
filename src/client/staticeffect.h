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

#include "thingtype.h"

class StaticEffect : public LuaObject
{
public:
    static StaticEffectPtr create(uint16_t id, uint16_t thingId, ThingCategory category);

    uint16_t getId() { return m_id; }

    float getSpeed() { return m_speed; }
    void setSpeed(float speed) { m_speed = speed; }

    bool getOnTop() { return m_onTop; }
    void setOnTop(bool onTop) { m_onTop = onTop; }

    void setOffset(int8_t x, int8_t y) { m_offset = { x, y }; }
    void setOffsetX(int8_t x) { m_offset.x = x; }
    void setOffsetY(int8_t y) { m_offset.y = y; }

    void setDirOffset(Otc::Direction direction, int8_t x, int8_t y) { m_offsetDirections[direction] = { x, y }; }

private:
    uint16_t m_id;

    float m_speed{ 1.f };
    bool m_onTop{ false };
    Point m_offset;
    ThingType* m_thingType;

    std::array<Point, Otc::Direction::West + 1> m_offsetDirections;
};
