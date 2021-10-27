/*
 * Copyright (c) 2010-2020 OTClient <https://github.com/edubart/otclient>
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

#include <framework/core/application.h>
#include <framework/core/eventdispatcher.h>

Map g_map;
TilePtr Map::m_nulltile;

void Map::init()
{
    resetAwareRange();
    m_animationFlags |= Animation_Show;
}

void Map::terminate()
{
    clean();
}

void Map::addMapView(const MapViewPtr& mapView)
{
    m_mapViews.push_back(mapView);
}

void Map::removeMapView(const MapViewPtr& mapView)
{
    const auto it = std::find(m_mapViews.begin(), m_mapViews.end(), mapView);
    if(it != m_mapViews.end())
        m_mapViews.erase(it);
}

void Map::resetAwareRange()
{
    AwareRange range;
    range.left = 8;
    range.top = 6;
    range.bottom = range.top + 1;
    range.right = range.left + 1;
    setAwareRange(range);
}

void Map::notificateKeyRelease(const InputEvent& inputEvent)
{
    for(const MapViewPtr& mapView : m_mapViews) {
        mapView->onKeyRelease(inputEvent);
    }
}

void Map::notificateCameraMove(const Point& offset)
{
    for(const MapViewPtr& mapView : m_mapViews) {
        mapView->onCameraMove(offset);
    }
}

void Map::notificateTileUpdate(const Position& pos, const ThingPtr& thing, const Otc::Operation operation)
{
    if(!pos.isMapPosition())
        return;

    for(const MapViewPtr& mapView : m_mapViews) {
        mapView->onTileUpdate(pos, thing, operation);
    }

    g_minimap.updateTile(pos, getTile(pos));
}

void Map::clean()
{
    cleanDynamicThings();

    for(int_fast8_t i = -1; ++i <= MAX_Z;)
        m_tileBlocks[i].clear();

    m_waypoints.clear();

    g_towns.clear();
    g_houses.clear();
    g_creatures.clearSpawns();
    m_tilesRect = Rect(65534, 65534, 0, 0);
}

void Map::cleanDynamicThings()
{
    for(const auto& pair : m_knownCreatures) {
        const CreaturePtr& creature = pair.second;
        removeThing(creature);
    }
    m_knownCreatures.clear();

    for(int_fast8_t i = -1; ++i <= MAX_Z;)
        m_floorMissiles[i].clear();

    cleanTexts();
}

void Map::cleanTexts()
{
    m_animatedTexts.clear();
    m_staticTexts.clear();
}

void Map::addThing(const ThingPtr& thing, const Position& pos, int16 stackPos)
{
    if(!thing)
        return;

    if(thing->isItem() || thing->isCreature() || thing->isEffect()) {
        const TilePtr& tile = getOrCreateTile(pos);
        if(tile && (m_floatingEffect || !thing->isEffect() || tile->getGround())) {
            tile->addThing(thing, stackPos);
        }
    } else {
        if(thing->isMissile()) {
            m_floorMissiles[pos.z].push_back(thing->static_self_cast<Missile>());
        } else if(thing->isAnimatedText()) {
            // this code will stack animated texts of the same color
            const AnimatedTextPtr animatedText = thing->static_self_cast<AnimatedText>();
            AnimatedTextPtr prevAnimatedText;

            bool merged = false;
            for(const auto& other : m_animatedTexts) {
                if(other->getPosition() == pos) {
                    prevAnimatedText = other;
                    if(other->merge(animatedText)) {
                        merged = true;
                        break;
                    }
                }
            }

            if(!merged) {
                if(prevAnimatedText) {
                    Point offset = prevAnimatedText->getOffset();
                    const float t = prevAnimatedText->getTimer().ticksElapsed();
                    if(t < ANIMATED_TEXT_DURATION / 4.0) { // didnt move 12 pixels
                        const int32 y = 12 - 48 * t / static_cast<float>(ANIMATED_TEXT_DURATION);
                        offset += Point(0, y);
                    }
                    offset.y = std::min<int32>(offset.y, 12);
                    animatedText->setOffset(offset);
                }
                m_animatedTexts.push_back(animatedText);
            }
        } else if(thing->isStaticText()) {
            const StaticTextPtr staticText = thing->static_self_cast<StaticText>();
            for(const auto& other : m_staticTexts) {
                // try to combine messages
                if(other->getPosition() == pos && other->addMessage(staticText->getName(), staticText->getMessageMode(), staticText->getFirstMessage())) {
                    return;
                }
            }

            m_staticTexts.push_back(staticText);
        }

        thing->setPosition(pos);
        thing->onAppear();
    }

    notificateTileUpdate(pos, thing, Otc::OPERATION_ADD);
}

ThingPtr Map::getThing(const Position& pos, int16 stackPos)
{
    if(TilePtr tile = getTile(pos))
        return tile->getThing(stackPos);

    return nullptr;
}

bool Map::removeThing(const ThingPtr& thing)
{
    if(!thing)
        return false;

    bool ret = false;
    if(thing->isAnimatedText()) {
        const AnimatedTextPtr animatedText = thing->static_self_cast<AnimatedText>();
        const auto it = std::find(m_animatedTexts.begin(), m_animatedTexts.end(), animatedText);
        if(it != m_animatedTexts.end()) {
            m_animatedTexts.erase(it);
            ret = true;
        }
    } else if(thing->isStaticText()) {
        const StaticTextPtr staticText = thing->static_self_cast<StaticText>();
        const auto it = std::find(m_staticTexts.begin(), m_staticTexts.end(), staticText);
        if(it != m_staticTexts.end()) {
            m_staticTexts.erase(it);
            ret = true;
        }
    } else {
        if(thing->isMissile()) {
            MissilePtr missile = thing->static_self_cast<Missile>();
            const uint8 z = missile->getPosition().z;
            const auto it = std::find(m_floorMissiles[z].begin(), m_floorMissiles[z].end(), missile);
            if(it != m_floorMissiles[z].end()) {
                m_floorMissiles[z].erase(it);
                ret = true;
            }
        } else if(const TilePtr& tile = thing->getTile()) {
            ret = tile->removeThing(thing);
        }
    }

    notificateTileUpdate(thing->getPosition(), thing, Otc::OPERATION_REMOVE);

    return ret;
}

bool Map::removeThingByPos(const Position& pos, int16 stackPos)
{
    if(TilePtr tile = getTile(pos))
        return removeThing(tile->getThing(stackPos));

    return false;
}

void Map::colorizeThing(const ThingPtr& thing, const Color& color)
{
    if(!thing)
        return;

    if(thing->isItem())
        thing->static_self_cast<Item>()->setColor(color);
    else if(thing->isCreature()) {
        const TilePtr& tile = thing->getTile();
        assert(tile);

        const ThingPtr& topThing = tile->getTopThing();
        assert(topThing);

        topThing->static_self_cast<Item>()->setColor(color);
    }
}

void Map::removeThingColor(const ThingPtr& thing)
{
    if(!thing)
        return;

    if(thing->isItem())
        thing->static_self_cast<Item>()->setColor(Color::alpha);
    else if(thing->isCreature()) {
        const TilePtr& tile = thing->getTile();
        assert(tile);

        const ThingPtr& topThing = tile->getTopThing();
        assert(topThing);

        topThing->static_self_cast<Item>()->setColor(Color::alpha);
    }
}

StaticTextPtr Map::getStaticText(const Position& pos)
{
    for(auto staticText : m_staticTexts) {
        // try to combine messages
        if(staticText->getPosition() == pos)
            return staticText;
    }

    return nullptr;
}

const TilePtr& Map::createTile(const Position& pos)
{
    if(!pos.isMapPosition())
        return m_nulltile;

    if(pos.x < m_tilesRect.left())
        m_tilesRect.setLeft(pos.x);

    if(pos.y < m_tilesRect.top())
        m_tilesRect.setTop(pos.y);

    if(pos.x > m_tilesRect.right())
        m_tilesRect.setRight(pos.x);

    if(pos.y > m_tilesRect.bottom())
        m_tilesRect.setBottom(pos.y);

    TileBlock& block = m_tileBlocks[pos.z][getBlockIndex(pos)];
    return block.create(pos);
}

template <typename... Items>
const TilePtr& Map::createTileEx(const Position& pos, const Items&... items)
{
    if(!pos.isValid())
        return m_nulltile;

    const TilePtr& tile = getOrCreateTile(pos);
    auto vec = { items... };
    for(auto it : vec)
        addThing(it, pos);

    return tile;
}

const TilePtr& Map::getOrCreateTile(const Position& pos)
{
    if(!pos.isMapPosition())
        return m_nulltile;

    if(pos.x < m_tilesRect.left())
        m_tilesRect.setLeft(pos.x);

    if(pos.y < m_tilesRect.top())
        m_tilesRect.setTop(pos.y);

    if(pos.x > m_tilesRect.right())
        m_tilesRect.setRight(pos.x);

    if(pos.y > m_tilesRect.bottom())
        m_tilesRect.setBottom(pos.y);

    TileBlock& block = m_tileBlocks[pos.z][getBlockIndex(pos)];
    return block.getOrCreate(pos);
}

const TilePtr& Map::getTile(const Position& pos)
{
    if(!pos.isMapPosition())
        return m_nulltile;

    auto it = m_tileBlocks[pos.z].find(getBlockIndex(pos));
    if(it != m_tileBlocks[pos.z].end())
        return it->second.get(pos);

    return m_nulltile;
}

const TileList Map::getTiles(int8 floor/* = -1*/)
{
    TileList tiles;
    if(floor > MAX_Z) return tiles;

    if(floor < 0) {
        // Search all floors
        for(int_fast8_t z = -1; ++z <= MAX_Z;) {
            for(const auto& pair : m_tileBlocks[z]) {
                const TileBlock& block = pair.second;
                for(const TilePtr& tile : block.getTiles()) {
                    if(tile != nullptr)
                        tiles.push_back(tile);
                }
            }
        }
    } else {
        for(const auto& pair : m_tileBlocks[floor]) {
            const TileBlock& block = pair.second;
            for(const TilePtr& tile : block.getTiles()) {
                if(tile != nullptr)
                    tiles.push_back(tile);
            }
        }
    }

    return tiles;
}

void Map::cleanTile(const Position& pos)
{
    if(!pos.isMapPosition())
        return;

    auto it = m_tileBlocks[pos.z].find(getBlockIndex(pos));
    if(it != m_tileBlocks[pos.z].end()) {
        TileBlock& block = it->second;
        if(const TilePtr& tile = block.get(pos)) {
            tile->clean();
            if(tile->canErase())
                block.remove(pos);

            notificateTileUpdate(pos, nullptr, Otc::OPERATION_CLEAN);
        } else {
            g_minimap.updateTile(pos, nullptr);
        }
    }

    for(auto itt = m_staticTexts.begin(); itt != m_staticTexts.end();) {
        const StaticTextPtr& staticText = *itt;
        if(staticText->getPosition() == pos && staticText->getMessageMode() == Otc::MessageNone)
            itt = m_staticTexts.erase(itt);
        else
            ++itt;
    }
}

void Map::setShowZone(tileflags_t zone, bool show)
{
    if(show)
        m_zoneFlags |= static_cast<uint32>(zone);
    else
        m_zoneFlags &= ~static_cast<uint32>(zone);
}

void Map::setShowZones(bool show)
{
    if(!show)
        m_zoneFlags = 0;
    else if(m_zoneFlags == 0)
        m_zoneFlags = TILESTATE_HOUSE | TILESTATE_PROTECTIONZONE;
}

void Map::setZoneColor(tileflags_t zone, const Color& color)
{
    if((m_zoneFlags & zone) == zone)
        m_zoneColors[zone] = color;
}

Color Map::getZoneColor(tileflags_t flag)
{
    const auto it = m_zoneColors.find(flag);
    if(it == m_zoneColors.end())
        return Color::alpha;

    return it->second;
}

void Map::setForceShowAnimations(bool force)
{
    if(!force) {
        m_animationFlags &= ~Animation_Force;
        return;
    }

    if(!(m_animationFlags & Animation_Force))
        m_animationFlags |= Animation_Force;
}

bool Map::isForcingAnimations()
{
    return (m_animationFlags & Animation_Force) == Animation_Force;
}

bool Map::isShowingAnimations()
{
    return (m_animationFlags & Animation_Show) == Animation_Show;
}

void Map::setShowAnimations(bool show)
{
    if(show) {
        if(!(m_animationFlags & Animation_Show))
            m_animationFlags |= Animation_Show;
    } else
        m_animationFlags &= ~Animation_Show;
}

void Map::beginGhostMode(float opacity)
{
    g_painter->setOpacity(opacity);
}

void Map::endGhostMode()
{
    g_painter->resetOpacity();
}

std::map<Position, ItemPtr> Map::findItemsById(uint16 clientId, uint32 max)
{
    std::map<Position, ItemPtr> ret;
    uint32 count = 0;
    for(uint8_t z = 0; z <= MAX_Z; ++z) {
        for(const auto& pair : m_tileBlocks[z]) {
            const TileBlock& block = pair.second;
            for(const TilePtr& tile : block.getTiles()) {
                if(unlikely(!tile || tile->isEmpty()))
                    continue;
                for(const ItemPtr& item : tile->getItems()) {
                    if(item->getId() == clientId) {
                        ret.insert(std::make_pair(tile->getPosition(), item));
                        if(++count >= max)
                            break;
                    }
                }
            }
        }
    }

    return ret;
}

void Map::addCreature(const CreaturePtr& creature)
{
    m_knownCreatures[creature->getId()] = creature;
}

CreaturePtr Map::getCreatureById(uint32 id)
{
    const auto it = m_knownCreatures.find(id);
    if(it == m_knownCreatures.end())
        return nullptr;
    return it->second;
}

void Map::removeCreatureById(uint32 id)
{
    if(id == 0)
        return;

    const auto it = m_knownCreatures.find(id);
    if(it != m_knownCreatures.end())
        m_knownCreatures.erase(it);
}

void Map::removeUnawareThings()
{
    // remove creatures from tiles that we are not aware of anymore
    for(const auto& pair : m_knownCreatures) {
        const CreaturePtr& creature = pair.second;
        if(!isAwareOfPosition(creature->getPosition()))
            removeThing(creature);
    }

    // remove static texts from tiles that we are not aware anymore
    for(auto it = m_staticTexts.begin(); it != m_staticTexts.end();) {
        const StaticTextPtr& staticText = *it;
        if(staticText->getMessageMode() == Otc::MessageNone && !isAwareOfPosition(staticText->getPosition()))
            it = m_staticTexts.erase(it);
        else
            ++it;
    }

    if(!g_game.getFeature(Otc::GameKeepUnawareTiles)) {
        // remove tiles that we are not aware anymore
        for(int_fast8_t z = -1; ++z <= MAX_Z;) {
            std::unordered_map<uint, TileBlock>& tileBlocks = m_tileBlocks[z];
            for(auto it = tileBlocks.begin(); it != tileBlocks.end();) {
                TileBlock& block = (*it).second;
                bool blockEmpty = true;
                for(const TilePtr& tile : block.getTiles()) {
                    if(!tile) continue;

                    const Position& pos = tile->getPosition();
                    if(isAwareOfPosition(pos)) {
                        blockEmpty = false;
                        continue;
                    }

                    block.remove(pos);
                }

                if(blockEmpty)
                    it = tileBlocks.erase(it);
                else
                    ++it;
            }
        }
    }
}

void Map::setCentralPosition(const Position& centralPosition)
{
    if(m_centralPosition == centralPosition)
        return;

    m_centralPosition = centralPosition;

    removeUnawareThings();

    // this fixes local player position when the local player is removed from the map,
    // the local player is removed from the map when there are too many creatures on his tile,
    // so there is no enough stackpos to the server send him
    g_dispatcher.addEvent([this] {
        LocalPlayerPtr localPlayer = g_game.getLocalPlayer();
        if(!localPlayer || localPlayer->getPosition() == m_centralPosition)
            return;
        TilePtr tile = localPlayer->getTile();
        if(tile && tile->hasThing(localPlayer))
            return;

        const Position oldPos = localPlayer->getPosition();
        const Position pos = m_centralPosition;
        if(oldPos != pos) {
            if(!localPlayer->isRemoved())
                localPlayer->onDisappear();
            localPlayer->setPosition(pos);
            localPlayer->onAppear();
            g_logger.debug("forced player position update");
        }
    });

    for(const MapViewPtr& mapView : m_mapViews)
        mapView->onMapCenterChange(centralPosition, mapView->m_lastCameraPosition);
}

void Map::setLight(const Light& light)
{
    m_light = light;
    for(const MapViewPtr& mapView : m_mapViews)
        mapView->onGlobalLightChange(m_light);
}

std::vector<CreaturePtr> Map::getSightSpectators(const Position& centerPos, bool multiFloor)
{
    return getSpectatorsInRangeEx(centerPos, multiFloor, m_awareRange.left - 1, m_awareRange.right - 2, m_awareRange.top - 1, m_awareRange.bottom - 2);
}

std::vector<CreaturePtr> Map::getSpectators(const Position& centerPos, bool multiFloor)
{
    return getSpectatorsInRangeEx(centerPos, multiFloor, m_awareRange.left, m_awareRange.right, m_awareRange.top, m_awareRange.bottom);
}

std::vector<CreaturePtr> Map::getSpectatorsInRange(const Position& centerPos, bool multiFloor, int32 xRange, int32 yRange)
{
    return getSpectatorsInRangeEx(centerPos, multiFloor, xRange, xRange, yRange, yRange);
}

std::vector<CreaturePtr> Map::getSpectatorsInRangeEx(const Position& centerPos, bool multiFloor, int32 minXRange, int32 maxXRange, int32 minYRange, int32 maxYRange)
{
    std::vector<CreaturePtr> creatures;
    uint8 minZRange = 0, maxZRange = 0;

    if(multiFloor) {
        minZRange = centerPos.z - getFirstAwareFloor();
        maxZRange = getLastAwareFloor() - centerPos.z;
    }

    //TODO: optimize
    //TODO: delivery creatures in distance order
    for(int_fast8_t iz = -minZRange; iz <= maxZRange; ++iz) {
        for(int_fast32_t iy = -minYRange; iy <= maxYRange; ++iy) {
            for(int_fast32_t ix = -minXRange; ix <= maxXRange; ++ix) {
                if(const TilePtr& tile = getTile(centerPos.translated(ix, iy, iz))) {
                    auto tileCreatures = tile->getCreatures();
                    creatures.insert(creatures.end(), tileCreatures.rbegin(), tileCreatures.rend());
                }
            }
        }
    }

    return creatures;
}

bool Map::isLookPossible(const Position& pos)
{
    TilePtr tile = getTile(pos);
    return tile && tile->isLookPossible();
}

bool Map::isCovered(const Position& pos, uint8 firstFloor)
{
    // check for tiles on top of the postion
    Position tilePos = pos;
    while(tilePos.coveredUp() && tilePos.z >= firstFloor) {
        TilePtr tile = getTile(tilePos);
        // the below tile is covered when the above tile has a full opaque
        if(tile && tile->isFullyOpaque())
            return true;

        tile = getTile(tilePos.translated(1, 1));
        if(tile && tile->isTopGround())
            return true;
    }
    return false;
}

bool Map::isCompletelyCovered(const Position& pos, uint8 firstFloor)
{
    const TilePtr& checkTile = getTile(pos);
    Position tilePos = pos;
    while(tilePos.coveredUp() && tilePos.z >= firstFloor) {
        bool covered = true;
        bool done = false;

        // Check is Top Ground
        for(int_fast8_t x = -1; ++x < 2 && !done;) {
            for(int_fast8_t y = -1; ++y < 2 && !done;) {
                const TilePtr& tile = getTile(tilePos.translated(x, x));
                if(!tile || !tile->isTopGround()) {
                    covered = false;
                    done = true;
                } else if(x == 1 && y == 1 && (!checkTile || checkTile->isSingleDimension())) {
                    done = true;
                }
            }
        }

        if(covered)
            return true;

        covered = true;
        done = false;

        // check in 2x2 range tiles that has no transparent pixels
        for(int_fast8_t x = -1; ++x < 2 && !done;) {
            for(int_fast8_t y = -1; ++y < 2 && !done;) {
                const TilePtr& tile = getTile(tilePos.translated(-x, -y));
                if(!tile || !tile->isFullyOpaque()) {
                    covered = false;
                    done = true;
                } else if(x == 0 && y == 0 && (!checkTile || checkTile->isSingleDimension())) {
                    done = true;
                }
            }
        }

        if(covered)
            return true;
    }
    return false;
}

bool Map::isAwareOfPosition(const Position& pos)
{
    if(pos.z < getFirstAwareFloor() || pos.z > getLastAwareFloor())
        return false;

    Position groundedPos = pos;
    while(groundedPos.z != m_centralPosition.z) {
        if(groundedPos.z > m_centralPosition.z) {
            if(groundedPos.x == UINT16_MAX || groundedPos.y == UINT16_MAX) // When pos == 65535,65535,15 we cant go up to 65536,65536,14
                break;
            groundedPos.coveredUp();
        } else {
            if(groundedPos.x == 0 || groundedPos.y == 0) // When pos == 0,0,0 we cant go down to -1,-1,1
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

uint8 Map::getFirstAwareFloor()
{
    if(m_centralPosition.z > SEA_FLOOR)
        return m_centralPosition.z - AWARE_UNDEGROUND_FLOOR_RANGE;

    return 0;
}

uint8 Map::getLastAwareFloor()
{
    if(m_centralPosition.z > SEA_FLOOR)
        return std::min<uint8>(m_centralPosition.z + AWARE_UNDEGROUND_FLOOR_RANGE, MAX_Z);

    return SEA_FLOOR;
}

std::tuple<std::vector<Otc::Direction>, Otc::PathFindResult> Map::findPath(const Position& startPos, const Position& goalPos, uint16 maxComplexity, uint32 flags)
{
    // pathfinding using A* search algorithm
    // as described in http://en.wikipedia.org/wiki/A*_search_algorithm

    struct Node {
        using Pair = std::pair<Node*, float>; // node, totalCost

        Node(const Position& pos) : cost(0), pos(pos), prev(nullptr), dir(Otc::InvalidDirection) {}
        float cost;
        Position pos;
        Node* prev;
        Otc::Direction dir;

        struct Compare {
            bool operator() (const Pair& a, const Pair& b) const
            {
                return b.second < a.second;
            }
        };
    };

    std::tuple<std::vector<Otc::Direction>, Otc::PathFindResult> ret;
    std::vector<Otc::Direction>& dirs = std::get<0>(ret);
    Otc::PathFindResult& result = std::get<1>(ret);

    result = Otc::PathFindResultNoWay;

    if(startPos == goalPos) {
        result = Otc::PathFindResultSamePosition;
        return ret;
    }

    if(startPos.z != goalPos.z) {
        result = Otc::PathFindResultImpossible;
        return ret;
    }

    // check the goal pos is walkable
    if(g_map.isAwareOfPosition(goalPos)) {
        const TilePtr goalTile = getTile(goalPos);
        if(!goalTile || !goalTile->isWalkable((flags & Otc::PathFindAllowCreatures))) {
            return ret;
        }
    } else {
        const MinimapTile& goalTile = g_minimap.getTile(goalPos);
        if(goalTile.hasFlag(MinimapTileNotWalkable)) {
            return ret;
        }
    }

    std::unordered_map<Position, Node*, Position::Hasher> nodes;
    std::priority_queue<Node::Pair, std::deque<Node::Pair>, Node::Compare> searchList;

    Node* currentNode = new Node(startPos);
    nodes[startPos] = currentNode;
    Node* foundNode = nullptr;
    float totalCost = 0;
    while(currentNode) {
        if(static_cast<uint16>(nodes.size()) > maxComplexity) {
            foundNode = nullptr;
            result = Otc::PathFindResultTooFar;
            break;
        }

        // path found
        if(currentNode->pos == goalPos && (!foundNode || currentNode->cost < foundNode->cost)) {
            foundNode = currentNode;

            // cost too high, and the priority_queue is sorted by "totalCost", so the rest of nodes won't be better
        } else if(foundNode && totalCost >= foundNode->cost) {
            break;
        } else {
            for(int_fast32_t i = -1; i <= 1; ++i) {
                for(int_fast32_t j = -1; j <= 1; ++j) {
                    if(i == 0 && j == 0)
                        continue;

                    bool wasSeen = false;
                    bool hasCreature = false;
                    bool isNotWalkable = true;
                    bool isNotPathable = true;
                    uint16 speed = 100;

                    Position neighborPos = currentNode->pos.translated(i, j);
                    if(g_map.isAwareOfPosition(neighborPos)) {
                        wasSeen = true;
                        if(const TilePtr& tile = getTile(neighborPos)) {
                            hasCreature = !tile->getCreatures().empty();
                            isNotWalkable = !tile->isWalkable(flags & Otc::PathFindAllowCreatures);
                            isNotPathable = !tile->isPathable();
                            speed = tile->getGroundSpeed();
                        }
                    } else {
                        const MinimapTile& mtile = g_minimap.getTile(neighborPos);
                        wasSeen = mtile.hasFlag(MinimapTileWasSeen);
                        isNotWalkable = mtile.hasFlag(MinimapTileNotWalkable);
                        isNotPathable = mtile.hasFlag(MinimapTileNotPathable);
                        if(isNotWalkable || isNotPathable)
                            wasSeen = true;
                        speed = mtile.getSpeed();
                    }

                    if(neighborPos != goalPos) {
                        if(!(flags & Otc::PathFindAllowNotSeenTiles) && !wasSeen)
                            continue;
                        if(wasSeen) {
                            if(!(flags & Otc::PathFindAllowCreatures) && hasCreature)
                                continue;
                            if(!(flags & Otc::PathFindAllowNonPathable) && isNotPathable)
                                continue;
                            if(!(flags & Otc::PathFindAllowNonWalkable) && isNotWalkable)
                                continue;
                        }
                    } else {
                        if(!(flags & Otc::PathFindAllowNotSeenTiles) && !wasSeen)
                            continue;
                        if(wasSeen) {
                            if(!(flags & Otc::PathFindAllowNonWalkable) && isNotWalkable)
                                continue;
                        }
                    }

                    float walkFactor;
                    const Otc::Direction walkDir = currentNode->pos.getDirectionFromPosition(neighborPos);
                    if(walkDir >= Otc::NorthEast)
                        walkFactor = 3.0f;
                    else
                        walkFactor = 1.0f;

                    const float cost = currentNode->cost + (speed * walkFactor) / 100.0f;

                    Node* neighborNode;
                    if(nodes.find(neighborPos) == nodes.end()) {
                        neighborNode = new Node(neighborPos);
                        nodes[neighborPos] = neighborNode;
                    } else {
                        neighborNode = nodes[neighborPos];
                        if(neighborNode->cost <= cost)
                            continue;
                    }

                    neighborNode->prev = currentNode;
                    neighborNode->cost = cost;
                    neighborNode->dir = walkDir;
                    searchList.emplace(neighborNode, neighborNode->cost + neighborPos.distance(goalPos));
                }
            }
        }

        if(!searchList.empty()) {
            const auto& top = searchList.top();
            currentNode = top.first;
            totalCost = top.second;
            searchList.pop();
        } else
            currentNode = nullptr;
    }

    if(foundNode) {
        currentNode = foundNode;
        while(currentNode) {
            dirs.push_back(currentNode->dir);
            currentNode = currentNode->prev;
        }
        dirs.pop_back();
        std::reverse(dirs.begin(), dirs.end());
        result = Otc::PathFindResultOk;
    }

    for(auto it : nodes)
        delete it.second;

    return ret;
}

void  Map::resetLastCamera()
{
    for(const MapViewPtr& mapView : m_mapViews)
        mapView->resetLastCamera();
}
