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

#ifdef FRAMEWORK_EDITOR

#include "game.h"
#include "map.h"
#include "tile.h"

#include <framework/core/application.h>
#include <framework/core/binarytree.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/filestream.h>
#include <framework/core/resourcemanager.h>
#include <framework/ui/uiwidget.h>

#include "houses.h"
#include "towns.h"

void Map::loadOtbm(const std::string& fileName)
{
    try {
        if (!g_things.isOtbLoaded())
            throw Exception("OTB isn't loaded yet to load a map.");

        const FileStreamPtr fin = g_resources.openFile(fileName);
        if (!fin)
            throw Exception("Unable to load map '%s'", fileName);

        fin->cache();

        char identifier[4];
        if (fin->read(identifier, 1, 4) < 4)
            throw Exception("Could not read file identifier");

        if (memcmp(identifier, "OTBM", 4) != 0 && memcmp(identifier, "\0\0\0\0", 4) != 0)
            throw Exception("Invalid file identifier detected: %s", identifier);

        const BinaryTreePtr root = fin->getBinaryTree();
        if (root->getU8())
            throw Exception("could not read root property!");

        const uint32_t headerVersion = root->getU32();
        if (headerVersion > 3)
            throw Exception("Unknown OTBM version detected: %u.", headerVersion);

        setWidth(root->getU16());
        setHeight(root->getU16());

        const uint32_t headerMajorItems = root->getU8();
        if (headerMajorItems > g_things.getOtbMajorVersion()) {
            throw Exception("This map was saved with different OTB version. read %d what it's supposed to be: %d",
                            headerMajorItems, g_things.getOtbMajorVersion());
        }

        root->skip(3);
        const uint32_t headerMinorItems = root->getU32();
        if (headerMinorItems > g_things.getOtbMinorVersion()) {
            g_logger.warning(stdext::format("This map needs an updated OTB. read %d what it's supposed to be: %d or less",
                             headerMinorItems, g_things.getOtbMinorVersion()));
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
                    throw Exception("Invalid attribute '%d'", static_cast<int>(attribute));
            }
        }

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
                        throw Exception("invalid node tile type %d", static_cast<int>(type));

                    HousePtr house = nullptr;
                    uint32_t flags = TILESTATE_NONE;
                    Position pos = basePos + nodeTile->getPoint();

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
                                break;
                            }
                            case OTBM_ATTR_ITEM:
                            {
                                addThing(Item::createFromOtb(nodeTile->getU16()), pos);
                                break;
                            }
                            default:
                            {
                                throw Exception("invalid tile attribute %d at pos %s",
                                                static_cast<int>(tileAttr), stdext::to_string(pos));
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
                            g_logger.warning(stdext::format("Moveable item found in house: %d at pos %s - escaping...", item->getId(), stdext::to_string(pos)));
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
                throw Exception("Unknown map data node %d", static_cast<int>(mapDataType));
        }

        fin->close();
    } catch (const std::exception& e) {
        g_logger.error(stdext::format("Failed to load '%s': %s", fileName, e.what()));
    }
}

void Map::saveOtbm(const std::string& fileName)
{
    try {
        const FileStreamPtr fin = g_resources.createFile(fileName);
        if (!fin)
            throw Exception("failed to open file '%s' for write", fileName);

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
                    for (const auto& it : m_tileBlocks[z]) {
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
        g_logger.error(stdext::format("Failed to save '%s': %s", fileName, e.what()));
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
        g_logger.error(stdext::format("failed to load OTCM map: %s", e.what()));
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
            for (const auto& it : m_tileBlocks[z]) {
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
        g_logger.error(stdext::format("failed to save OTCM map: %s", e.what()));
    }
}

#endif
/* vim: set ts=4 sw=4 et: */