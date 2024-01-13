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

#include "tile.h"
#include <framework/core/eventdispatcher.h>
#include <framework/core/graphicalapplication.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/ui/uimanager.h>
#include <framework/ui/uiwidget.h>
#include "client.h"
#include "effect.h"
#include "game.h"
#include "item.h"
#include "lightview.h"
#include "map.h"
#include "uimap.h"
#include "protocolgame.h"
#include "statictext.h"
#include "localplayer.h"

Tile::Tile(const Position& position) : m_position(position) {}

void Tile::drawThing(const ThingPtr& thing, const Point& dest, int flags, LightView* lightView)
{
    thing->draw(dest - m_drawElevation * g_drawPool.getScaleFactor(), flags & Otc::DrawThings, lightView);
    if (thing->hasElevation())
        m_drawElevation = std::min<uint8_t>(m_drawElevation + thing->getElevation(), g_gameConfig.getTileMaxElevation());
}

void Tile::draw(const Point& dest, const MapPosInfo& mapRect, int flags, LightView* lightView)
{
    m_drawElevation = 0;
    m_lastDrawDest = dest;

#ifndef BOT_PROTECTION
    if (m_fill != Color::alpha) {
        g_drawPool.addFilledRect(Rect(dest, Size{ g_gameConfig.getSpriteSize() }), m_fill);
        return;
    }
#endif

    for (const auto& thing : m_things) {
        if (!thing->isGround() && !thing->isGroundBorder() && !thing->isOnBottom())
            break;

        drawThing(thing, dest, flags, lightView);
    }

    if (hasCommonItem()) {
        for (auto it = m_things.rbegin(); it != m_things.rend(); ++it) {
            const auto& item = *it;
            if (!item->isCommon()) continue;
            drawThing(item, dest, flags, lightView);
        }
    }

    // after we render 2x2 lying corpses, we must redraw previous creatures/ontop above them
    for (const auto& tile : m_tilesRedraw) {
        tile->drawCreature(tile->m_lastDrawDest, mapRect, flags, true, lightView);
        tile->drawTop(tile->m_lastDrawDest, flags, true, lightView);
    }

    drawCreature(dest, mapRect, flags, false, lightView);
    drawTop(dest, flags, false, lightView);
    drawAttachedEffect(dest, lightView, false);
    drawAttachedParticlesEffect(dest);
}

void Tile::drawCreature(const Point& dest, const MapPosInfo& mapRect, int flags, bool forceDraw, LightView* lightView)
{
    if (!forceDraw && !m_drawTopAndCreature)
        return;

    if (hasCreature()) {
        for (const auto& thing : m_things) {
            if (!thing->isCreature() || thing->static_self_cast<Creature>()->isWalking()) continue;

            drawThing(thing, dest, flags, lightView);
        }
    }

    for (const auto& creature : m_walkingCreatures) {
        const auto& cDest = Point(
            dest.x + ((creature->getPosition().x - m_position.x) * g_gameConfig.getSpriteSize() - creature->getDrawElevation()) * g_drawPool.getScaleFactor(),
            dest.y + ((creature->getPosition().y - m_position.y) * g_gameConfig.getSpriteSize() - creature->getDrawElevation()) * g_drawPool.getScaleFactor()
        );

        creature->draw(cDest, flags & Otc::DrawThings, lightView);
    }
}

void Tile::drawTop(const Point& dest, int flags, bool forceDraw, LightView* lightView)
{
    if (!forceDraw && !m_drawTopAndCreature)
        return;

    for (const auto& effect : m_effects)
        drawThing(effect, dest, flags & Otc::DrawThings, lightView);

    if (hasTopItem()) {
        for (const auto& item : m_things) {
            if (!item->isOnTop()) continue;
            item->draw(dest, flags & Otc::DrawThings, lightView);
        }
    }
}

void Tile::clean()
{
    if (g_client.getMapWidget()
#ifndef BOT_PROTECTION
        && (m_text || m_timerText)
#endif
        ) {
        g_dispatcher.scheduleEvent([tile = static_self_cast<Tile>()] {
            if (g_client.getMapWidget())
                g_client.getMapWidget()->getMapView()->removeForegroundTile(tile);
        }, g_game.getServerBeat());
    }

    if (hasAttachedWidgets()) {
        clearAttachedWidgets();
    }

    m_highlightThing = nullptr;
    while (!m_things.empty())
        removeThing(m_things.front());

    m_tilesRedraw.clear();
    m_thingTypeFlag = 0;

#ifdef FRAMEWORK_EDITOR
    m_flags = 0;
#endif
}

void Tile::addWalkingCreature(const CreaturePtr& creature)
{
    m_walkingCreatures.emplace_back(creature);
    setThingFlag(creature);
}

void Tile::removeWalkingCreature(const CreaturePtr& creature)
{
    const auto it = std::find(m_walkingCreatures.begin(), m_walkingCreatures.end(), creature);
    if (it == m_walkingCreatures.end())
        return;

    m_walkingCreatures.erase(it);
    recalculateThingFlag();
}

// TODO: Need refactoring
// Redo Stack Position System
void Tile::addThing(const ThingPtr& thing, int stackPos)
{
    if (!thing)
        return;

    if (thing->isEffect()) {
        const auto& newEffect = thing->static_self_cast<Effect>();

        const bool mustOptimize = g_app.mustOptimize() || g_app.isForcedEffectOptimization();

        for (const auto& prevEffect : m_effects) {
            if (!prevEffect->canDraw())
                continue;

            if (mustOptimize && newEffect->getSize() > prevEffect->getSize()) {
                prevEffect->canDraw(false);
            } else if (mustOptimize || newEffect->getId() == prevEffect->getId()) {
                if (!newEffect->waitFor(prevEffect))
                    return;
            }
        }

        if (newEffect->isTopEffect())
            m_effects.insert(m_effects.begin(), newEffect);
        else
            m_effects.emplace_back(newEffect);

        setThingFlag(thing);

        thing->setPosition(m_position);
        thing->onAppear();
        return;
    }

    const uint8_t size = m_things.size();

    // priority                                    854
    // 0 - ground,                        -->      -->
    // 1 - ground borders                 -->      -->
    // 2 - bottom (walls),                -->      -->
    // 3 - on top (doors)                 -->      -->
    // 4 - creatures, from top to bottom  <--      -->
    // 5 - items, from top to bottom      <--      <--
    if (stackPos < 0 || stackPos == 255) {
        const int priority = thing->getStackPriority();

        // -1 or 255 => auto detect position
        // -2        => append

        bool append;
        if (stackPos == -2)
            append = true;
        else {
            append = (priority <= 3);

            // newer protocols does not store creatures in reverse order
            if (g_game.getClientVersion() >= 854 && priority == 4)
                append = !append;
        }

        for (stackPos = 0; stackPos < size; ++stackPos) {
            const int otherPriority = m_things[stackPos]->getStackPriority();
            if ((append && otherPriority > priority) || (!append && otherPriority >= priority))
                break;
        }
    } else if (stackPos > static_cast<int>(size))
        stackPos = size;

    m_things.insert(m_things.begin() + stackPos, thing);

    // get the elevation status before analyze the new item.
    const bool hasElev = hasElevation();

    setThingFlag(thing);
    checkForDetachableThing();

    if (size > g_gameConfig.getTileMaxThings())
        removeThing(m_things[g_gameConfig.getTileMaxThings()]);

    // Do not change if you do not understand what is being done.
    {
        if (const auto& ground = getGround()) {
            stackPos = std::max<int>(--stackPos, 0);
            if (ground->isTopGround()) {
                ground->ungroup();
                thing->ungroup();
            }
        }
    }

    thing->setPosition(m_position, stackPos, hasElev);
    thing->onAppear();

    if (g_game.isTileThingLuaCallbackEnabled())
        callLuaField("onAddThing", thing);
}

// TODO: Need refactoring
bool Tile::removeThing(const ThingPtr thing)
{
    if (!thing) return false;

    if (thing->isEffect()) {
        const auto& effect = thing->static_self_cast<Effect>();
        const auto it = std::find(m_effects.begin(), m_effects.end(), effect);
        if (it == m_effects.end())
            return false;

        m_effects.erase(it);
        return true;
    }

    const auto it = std::find(m_things.begin(), m_things.end(), thing);
    if (it == m_things.end())
        return false;

    m_things.erase(it);

    recalculateThingFlag();
    if (thing->hasElevation())
        --m_elevation;

    checkForDetachableThing();

    thing->onDisappear();

    if (g_game.isTileThingLuaCallbackEnabled())
        callLuaField("onRemoveThing", thing);

    return true;
}

ThingPtr Tile::getThing(int stackPos)
{
    if (stackPos >= 0 && stackPos < static_cast<int>(m_things.size()))
        return m_things[stackPos];

    return nullptr;
}

std::vector<CreaturePtr> Tile::getCreatures()
{
    std::vector<CreaturePtr> creatures;
    if (hasCreature()) {
        for (const auto& thing : m_things) {
            if (thing->isCreature())
                creatures.emplace_back(thing->static_self_cast<Creature>());
        }
    }

    return creatures;
}

int Tile::getThingStackPos(const ThingPtr& thing)
{
    for (int stackpos = -1, s = m_things.size(); ++stackpos < s;) {
        if (thing == m_things[stackpos]) return stackpos;
    }

    return -1;
}

ThingPtr Tile::getTopThing()
{
    if (isEmpty())
        return nullptr;

    for (const auto& thing : m_things)
        if (thing->isCommon())
            return thing;

    return m_things[m_things.size() - 1];
}

std::vector<ItemPtr> Tile::getItems()
{
    std::vector<ItemPtr> items;
    for (const auto& thing : m_things) {
        if (!thing->isItem())
            continue;

        items.emplace_back(thing->static_self_cast<Item>());
    }
    return items;
}

EffectPtr Tile::getEffect(uint16_t id) const
{
    for (const auto& effect : m_effects)
        if (effect->getId() == id)
            return effect;

    return nullptr;
}

int Tile::getGroundSpeed()
{
    if (const auto& ground = getGround())
        return ground->getGroundSpeed();

    return 100;
}

uint8_t Tile::getMinimapColorByte()
{
    if (m_minimapColor != 0)
        return m_minimapColor;

    for (auto it = m_things.rbegin(); it != m_things.rend(); ++it) {
        const auto& thing = *it;
        if (thing->isCreature() || thing->isCommon())
            continue;

        const uint8_t c = thing->getMinimapColor();
        if (c != 0) return c;
    }

    return 255;
}

ThingPtr Tile::getTopLookThing()
{
    if (isEmpty())
        return nullptr;

    for (const auto& thing : m_things) {
        if (!thing->isIgnoreLook() && (!thing->isGround() && !thing->isGroundBorder() && !thing->isOnBottom() && !thing->isOnTop()))
            return thing;
    }

    return m_things[0];
}

ThingPtr Tile::getTopUseThing()
{
    if (isEmpty())
        return nullptr;

    for (const auto& thing : m_things) {
        if (thing->isForceUse() || (!thing->isGround() && !thing->isGroundBorder() && !thing->isOnBottom() && !thing->isOnTop() && !thing->isCreature() && !thing->isSplash()))
            return thing;
    }

    for (uint i = m_things.size() - 1; i > 0; --i) {
        ThingPtr thing = m_things[i];
        if (!thing->isSplash() && !thing->isCreature())
            return thing;
    }

    return m_things[0];
}

CreaturePtr Tile::getTopCreature(const bool checkAround)
{
    if (!hasCreature()) return nullptr;

    CreaturePtr creature;
    for (const auto& thing : m_things) {
        if (thing->isLocalPlayer()) // return local player if there is no other creature
            creature = thing->static_self_cast<Creature>();
        else if (thing->isCreature())
            return thing->static_self_cast<Creature>();
    }

    if (creature)
        return creature;

    if (!m_walkingCreatures.empty())
        return m_walkingCreatures.back();

    // check for walking creatures in tiles around
    if (checkAround) {
        for (const auto& pos : m_position.getPositionsAround()) {
            const auto& tile = g_map.getTile(pos);
            if (!tile) continue;

            for (const auto& c : tile->getCreatures()) {
                if (c->isWalking() && c->getLastStepFromPosition() == m_position && c->getStepProgress() < .75f) {
                    return c;
                }
            }
        }
    }

    return nullptr;
}

ThingPtr Tile::getTopMoveThing()
{
    if (isEmpty())
        return nullptr;

    for (int8_t i = -1, s = m_things.size(); ++i < s;) {
        const auto& thing = m_things[i];
        if (thing->isCommon()) {
            if (i > 0 && thing->isNotMoveable())
                return m_things[i - 1];

            return thing;
        }
    }

    for (const auto& thing : m_things) {
        if (thing->isCreature())
            return thing;
    }

    return m_things[0];
}

ThingPtr Tile::getTopMultiUseThing()
{
    if (isEmpty())
        return nullptr;

    if (const auto& topCreature = getTopCreature())
        return topCreature;

    for (const auto& thing : m_things) {
        if (thing->isForceUse())
            return thing;
    }

    for (int8_t i = -1, s = m_things.size(); ++i < s;) {
        const auto& thing = m_things[i];
        if (!thing->isGround() && !thing->isGroundBorder() && !thing->isOnBottom() && !thing->isOnTop()) {
            if (i > 0 && thing->isSplash())
                return m_things[i - 1];

            return thing;
        }
    }

    for (const auto& thing : m_things) {
        if (!thing->isGround() && !thing->isGroundBorder() && !thing->isOnTop())
            return thing;
    }

    return m_things[0];
}

bool Tile::isWalkable(bool ignoreCreatures)
{
    if (m_thingTypeFlag & TileThingType::NOT_WALKABLE || !getGround()) {
        return false;
    }

    if (!ignoreCreatures && hasCreature()) {
        for (const auto& thing : m_things) {
            if (!thing->isCreature()) continue;

            const auto& creature = thing->static_self_cast<Creature>();
            if (!creature->isPassable() && creature->canBeSeen())
                return false;
        }
    }

    return true;
}

bool Tile::isCompletelyCovered(uint8_t firstFloor, bool resetCache)
{
    if (m_position.z == 0 || m_position.z == firstFloor) return false;

    if (resetCache) {
        m_isCompletelyCovered = m_isCovered = 0;
    }

    if (hasCreature() || !m_walkingCreatures.empty() || hasLight())
        return false;

    const uint32_t idChecked = 1 << firstFloor;
    const uint32_t idState = 1 << (firstFloor + g_gameConfig.getMapMaxZ());
    if ((m_isCompletelyCovered & idChecked) == 0) {
        m_isCompletelyCovered |= idChecked;
        if (g_map.isCompletelyCovered(m_position, firstFloor)) {
            m_isCompletelyCovered |= idState;
            m_isCovered |= idChecked; // Set covered is Checked
            m_isCovered |= idState;
        }
    }

    return (m_isCompletelyCovered & idState) == idState;
}

bool Tile::isCovered(int8_t firstFloor)
{
    if (m_position.z == 0 || m_position.z == firstFloor) return false;

    const uint32_t idChecked = 1 << firstFloor;
    const uint32_t idState = 1 << (firstFloor + g_gameConfig.getMapMaxZ());

    if ((m_isCovered & idChecked) == 0) {
        m_isCovered |= idChecked;
        if (g_map.isCovered(m_position, firstFloor))
            m_isCovered |= idState;
    }

    return (m_isCovered & idState) == idState;
}

void Tile::onAddInMapView()
{
    m_drawTopAndCreature = true;
    m_tilesRedraw.clear();

    if (m_thingTypeFlag & TileThingType::CORRECT_CORPSE) {
        uint8_t redrawPreviousTopW = 0,
            redrawPreviousTopH = 0;

        for (const auto& item : m_things) {
            if (!item->isLyingCorpse()) continue;

            redrawPreviousTopW = std::max<int>(item->getWidth() - 1, redrawPreviousTopW);
            redrawPreviousTopH = std::max<int>(item->getHeight() - 1, redrawPreviousTopH);
        }

        for (int x = -redrawPreviousTopW; x <= 0; ++x) {
            for (int y = -redrawPreviousTopH; y <= 0; ++y) {
                if (x == 0 && y == 0)
                    continue;

                if (const auto& tile = g_map.getTile(m_position.translated(x, y))) {
                    tile->m_drawTopAndCreature = false;
                    m_tilesRedraw.emplace_back(tile);
                }
            }
        }
    }
}

bool Tile::hasBlockingCreature() const
{
    for (const auto& thing : m_things)
        if (thing->isCreature() && !thing->static_self_cast<Creature>()->isPassable() && !thing->isLocalPlayer())
            return true;
    return false;
}

bool Tile::limitsFloorsView(bool isFreeView)
{
    // ground and walls limits the view
    const auto& firstThing = getThing(0);
    return firstThing && !firstThing->isDontHide() && (firstThing->isGround() || (isFreeView ? firstThing->isOnBottom() : firstThing->isOnBottom() && firstThing->blockProjectile()));
}

bool Tile::checkForDetachableThing()
{
    if (m_highlightThing)
        m_highlightThing->setMarked(Color::white);

    m_highlightThing = nullptr;
    if (const auto& creature = getTopCreature()) {
        m_highlightThing = creature;
        return true;
    }

    if (hasCommonItem()) {
        for (const auto& item : m_things) {
            if ((!item->isCommon() || !item->canDraw() || item->isIgnoreLook() || item->isCloth()) && (!item->isUsable()) && (!item->hasLight())) {
                continue;
            }

            m_highlightThing = item;
            return true;
        }
    }

    if (hasBottomItem()) {
        for (auto it = m_things.rbegin(); it != m_things.rend(); ++it) {
            const auto& item = *it;
            if (!item->isOnBottom() || !item->canDraw() || item->isIgnoreLook() || item->isFluidContainer()) continue;
            m_highlightThing = item;
            return true;
        }
    }

    if (hasTopItem()) {
        for (auto it = m_things.rbegin(); it != m_things.rend(); ++it) {
            const auto& item = *it;
            if (!item->isOnTop()) break;
            if (!item->canDraw() || item->isIgnoreLook()) continue;

            if (item->hasLensHelp()) {
                m_highlightThing = item;
                return true;
            }
        }
    }

    return false;
}

void Tile::setThingFlag(const ThingPtr& thing)
{
    if (thing->hasLight())
        m_thingTypeFlag |= TileThingType::HAS_LIGHT;

    if (thing->hasDisplacement())
        m_thingTypeFlag |= TileThingType::HAS_DISPLACEMENT;

    if (thing->isEffect()) return;

    if (thing->isCommon())
        m_thingTypeFlag |= TileThingType::HAS_COMMON_ITEM;

    if (thing->isOnTop())
        m_thingTypeFlag |= TileThingType::HAS_TOP_ITEM;

    if (thing->isCreature())
        m_thingTypeFlag |= TileThingType::HAS_CREATURE;

    if (thing->isSingleGroundBorder())
        m_thingTypeFlag |= TileThingType::HAS_GROUND_BORDER;

    if (thing->isTopGroundBorder())
        m_thingTypeFlag |= TileThingType::HAS_TOP_GROUND_BORDER;

    if (thing->isLyingCorpse() && !g_game.getFeature(Otc::GameMapDontCorrectCorpse))
        m_thingTypeFlag |= TileThingType::CORRECT_CORPSE;

    // Creatures and items
    if (thing->isOnBottom()) {
        m_thingTypeFlag |= TileThingType::HAS_BOTTOM_ITEM;

        if (thing->isHookSouth())
            m_thingTypeFlag |= TileThingType::HAS_HOOK_SOUTH;

        if (thing->isHookEast())
            m_thingTypeFlag |= TileThingType::HAS_HOOK_EAST;
    }

    if (hasElevation())
        m_thingTypeFlag |= TileThingType::HAS_THING_WITH_ELEVATION;

    if (thing->isIgnoreLook())
        m_thingTypeFlag |= TileThingType::IGNORE_LOOK;

    // best option to have something more real, but in some cases as a custom project,
    // the developers are not defining crop size
    //if(thing->getRealSize() > g_gameConfig.getSpriteSize())
    if (!thing->isSingleDimension() || thing->hasElevation() || thing->hasDisplacement())
        m_thingTypeFlag |= TileThingType::NOT_SINGLE_DIMENSION;

    if (thing->getHeight() > 1) {
        m_thingTypeFlag |= TileThingType::HAS_TALL_THINGS;

        if (thing->getHeight() > 2)
            m_thingTypeFlag |= TileThingType::HAS_TALL_THINGS_2;
    }

    if (thing->getWidth() > 1) {
        m_thingTypeFlag |= TileThingType::HAS_WIDE_THINGS;

        if (thing->getWidth() > 2)
            m_thingTypeFlag |= TileThingType::HAS_WIDE_THINGS_2;
    }

    if (!thing->isItem()) return;

    if (thing->getWidth() > 1 && thing->getHeight() > 1)
        m_thingTypeFlag |= TileThingType::HAS_WALL;

    if (thing->isNotWalkable())
        m_thingTypeFlag |= TileThingType::NOT_WALKABLE;

    if (thing->isNotPathable())
        m_thingTypeFlag |= TileThingType::NOT_PATHABLE;

    if (thing->blockProjectile())
        m_thingTypeFlag |= TileThingType::BLOCK_PROJECTTILE;

    if (thing->isFullGround())
        m_thingTypeFlag |= TileThingType::FULL_GROUND;

    if (thing->isOpaque())
        m_thingTypeFlag |= TileThingType::IS_OPAQUE;

    if (thing->hasElevation())
        ++m_elevation;
}

void Tile::select(TileSelectType selectType)
{
    if (selectType == TileSelectType::NO_FILTERED && !isEmpty()) {
        if (!(m_highlightThing = getTopCreature()))
            m_highlightThing = m_things.back();
    }

    if (m_highlightThing)
        m_highlightThing->setMarked(Color::yellow);

    m_selectType = selectType;
}

void Tile::unselect()
{
    if (m_highlightThing)
        m_highlightThing->setMarked(Color::white);

    if (m_selectType == TileSelectType::NO_FILTERED)
        checkForDetachableThing();

    m_selectType = TileSelectType::NONE;
}

bool Tile::canRender(uint32_t& flags, const Position& cameraPosition, const AwareRange viewPort)
{
    const int8_t dz = m_position.z - cameraPosition.z;
    const auto& checkPos = m_position.translated(dz, dz);

    bool draw = true;

    // Check for non-visible tiles on the screen and ignore them
    {
        if ((cameraPosition.x - checkPos.x >= viewPort.left) || (checkPos.x - cameraPosition.x == viewPort.right && !hasWideThings() && !hasDisplacement() && !hasThingWithElevation() && m_walkingCreatures.empty()))
            draw = false;
        else if ((cameraPosition.y - checkPos.y >= viewPort.top) || (checkPos.y - cameraPosition.y == viewPort.bottom && !hasTallThings() && !hasWideThings2() && !hasDisplacement() && !hasThingWithElevation() && m_walkingCreatures.empty()))
            draw = false;
        else if (((checkPos.x - cameraPosition.x > viewPort.right && (!hasWideThings() || !hasDisplacement() || !hasThingWithElevation())) || (checkPos.y - cameraPosition.y > viewPort.bottom)) && !hasTallThings2())
            draw = false;
    }

    if (!draw) {
        flags &= ~Otc::DrawThings;
        if (!hasLight())
            flags &= ~Otc::DrawLights;
        if (!hasCreature())
            flags &= ~(Otc::DrawManaBar | Otc::DrawNames | Otc::DrawBars);
    }

    return flags > 0;
}

#ifndef BOT_PROTECTION
void Tile::drawTexts(Point dest)
{
    if (m_timerText && g_clock.millis() < m_timer) {
        if (m_text && m_text->hasText())
            dest.y -= 8;
        m_timerText->setText(stdext::format("%.01f", (m_timer - g_clock.millis()) / 1000.));
        m_timerText->drawText(dest, Rect(dest.x - 64, dest.y - 64, 128, 128));
        dest.y += 16;
    }

    if (m_text && m_text->hasText()) {
        m_text->drawText(dest, Rect(dest.x - 64, dest.y - 64, 128, 128));
    }
}

void Tile::setText(const std::string& text, Color color)
{
    if (!m_text) {
        m_text = std::make_shared<StaticText>();
        g_dispatcher.scheduleEvent([tile = static_self_cast<Tile>()] {
            if (g_client.getMapWidget())
                g_client.getMapWidget()->getMapView()->addForegroundTile(tile);
        }, g_game.getServerBeat());
    }

    m_text->setText(text);
    m_text->setColor(color);
}

std::string Tile::getText()
{
    return m_text ? m_text->getText() : "";
}

void Tile::setTimer(int time, Color color)
{
    if (time > 60000) {
        g_logger.warning("Max tile timer value is 300000 (300s)!");
        return;
    }
    m_timer = time + g_clock.millis();
    if (!m_timerText) {
        m_timerText = std::make_shared<StaticText>();
        g_dispatcher.scheduleEvent([tile = static_self_cast<Tile>()] {
            if (g_client.getMapWidget())
                g_client.getMapWidget()->getMapView()->addForegroundTile(tile);
        }, g_game.getServerBeat());
    }

    m_timerText->setColor(color);
}

int Tile::getTimer()
{
    return m_timerText ? std::max<int>(0, m_timer - g_clock.millis()) : 0;
}

void Tile::setFill(Color color)
{
    m_fill = color;
}

bool Tile::canShoot(int distance)
{
    auto player = g_game.getLocalPlayer();
    if (!player) return false;
    auto playerPos = player->getPosition();
    if (distance > 0 && std::max<int>(std::abs(m_position.x - playerPos.x), std::abs(m_position.y - playerPos.y)) > distance)
        return false;
    return g_map.isSightClear(playerPos, m_position);
}
#endif
