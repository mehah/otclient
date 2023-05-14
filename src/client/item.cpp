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

#include "item.h"
#include "container.h"
#include "game.h"
#include "map.h"
#include "spritemanager.h"
#include "thing.h"
#include "thingtypemanager.h"
#include "tile.h"

#include <framework/core/binarytree.h>
#include <framework/core/clock.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/filestream.h>
#include <framework/core/graphicalapplication.h>

#include "shadermanager.h"

ItemPtr Item::create(int id)
{
    const auto& item = std::make_shared<Item>();
    item->setId(id);

    return item;
}

void Item::draw(const Point& dest, uint32_t flags, const Color& c, LightView* lightView)
{
    if (!canDraw(m_color) || isHided())
        return;

    // determine animation phase
    const int animationPhase = calculateAnimationPhase();
    const auto& color = c == Color::white ? m_color : c;

    internalDraw(animationPhase, dest, color, false, flags, lightView);

    if (isMarked())
        internalDraw(animationPhase, dest, getMarkedColor(), true, flags);
}

void Item::internalDraw(int animationPhase, const Point& dest, const Color& color, bool isMarked, uint32_t flags, LightView* lightView)
{
    if (isMarked)
        g_drawPool.setShaderProgram(g_painter->getReplaceColorShader(), true);
    else {
        drawAttachedEffect(dest, lightView, false); // On Bottom
        if (m_shader)
            g_drawPool.setShaderProgram(m_shader, true, m_shaderAction);
    }
    getThingType()->draw(dest, 0, m_numPatternX, m_numPatternY, m_numPatternZ, animationPhase, flags, color, lightView, m_drawConductor);
    if (!isMarked)
        drawAttachedEffect(dest, lightView, true); // On Top
}

void Item::setConductor()
{
    if (isSingleGround()) {
        m_drawConductor.agroup = true;
        m_drawConductor.order = DrawOrder::FIRST;
    } else if (isSingleGroundBorder() && !hasElevation()) {
        m_drawConductor.agroup = true;
        m_drawConductor.order = DrawOrder::SECOND;
    }
}

void Item::setPosition(const Position& position, uint8_t stackPos, bool hasElevation)
{
    Thing::setPosition(position, stackPos);

    if (hasElevation || (m_drawConductor.agroup && stackPos > 0))
        m_drawConductor.agroup = false;
}

int Item::getSubType()
{
    if (isSplash() || isFluidContainer())
        return m_countOrSubType;
    if (g_game.getClientVersion() > 862)
        return 0;
    return 1;
}

ItemPtr Item::clone()
{
    auto item = std::make_shared<Item>();
    *(item.get()) = *this;
    return item;
}

void Item::updatePatterns()
{
    m_numPatternX = m_numPatternY =
        m_numPatternZ = 0;

    // Avoid crashes with invalid items
    if (!isValid())
        return;

    const int numPatternX = getNumPatternX();
    const int numPatternY = getNumPatternY();

    if (isStackable() && numPatternX == 4 && numPatternY == 2) {
        if (m_countOrSubType <= 0) {
            m_numPatternX = 0;
            m_numPatternY = 0;
        } else if (m_countOrSubType < 5) {
            m_numPatternX = m_countOrSubType - 1;
            m_numPatternY = 0;
        } else if (m_countOrSubType < 10) {
            m_numPatternX = 0;
            m_numPatternY = 1;
        } else if (m_countOrSubType < 25) {
            m_numPatternX = 1;
            m_numPatternY = 1;
        } else if (m_countOrSubType < 50) {
            m_numPatternX = 2;
            m_numPatternY = 1;
        } else {
            m_numPatternX = 3;
            m_numPatternY = 1;
        }
    } else if (isHangable()) {
        const auto& tile = getTile();
        if (tile) {
            if (tile->mustHookSouth())
                m_numPatternX = numPatternX >= 2 ? 1 : 0;
            else if (tile->mustHookEast())
                m_numPatternX = numPatternX >= 3 ? 2 : 0;
        }
    } else if (isSplash() || isFluidContainer()) {
        int color = m_countOrSubType;
        if (g_game.getFeature(Otc::GameNewFluids)) {
            switch (m_countOrSubType) {
                case Otc::FluidNone:
                    color = Otc::FluidTransparent;
                    break;
                case Otc::FluidWater:
                    color = Otc::FluidBlue;
                    break;
                case Otc::FluidMana:
                    color = Otc::FluidPurple;
                    break;
                case Otc::FluidBeer:
                    color = Otc::FluidBrown;
                    break;
                case Otc::FluidOil:
                    color = Otc::FluidBrown;
                    break;
                case Otc::FluidBlood:
                    color = Otc::FluidRed;
                    break;
                case Otc::FluidSlime:
                    color = Otc::FluidGreen;
                    break;
                case Otc::FluidMud:
                    color = Otc::FluidBrown;
                    break;
                case Otc::FluidLemonade:
                    color = Otc::FluidYellow;
                    break;
                case Otc::FluidMilk:
                    color = Otc::FluidWhite;
                    break;
                case Otc::FluidWine:
                    color = Otc::FluidPurple;
                    break;
                case Otc::FluidHealth:
                    color = Otc::FluidRed;
                    break;
                case Otc::FluidUrine:
                    color = Otc::FluidYellow;
                    break;
                case Otc::FluidRum:
                    color = Otc::FluidBrown;
                    break;
                case Otc::FluidFruidJuice:
                    color = Otc::FluidYellow;
                    break;
                case Otc::FluidCoconutMilk:
                    color = Otc::FluidWhite;
                    break;
                case Otc::FluidTea:
                    color = Otc::FluidBrown;
                    break;
                case Otc::FluidMead:
                    color = Otc::FluidBrown;
                    break;
                default:
                    color = Otc::FluidTransparent;
                    break;
            }
        }

        m_numPatternX = (color % 4) % numPatternX;
        m_numPatternY = (color / 4) % numPatternY;
    } else {
        m_numPatternX = m_position.x % std::max<int>(1, numPatternX);
        m_numPatternY = m_position.y % std::max<int>(1, numPatternY);
        m_numPatternZ = m_position.z % std::max<int>(1, getNumPatternZ());
    }
}

int Item::calculateAnimationPhase()
{
    if (!hasAnimationPhases()) return 0;

    if (getIdleAnimator()) return getIdleAnimator()->getPhase();

    if (m_async) {
        return (g_clock.millis() % (g_gameConfig.getItemTicksPerFrame() * getAnimationPhases())) / g_gameConfig.getItemTicksPerFrame();
    }

    if (g_clock.millis() - m_lastPhase >= g_gameConfig.getItemTicksPerFrame()) {
        m_phase = (m_phase + 1) % getAnimationPhases();
        m_lastPhase = g_clock.millis();
    }

    return m_phase;
}

void Item::setId(uint32_t id)
{
    if (!g_things.isValidDatId(id, ThingCategoryItem))
        id = 0;

#ifdef FRAMEWORK_EDITOR
    m_serverId = g_things.findItemTypeByClientId(id)->getServerId();
#endif

    m_clientId = id;
    m_thingType = g_things.getThingType(m_clientId, ThingCategoryItem).get();
    setConductor();

    // Shader example on only items that can be marketed.
    /*
    if (isMarketable()) {
        m_shader = g_shaders.getShader("Outfit - Rainbow");

        // Example of how to send a UniformValue to shader
        m_shaderAction = [=]()-> void {
            m_shader->bind();
            m_shader->setUniformValue(ShaderManager::ITEM_ID_UNIFORM, static_cast<int>(id));
        };
    }
    */
}

#ifdef FRAMEWORK_EDITOR

std::string Item::getName()
{
    return g_things.findItemTypeByClientId(m_clientId)->getName();
}

ItemPtr Item::createFromOtb(int id)
{
    const auto& item = std::make_shared<Item>();
    item->setOtbId(id);

    return item;
}

void Item::setOtbId(uint16_t id)
{
    if (!g_things.isValidOtbId(id))
        id = 0;

    const auto& itemType = g_things.getItemType(id);
    m_serverId = id;

    id = itemType->getClientId();
    if (!g_things.isValidDatId(id, ThingCategoryItem))
        id = 0;

    m_clientId = id;
    m_thingType = g_things.getThingType(m_clientId, ThingCategoryItem).get();
    setConductor();
}

void Item::unserializeItem(const BinaryTreePtr& in)
{
    try {
        while (in->canRead()) {
            ItemAttr attrib = static_cast<ItemAttr>(in->getU8());
            if (attrib == 0)
                break;

            switch (attrib) {
                case ATTR_COUNT:
                case ATTR_RUNE_CHARGES:
                    setCount(in->getU8());
                    break;
                case ATTR_CHARGES:
                    setCount(in->getU16());
                    break;
                case ATTR_HOUSEDOORID:
                case ATTR_SCRIPTPROTECTED:
                case ATTR_DUALWIELD:
                case ATTR_DECAYING_STATE:
                    m_attribs.set(attrib, in->getU8());
                    break;
                case ATTR_ACTION_ID:
                case ATTR_UNIQUE_ID:
                case ATTR_DEPOT_ID:
                    m_attribs.set(attrib, in->getU16());
                    break;
                case ATTR_CONTAINER_ITEMS:
                case ATTR_ATTACK:
                case ATTR_EXTRAATTACK:
                case ATTR_DEFENSE:
                case ATTR_EXTRADEFENSE:
                case ATTR_ARMOR:
                case ATTR_ATTACKSPEED:
                case ATTR_HITCHANCE:
                case ATTR_DURATION:
                case ATTR_WRITTENDATE:
                case ATTR_SLEEPERGUID:
                case ATTR_SLEEPSTART:
                case ATTR_ATTRIBUTE_MAP:
                    m_attribs.set(attrib, in->getU32());
                    break;
                case ATTR_TELE_DEST:
                {
                    const uint16_t x = in->getU16();
                    const uint16_t y = in->getU16();
                    const uint8_t z = in->getU8();
                    m_attribs.set(attrib, Position{ x, y, z });
                    break;
                }
                case ATTR_NAME:
                case ATTR_TEXT:
                case ATTR_DESC:
                case ATTR_ARTICLE:
                case ATTR_WRITTENBY:
                    m_attribs.set(attrib, in->getString());
                    break;
                default:
                    throw Exception("invalid item attribute %d", attrib);
            }
        }
    } catch (const stdext::exception& e) {
        g_logger.error(stdext::format("Failed to unserialize OTBM item: %s", e.what()));
    }
}

void Item::serializeItem(const OutputBinaryTreePtr& out)
{
    out->startNode(OTBM_ITEM);
    out->addU16(getServerId());

    out->addU8(ATTR_COUNT);
    out->addU8(getCount());

    out->addU8(ATTR_CHARGES);
    out->addU16(getCountOrSubType());

    const auto& dest = getTeleportDestination();
    if (dest.isValid()) {
        out->addU8(ATTR_TELE_DEST);
        out->addPos(dest.x, dest.y, dest.z);
    }

    if (isDepot()) {
        out->addU8(ATTR_DEPOT_ID);
        out->addU16(getDepotId());
    }

    if (isHouseDoor()) {
        out->addU8(ATTR_HOUSEDOORID);
        out->addU8(getDoorId());
    }

    const auto aid = getActionId();
    const auto uid = getUniqueId();
    if (aid) {
        out->addU8(ATTR_ACTION_ID);
        out->addU16(aid);
    }

    if (uid) {
        out->addU8(ATTR_UNIQUE_ID);
        out->addU16(uid);
    }

    const auto& text = getText();
    if (g_things.getItemType(m_serverId)->isWritable() && !text.empty()) {
        out->addU8(ATTR_TEXT);
        out->addString(text);
    }

    const auto& desc = getDescription();
    if (!desc.empty()) {
        out->addU8(ATTR_DESC);
        out->addString(desc);
    }

    out->endNode();
    for (const auto& i : m_containerItems)
        i->serializeItem(out);
}

#endif

/* vim: set ts=4 sw=4 et :*/