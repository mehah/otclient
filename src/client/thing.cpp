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
#include "shadermanager.h"

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

void Thing::onDisappear() {
    if (m_drawBuffer)
        m_drawBuffer->invalidate();
}

void Thing::setShader(const std::string_view name) { m_shader = g_shaders.getShader(name); }

void Thing::attachEffect(const AttachedEffectPtr& obj) {
    if (isCreature()) {
        if (obj->m_thingType->getCategory() == ThingCategoryCreature || obj->m_thingType->getCategory() == ThingCategoryMissile)
            obj->m_direction = static_self_cast<Creature>()->getDirection();
    }

    m_attachedEffects.emplace_back(obj);
    obj->callLuaField("onAttach", asLuaObject());
}

bool Thing::detachEffectById(uint16_t id) {
    const auto it = std::find_if(m_attachedEffects.begin(), m_attachedEffects.end(),
                                 [id](const AttachedEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_attachedEffects.end())
        return false;

    (*it)->callLuaField("onDetach", asLuaObject());
    m_attachedEffects.erase(it);

    return true;
}

void Thing::clearAttachedEffects() {
    for (const auto& e : m_attachedEffects)
        e->callLuaField("onDetach", asLuaObject());
    m_attachedEffects.clear();
}

AttachedEffectPtr Thing::getAttachedEffectById(uint16_t id) {
    const auto it = std::find_if(m_attachedEffects.begin(), m_attachedEffects.end(),
                                 [id](const AttachedEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_attachedEffects.end())
        return nullptr;

    return *it;
}
