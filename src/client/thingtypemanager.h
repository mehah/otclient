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

#pragma once

#include "staticdata.h"
#include "spritemanager.h"

using RaceList = std::vector<RaceType>;
static const RaceType emptyRaceType{};

struct AssetResourceInfo
{
    uint16_t resourceId = 0;
    int clientVersionId = 0;
    std::string dir;
};

class ThingTypeManager
{
public:
    ThingTypeManager() = default;
    ~ThingTypeManager() = default;

    // non-copyable
    ThingTypeManager(const ThingTypeManager&) = delete;
    ThingTypeManager& operator=(const ThingTypeManager&) = delete;

    void init();
    void terminate();

    bool loadDat(const std::string& file, const uint16_t resourceId);
    bool loadSpr(const std::string& file, const uint16_t resourceId);
    bool loadOtml(std::string file, uint16_t resourceId);
    bool loadAppearances(const std::string& file, const uint16_t resourceId);
    bool loadStaticData(const std::string& file);
    PackInfoResourceList decodePackInfo(const std::string& file);

#ifdef FRAMEWORK_EDITOR
    void parseItemType(uint16_t id, pugi::xml_node node);
    void loadOtb(const std::string& file);
    void loadXml(const std::string& file);
    void saveDat(const std::string& fileName);
    uint32_t getOtbMajorVersion() { return m_otbMajorVersion; }
    uint32_t getOtbMinorVersion() { return m_otbMinorVersion; }
    bool isXmlLoaded() { return m_xmlLoaded; }
    bool isOtbLoaded() { return m_otbLoaded; }
    bool isValidOtbId(uint16_t id) { return id >= 1 && id < m_itemTypes.size(); }
    const ItemTypeList& getItemTypes() { return m_itemTypes; }
    void addItemType(const ItemTypePtr& itemType);
    const ItemTypePtr& findItemTypeByClientId(uint16_t id);
    const ItemTypePtr& findItemTypeByName(const std::string& name);
    ItemTypeList findItemTypesByName(const std::string& name);
    ItemTypeList findItemTypesByString(const std::string& name);
    const ItemTypePtr& getNullItemType() { return m_nullItemType; }
    const ItemTypePtr& getItemType(uint16_t id);

    ItemTypeList findItemTypeByCategory(ItemCategory category);
#endif

    ThingTypeList findThingTypeByAttr(ThingAttr attr, ThingCategory category);

    const RaceType& getRaceData(uint32_t raceId);
    RaceList getRacesByName(const std::string& searchString);

    const ThingTypePtr& getNullThingType() const { return m_nullThingType; }

    const ThingTypePtr& getThingType(uint16_t id, ThingCategory category, const uint16_t resourceId) const;
    ThingType* getRawThingType(uint16_t id, ThingCategory category, uint16_t resourceId) const;

    const ThingTypeList& getThingTypes(ThingCategory category, uint16_t resourceId = 0);

    AssetResourcePtr getResourceById(const uint16_t resourceId) const;
    SpriteManagerPtr getSpriteManagerById(const uint16_t resourceId) const;
    size_t getResourcesCount() const { return m_assetResources.size(); }
    uint32_t getDatSignature(const uint16_t resourceId = 0) const;
    uint16_t getContentRevision(const uint16_t resourceId = 0) const;

    ImagePtr getSpriteImage(int id, uint16_t resourceId, bool& isLoading);

    bool isDatLoaded();
    bool isValidDatId(const uint16_t id, const ThingCategory category, const uint16_t resourceId) const;

    void reloadSprites();
    bool isSprLoaded(uint16_t resourceId);
    bool isUsingProtobuf(uint16_t resourceId);

private:

    // loaded spr/dat/assets storage
    // resources 0 .. n
    AssetResourceList m_assetResources;

    // loaded sprite managers
    // contains dedicated sprite manager for each loaded resource
    // if assets: uses ProtobufSpriteManager object
    // if spr/dat: uses LegacySpriteManager object
    SpriteManagerList m_spriteManagers;

    ThingTypePtr m_nullThingType;

    // to do: m_resourceId support
    RaceList m_monsterRaces;

#ifdef FRAMEWORK_EDITOR
    ItemTypePtr m_nullItemType;
    ItemTypeList m_reverseItemTypes;
    ItemTypeList m_itemTypes;
    uint32_t m_otbMinorVersion{ 0 };
    uint32_t m_otbMajorVersion{ 0 };
    bool m_xmlLoaded{ false };
    bool m_otbLoaded{ false };
#endif
};

extern ThingTypeManager g_things;

class AssetResource : public std::enable_shared_from_this<AssetResource>
{
public:
    // AssetResource::Create(resourceId)
    static std::shared_ptr<AssetResource> Create(uint16_t resourceId) {
        // Using 'new' here intentionally due to private constructor
        return std::shared_ptr<AssetResource>(new AssetResource(resourceId));
    }

    ~AssetResource() = default;

    // non-copyable
    AssetResource(const AssetResource&) = delete;
    AssetResource& operator=(const AssetResource&) = delete;

    uint16_t getId() const { return m_resourceId; }
    
    uint32_t getDatSignature() const { return m_datSignature; }
    uint16_t getContentRevision() const { return m_contentRevision; }

    const ThingTypeList& getThingTypes(const ThingCategory category);

    const ThingTypePtr& getThingType(uint16_t id, ThingCategory category);
    ThingType* getRawThingType(uint16_t id, ThingCategory category);

    void findThingTypesByAttr(ThingAttr attr, ThingCategory category, ThingTypeList& out) const;

    // spr/dat
    bool loadDat(const std::string& file);
    bool isDatLoaded() const { return m_datLoaded; }
    bool isValidDatId(const uint16_t id, const ThingCategory category) const { return category < ThingLastCategory && id >= 1 && id < m_thingTypes[category].size(); }

    // protobuf assets
    SpriteManagerPtr loadAppearances(const std::string& file);

private:
    explicit AssetResource(uint16_t resourceId) : m_resourceId(resourceId) {}

    ThingTypeList m_thingTypes[ThingLastCategory];

    uint32_t m_datSignature{ 0 };
    uint16_t m_contentRevision{ 0 };
    uint16_t m_clientVersion{ 0 };
    uint16_t m_resourceId{ 0 };

    bool m_datLoaded{ false };

    friend class GarbageCollection;
};
