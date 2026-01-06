/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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

#ifdef FRAMEWORK_EDITOR

#include "game.h"
#include "map.h"
#include "tile.h"
#include "item.h"
#include "spritemanager.h"

#include <framework/core/application.h>
#include <framework/core/asyncdispatcher.h>
#include <framework/core/binarytree.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/filestream.h>
#include <framework/core/resourcemanager.h>
#include <framework/ui/uiwidget.h>
#include <framework/graphics/image.h>

#include "houses.h"
#include "towns.h"

#include <condition_variable>
#include <memory>
#include <mutex>
#include <sstream>
#include <thread>
#include <atomic>
#include <set>

void Map::loadOtbm(const std::string& fileName)
{
    try {
        // Clear map at load - we want to load map part and limit RAM usage
        // This prevents stale tiles from previous map parts appearing in generated images
        cleanDynamicThings();
        
        for (auto& floor : m_floors) {
            floor.tileBlocks.clear();
        }
        
        m_waypoints.clear();
        g_towns.clear();
        g_houses.clear();
        g_creatures.clearSpawns();

        if (!g_things.isOtbLoaded())
            throw Exception("OTB isn't loaded yet to load a map.");

        const FileStreamPtr fin = g_resources.openFile(fileName);
        if (!fin)
            throw Exception("Unable to load map '{}'", fileName);

        fin->cache();

        char identifier[4];
        if (fin->read(identifier, 1, 4) < 4)
            throw Exception("Could not read file identifier");

        if (memcmp(identifier, "OTBM", 4) != 0 && memcmp(identifier, "\0\0\0\0", 4) != 0)
            throw Exception("Invalid file identifier detected: {}", identifier);

        const BinaryTreePtr root = fin->getBinaryTree();
        if (root->getU8())
            throw Exception("could not read root property!");

        const uint32_t headerVersion = root->getU32();
        if (headerVersion > 3)
            throw Exception("Unknown OTBM version detected: {}.", headerVersion);

        setWidth(root->getU16());
        setHeight(root->getU16());

        const uint32_t headerMajorItems = root->getU8();
        if (headerMajorItems > g_things.getOtbMajorVersion()) {
            throw Exception("This map was saved with different OTB version. read {} what it's supposed to be: {}", headerMajorItems, g_things.getOtbMajorVersion());
        }

        root->skip(3);
        const uint32_t headerMinorItems = root->getU32();
        if (headerMinorItems > g_things.getOtbMinorVersion()) {
            g_logger.warning("This map needs an updated OTB. read {} what it's supposed to be: {} or less", headerMinorItems, g_things.getOtbMinorVersion());
        }

        const BinaryTreePtr node = root->getChildren()[0];
        if (node->getU8() != OTBM_MAP_DATA)
            throw Exception("Could not read root data node");

        while (node->canRead()) {
            const uint8_t attribute = node->getU8();
            std::string tmp = node->getString();
            switch (attribute) {
                case OTBM_ATTR_DESCRIPTION:
                    setDescription(tmp);
                    break;
                case OTBM_ATTR_SPAWN_FILE:
                    setSpawnFile(fileName.substr(0, fileName.rfind('/') + 1).c_str() + tmp);
                    break;
                case OTBM_ATTR_HOUSE_FILE:
                    setHouseFile(fileName.substr(0, fileName.rfind('/') + 1).c_str() + tmp);
                    break;
                default:
                    throw Exception("Invalid attribute '{}'", static_cast<int>(attribute));
            }
        }

        // Reset map generator data structures
        m_mapAreas.clear();
        m_mapTilesPerX.clear();
        m_minPosition = Position(65535, 65535, 255);
        m_maxPosition = Position(0, 0, 0);

        for (const auto& nodeMapData : node->getChildren()) {
            const uint8_t mapDataType = nodeMapData->getU8();
            if (mapDataType == OTBM_TILE_AREA) {
                Position basePos;
                basePos.x = nodeMapData->getU16();
                basePos.y = nodeMapData->getU16();
                basePos.z = nodeMapData->getU8();

                for (const auto& nodeTile : nodeMapData->getChildren()) {
                    const uint8_t type = nodeTile->getU8();
                    if (unlikely(type != OTBM_TILE && type != OTBM_HOUSETILE))
                        throw Exception("invalid node tile type {}", static_cast<int>(type));

                    HousePtr house = nullptr;
                    uint32_t flags = TILESTATE_NONE;
                    Position pos = basePos + nodeTile->getPoint();

                    // Track min/max position and tiles per X for map generator
                    if (m_maxXToLoad == -1) {
                        // Only tracking map bounds, not loading tiles
                        m_minPosition.x = std::min(m_minPosition.x, pos.x);
                        m_minPosition.y = std::min(m_minPosition.y, pos.y);
                        m_minPosition.z = std::min(m_minPosition.z, pos.z);
                        m_maxPosition.x = std::max(m_maxPosition.x, pos.x);
                        m_maxPosition.y = std::max(m_maxPosition.y, pos.y);
                        m_maxPosition.z = std::max(m_maxPosition.z, pos.z);
                        m_mapTilesPerX[pos.x]++;
                    }

                    // Skip loading tile if outside X range
                    if (m_maxXToLoad != -1 && (pos.x < m_minXToLoad || pos.x > m_maxXToLoad)) {
                        continue;
                    }

                    // Add to generator area list if within render range
                    if (m_minXToRender <= pos.x && pos.x <= m_maxXToRender) {
                        // For surface tiles (Z <= 7): generate areas from min loaded Z to tile Z
                        // For underground tiles (Z > 7): generate areas from 8 to tile Z
                        // This creates separate "view layers" - surface (0-7) and underground (8-15)
                        int16_t startFloor = (pos.z <= 7) ? 0 : 8;
                        for (int16_t allFloors = startFloor; allFloors <= pos.z; allFloors++) {
                            uint32_t areaKey = allFloors + (pos.y / 8) * 16 + (pos.x / 8) * 262144;
                            uint32_t positionInt = allFloors + (pos.y << 4) + (pos.x << 18);
                            m_mapAreas[areaKey] = positionInt;
                        }
                    }
                    
                    // Debug: log unique z levels being added (limit spam)
                    static std::set<int16_t> zLevelsLogged;
                    if (zLevelsLogged.find(pos.z) == zLevelsLogged.end()) {
                        g_logger.info("loadOtbm: First tile at Z={} found at ({}, {})", pos.z, pos.x, pos.y);
                        zLevelsLogged.insert(pos.z);
                    }

                    if (type == OTBM_HOUSETILE) {
                        const uint32_t hId = nodeTile->getU32();
                        TilePtr tile = getOrCreateTile(pos);
                        if (!(house = g_houses.getHouse(hId))) {
                            house = std::make_shared<House>(hId);
                            g_houses.addHouse(house);
                        }
                        house->setTile(tile);
                    }

                    while (nodeTile->canRead()) {
                        const uint8_t tileAttr = nodeTile->getU8();
                        switch (tileAttr) {
                            case OTBM_ATTR_TILE_FLAGS:
                            {
                                const uint32_t _flags = nodeTile->getU32();
                                if ((_flags & TILESTATE_PROTECTIONZONE) == TILESTATE_PROTECTIONZONE)
                                    flags |= TILESTATE_PROTECTIONZONE;
                                else if ((_flags & TILESTATE_OPTIONALZONE) == TILESTATE_OPTIONALZONE)
                                    flags |= TILESTATE_OPTIONALZONE;
                                else if ((_flags & TILESTATE_HARDCOREZONE) == TILESTATE_HARDCOREZONE)
                                    flags |= TILESTATE_HARDCOREZONE;

                                if ((_flags & TILESTATE_NOLOGOUT) == TILESTATE_NOLOGOUT)
                                    flags |= TILESTATE_NOLOGOUT;

                                if ((_flags & TILESTATE_REFRESH) == TILESTATE_REFRESH)
                                    flags |= TILESTATE_REFRESH;

                                if (_flags & TILESTATE_ZONE_BRUSH) {
                                    uint16_t zoneId = 0;
                                    do {
                                        zoneId = nodeTile->getU16();
                                    } while (zoneId != 0);
                                }
                                break;
                            }
                            case OTBM_ATTR_ITEM:
                            {
                                addThing(Item::createFromOtb(nodeTile->getU16()), pos);
                                break;
                            }
                            default:
                            {
                                throw Exception("invalid tile attribute {} at pos {}", static_cast<int>(tileAttr), pos);
                            }
                        }
                    }

                    for (const auto& nodeItem : nodeTile->getChildren()) {
                        if (unlikely(nodeItem->getU8() != OTBM_ITEM))
                            throw Exception("invalid item node");

                        ItemPtr item = Item::createFromOtb(nodeItem->getU16());
                        item->unserializeItem(nodeItem);

                        if (item->isContainer()) {
                            for (const auto& containerItem : nodeItem->getChildren()) {
                                if (containerItem->getU8() != OTBM_ITEM)
                                    throw Exception("invalid container item node");

                                ItemPtr cItem = Item::createFromOtb(containerItem->getU16());
                                cItem->unserializeItem(containerItem);
                                item->addContainerItem(cItem);
                            }
                        }

                        if (house && item->isMoveable()) {
                            g_logger.warning("Moveable item found in house: {} at pos {} - escaping...", item->getId(), pos);
                            item.reset();
                        }

                        addThing(item, pos);
                    }

                    if (const TilePtr& tile = getTile(pos)) {
                        if (house)
                            tile->setFlag(TILESTATE_HOUSE);
                        tile->setFlag(flags);
                    }
                }
            } else if (mapDataType == OTBM_TOWNS) {
                TownPtr town = nullptr;
                for (const auto& nodeTown : nodeMapData->getChildren()) {
                    if (nodeTown->getU8() != OTBM_TOWN)
                        throw Exception("invalid town node.");

                    const uint32_t townId = nodeTown->getU32();
                    const auto& townName = nodeTown->getString();

                    Position townCoords;
                    townCoords.x = nodeTown->getU16();
                    townCoords.y = nodeTown->getU16();
                    townCoords.z = nodeTown->getU8();

                    if (!(town = g_towns.getTown(townId)))
                        g_towns.addTown(std::make_shared<Town>(townId, townName, townCoords));
                }
                g_towns.sort();
            } else if (mapDataType == OTBM_WAYPOINTS && headerVersion > 1) {
                for (const auto& nodeWaypoint : nodeMapData->getChildren()) {
                    if (nodeWaypoint->getU8() != OTBM_WAYPOINT)
                        throw Exception("invalid waypoint node.");

                    std::string name = nodeWaypoint->getString();

                    Position waypointPos;
                    waypointPos.x = nodeWaypoint->getU16();
                    waypointPos.y = nodeWaypoint->getU16();
                    waypointPos.z = nodeWaypoint->getU8();

                    if (waypointPos.isValid() && !name.empty() && !m_waypoints.contains(waypointPos))
                        m_waypoints.emplace(waypointPos, name);
                }
            } else
                throw Exception("Unknown map data node {}", static_cast<int>(mapDataType));
        }

        fin->close();
    } catch (const std::exception& e) {
        g_logger.error("Failed to load '{}': {}", fileName, e.what());
    }
}

void Map::saveOtbm(const std::string& fileName)
{
    try {
        const FileStreamPtr fin = g_resources.createFile(fileName);
        if (!fin)
            throw Exception("failed to open file '{}' for write", fileName);

        fin->cache();
        std::string dir;
        if (fileName.find_last_of('/') == std::string::npos)
            dir = g_resources.getWorkDir();
        else
            dir = fileName.substr(0, fileName.find_last_of('/'));

        uint32_t version = 0;
        if (g_things.getOtbMajorVersion() < ClientVersion820)
            version = 1;
        else
            version = 2;

        /// Usually when a map has empty house/spawn file it means the map is new.
        /// TODO: Ask the user for a map name instead of those ugly uses of substr
        std::string::size_type sep_pos;
        std::string houseFile = getHouseFile();
        std::string spawnFile = getSpawnFile();
        std::string cpyf;

        if ((sep_pos = fileName.rfind('.')) != std::string::npos && fileName.ends_with(".otbm"))
            cpyf = fileName.substr(0, sep_pos);

        if (houseFile.empty())
            houseFile = cpyf + "-houses.xml";

        if (spawnFile.empty())
            spawnFile = cpyf + "-spawns.xml";

        /// we only need the filename to save to, the directory should be resolved by the OTBM loader not here
        if ((sep_pos = spawnFile.rfind('/')) != std::string::npos)
            spawnFile = spawnFile.substr(sep_pos + 1);

        if ((sep_pos = houseFile.rfind('/')) != std::string::npos)
            houseFile = houseFile.substr(sep_pos + 1);

        fin->addU32(0); // file version
        const auto& root = std::make_shared<OutputBinaryTree>(fin);
        {
            root->addU32(version);

            const Size mapSize = getSize();
            root->addU16(mapSize.width());
            root->addU16(mapSize.height());

            root->addU32(g_things.getOtbMajorVersion());
            root->addU32(g_things.getOtbMinorVersion());

            root->startNode(OTBM_MAP_DATA);
            {
                root->addU8(OTBM_ATTR_DESCRIPTION);
                root->addString(m_desc);

                root->addU8(OTBM_ATTR_SPAWN_FILE);
                root->addString(spawnFile);

                root->addU8(OTBM_ATTR_HOUSE_FILE);
                root->addString(houseFile);

                int px = -1;
                int py = -1;
                int pz = -1;
                bool firstNode = true;

                for (uint8_t z = 0; z <= g_gameConfig.getMapMaxZ(); ++z) {
                    for (const auto& it : m_floors[z].tileBlocks) {
                        const TileBlock& block = it.second;
                        for (const TilePtr& tile : block.getTiles()) {
                            if (unlikely(!tile || tile->isEmpty()))
                                continue;

                            const Position& pos = tile->getPosition();
                            if (unlikely(!pos.isValid()))
                                continue;

                            if (pos.x < px || pos.x >= px + 256
                                || pos.y < py || pos.y >= py + 256
                                || pos.z != pz) {
                                if (!firstNode)
                                    root->endNode(); /// OTBM_TILE_AREA

                                firstNode = false;
                                root->startNode(OTBM_TILE_AREA);

                                px = pos.x & 0xFF00;
                                py = pos.y & 0xFF00;
                                pz = pos.z;
                                root->addPos(px, py, pz);
                            }

                            root->startNode(tile->isHouseTile() ? OTBM_HOUSETILE : OTBM_TILE);
                            root->addPoint(Point(pos.x, pos.y) & 0xFF);
                            if (tile->isHouseTile())
                                root->addU32(tile->getHouseId());

                            if (tile->getFlags()) {
                                root->addU8(OTBM_ATTR_TILE_FLAGS);
                                root->addU32(tile->getFlags());
                            }

                            const auto& itemList = tile->getItems();
                            const ItemPtr& ground = tile->getGround();
                            if (ground) {
                                // Those types are called "complex" needs other stuff to be written.
                                // For containers, there is container items, for depot, depot it and so on.
                                if (!ground->isContainer() && !ground->isDepot()
                                    && !ground->isDoor() && !ground->isTeleport()) {
                                    root->addU8(OTBM_ATTR_ITEM);
                                    root->addU16(ground->getServerId());
                                } else
                                    ground->serializeItem(root);
                            }
                            for (const ItemPtr& item : itemList)
                                if (!item->isGround())
                                    item->serializeItem(root);

                            root->endNode(); // OTBM_TILE
                        }
                    }
                }

                if (!firstNode)
                    root->endNode();  // OTBM_TILE_AREA

                root->startNode(OTBM_TOWNS);
                for (const TownPtr& town : g_towns.getTowns()) {
                    root->startNode(OTBM_TOWN);

                    root->addU32(town->getId());
                    root->addString(town->getName());

                    const Position townPos = town->getPos();
                    root->addPos(townPos.x, townPos.y, townPos.z);
                    root->endNode();
                }
                root->endNode();

                if (version > 1) {
                    root->startNode(OTBM_WAYPOINTS);
                    for (const auto& it : m_waypoints) {
                        root->startNode(OTBM_WAYPOINT);
                        root->addString(it.second);

                        const Position pos = it.first;
                        root->addPos(pos.x, pos.y, pos.z);
                        root->endNode();
                    }
                    root->endNode();
                }
            }
            root->endNode(); // OTBM_MAP_DATA
        }
        root->endNode();

        fin->flush();
        fin->close();
    } catch (const std::exception& e) {
        g_logger.error("Failed to save '{}': {}", fileName, e.what());
    }
}

bool Map::loadOtcm(const std::string& fileName)
{
    try {
        const FileStreamPtr fin = g_resources.openFile(fileName);
        if (!fin)
            throw Exception("unable to open file");

        fin->cache();

        if (const uint32_t signature = fin->getU32(); signature != OTCM_SIGNATURE)
            throw Exception("invalid otcm file");

        const uint16_t start = fin->getU16();
        const uint16_t version = fin->getU16();
        fin->getU32(); // flags

        switch (version) {
            case 1:
            {
                fin->getString(); // description
                const uint32_t datSignature = fin->getU32();
                fin->getU16(); // protocol version
                fin->getString(); // world name

                if (datSignature != g_things.getDatSignature())
                    g_logger.warning("otcm map loaded was created with a different dat signature");

                break;
            }
            default:
                throw Exception("otcm version not supported");
        }

        fin->seek(start);

        while (true) {
            Position pos;

            pos.x = fin->getU16();
            pos.y = fin->getU16();
            pos.z = fin->getU8();

            // end of file
            if (!pos.isValid())
                break;

            const TilePtr& tile = g_map.createTile(pos);

            int stackPos = 0;
            while (true) {
                const int id = fin->getU16();

                // end of tile
                if (id == 0xFFFF)
                    break;

                const int countOrSubType = fin->getU8();

                ItemPtr item = Item::create(id);
                item->setCountOrSubType(countOrSubType);

                if (item->isValid())
                    tile->addThing(item, ++stackPos);
            }

            g_map.notificateTileUpdate(pos, nullptr, Otc::OPERATION_ADD);
        }

        fin->close();

        return true;
    } catch (const stdext::exception& e) {
        g_logger.error("failed to load OTCM map: {}", e.what());
        return false;
    }
}

void Map::saveOtcm(const std::string& fileName)
{
    try {
        stdext::timer saveTimer;

        const FileStreamPtr fin = g_resources.createFile(fileName);
        fin->cache();

        //TODO: compression flag with zlib
        const uint32_t flags = 0;

        // header
        fin->addU32(OTCM_SIGNATURE);
        fin->addU16(0); // data start, will be overwritten later
        fin->addU16(OTCM_VERSION);
        fin->addU32(flags);

        // version 1 header
        fin->addString("OTCM 1.0"); // map description
        fin->addU32(g_things.getDatSignature());
        fin->addU16(g_game.getClientVersion());
        fin->addString(g_game.getWorldName());

        // go back and rewrite where the map data starts
        const uint32_t start = fin->tell();
        fin->seek(4);
        fin->addU16(start);
        fin->seek(start);

        for (uint8_t z = 0; z <= g_gameConfig.getMapMaxZ(); ++z) {
            for (const auto& it : m_floors[z].tileBlocks) {
                const TileBlock& block = it.second;
                for (const TilePtr& tile : block.getTiles()) {
                    if (!tile || tile->isEmpty())
                        continue;

                    const Position pos = tile->getPosition();
                    fin->addU16(pos.x);
                    fin->addU16(pos.y);
                    fin->addU8(pos.z);

                    for (const ThingPtr& thing : tile->getThings()) {
                        if (thing->isItem()) {
                            const ItemPtr item = thing->static_self_cast<Item>();
                            fin->addU16(item->getId());
                            fin->addU8(item->getCountOrSubType());
                        }
                    }

                    // end of tile
                    fin->addU16(0xFFFF);
                }
            }
        }

        // end of file
        const Position invalidPos;
        fin->addU16(invalidPos.x);
        fin->addU16(invalidPos.y);
        fin->addU8(invalidPos.z);

        fin->flush();

        fin->close();
    } catch (const stdext::exception& e) {
        g_logger.error("failed to save OTCM map: {}", e.what());
    }
}

// Map image generation implementation
static std::unique_ptr<BS::thread_pool> g_mapGeneratorThreadPool;

void mapPartGenerator(int x, int y, int z)
{
    std::stringstream path;
    path << "exported_images/map/" << x << "_" << y << "_" << z << ".png";
    g_map.drawMap(path.str(), x * 8, y * 8, z, 8);
    g_map.increaseGeneratedAreasCount();
}

void Map::initializeMapGenerator(int threadsNumber)
{
    g_mapGeneratorThreadPool = std::make_unique<BS::thread_pool>(threadsNumber);
    g_logger.info("Started {} map generator threads.", threadsNumber);
}

void Map::increaseGeneratedAreasCount()
{
    std::lock_guard<std::mutex> lock(m_generatedAreasCountMutex);
    m_generatedAreasCount++;
}

void Map::addAreasToGenerator(int startAreaId, int endAreaId)
{
    if (!g_mapGeneratorThreadPool) {
        g_logger.error("Map generator thread pool not initialized. Call initializeMapGenerator(threadsNumber) before adding areas to generator.");
        return;
    }

    int i = 0;
    uint32_t areaKey, x, y, z;
    
    // Debug: track Z levels in areas
    std::set<int> zLevelsFound;
    
    for (auto iterator = m_mapAreas.begin(); iterator != m_mapAreas.end(); iterator++) {
        if (startAreaId <= i && i <= endAreaId) {
            // Use the KEY (areaKey) to decode area coordinates
            // areaKey format: z + (y/8)*16 + (x/8)*262144
            areaKey = iterator->first;
            z = areaKey & 0x0F;                 // z is in bits 0-3
            y = (areaKey >> 4) & 0x3FFF;        // y/8 is in bits 4-17
            x = (areaKey >> 18) & 0x3FFF;       // x/8 is in bits 18-31
            zLevelsFound.insert(z);
            g_mapGeneratorThreadPool->detach_task([x, y, z]() { mapPartGenerator(x, y, z); });
        }
        i++;
    }
    
    // Log Z levels found in this batch
    std::string zList;
    for (int zl : zLevelsFound) {
        if (!zList.empty()) zList += ",";
        zList += std::to_string(zl);
    }
    g_logger.info("addAreasToGenerator({}-{}): {} areas queued, Z levels: [{}]", 
        startAreaId, endAreaId, std::min(endAreaId - startAreaId + 1, i), zList);
}

void Map::generateMapForZ(int16_t targetZ, uint8_t shadowPercent)
{
    if (!g_mapGeneratorThreadPool) {
        g_logger.error("Map generator thread pool not initialized. Call initializeMapGenerator first.");
        return;
    }
    
    m_shadowPercent = shadowPercent;
    
    // Use the min/max position bounds that were set during loadOtbm
    const int minX = m_minPosition.x / 8;
    const int maxX = m_maxPosition.x / 8;
    const int minY = m_minPosition.y / 8;
    const int maxY = m_maxPosition.y / 8;
    
    g_logger.info("generateMapForZ: Generating for Z={}, X range: {}-{} (tiles {}-{}), Y range: {}-{} (tiles {}-{})",
        targetZ, minX, maxX, m_minPosition.x, m_maxPosition.x, 
        minY, maxY, m_minPosition.y, m_maxPosition.y);
    
    int generatedCount = 0;
    
    for (int x = minX; x <= maxX; ++x) {
        for (int y = minY; y <= maxY; ++y) {
            g_mapGeneratorThreadPool->detach_task([x, y, targetZ]() { 
                mapPartGenerator(x, y, targetZ); 
            });
            generatedCount++;
        }
    }
    
    g_logger.info("generateMapForZ: Queued {} images for Z={}", generatedCount, targetZ);
}

void Map::drawMap(std::string fileName, int sx, int sy, int16_t sz, int size, uint32_t houseId)
{
    Position pos;
    const int squareSize = g_gameConfig.getSpriteSize();
    // Image is 2 tiles larger than area to accommodate 64x64 sprites extending beyond tile bounds
    ImagePtr image(new Image(Size(squareSize * (size + 2), squareSize * (size + 2))));
    
    // m_shadowPercent == -1 means single layer mode (only current floor, transparent background)
    // m_shadowPercent >= 0 means render lower floors with that shadow percentage
    const bool singleLayerMode = (m_shadowPercent < 0);
    
    if (!singleLayerMode) {
        // Determine the lowest floor to draw based on target floor
        // For underground (z > 7): draw from floor 15 down to current floor+1
        // For surface (z <= 7): draw from floor 7 down to current floor+1
        int16_t lowestFloor = (sz <= 7) ? 7 : 15;

        // Draw lower floors (stacked view) - these get shadow applied
        int offset = 0;
        for (int16_t z = lowestFloor; z > sz; z--) {
            pos.z = z;
            offset = z - sz;
            for (int x = -offset; x <= size; x++) {
                for (int y = -offset; y <= size; y++) {
                    pos.x = sx + x;
                    pos.y = sy + y;
                    if (const TilePtr& tile = getTile(pos)) {
                        int offX = x + 1 + offset;
                        int offY = y + 1 + offset;
                        if (offX < size + 2 && offY < size + 2) {
                            Point dest(offX * squareSize, offY * squareSize);
                            tile->drawToImage(dest, image);
                        }
                    }
                }
            }
        }

        // Apply shadow to lower floors
        // shadowPercent=30 means floors below are 70% brightness
        image->addShadow(static_cast<uint8_t>(100 - m_shadowPercent));
    }

    // Draw current floor on top (no shadow)
    pos.z = sz;
    for (int x = 0; x <= size; x++) {
        for (int y = 0; y <= size; y++) {
            pos.x = sx + x;
            pos.y = sy + y;
            if (const TilePtr& tile = getTile(pos)) {
                int offX = x + 1;
                int offY = y + 1;
                if (offX < size + 2 && offY < size + 2) {
                    Point dest(offX * squareSize, offY * squareSize);
                    tile->drawToImage(dest, image);
                }
            }
        }
    }

    // Reduce image size - remove the 2-tile margin used for 64x64 items
    image->cut();
    
    // Save to file (savePNG skips empty images via wasBlited check)
    image->savePNG(fileName);
}

void Map::saveImage(const std::string& fileName, int minX, int minY, int maxX, int maxY, short z, bool drawLowerFloors)
{
    try {
        // Maximum dimension to prevent integer overflow in memory calculations
        constexpr int MAX_DIMENSION = 10000;

        const int width = maxX - minX + 1;
        const int height = maxY - minY + 1;

        if (width <= 0 || height <= 0) {
            g_logger.error("Invalid map dimensions for saveImage: width={}, height={}", width, height);
            return;
        }

        if (width > MAX_DIMENSION || height > MAX_DIMENSION) {
            g_logger.error("Map dimensions too large for saveImage: width={}, height={} (max={})", width, height, MAX_DIMENSION);
            return;
        }

        const int squareSize = g_gameConfig.getSpriteSize();
        g_logger.info("saveImage: spriteSize={}, sprites loaded={}", squareSize, g_sprites.isLoaded());

        // Check for overflow in image size calculation
        if (width > MAX_DIMENSION / squareSize || height > MAX_DIMENSION / squareSize) {
            g_logger.error("Image size would overflow: {}x{} with square size {}", width, height, squareSize);
            return;
        }

        // Add margin of 1 tile on each side for large sprites (64x64) that extend beyond tile bounds
        const int margin = 1;
        ImagePtr image = std::make_shared<Image>(Size((width + margin * 2) * squareSize, (height + margin * 2) * squareSize));

        int tilesFound = 0;
        int tilesWithItems = 0;
        Position position;

        // Draw lower floors first (if enabled)
        if (drawLowerFloors) {
            // Determine the lowest floor to draw based on target floor
            // For surface (z <= 7): lowestFloor = 7, which means NO lower floors are drawn (loop won't execute)
            // For underground (z > 7): lowestFloor = 15, draw from floor 15 down to current floor+1
            short lowestFloor = (z <= 7) ? 7 : 15;

            // Draw lower floors (floors below current, which have higher Z values in underground)
            for (short floor = lowestFloor; floor > z; floor--) {
                position.z = floor;
                int offset = floor - z;
                
                for (int x = -offset; x <= width; x++) {
                    for (int y = -offset; y <= height; y++) {
                        position.x = minX + x;
                        position.y = minY + y;
                        
                        if (const TilePtr& tile = getTile(position)) {
                            int offX = x + margin + offset;
                            int offY = y + margin + offset;
                            if (offX >= 0 && offX < width + margin * 2 && offY >= 0 && offY < height + margin * 2) {
                                Point dest(offX * squareSize, offY * squareSize);
                                tile->drawToImage(dest, image);
                            }
                        }
                    }
                }
            }

            // Apply shadow to all lower floors
            if (m_lowerFloorsShadowPercent > 0) {
                image->addShadow(static_cast<uint8_t>(100 - m_lowerFloorsShadowPercent));
            }
        }

        // Draw current floor on top (no shadow)
        position.z = z;
        for (int x = 0; x < width; ++x) {
            for (int y = 0; y < height; ++y) {
                position.x = minX + x;
                position.y = minY + y;
                
                const auto& tile = getTile(position);
                if (tile) {
                    tilesFound++;
                    if (!tile->isEmpty()) {
                        tilesWithItems++;
                    }
                    Point dest((x + margin) * squareSize, (y + margin) * squareSize);
                    tile->drawToImage(dest, image);
                }
            }
        }

        g_logger.info("saveImage: found {} tiles, {} have items", tilesFound, tilesWithItems);
        image->savePNG(fileName);
        g_logger.info("Map image saved to {}", fileName);
    } catch (const stdext::exception& e) {
        g_logger.error("Failed to save map image: {}", e.what());
    }
}
#endif
/* vim: set ts=4 sw=4 et: */