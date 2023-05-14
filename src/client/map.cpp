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

#include "map.h"
#include "game.h"
#include "item.h"
#include "localplayer.h"
#include "mapview.h"
#include "minimap.h"
#include "missile.h"
#include "statictext.h"
#include "tile.h"

#include <framework/core/asyncdispatcher.h>
#include <framework/core/graphicalapplication.h>
#include <framework/core/eventdispatcher.h>

#ifdef FRAMEWORK_EDITOR
#include "houses.h"
#include "towns.h"
#endif

const static TilePtr m_nulltile;

Map g_map;

void Map::init()
{
    m_floors.resize(g_gameConfig.getMapMaxZ() + 1);

    resetAwareRange();

#ifdef FRAMEWORK_EDITOR
    m_animationFlags |= Animation_Show;
#endif
}

void Map::terminate()
{
    clean();
}

void Map::addMapView(const MapViewPtr& mapView) { m_mapViews.push_back(mapView); }

void Map::removeMapView(const MapViewPtr& mapView)
{
    const auto it = std::find(m_mapViews.begin(), m_mapViews.end(), mapView);
    if (it != m_mapViews.end())
        m_mapViews.erase(it);
}

void Map::notificateKeyRelease(const InputEvent& inputEvent) const
{
    for (const auto& mapView : m_mapViews) {
        mapView->onKeyRelease(inputEvent);
    }
}

void Map::notificateCameraMove(const Point& offset) const
{
    for (const auto& mapView : m_mapViews) {
        mapView->onCameraMove(offset);
    }
}

void Map::notificateTileUpdate(const Position& pos, const ThingPtr& thing, const Otc::Operation operation)
{
    if (!pos.isMapPosition())
        return;

    for (const auto& mapView : m_mapViews) {
        mapView->onTileUpdate(pos, thing, operation);
    }

    if (thing && thing->isItem()) {
        g_minimap.updateTile(pos, getTile(pos));
    }
}

void Map::clean()
{
    cleanDynamicThings();

    for (int_fast8_t i = -1; ++i <= g_gameConfig.getMapMaxZ();)
        m_floors[i].tileBlocks.clear();

#ifdef FRAMEWORK_EDITOR
    m_waypoints.clear();
    g_towns.clear();
    g_houses.clear();
    g_creatures.clearSpawns();
#endif
}

void Map::cleanDynamicThings()
{
    for (const auto& [uid, creature] : m_knownCreatures) {
        removeThing(creature);
    }
    m_knownCreatures.clear();

    for (int_fast8_t i = -1; ++i <= g_gameConfig.getMapMaxZ();)
        m_floors[i].missiles.clear();

    cleanTexts();
}

void Map::addThing(const ThingPtr& thing, const Position& pos, int16_t stackPos)
{
    if (!thing)
        return;

    if (thing->isItem() && thing->getId() == 0)
        return;

    if (thing->isMissile()) {
        m_floors[pos.z].missiles.emplace_back(thing->static_self_cast<Missile>());
        thing->setPosition(pos);
        thing->onAppear();
        return;
    }

    if (const auto& tile = getOrCreateTile(pos)) {
        if (m_floatingEffect || !thing->isEffect() || tile->getGround()) {
            tile->addThing(thing, stackPos);
            notificateTileUpdate(pos, thing, Otc::OPERATION_ADD);
        }
    }
}

void Map::addStaticText(const StaticTextPtr& txt, const Position& pos) {
    if (!g_app.isDrawingTexts())
        return;

    for (const auto& other : m_staticTexts) {
        // try to combine messages
        if (other->getPosition() == pos && other->addMessage(txt->getName(), txt->getMessageMode(), txt->getFirstMessage())) {
            return;
        }
    }

    txt->setPosition(pos);
    m_staticTexts.emplace_back(txt);
}

void Map::addAnimatedText(const AnimatedTextPtr& txt, const Position& pos) {
    if (!g_app.isDrawingTexts())
        return;

    // this code will stack animated texts of the same color
    AnimatedTextPtr prevAnimatedText;

    bool merged = false;
    for (const auto& other : m_animatedTexts) {
        if (other->getPosition() == pos) {
            prevAnimatedText = other;
            if (other->merge(txt)) {
                merged = true;
                break;
            }
        }
    }

    if (!merged) {
        if (prevAnimatedText) {
            Point offset = prevAnimatedText->getOffset();
            if (const float t = prevAnimatedText->getTimer().ticksElapsed();
                t < g_gameConfig.getAnimatedTextDuration() / 4.0) { // didnt move 12 pixels
                const int32_t y = 12 - 48 * t / static_cast<float>(g_gameConfig.getAnimatedTextDuration());
                offset += Point(0, y);
            }
            offset.y = std::min<int32_t>(offset.y, 12);
            txt->setOffset(offset);
        }
        m_animatedTexts.emplace_back(txt);
    }

    txt->setPosition(pos);
    txt->onAppear();
}

ThingPtr Map::getThing(const Position& pos, int16_t stackPos)
{
    if (const auto& tile = getTile(pos))
        return tile->getThing(stackPos);

    return nullptr;
}

bool Map::removeThing(const ThingPtr& thing)
{
    if (!thing)
        return false;

    if (thing->isMissile()) {
        auto& missiles = m_floors[thing->getPosition().z].missiles;
        const auto it = std::find(missiles.begin(), missiles.end(), thing->static_self_cast<Missile>());
        if (it == missiles.end())
            return false;

        missiles.erase(it);
        return true;
    }

    if (const auto& tile = thing->getTile()) {
        if (tile->removeThing(thing)) {
            notificateTileUpdate(thing->getPosition(), thing, Otc::OPERATION_REMOVE);
            return true;
        }
    }

    return false;
}

bool Map::removeThingByPos(const Position& pos, int16_t stackPos)
{
    if (const auto& tile = getTile(pos))
        return removeThing(tile->getThing(stackPos));

    return false;
}

bool Map::removeStaticText(const StaticTextPtr& txt) {
    const auto it = std::find(m_staticTexts.begin(), m_staticTexts.end(), txt);
    if (it == m_staticTexts.end())
        return false;

    m_staticTexts.erase(it);
    return true;
}

bool Map::removeAnimatedText(const AnimatedTextPtr& txt) {
    const auto it = std::find(m_animatedTexts.begin(), m_animatedTexts.end(), txt);
    if (it == m_animatedTexts.end())
        return false;

    m_animatedTexts.erase(it);
    return true;
}

void Map::colorizeThing(const ThingPtr& thing, const Color& color)
{
    if (!thing)
        return;

    if (thing->isItem())
        thing->static_self_cast<Item>()->setColor(color);
    else if (thing->isCreature()) {
        const auto& tile = thing->getTile();
        assert(tile);

        const auto& topThing = tile->getTopThing();
        assert(topThing);

        topThing->static_self_cast<Item>()->setColor(color);
    }
}

void Map::removeThingColor(const ThingPtr& thing)
{
    if (!thing)
        return;

    if (thing->isItem())
        thing->static_self_cast<Item>()->setColor(Color::alpha);
    else if (thing->isCreature()) {
        const auto& tile = thing->getTile();
        assert(tile);

        const auto& topThing = tile->getTopThing();
        assert(topThing);

        topThing->static_self_cast<Item>()->setColor(Color::alpha);
    }
}

StaticTextPtr Map::getStaticText(const Position& pos) const
{
    for (const auto& staticText : m_staticTexts) {
        // try to combine messages
        if (staticText->getPosition() == pos)
            return staticText;
    }

    return nullptr;
}

const TilePtr& Map::createTile(const Position& pos) { return pos.isMapPosition() ? m_floors[pos.z].tileBlocks[getBlockIndex(pos)].create(pos) : m_nulltile; }
const TilePtr& Map::getOrCreateTile(const Position& pos) { return pos.isMapPosition() ? m_floors[pos.z].tileBlocks[getBlockIndex(pos)].getOrCreate(pos) : m_nulltile; }

template <typename... Items>
const TilePtr& Map::createTileEx(const Position& pos, const Items&... items)
{
    if (!pos.isValid())
        return m_nulltile;

    const auto& tile = getOrCreateTile(pos);
    for (auto vec = { items... }; auto it : vec)
        addThing(it, pos);

    return tile;
}

const TilePtr& Map::getTile(const Position& pos)
{
    if (!pos.isMapPosition())
        return m_nulltile;

    auto& tileBlocks = m_floors[pos.z].tileBlocks;

    const auto it = tileBlocks.find(getBlockIndex(pos));
    if (it != tileBlocks.end())
        return it->second.get(pos);

    return m_nulltile;
}

TileList Map::getTiles(int8_t floor/* = -1*/)
{
    TileList tiles;
    if (floor > g_gameConfig.getMapMaxZ())
        return tiles;

    if (floor < 0) {
        // Search all floors
        for (int_fast8_t z = -1; ++z <= g_gameConfig.getMapMaxZ();) {
            for (const auto& [key, block] : m_floors[z].tileBlocks) {
                for (const auto& tile : block.getTiles()) {
                    if (tile != nullptr)
                        tiles.emplace_back(tile);
                }
            }
        }
    } else {
        for (const auto& [key, block] : m_floors[floor].tileBlocks) {
            for (const auto& tile : block.getTiles()) {
                if (tile != nullptr)
                    tiles.emplace_back(tile);
            }
        }
    }

    return tiles;
}

void Map::cleanTile(const Position& pos)
{
    if (!pos.isMapPosition())
        return;

    const auto it = m_floors[pos.z].tileBlocks.find(getBlockIndex(pos));
    if (it != m_floors[pos.z].tileBlocks.end()) {
        auto& block = it->second;
        if (const auto& tile = block.get(pos)) {
            tile->clean();
            if (tile->canErase())
                block.remove(pos);

            notificateTileUpdate(pos, nullptr, Otc::OPERATION_CLEAN);
        } else {
            g_minimap.updateTile(pos, nullptr);
        }
    }

    for (auto itt = m_staticTexts.begin(); itt != m_staticTexts.end();) {
        const auto& staticText = *itt;
        if (staticText->getPosition() == pos && staticText->getMessageMode() == Otc::MessageNone)
            itt = m_staticTexts.erase(itt);
        else
            ++itt;
    }
}

#ifdef FRAMEWORK_EDITOR
void Map::setShowZone(tileflags_t zone, bool show)
{
    if (show)
        m_zoneFlags |= static_cast<uint32_t>(zone);
    else
        m_zoneFlags &= ~static_cast<uint32_t>(zone);
}

void Map::setShowZones(bool show)
{
    if (!show)
        m_zoneFlags = 0;
    else if (m_zoneFlags == 0)
        m_zoneFlags = TILESTATE_HOUSE | TILESTATE_PROTECTIONZONE;
}

void Map::setZoneColor(tileflags_t zone, const Color& color)
{
    if ((m_zoneFlags & zone) == zone)
        m_zoneColors[zone] = color;
}

Color Map::getZoneColor(tileflags_t flag)
{
    const auto it = m_zoneColors.find(flag);
    if (it == m_zoneColors.end())
        return Color::alpha;

    return it->second;
}

void Map::setForceShowAnimations(bool force)
{
    if (!force) {
        m_animationFlags &= ~Animation_Force;
        return;
    }

    if (!(m_animationFlags & Animation_Force))
        m_animationFlags |= Animation_Force;
}

void Map::setShowAnimations(bool show)
{
    if (show) {
        if (!(m_animationFlags & Animation_Show))
            m_animationFlags |= Animation_Show;
    } else
        m_animationFlags &= ~Animation_Show;
}
#endif

void Map::beginGhostMode(float opacity) { g_painter->setOpacity(opacity); }
void Map::endGhostMode() { g_painter->resetOpacity(); }

stdext::map<Position, ItemPtr, Position::Hasher> Map::findItemsById(uint16_t clientId, uint32_t  max)
{
    stdext::map<Position, ItemPtr, Position::Hasher> ret;
    uint32_t  count = 0;
    for (uint8_t z = 0; z <= g_gameConfig.getMapMaxZ(); ++z) {
        for (const auto& [uid, block] : m_floors[z].tileBlocks) {
            for (const auto& tile : block.getTiles()) {
                if (unlikely(!tile || tile->isEmpty()))
                    continue;
                for (const auto& item : tile->getItems()) {
                    if (item->getId() == clientId) {
                        ret.emplace(tile->getPosition(), item);
                        if (++count >= max)
                            break;
                    }
                }
            }
        }
    }

    return ret;
}

CreaturePtr Map::getCreatureById(uint32_t  id)
{
    const auto it = m_knownCreatures.find(id);
    return it != m_knownCreatures.end() ? it->second : nullptr;
}

void Map::addCreature(const CreaturePtr& creature) { m_knownCreatures[creature->getId()] = creature; }
void Map::removeCreatureById(uint32_t  id)
{
    if (id == 0)
        return;

    const auto it = m_knownCreatures.find(id);
    if (it != m_knownCreatures.end())
        m_knownCreatures.erase(it);
}

void Map::removeUnawareThings()
{
    // remove creatures from tiles that we are not aware of anymore
    for (const auto& [uid, creature] : m_knownCreatures) {
        if (!isAwareOfPosition(creature->getPosition()))
            removeThing(creature);
    }

    // remove static texts from tiles that we are not aware anymore
    for (auto it = m_staticTexts.begin(); it != m_staticTexts.end();) {
        const auto& staticText = *it;
        if (staticText->getMessageMode() == Otc::MessageNone && !isAwareOfPosition(staticText->getPosition()))
            it = m_staticTexts.erase(it);
        else
            ++it;
    }

    if (!g_game.getFeature(Otc::GameKeepUnawareTiles)) {
        // remove tiles that we are not aware anymore
        for (int_fast8_t z = -1; ++z <= g_gameConfig.getMapMaxZ();) {
            auto& tileBlocks = m_floors[z].tileBlocks;
            for (auto it = tileBlocks.begin(); it != tileBlocks.end();) {
                auto& block = (*it).second;
                bool blockEmpty = true;
                for (const auto& tile : block.getTiles()) {
                    if (!tile) continue;

                    const auto& pos = tile->getPosition();
                    if (isAwareOfPosition(pos)) {
                        blockEmpty = false;
                        continue;
                    }

                    block.remove(pos);
                }

                if (blockEmpty)
                    it = tileBlocks.erase(it);
                else
                    ++it;
            }
        }
    }
}

void Map::setCentralPosition(const Position& centralPosition)
{
    if (m_centralPosition == centralPosition)
        return;

    m_centralPosition = centralPosition;

    removeUnawareThings();

    // this fixes local player position when the local player is removed from the map,
    // the local player is removed from the map when there are too many creatures on his tile,
    // so there is no enough stackpos to the server send him
    g_dispatcher.addEvent([this] {
        const auto& localPlayer = g_game.getLocalPlayer();
        if (!localPlayer || localPlayer->getPosition() == m_centralPosition)
            return;

        if (const auto& tile = localPlayer->getTile()) {
            if (tile->hasThing(localPlayer))
                return;
        }

        const auto& oldPos = localPlayer->getPosition();
        const auto& pos = m_centralPosition;
        if (oldPos != pos) {
            if (!localPlayer->isRemoved())
                localPlayer->onDisappear();
            localPlayer->setPosition(pos);
            localPlayer->onAppear();
            g_logger.debug("forced player position update");
        }
    });

    for (const auto& mapView : m_mapViews)
        mapView->onMapCenterChange(centralPosition, mapView->m_lastCameraPosition);
}

void Map::setLight(const Light& light)
{
    m_light = light;
    for (const auto& mapView : m_mapViews)
        mapView->onGlobalLightChange(m_light);
}

std::vector<CreaturePtr> Map::getSpectatorsInRangeEx(const Position& centerPos, bool multiFloor, int32_t minXRange, int32_t maxXRange, int32_t minYRange, int32_t maxYRange)
{
    std::vector<CreaturePtr> creatures;
    uint8_t minZRange = 0;
    uint8_t maxZRange = 0;

    if (multiFloor) {
        minZRange = centerPos.z - getFirstAwareFloor();
        maxZRange = getLastAwareFloor() - centerPos.z;
    }

    //TODO: optimize
    //TODO: delivery creatures in distance order
    for (int_fast8_t iz = -minZRange; iz <= maxZRange; ++iz) {
        for (int_fast32_t iy = -minYRange; iy <= maxYRange; ++iy) {
            for (int_fast32_t ix = -minXRange; ix <= maxXRange; ++ix) {
                if (const auto& tile = getTile(centerPos.translated(ix, iy, iz))) {
                    const auto& tileCreatures = tile->getCreatures();
                    creatures.insert(creatures.end(), tileCreatures.rbegin(), tileCreatures.rend());
                }
            }
        }
    }

    return creatures;
}

bool Map::isLookPossible(const Position& pos)
{
    const auto& tile = getTile(pos);
    return tile && tile->isLookPossible();
}

bool Map::isCovered(const Position& pos, uint8_t firstFloor)
{
    // check for tiles on top of the postion
    Position tilePos = pos;
    while (tilePos.coveredUp() && tilePos.z >= firstFloor) {
        // the below tile is covered when the above tile has a full opaque
        if (const auto& tile = getTile(tilePos)) {
            if (tile->isFullyOpaque())
                return true;
        }

        if (const auto& tile = getTile(tilePos.translated(1, 1))) {
            if (tile->isTopGround())
                return true;
        }
    }

    return false;
}

bool Map::isCompletelyCovered(const Position& pos, uint8_t firstFloor)
{
    const auto& checkTile = getTile(pos);
    Position tilePos = pos;
    while (tilePos.coveredUp() && tilePos.z >= firstFloor) {
        bool covered = true;
        bool done = false;

        // Check is Top Ground
        for (int_fast8_t x = -1; ++x < 2 && !done;) {
            for (int_fast8_t y = -1; ++y < 2 && !done;) {
                const auto& tile = getTile(tilePos.translated(x, x));
                if (!tile || !tile->isTopGround()) {
                    covered = false;
                    done = true;
                } else if (x == 1 && y == 1 && (!checkTile || checkTile->isSingleDimension())) {
                    done = true;
                }
            }
        }

        if (covered)
            return true;

        covered = true;
        done = false;

        // check in 2x2 range tiles that has no transparent pixels
        for (int_fast8_t x = -1; ++x < 2 && !done;) {
            for (int_fast8_t y = -1; ++y < 2 && !done;) {
                const auto& tile = getTile(tilePos.translated(-x, -y));
                if (!tile || !tile->isFullyOpaque()) {
                    covered = false;
                    done = true;
                } else if (x == 0 && y == 0 && (!checkTile || checkTile->isSingleDimension())) {
                    done = true;
                }
            }
        }

        if (covered)
            return true;
    }
    return false;
}

bool Map::isAwareOfPosition(const Position& pos) const
{
    if (pos.z < getFirstAwareFloor() || pos.z > getLastAwareFloor())
        return false;

    Position groundedPos = pos;
    while (groundedPos.z != m_centralPosition.z) {
        if (groundedPos.z > m_centralPosition.z) {
            if (groundedPos.x == UINT16_MAX || groundedPos.y == UINT16_MAX) // When pos == 65535,65535,15 we cant go up to 65536,65536,14
                break;
            groundedPos.coveredUp();
        } else {
            if (groundedPos.x == 0 || groundedPos.y == 0) // When pos == 0,0,0 we cant go down to -1,-1,1
                break;
            groundedPos.coveredDown();
        }
    }

    return m_centralPosition.isInRange(groundedPos, m_awareRange.left,
                                       m_awareRange.right,
                                       m_awareRange.top,
                                       m_awareRange.bottom);
}

void Map::setAwareRange(const AwareRange& range)
{
    m_awareRange = range;
    removeUnawareThings();
}

void Map::resetAwareRange() {
    setAwareRange({
        static_cast<uint8_t>(g_gameConfig.getMapViewPort().width()) ,
        static_cast<uint8_t>(g_gameConfig.getMapViewPort().height()),
        static_cast<uint8_t>(g_gameConfig.getMapViewPort().width() + 1),
        static_cast<uint8_t>(g_gameConfig.getMapViewPort().height() + 1)
    });
}

uint8_t Map::getFirstAwareFloor() const
{
    if (m_centralPosition.z <= g_gameConfig.getMapSeaFloor())
        return 0;

    return m_centralPosition.z - g_gameConfig.getMapAwareUndergroundFloorRange();
}

uint8_t Map::getLastAwareFloor() const
{
    if (m_centralPosition.z <= g_gameConfig.getMapSeaFloor())
        return g_gameConfig.getMapSeaFloor();

    return std::min<uint8_t >(m_centralPosition.z + g_gameConfig.getMapAwareUndergroundFloorRange(), g_gameConfig.getMapMaxZ());
}

std::tuple<std::vector<Otc::Direction>, Otc::PathFindResult> Map::findPath(const Position& startPos, const Position& goalPos, int maxComplexity, int flags)
{
    // pathfinding using dijkstra search algorithm

    struct SNode
    {
        SNode(const Position& pos) : cost(0), totalCost(0), pos(pos), prev(nullptr), dir(Otc::InvalidDirection) {}
        float cost;
        float totalCost;
        Position pos;
        SNode* prev;
        Otc::Direction dir;
    };

    struct LessNode
    {
        bool operator()(std::pair<SNode*, float> a, std::pair<SNode*, float> b) const
        {
            return b.second < a.second;
        }
    };

    std::tuple<std::vector<Otc::Direction>, Otc::PathFindResult> ret;
    std::vector<Otc::Direction>& dirs = std::get<0>(ret);
    Otc::PathFindResult& result = std::get<1>(ret);

    result = Otc::PathFindResultNoWay;

    if (startPos == goalPos) {
        result = Otc::PathFindResultSamePosition;
        return ret;
    }

    if (startPos.z != goalPos.z) {
        result = Otc::PathFindResultImpossible;
        return ret;
    }

    // check the goal pos is walkable
    if (g_map.isAwareOfPosition(goalPos)) {
        const auto& goalTile = getTile(goalPos);
        if (!goalTile || (!goalTile->isWalkable(flags & Otc::PathFindIgnoreCreatures))) {
            return ret;
        }
    } else {
        const auto& goalTile = g_minimap.getTile(goalPos);
        if (goalTile.hasFlag(MinimapTileNotWalkable)) {
            return ret;
        }
    }

    stdext::map<Position, SNode*, Position::Hasher> nodes;
    std::priority_queue<std::pair<SNode*, float>, std::vector<std::pair<SNode*, float>>, LessNode> searchList;

    auto* currentNode = new SNode(startPos);
    currentNode->pos = startPos;
    nodes[startPos] = currentNode;
    SNode* foundNode = nullptr;
    while (currentNode) {
        if (static_cast<int>(nodes.size()) > maxComplexity) {
            result = Otc::PathFindResultTooFar;
            break;
        }

        // path found
        if (currentNode->pos == goalPos && (!foundNode || currentNode->cost < foundNode->cost))
            foundNode = currentNode;

        // cost too high
        if (foundNode && currentNode->totalCost >= foundNode->cost)
            break;

        for (int i = -1; i <= 1; ++i) {
            for (int j = -1; j <= 1; ++j) {
                if (i == 0 && j == 0)
                    continue;

                bool wasSeen = false;
                bool hasCreature = false;
                bool isNotWalkable = true;
                bool isNotPathable = true;
                int speed = 100;

                Position neighborPos = currentNode->pos.translated(i, j);
                if (neighborPos.x < 0 || neighborPos.y < 0) continue;
                if (g_map.isAwareOfPosition(neighborPos)) {
                    wasSeen = true;
                    if (const auto& tile = getTile(neighborPos)) {
                        hasCreature = tile->hasCreature() && (!(flags & Otc::PathFindIgnoreCreatures));
                        isNotWalkable = !tile->isWalkable(flags & Otc::PathFindIgnoreCreatures);
                        isNotPathable = !tile->isPathable();
                        speed = tile->getGroundSpeed();
                    }
                } else {
                    const auto& mtile = g_minimap.getTile(neighborPos);
                    wasSeen = mtile.hasFlag(MinimapTileWasSeen);
                    isNotWalkable = mtile.hasFlag(MinimapTileNotWalkable);
                    isNotPathable = mtile.hasFlag(MinimapTileNotPathable);
                    if (isNotWalkable || isNotPathable)
                        wasSeen = true;
                    speed = mtile.getSpeed();
                }

                float walkFactor = 0;
                if (neighborPos != goalPos) {
                    if (!(flags & Otc::PathFindAllowNotSeenTiles) && !wasSeen)
                        continue;
                    if (wasSeen) {
                        if (!(flags & Otc::PathFindAllowCreatures) && hasCreature)
                            continue;
                        if (!(flags & Otc::PathFindAllowNonPathable) && isNotPathable)
                            continue;
                        if (!(flags & Otc::PathFindAllowNonWalkable) && isNotWalkable)
                            continue;
                    }
                } else {
                    if (!(flags & Otc::PathFindAllowNotSeenTiles) && !wasSeen)
                        continue;
                    if (wasSeen) {
                        if (!(flags & Otc::PathFindAllowNonWalkable) && isNotWalkable)
                            continue;
                    }
                }

                const Otc::Direction walkDir = currentNode->pos.getDirectionFromPosition(neighborPos);
                if (walkDir >= Otc::NorthEast)
                    walkFactor += 3.0f;
                else
                    walkFactor += 1.0f;

                const float cost = currentNode->cost + (speed * walkFactor) / 100.0f;

                SNode* neighborNode;
                if (!nodes.contains(neighborPos)) {
                    neighborNode = new SNode(neighborPos);
                    nodes[neighborPos] = neighborNode;
                } else {
                    neighborNode = nodes[neighborPos];
                    if (neighborNode->cost <= cost)
                        continue;
                }

                neighborNode->prev = currentNode;
                neighborNode->cost = cost;
                neighborNode->totalCost = neighborNode->cost + neighborPos.distance(goalPos);
                neighborNode->dir = walkDir;
                searchList.push(std::make_pair(neighborNode, neighborNode->totalCost));
            }
        }

        if (!searchList.empty()) {
            currentNode = searchList.top().first;
            searchList.pop();
        } else
            currentNode = nullptr;
    }

    if (foundNode) {
        currentNode = foundNode;
        while (currentNode) {
            dirs.push_back(currentNode->dir);
            currentNode = currentNode->prev;
        }
        dirs.pop_back();
        std::reverse(dirs.begin(), dirs.end());
        result = Otc::PathFindResultOk;
    }

    for (const auto& it : nodes)
        delete it.second;

    return ret;
}

void Map::resetLastCamera() const
{
    for (const auto& mapView : m_mapViews)
        mapView->resetLastCamera();
}

PathFindResult_ptr Map::newFindPath(const Position& start, const Position& goal, const std::shared_ptr<std::list<Node*>>
                                    & visibleNodes)
{
    auto ret = std::make_shared<PathFindResult>();
    ret->start = start;
    ret->destination = goal;

    if (start == goal) {
        ret->status = Otc::PathFindResultSamePosition;
        return ret;
    }

    if (goal.z != start.z) {
        return ret;
    }

    // check the goal pos is walkable
    if (g_map.isAwareOfPosition(goal)) {
        const auto& goalTile = getTile(goal);
        if (!goalTile || (!goalTile->isWalkable())) {
            return ret;
        }
    } else {
        const auto& goalTile = g_minimap.getTile(goal);
        if (goalTile.hasFlag(MinimapTileNotWalkable)) {
            return ret;
        }
    }

    struct LessNode
    {
        bool operator()(Node const* a, Node const* b) const
        {
            return b->totalCost < a->totalCost;
        }
    };

    stdext::map<Position, Node*, Position::Hasher> nodes;
    std::priority_queue<Node*, std::vector<Node*>, LessNode> searchList;

    if (visibleNodes) {
        for (auto& node : *visibleNodes)
            nodes.emplace(node->pos, node);
    }

    const auto& initNode = new Node{ 1, 0, start, nullptr, 0, 0 };
    nodes[start] = initNode;
    searchList.push(initNode);

    int limit = 50000;
    const float distance = start.distance(goal);

    Node* dstNode = nullptr;
    while (!searchList.empty() && --limit) {
        Node* node = searchList.top();
        searchList.pop();
        if (node->pos == goal) {
            dstNode = node;
            break;
        }
        if (node->pos.distance(goal) > distance + 10000)
            continue;
        for (int i = -1; i <= 1; ++i) {
            for (int j = -1; j <= 1; ++j) {
                if (i == 0 && j == 0)
                    continue;
                Position neighbor = node->pos.translated(i, j);
                if (neighbor.x < 0 || neighbor.y < 0) continue;
                auto it = nodes.find(neighbor);
                if (it == nodes.end()) {
                    const auto& [block, tile] = g_minimap.threadGetTile(neighbor);
                    const bool wasSeen = tile.hasFlag(MinimapTileWasSeen);
                    const bool isNotWalkable = tile.hasFlag(MinimapTileNotWalkable);
                    const bool isNotPathable = tile.hasFlag(MinimapTileNotPathable);
                    const bool isEmpty = tile.hasFlag(MinimapTileEmpty);
                    float speed = tile.getSpeed();
                    if ((isNotWalkable || isNotPathable || isEmpty) && neighbor != goal) {
                        it = nodes.emplace(neighbor, nullptr).first;
                    } else {
                        if (!wasSeen)
                            speed = 2000;
                        it = nodes.emplace(neighbor, new Node{ speed, 10000000.0f, neighbor, node, node->distance + 1, wasSeen ? 0 : 1 }).first;
                    }
                }
                if (!it->second) // no way
                    continue;

                if (it->second->unseen > 50)
                    continue;

                const float diagonal = ((i == 0 || j == 0) ? 1.0f : 3.0f);
                float cost = it->second->cost * diagonal;
                cost += diagonal * (50.0f * std::max<float>(5.0f, it->second->pos.distance(goal))); // heuristic
                if (node->totalCost + cost + 50 < it->second->totalCost) {
                    it->second->totalCost = node->totalCost + cost;
                    it->second->prev = node;
                    if (it->second->unseen)
                        it->second->unseen = node->unseen + 1;
                    it->second->distance = node->distance + 1;
                    searchList.push(it->second);
                }
            }
        }
    }

    if (dstNode) {
        while (dstNode && dstNode->prev) {
            if (dstNode->unseen) {
                ret->path.clear();
            } else {
                ret->path.push_back(dstNode->prev->pos.getDirectionFromPosition(dstNode->pos));
            }
            dstNode = dstNode->prev;
        }
        std::reverse(ret->path.begin(), ret->path.end());
        ret->status = Otc::PathFindResultOk;
    }
    ret->complexity = 50000 - limit;

    for (const auto& node : nodes) {
        delete node.second;
    }

    return ret;
}

void Map::findPathAsync(const Position& start, const Position& goal, const std::function<void(PathFindResult_ptr)>&
                        callback)
{
    const auto visibleNodes = std::make_shared<std::list<Node*>>();
    for (const auto& tile : getTiles(start.z)) {
        if (tile->getPosition() == start)
            continue;
        const bool isNotWalkable = !tile->isWalkable(false);
        const bool isNotPathable = !tile->isPathable();
        const float speed = tile->getGroundSpeed();
        if ((isNotWalkable || isNotPathable) && tile->getPosition() != goal) {
            visibleNodes->push_back(new Node{ speed, 0, tile->getPosition(), nullptr, 0, 0 });
        } else {
            visibleNodes->push_back(new Node{ speed, 10000000.0f, tile->getPosition(), nullptr, 0, 0 });
        }
    }

    g_asyncDispatcher.dispatch([=] {
        const auto ret = g_map.newFindPath(start, goal, visibleNodes);
        g_dispatcher.addEvent(std::bind(callback, ret));
    });
}