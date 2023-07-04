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
#include "shadermanager.h"
#include "thingtypemanager.h"
#include "tile.h"

#include <framework/core/eventdispatcher.h>
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
        return STACK_PRIORITY::GROUND;

    if (isGroundBorder())
        return STACK_PRIORITY::GROUND_BORDER;

    if (isOnBottom())
        return STACK_PRIORITY::ON_BOTTOM;

    if (isOnTop())
        return STACK_PRIORITY::ON_TOP;

    if (isCreature())
        return STACK_PRIORITY::CREATURE;

    // common items
    return STACK_PRIORITY::COMMON_ITEMS;
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

void Thing::setShader(const std::string_view name) {
    if (name.empty()) {
        m_shader = nullptr;
        return;
    }

    m_shader = g_shaders.getShader(name.data());
}

void Thing::attachEffect(const AttachedEffectPtr& obj) {
    if (isCreature()) {
        if (obj->m_thingType && (obj->m_thingType->isCreature() || obj->m_thingType->isMissile()))
            obj->m_direction = static_self_cast<Creature>()->getDirection();
    }

    if (obj->isHidedOwner())
        ++m_hidden;

    if (obj->getDuration() > 0) {
        g_dispatcher.scheduleEvent([self = static_self_cast<Thing>(), effectId = obj->getId()]() {
            self->detachEffectById(effectId);
        }, obj->getDuration());
    }

    if (obj->isDisabledWalkAnimation() && isCreature()) {
        const auto& creature = static_self_cast<Creature>();
        creature->setDisableWalkAnimation(true);
    }

    m_attachedEffects.emplace_back(obj);
    g_dispatcher.addEvent([effect = obj, self = static_self_cast<Thing>()] {
        if (effect->isTransform() && self->isCreature() && effect->m_thingType) {
            const auto& creature = self->static_self_cast<Creature>();
            const auto& outfit = creature->getOutfit();
            if (outfit.isTemp())
                return;

            effect->m_outfitOwner = outfit;

            Outfit newOutfit = outfit;
            newOutfit.setTemp(true);
            newOutfit.setCategory(effect->m_thingType->getCategory());
            if (newOutfit.isCreature())
                newOutfit.setId(effect->m_thingType->getId());
            else
                newOutfit.setAuxId(effect->m_thingType->getId());

            creature->setOutfit(newOutfit);
        }

        effect->callLuaField("onAttach", self->asLuaObject());
    });
}

bool Thing::detachEffectById(uint16_t id) {
    const auto it = std::find_if(m_attachedEffects.begin(), m_attachedEffects.end(),
                                 [id](const AttachedEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_attachedEffects.end())
        return false;

    onDetachEffect(*it);
    m_attachedEffects.erase(it);

    return true;
}

void Thing::onDetachEffect(const AttachedEffectPtr& effect) {
    if (effect->isHidedOwner())
        --m_hidden;

    if (isCreature()) {
        const auto& creature = static_self_cast<Creature>();

        if (effect->isDisabledWalkAnimation())
            creature->setDisableWalkAnimation(false);

        if (effect->isTransform() && !effect->m_outfitOwner.isInvalid()) {
            creature->setOutfit(effect->m_outfitOwner);
        }
    }

    effect->callLuaField("onDetach", asLuaObject());
}

void Thing::clearAttachedEffects() {
    for (const auto& e : m_attachedEffects)
        onDetachEffect(e);
    m_attachedEffects.clear();
}

AttachedEffectPtr Thing::getAttachedEffectById(uint16_t id) {
    const auto it = std::find_if(m_attachedEffects.begin(), m_attachedEffects.end(),
                                 [id](const AttachedEffectPtr& obj) { return obj->getId() == id; });

    if (it == m_attachedEffects.end())
        return nullptr;

    return *it;
}

void Thing::drawAttachedEffect(const Point& dest, LightView* lightView, bool isOnTop)
{
    for (const auto& effect : m_attachedEffects) {
        effect->draw(dest, isOnTop, lightView);
        if (effect->getLoop() == 0) {
            g_dispatcher.addEvent([self = static_self_cast<Thing>(), effectId = effect->getId()]() {
                self->detachEffectById(effectId);
            });
        }
    }
}