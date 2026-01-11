/*
 * Copyright (c) 2010-2026 OTClient <https://github.com/edubart/otclient>
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

#include "thingtypemanager.h"

#include <nlohmann/json.hpp>
#include <nlohmann/json_fwd.hpp>

#include "game.h"
#include "spritemanager.h"
#include "thingtype.h"
#include "framework/core/filestream.h"
#include "framework/core/resourcemanager.h"
#include "framework/otml/otmldocument.h"
#include <staticdata.pb.h>

#ifdef FRAMEWORK_EDITOR
#include "itemtype.h"
#include "creatures.h"
#include <framework/core/binarytree.h>
#endif

using json = nlohmann::json;

ThingTypeManager g_things;

void ThingTypeManager::init()
{
    m_nullThingType = std::make_shared<ThingType>();

#ifdef FRAMEWORK_EDITOR
    m_nullItemType = std::make_shared<ItemType>();
    m_itemTypes.resize(1, m_nullItemType);
#endif
}

void ThingTypeManager::terminate()
{
    m_nullThingType = nullptr;

#ifdef FRAMEWORK_EDITOR
    m_itemTypes.clear();
    m_reverseItemTypes.clear();
    m_nullItemType = nullptr;
#endif
}

bool ThingTypeManager::loadDat(const std::string& file, const uint16_t resourceId)
{
    auto resource = AssetResource::Create(resourceId);
    if (!resource->loadDat(file))
        return false;

    // resize vector before inserting if necessary
    if (resourceId >= m_assetResources.size()) {
        const auto newSize = static_cast<size_t>(resourceId) + 1;
        m_assetResources.resize(newSize);
        m_spriteManagers.resize(newSize);
    }

    // insert into resource list
    m_assetResources[resourceId] = std::move(resource);
    m_spriteManagers[resourceId] = std::make_shared<LegacySpriteManager>();

    // notify Lua
    // IMPORTANT: this may require moving so it's called only once
    // or introducing a new method
    g_lua.callGlobalField("g_things", "onLoadDat", file);

    return true;
}

bool ThingTypeManager::loadSpr(const std::string& file, const uint16_t resourceId)
{
    auto sprManager = dynamic_pointer_cast<LegacySpriteManager>(getSpriteManagerById(resourceId));
    if (!sprManager) {
        g_logger.error("Failed to read '{}': Sprite manager not initialized!'", file);
        return false;
    }

    return sprManager->loadSpr(file);
}

bool ThingTypeManager::loadOtml(std::string file, uint16_t resourceId)
{
    try {
        file = g_resources.guessFilePath(file, "otml");

        const auto& doc = OTMLDocument::parse(file);
        for (const auto& node : doc->children()) {
            ThingCategory category;
            if (node->tag() == "creatures")
                category = ThingCategoryCreature;
            else if (node->tag() == "items")
                category = ThingCategoryItem;
            else if (node->tag() == "effects")
                category = ThingCategoryEffect;
            else if (node->tag() == "missiles")
                category = ThingCategoryMissile;
            else {
                throw OTMLException(node, "not a valid thing category");
            }

            for (const auto& node2 : node->children()) {
                const auto id = stdext::safe_cast<uint16_t>(node2->tag());
                const auto& thing = getThingType(id, category, resourceId);
                if (thing->getId() == 0)
                    throw OTMLException(node2, "thing not found, using ");
                thing->unserializeOtml(node2);
            }
        }
        return true;
    } catch (const std::exception& e) {
        g_logger.error("Failed to read dat otml '{}': {}'", file, e.what());
        return false;
    }
}

bool ThingTypeManager::loadAppearances(const std::string& file, uint16_t resourceId)
{
    auto resource = AssetResource::Create(resourceId);
    auto sprManager = resource->loadAppearances(file);
    if (!sprManager) {
        return false;
    }

    // resize vector before inserting if necessary
    if (resourceId >= m_assetResources.size()) {
        const auto newSize = static_cast<size_t>(resourceId) + 1;
        m_assetResources.resize(newSize);
        m_spriteManagers.resize(newSize);
    }

    // insert into resource list
    m_assetResources[resourceId] = std::move(resource);
    m_spriteManagers[resourceId] = std::move(sprManager);

    return true;
}

namespace {
    using RaceBank = google::protobuf::RepeatedPtrField<staticdata::Creature>;

    void loadCreatureBank(RaceList& otcRaceList, const RaceBank& protobufRaceList, bool boss) {
        for (const auto& protobufRace : protobufRaceList) {
            // add race to vector
            RaceType otcRaceType = RaceType();
            otcRaceType.raceId = protobufRace.raceid();
            otcRaceType.name = protobufRace.name();
            otcRaceType.boss = boss;

            const auto& protobufOutfit = protobufRace.outfit();

            ColorOutfit parsedOutfit;
            parsedOutfit.type = static_cast<uint16_t>(protobufOutfit.looktype());
            parsedOutfit.typeEx = static_cast<uint16_t>(protobufOutfit.lookitem());

            if (protobufOutfit.has_colors()) {
                const auto& pbColors = protobufOutfit.colors();
                parsedOutfit.head = static_cast<uint8_t>(pbColors.head());
                parsedOutfit.body = static_cast<uint8_t>(pbColors.body());
                parsedOutfit.legs = static_cast<uint8_t>(pbColors.legs());
                parsedOutfit.feet = static_cast<uint8_t>(pbColors.feet());
                parsedOutfit.applyColors();
            }

            Outfit otcOutfit;
            otcOutfit.applyOutfit(parsedOutfit);
            otcOutfit.setAddons(static_cast<uint8_t>(protobufOutfit.lookaddons()));

            otcRaceType.outfit = otcOutfit;
            otcRaceList.emplace_back(otcRaceType);
        }
    }
}

bool ThingTypeManager::loadStaticData(const std::string& file)
{
    try {
        std::string staticDataFile;

        json document = json::parse(g_resources.readFileContents(g_resources.resolvePath(g_resources.guessFilePath(file + "catalog-content", "json"))));
        for (const auto& obj : document) {
            const auto& type = obj["type"];
            if (type == "staticdata") {
                staticDataFile = obj["file"];
            }
        }

        // load staticdata.dat
        std::stringstream datFileStream;
        g_resources.readFileStream(g_resources.resolvePath(fmt::format("{}{}", file, staticDataFile)), datFileStream);
        auto staticDataLib = staticdata::Staticdata();
        if (!staticDataLib.ParseFromIstream(&datFileStream)) {
            throw stdext::exception("Couldn't parse staticdata lib.");
        }

        // if reload, start again
        m_monsterRaces.clear();

        const auto& raceBank = staticDataLib.monsters();
        const auto& bossBank = staticDataLib.bosses();
        m_monsterRaces.reserve(static_cast<size_t>(raceBank.size()) + bossBank.size());

        // load monsters and bosses
        // note: aside from compatibility with the QT client,
        // there is no need to have monsters and bosses
        // in separate data banks
        loadCreatureBank(m_monsterRaces, raceBank, false);
        loadCreatureBank(m_monsterRaces, bossBank, true);
        return true;
    } catch (const std::exception& e) {
        g_logger.error("Failed to load '{}' (StaticData): {}", file, e.what());
        return false;
    }

    return false;
}

PackInfoResourceList ThingTypeManager::decodePackInfo(const std::string& file)
{
    PackInfoResourceList resourceList;

    try {
        pugi::xml_document doc;
        if (pugi::xml_parse_result result = doc.load_string(
            g_resources.readFileContents(
            g_resources.resolvePath(
            g_resources.guessFilePath(file + "packinfo", "xml")
            )
            ).c_str()
            ); !result) {
            throw Exception("cannot load '{}: '{}'", file, result.description());
        }

        pugi::xml_node root = doc.child("resources");
        if (root.empty())
            throw Exception("malformed packinfo file");

        for (pugi::xml_node node = root.first_child(); node; node = node.next_sibling()) {
            if (node.name() != std::string("resource"))
                throw Exception("invalid resource node");

            AssetResourceInfo res = {};
            res.resourceId = node.attribute("id").as_int();
            res.clientVersionId = node.attribute("version").as_int();
            res.dir = node.attribute("dir").as_string();

            resourceList.push_back(res);
        }

        g_logger.debug("Packinfo read successfully.");
    } catch (const std::exception& e) {
        g_logger.error("Failed to load '{}': {}", file, e.what());
    }

    return resourceList;
}

const ThingTypeList& ThingTypeManager::getThingTypes(const ThingCategory category, uint16_t resourceId)
{
    auto res = getResourceById(resourceId);
    if (!res) {
        throw Exception("invalid resource id {}", resourceId);
    }

    return res->getThingTypes(category);
}

AssetResourcePtr ThingTypeManager::getResourceById(const uint16_t resourceId) const
{
    if (resourceId >= m_assetResources.size())
        return nullptr;

    return m_assetResources[resourceId];
}

SpriteManagerPtr ThingTypeManager::getSpriteManagerById(const uint16_t resourceId) const
{
    if (resourceId >= m_spriteManagers.size())
        return nullptr;

    return m_spriteManagers[resourceId];
}

uint32_t ThingTypeManager::getSprSignature(const uint16_t resourceId) const
{
    auto res = getSpriteManagerById(resourceId);
    return res ? res->getSignature() : 0;
}

uint32_t ThingTypeManager::getDatSignature(const uint16_t resourceId) const
{
    auto res = getResourceById(resourceId);
    return res ? res->getDatSignature() : 0;
}

uint16_t ThingTypeManager::getContentRevision(const uint16_t resourceId) const
{
    auto res = getResourceById(resourceId);
    return res ? res->getContentRevision() : 0;
}

ImagePtr ThingTypeManager::getSpriteImage(int id, uint16_t resourceId, bool& isLoading)
{
    auto res = getSpriteManagerById(resourceId);
    if (!res)
        return nullptr;

    return res->getSpriteImage(id, isLoading);
}

bool ThingTypeManager::isDatLoaded()
{
    // return the state of the first resource encountered
    for (const auto& resource : m_assetResources) {
        if (resource) {
            return m_assetResources.front()->isDatLoaded();
        }
    }

    // no resources allocated
    return false;
}

bool ThingTypeManager::isValidDatId(const uint16_t id, const ThingCategory category, const uint16_t resourceId) const
{
    auto res = getResourceById(resourceId);
    return res ? res->isValidDatId(id, category) : false;
}

void ThingTypeManager::reloadSprites()
{
    for (const auto& sprManager : m_spriteManagers)
        if (sprManager)
            sprManager->reload();
}

bool ThingTypeManager::isSprLoaded(uint16_t resourceId)
{
    auto res = getSpriteManagerById(resourceId);
    if (!res)
        return false;

    return res->isLoaded();
}

bool ThingTypeManager::isUsingProtobuf(uint16_t resourceId)
{
    auto res = getSpriteManagerById(resourceId);
    if (!res)
        return false;

    return res->isProtobuf();
}

const ThingTypePtr& ThingTypeManager::getThingType(const uint16_t id, const ThingCategory category, const uint16_t resourceId) const
{
    auto res = getResourceById(resourceId);
    if (!res) {
        g_logger.error("failed to get raw thing type {} in category {}: resource {} not loaded", id, static_cast<uint8_t>(category), resourceId);
        return getNullThingType();
    }

    return res->getThingType(id, category);
}

ThingType* ThingTypeManager::getRawThingType(uint16_t id, ThingCategory category, uint16_t resourceId) const
{
    auto res = getResourceById(resourceId);
    if (!res) {
        g_logger.error("failed to get raw thing type {} in category {}: resource {} not loaded", id, static_cast<uint8_t>(category), resourceId);
        return nullptr;
    }

    return res->getRawThingType(id, category);
}

ThingTypeList ThingTypeManager::findThingTypeByAttr(const ThingAttr attr, const ThingCategory category)
{
    ThingTypeList ret;

    // read items from all resources
    // (this is for displaying them in market or cyclopedia)
    for (const auto& resource : m_assetResources) {
        if (!resource)
            continue;

        resource->findThingTypesByAttr(attr, category, ret);
    }

    return ret;
}

const RaceType& ThingTypeManager::getRaceData(uint32_t raceId)
{
    for (const auto& raceData : m_monsterRaces) {
        if (raceData.raceId == raceId) {
            return raceData;
        }
    }

    return emptyRaceType;
}

RaceList ThingTypeManager::getRacesByName(const std::string& searchString)
{
    RaceList result;
    for (const auto& race : m_monsterRaces) {
        if (race.name.find(searchString) != std::string::npos) {
            result.push_back(race);
        }
    }
    return result;
}

#ifdef FRAMEWORK_EDITOR
void ThingTypeManager::parseItemType(uint16_t serverId, pugi::xml_node node)
{
    bool s;
    int d;

    if (g_game.getClientVersion() < 960) {
        s = serverId > 20000 && serverId < 20100;
        d = 20000;
    } else {
        s = serverId > 30000 && serverId < 30100;
        d = 30000;
    }

    ItemTypePtr itemType;
    if (s) {
        serverId -= d;
        itemType = std::make_shared<ItemType>();
        itemType->setServerId(serverId);
        addItemType(itemType);
    } else
        itemType = getItemType(serverId);

    itemType->setName(node.attribute("name").as_string());
    for (auto attrib : node.children()) {
        std::string key = attrib.attribute("key").as_string();
        if (key.empty())
            continue;

        stdext::tolower(key);
        if (key == "description")
            itemType->setDesc(attrib.attribute("value").as_string());
        else if (key == "weapontype")
            itemType->setCategory(ItemCategoryWeapon);
        else if (key == "ammotype")
            itemType->setCategory(ItemCategoryAmmunition);
        else if (key == "armor")
            itemType->setCategory(ItemCategoryArmor);
        else if (key == "charges")
            itemType->setCategory(ItemCategoryCharges);
        else if (key == "type") {
            std::string value = attrib.attribute("value").as_string();
            stdext::tolower(value);

            if (value == "key")
                itemType->setCategory(ItemCategoryKey);
            else if (value == "magicfield")
                itemType->setCategory(ItemCategoryMagicField);
            else if (value == "teleport")
                itemType->setCategory(ItemCategoryTeleport);
            else if (value == "door")
                itemType->setCategory(ItemCategoryDoor);
        }
    }
}

void ThingTypeManager::addItemType(const ItemTypePtr& itemType)
{
    const uint16_t id = itemType->getServerId();
    if (unlikely(id >= m_itemTypes.size()))
        m_itemTypes.resize(id + 1, m_nullItemType);
    m_itemTypes[id] = itemType;
}

const ItemTypePtr& ThingTypeManager::findItemTypeByClientId(uint16_t id)
{
    if (id == 0 || id >= m_reverseItemTypes.size())
        return m_nullItemType;

    if (m_reverseItemTypes[id])
        return m_reverseItemTypes[id];
    return m_nullItemType;
}

const ItemTypePtr& ThingTypeManager::findItemTypeByName(const std::string& name)
{
    for (const ItemTypePtr& it : m_itemTypes)
        if (it->getName() == name)
            return it;
    return m_nullItemType;
}

ItemTypeList ThingTypeManager::findItemTypesByName(const std::string& name)
{
    ItemTypeList ret;
    for (const ItemTypePtr& it : m_itemTypes)
        if (it->getName() == name)
            ret.emplace_back(it);
    return ret;
}

ItemTypeList ThingTypeManager::findItemTypesByString(const std::string& name)
{
    ItemTypeList ret;
    for (const ItemTypePtr& it : m_itemTypes)
        if (it->getName().find(name) != std::string::npos)
            ret.emplace_back(it);
    return ret;
}

const ItemTypePtr& ThingTypeManager::getItemType(uint16_t id)
{
    if (id >= m_itemTypes.size() || m_itemTypes[id] == m_nullItemType) {
        g_logger.error("invalid thing type, server id: {}", id);
        return m_nullItemType;
    }
    return m_itemTypes[id];
}

ItemTypeList ThingTypeManager::findItemTypeByCategory(ItemCategory category)
{
    ItemTypeList ret;
    for (const ItemTypePtr& type : m_itemTypes)
        if (type->getCategory() == category)
            ret.emplace_back(type);
    return ret;
}

void ThingTypeManager::saveDat(const std::string& fileName, uint16_t resourceId)
{
    auto res = g_things.getResourceById(resourceId);
    if (!res)
        throw Exception("failed to save, resource not found");

    res->saveDat(fileName);
}

void ThingTypeManager::saveSpr(const std::string& fileName, uint16_t resourceId)
{
    if (auto res = g_things.getSpriteManagerById(resourceId))
        res->saveSpr(fileName);
}

void ThingTypeManager::loadOtb(const std::string& file)
{
    try {
        const auto& fin = g_resources.openFile(file);
        fin->cache();

        uint32_t signature = fin->getU32();
        if (signature != 0)
            throw Exception("invalid otb file");

        const auto& root = fin->getBinaryTree();
        root->skip(1); // otb first byte is always 0

        signature = root->getU32();
        if (signature != 0)
            throw Exception("invalid otb file");

        if (const uint8_t rootAttr = root->getU8(); rootAttr == 0x01) { // OTB_ROOT_ATTR_VERSION
            if (const uint16_t size = root->getU16(); size != 4 + 4 + 4 + 128)
                throw Exception("invalid otb root attr version size");

            m_otbMajorVersion = root->getU32();
            m_otbMinorVersion = root->getU32();
            root->skip(4); // buildNumber
            root->skip(128); // description
        }

        const BinaryTreeVec children = root->getChildren();
        m_reverseItemTypes.clear();
        m_itemTypes.resize(children.size() + 1, m_nullItemType);
        m_reverseItemTypes.resize(children.size() + 1, m_nullItemType);

        for (const auto& node : children) {
            const auto& itemType = std::make_shared<ItemType>();
            itemType->unserialize(node);
            addItemType(itemType);

            const uint16_t clientId = itemType->getClientId();
            if (unlikely(clientId >= m_reverseItemTypes.size()))
                m_reverseItemTypes.resize(clientId + 1);
            m_reverseItemTypes[clientId] = itemType;
        }

        m_otbLoaded = true;
        g_lua.callGlobalField("g_things", "onLoadOtb", file);
    } catch (const std::exception& e) {
        g_logger.error("Failed to load '{}' (OTB file): {}", file, e.what());
    }
}

void ThingTypeManager::loadXml(const std::string& file)
{
    try {
        if (!isOtbLoaded())
            throw Exception("OTB must be loaded before XML");

        pugi::xml_document doc;
        pugi::xml_parse_result result = doc.load_file(file.c_str());
        if (!result)
            throw Exception("failed to parse '{}': '{}'", file, result.description());

        pugi::xml_node root = doc.child("items");
        if (root.empty())
            throw Exception("invalid root tag name");

        for (pugi::xml_node element = root.first_child(); element; element = element.next_sibling()) {
            if (element.name() != std::string("item"))
                continue;

            const auto id = element.attribute("id").as_uint();
            if (id != 0) {
                std::vector<std::string> s_ids = stdext::split(element.attribute("id").as_string(), ";");
                for (const std::string& s : s_ids) {
                    std::vector<int32_t> ids = stdext::split<int32_t>(s, "-");
                    if (ids.size() > 1) {
                        int32_t i = ids[0];
                        while (i <= ids[1])
                            parseItemType(++i, element);
                    } else
                        parseItemType(atoi(s.c_str()), element);
                }
            } else {
                std::vector<int32_t> begin = stdext::split<int32_t>(element.attribute("fromid").as_string(), ";");
                std::vector<int32_t> end = stdext::split<int32_t>(element.attribute("toid").as_string(), ";");
                if (begin[0] && begin.size() == end.size()) {
                    const size_t size = begin.size();
                    for (size_t i = 0; i < size; ++i)
                        while (begin[i] <= end[i])
                            parseItemType(++begin[i], element);
                }
            }
        }

        m_xmlLoaded = true;
        g_logger.debug("items.xml read successfully.");
    } catch (const std::exception& e) {
        g_logger.error("Failed to load '{}' (XML file): {}", file, e.what());
    }
}

#endif

bool AssetResource::loadDat(const std::string& file)
{
    if (m_datLoaded) {
        g_logger.error("Failed to read dat '{}': Resource already loaded!", file);
        return false;
    }

    try {
        auto fin = g_resources.openFile(file);
        fin->cache(true);

        m_datSignature = fin->getU32();
        m_contentRevision = static_cast<uint16_t>(m_datSignature);

        for (auto& thingTypeList : m_thingTypes) {
            const uint16_t count = fin->getU16() + 1;
            thingTypeList.clear();
            thingTypeList.resize(count);
        }

        for (int category = 0; category < ThingLastCategory; ++category) {
            const uint16_t firstId = (category == ThingCategoryItem ? 100 : 1);
            auto& thingList = m_thingTypes[category];

            for (uint16_t id = firstId; id < thingList.size(); ++id) {
                auto type = std::make_shared<ThingType>();
                type->unserialize(id, m_resourceId, static_cast<ThingCategory>(category), fin);
                thingList[id] = std::move(type);
            }
        }

        m_datLoaded = true;
        return true;

    } catch (const stdext::exception& e) {
        g_logger.error("Failed to read dat '{}': {}", file, e.what());
        return false;
    }
}

#ifdef FRAMEWORK_EDITOR
void AssetResource::saveDat(const std::string& file)
{
    try {
        if (!isDatLoaded()) {
            throw Exception("failed to save {}, dat is not loaded", file);
        }

        const auto& fin = g_resources.createFile(file);
        if (!fin)
            throw Exception("failed to open file '{}' for write", file);

        fin->cache();

        fin->addU32(m_datSignature);

        for (const auto& m_thingType : m_thingTypes)
            fin->addU16(m_thingType.size() - 1);

        for (int category = 0; category < ThingLastCategory; ++category) {
            uint16_t firstId = 1;
            if (category == ThingCategoryItem)
                firstId = 100;

            for (uint16_t id = firstId; id < m_thingTypes[category].size(); ++id)
                m_thingTypes[category][id]->serialize(fin);
        }

        fin->flush();
        fin->close();
    } catch (const std::exception& e) {
        g_logger.error("Failed to save '{}': {}", file, e.what());
    }
}
#endif

SpriteManagerPtr AssetResource::loadAppearances(const std::string& file)
{
    if (m_datLoaded) {
        g_logger.error("Failed to read '{}': Resource already loaded!", file);
        return nullptr;
    }

    try {
        int spritesCount = 0;
        std::string appearancesFile;

        json document = json::parse(
            g_resources.readFileContents(
                g_resources.resolvePath(
                    g_resources.guessFilePath(file + "catalog-content", "json")
                )
            )
        );

        auto protoSprites = std::make_shared<ProtobufSpriteManager>();

        for (const auto& obj : document) {
            const auto& type = obj["type"];

            if (type == "appearances") {
                appearancesFile = obj["file"];
            } else if (type == "sprite") {
                int lastSpriteId = obj["lastspriteid"].get<int>();
                auto sheet = std::make_shared<SpriteSheet>(
                    obj["firstspriteid"].get<int>(),
                    lastSpriteId,
                    static_cast<SpriteLayout>(obj["spritetype"].get<int>()),
                    obj["file"].get<std::string>()
                );

                const int maxSpriteId = sheet->firstId + sheet->getSpritesPerSheet() - 1;
                if (lastSpriteId > maxSpriteId) {
                    lastSpriteId = maxSpriteId;
                    sheet->lastId = maxSpriteId;
                }

                protoSprites->addSpriteSheet(sheet);
                spritesCount = std::max(spritesCount, lastSpriteId);
            }
        }

        protoSprites->setSpritesCount(spritesCount + 1);
        protoSprites->setPath(file);

        // load appearances.dat
        std::stringstream fin;
        g_resources.readFileStream(
            g_resources.resolvePath(fmt::format("{}{}", file, appearancesFile)),
            fin
        );

        appearances::Appearances appearancesLib;
        if (!appearancesLib.ParseFromIstream(&fin))
            throw stdext::exception("Couldn't parse appearances lib.");

        auto& nullThing = g_things.getNullThingType();
        for (int category = ThingCategoryItem; category < ThingLastCategory; ++category) {
            const google::protobuf::RepeatedPtrField<appearances::Appearance>* appearances = nullptr;
            switch (category) {
                case ThingCategoryItem: appearances = &appearancesLib.object(); break;
                case ThingCategoryCreature: appearances = &appearancesLib.outfit(); break;
                case ThingCategoryEffect: appearances = &appearancesLib.effect(); break;
                case ThingCategoryMissile: appearances = &appearancesLib.missile(); break;
                default: return nullptr;
            }
            // fix for custom assets, in which the ids are not sorted.
            uint32_t lastAppearanceId = 0;
            for (const auto& appearance : *appearances) {
                if (appearance.id() > lastAppearanceId)
                    lastAppearanceId = appearance.id();
            }
            auto& things = m_thingTypes[category];
            things.clear();
            things.resize(lastAppearanceId + 1, nullThing);
            for (const auto& appearance : *appearances) {
                const auto& type = std::make_shared<ThingType>();
                const uint16_t id = appearance.id();
                type->unserializeAppearance(id, m_resourceId, protoSprites, static_cast<ThingCategory>(category), appearance);
                m_thingTypes[category][id] = type;
            }
        }

        m_datLoaded = true;
        return protoSprites;
    } catch (const std::exception& e) {
        g_logger.error("Failed to load appearances '{}': {}", file, e.what());
        return nullptr;
    }
}

const ThingTypeList& AssetResource::getThingTypes(const ThingCategory category)
{
    if (category < ThingLastCategory)
        return m_thingTypes[category];

    throw Exception("invalid thing type category {}", category);
}

const ThingTypePtr& AssetResource::getThingType(const uint16_t id, const ThingCategory category)
{
    if (category >= ThingLastCategory || id >= m_thingTypes[category].size()) {
        g_logger.error("invalid thing type client id {} in category {}", id, static_cast<uint8_t>(category));
        return g_things.getNullThingType();
    }
    return m_thingTypes[category][id];
}

ThingType* AssetResource::getRawThingType(uint16_t id, ThingCategory category)
{
    if (category >= ThingLastCategory || id >= m_thingTypes[category].size()) {
        g_logger.error("invalid thing type client id {} in category {}", id, static_cast<uint8_t>(category));
        return nullptr;
    }
    return m_thingTypes[category][id].get();
}

void AssetResource::findThingTypesByAttr(ThingAttr attr, ThingCategory category, ThingTypeList& out) const
{
    if (!m_datLoaded || category >= ThingLastCategory)
        return;

    const auto& nullThing = g_things.getNullThingType();

    for (const auto& type : m_thingTypes[category]) {
        if (!type || type == nullThing)
            continue;

        if (type->hasAttr(attr))
            out.emplace_back(type);
    }
}

/* vim: set ts=4 sw=4 et: */