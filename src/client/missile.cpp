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
#include <framework/core/eventdispatcher.h>
#include "map.h"
#include "thingtypemanager.h"
#include "tile.h"

void Missile::draw(const Point& dest, bool drawThings, LightView* lightView)
{
    if (!canDraw() || isHided())
        return;

    const float fraction = m_animationTimer.ticksElapsed() / m_duration;
    getThingType()->draw(dest + m_delta * fraction * g_drawPool.getScaleFactor(), 0, m_numPatternX, m_numPatternY, 0, 0, Color::white, drawThings, lightView, m_drawConductor);
}

void Missile::setPath(const Position& fromPosition, const Position& toPosition)
{
    m_position = fromPosition;
    m_delta = Point(toPosition.x - fromPosition.x, toPosition.y - fromPosition.y);

    const float deltaLength = m_delta.length();
    if (deltaLength == 0) {
        g_map.removeThing(asMissile());
        return;
    }

    m_direction = fromPosition.getDirectionFromPosition(toPosition);

    m_duration = (g_gameConfig.getMissileTicksPerFrame() * 2) * std::sqrt(deltaLength);
    m_delta *= g_gameConfig.getSpriteSize();
    m_animationTimer.restart();
    m_distance = fromPosition.distance(toPosition);

    { // Update Pattern
        if (m_direction == Otc::NorthWest) {
            m_numPatternX = 0;
            m_numPatternY = 0;
        } else if (m_direction == Otc::North) {
            m_numPatternX = 1;
            m_numPatternY = 0;
        } else if (m_direction == Otc::NorthEast) {
            m_numPatternX = 2;
            m_numPatternY = 0;
        } else if (m_direction == Otc::East) {
            m_numPatternX = 2;
            m_numPatternY = 1;
        } else if (m_direction == Otc::SouthEast) {
            m_numPatternX = 2;
            m_numPatternY = 2;
        } else if (m_direction == Otc::South) {
            m_numPatternX = 1;
            m_numPatternY = 2;
        } else if (m_direction == Otc::SouthWest) {
            m_numPatternX = 0;
            m_numPatternY = 2;
        } else if (m_direction == Otc::West) {
            m_numPatternX = 0;
            m_numPatternY = 1;
        } else {
            m_numPatternX = 1;
            m_numPatternY = 1;
        }
    }

    // schedule removal
    g_dispatcher.scheduleEvent([self = asMissile()] { g_map.removeThing(self); }, m_duration);
}

void Missile::setId(uint32_t id)
{
    if (!g_things.isValidDatId(id, ThingCategoryMissile))
        id = 0;

    m_clientId = id;
    m_thingType = g_things.getThingType(id, ThingCategoryMissile).get();
}