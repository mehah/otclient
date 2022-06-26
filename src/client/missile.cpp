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

#include "missile.h"
#include "map.h"
#include "thingtypemanager.h"
#include "tile.h"
#include <framework/core/eventdispatcher.h>

void Missile::drawMissile(const Point& dest, float scaleFactor, LightView* lightView)
{
    if (m_id == 0 || !m_drawBuffer)
        return;

    int xPattern = 0, yPattern = 0;
    if (m_direction == Otc::NorthWest) {
        xPattern = 0;
        yPattern = 0;
    } else if (m_direction == Otc::North) {
        xPattern = 1;
        yPattern = 0;
    } else if (m_direction == Otc::NorthEast) {
        xPattern = 2;
        yPattern = 0;
    } else if (m_direction == Otc::East) {
        xPattern = 2;
        yPattern = 1;
    } else if (m_direction == Otc::SouthEast) {
        xPattern = 2;
        yPattern = 2;
    } else if (m_direction == Otc::South) {
        xPattern = 1;
        yPattern = 2;
    } else if (m_direction == Otc::SouthWest) {
        xPattern = 0;
        yPattern = 2;
    } else if (m_direction == Otc::West) {
        xPattern = 0;
        yPattern = 1;
    } else {
        xPattern = 1;
        yPattern = 1;
    }

    const float fraction = m_animationTimer.ticksElapsed() / m_duration;
    const auto& _dest = dest + m_delta * fraction;

    if (m_drawBuffer)
        m_drawBuffer->validate(dest);

    getThingType()->draw(_dest * scaleFactor, scaleFactor, 0, xPattern, yPattern, 0, 0, TextureType::NONE, Color::white, lightView, m_drawBuffer);
}

void Missile::setPath(const Position& fromPosition, const Position& toPosition)
{
    m_position = fromPosition;
    m_delta = Point(toPosition.x - fromPosition.x, toPosition.y - fromPosition.y);

    const float deltaLength = m_delta.length();
    if (deltaLength == 0) {
        g_map.removeThing(this);
        return;
    }

    m_direction = fromPosition.getDirectionFromPosition(toPosition);

    m_duration = (MISSILE_TICKS_PER_FRAME * 2) * std::sqrt(deltaLength);
    m_delta *= SPRITE_SIZE;
    m_animationTimer.restart();
    m_distance = fromPosition.distance(toPosition);

    // schedule removal
    const auto self = asMissile();
    g_dispatcher.scheduleEvent([self] { g_map.removeThing(self); }, m_duration);

    generateBuffer();
}

void Missile::setId(uint32_t  id)
{
    if (!g_things.isValidDatId(id, ThingCategoryMissile))
        id = 0;

    m_id = id;
    m_thingType = nullptr;
}

const ThingTypePtr& Missile::getThingType()
{
    return m_thingType ? m_thingType : m_thingType = g_things.getThingType(m_id, ThingCategoryMissile);
}
