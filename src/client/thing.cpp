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

#include "thing.h"
#include "game.h"
#include "map.h"
#include "thingtypemanager.h"
#include "tile.h"

#include <framework/core/graphicalapplication.h>

void Thing::setPosition(const Position& position, uint8_t stackPos, bool hasElevation)
{
    if (m_position == position)
        return;

    const Position oldPos = m_position;
    m_position = position;
    onPositionChange(position, oldPos);
}

int Thing::getStackPriority()
{
    if (isGround())
        return 0;

    if (isGroundBorder())
        return 1;

    if (isOnBottom())
        return 2;

    if (isOnTop())
        return 3;

    if (isCreature())
        return 4;

    // common items
    return 5;
}

const TilePtr& Thing::getTile()
{
    return g_map.getTile(m_position);
}

ContainerPtr Thing::getParentContainer()
{
    if (m_position.x == 0xffff && m_position.y & 0x40) {
        const int containerId = m_position.y ^ 0x40;
        return g_game.getContainer(containerId);
    }

    return nullptr;
}

int Thing::getStackPos()
{
    if (m_position.x == UINT16_MAX && isItem()) // is inside a container
        return m_position.z;

    if (const TilePtr& tile = getTile())
        return tile->getThingStackPos(static_self_cast<Thing>());

    g_logger.traceError("got a thing with invalid stackpos");
    return -1;
}

void Thing::addStaticEffect(const StaticEffectPtr& obj) {
    if (isCreature()) {
        if (obj->m_thingType->getCategory() == ThingCategoryCreature || obj->m_thingType->getCategory() == ThingCategoryMissile)
            obj->m_direction = static_self_cast<Creature>()->getDirection();
    }

    m_staticEffects.emplace_back(obj);
    obj->callLuaField("onAdd", this);
}

bool Thing::removeStaticEffectById(uint16_t id) {
    const auto it = std::find_if(m_staticEffects.begin(), m_staticEffects.end(),
        [id](const StaticEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_staticEffects.end())
        return false;

    (*it)->callLuaField("onRemove", this);
    m_staticEffects.erase(it);

    return true;
}

void Thing::clearStaticEffect() {
    for (const auto& e : m_staticEffects)
        e->callLuaField("onRemove", this);
    m_staticEffects.clear();
}

StaticEffectPtr Thing::getStaticEffectById(uint16_t id) {
    const auto it = std::find_if(m_staticEffects.begin(), m_staticEffects.end(),
        [id](const StaticEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_staticEffects.end())
        return nullptr;

    return *it;
}
