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

#pragma once

#include <framework/global.h>
#include "effect.h"
#include "thing.h"

enum ItemAttr : uint8_t
{
    ATTR_END = 0,
    //ATTR_DESCRIPTION = 1,
    //ATTR_EXT_FILE = 2,
    ATTR_TILE_FLAGS = 3,
    ATTR_ACTION_ID = 4,
    ATTR_UNIQUE_ID = 5,
    ATTR_TEXT = 6,
    ATTR_DESC = 7,
    ATTR_TELE_DEST = 8,
    ATTR_ITEM = 9,
    ATTR_DEPOT_ID = 10,
    //ATTR_EXT_SPAWN_FILE = 11,
    ATTR_RUNE_CHARGES = 12,
    //ATTR_EXT_HOUSE_FILE = 13,
    ATTR_HOUSEDOORID = 14,
    ATTR_COUNT = 15,
    ATTR_DURATION = 16,
    ATTR_DECAYING_STATE = 17,
    ATTR_WRITTENDATE = 18,
    ATTR_WRITTENBY = 19,
    ATTR_SLEEPERGUID = 20,
    ATTR_SLEEPSTART = 21,
    ATTR_CHARGES = 22,
    ATTR_CONTAINER_ITEMS = 23,
    ATTR_NAME = 30,
    ATTR_PLURALNAME = 31,
    ATTR_ATTACK = 33,
    ATTR_EXTRAATTACK = 34,
    ATTR_DEFENSE = 35,
    ATTR_EXTRADEFENSE = 36,
    ATTR_ARMOR = 37,
    ATTR_ATTACKSPEED = 38,
    ATTR_HITCHANCE = 39,
    ATTR_SHOOTRANGE = 40,
    ATTR_ARTICLE = 41,
    ATTR_SCRIPTPROTECTED = 42,
    ATTR_DUALWIELD = 43,
    ATTR_ATTRIBUTE_MAP = 128,
    ATTR_LAST
};

// @bindclass
#pragma pack(push,1) // disable memory alignment
class Item : public Thing
{
public:
    static ItemPtr create(int id);

    void draw(const Point& dest, uint32_t flags, const Color& color, LightView* lightView = nullptr);
    void draw(const Point& dest, uint32_t flags, LightView* lightView = nullptr) override {
        draw(dest, flags, Color::white, lightView);
    };

    void setId(uint32_t id) override;

    void setCountOrSubType(int value) { m_countOrSubType = value; updatePatterns(); }
    void setCount(int count) { m_countOrSubType = count; updatePatterns(); }
    void setSubType(int subType) { m_countOrSubType = subType; updatePatterns(); }
    void setColor(const Color& c) { m_color = c; }
    void setPosition(const Position& position, uint8_t stackPos = 0, bool hasElevation = false) override;

    int getCountOrSubType() const { return m_countOrSubType; }
    int getSubType();
    int getCount() { return isStackable() ? m_countOrSubType : 1; }

    bool isValid() { return getThingType() != nullptr; }

    void setAsync(bool enable) { m_async = enable; }

    ItemPtr clone();
    ItemPtr asItem() { return static_self_cast<Item>(); }
    bool isItem() override { return true; }

    void updatePatterns();
    int calculateAnimationPhase();
    int getExactSize(int layer = 0, int xPattern = 0, int yPattern = 0, int zPattern = 0, int animationPhase = 0) override {
        return Thing::getExactSize(layer, m_numPatternX, m_numPatternY, m_numPatternZ, calculateAnimationPhase());
    }

    void onPositionChange(const Position& /*newPos*/, const Position& /*oldPos*/) override { updatePatterns(); }

#ifdef FRAMEWORK_EDITOR
    std::string getName();
    static ItemPtr createFromOtb(int id);
    uint16_t getServerId() { return m_serverId; }
    void setOtbId(uint16_t id);
    void unserializeItem(const BinaryTreePtr& in);
    void serializeItem(const OutputBinaryTreePtr& out);

    void setDepotId(uint16_t depotId) { m_attribs.set(ATTR_DEPOT_ID, depotId); }
    uint16_t getDepotId() { return m_attribs.get<uint16_t>(ATTR_DEPOT_ID, 0); }

    void setDoorId(uint8_t doorId) { m_attribs.set(ATTR_HOUSEDOORID, doorId); }
    uint8_t getDoorId() { return m_attribs.get<uint8_t >(ATTR_HOUSEDOORID, 0); }

    uint16_t getUniqueId() { return m_attribs.get<uint16_t>(ATTR_UNIQUE_ID, 0); }
    uint16_t getActionId() { return m_attribs.get<uint16_t>(ATTR_ACTION_ID, 0); }
    void setActionId(uint16_t actionId) { m_attribs.set(ATTR_ACTION_ID, actionId); }
    void setUniqueId(uint16_t uniqueId) { m_attribs.set(ATTR_UNIQUE_ID, uniqueId); }

    std::string getText() { return m_attribs.get<std::string>(ATTR_TEXT); }
    std::string getDescription() { return m_attribs.get<std::string>(ATTR_DESC); }
    void setDescription(const std::string& desc) { m_attribs.set(ATTR_DESC, desc); }
    void setText(const std::string& txt) { m_attribs.set(ATTR_TEXT, txt); }

    Position getTeleportDestination() { return m_attribs.get<Position>(ATTR_TELE_DEST); }
    void setTeleportDestination(const Position& pos) { m_attribs.set(ATTR_TELE_DEST, pos); }

    bool isHouseDoor() { return m_attribs.has(ATTR_HOUSEDOORID); }
    bool isDepot() { return m_attribs.has(ATTR_DEPOT_ID); }
    bool isContainer() override { return m_attribs.has(ATTR_CONTAINER_ITEMS) || Thing::isContainer(); }
    bool isDoor() { return m_attribs.has(ATTR_HOUSEDOORID); }
    bool isTeleport() { return m_attribs.has(ATTR_TELE_DEST); }

    ItemVector getContainerItems() { return m_containerItems; }
    ItemPtr getContainerItem(int slot) { return m_containerItems[slot]; }
    void addContainerItemIndexed(const ItemPtr& i, int slot) { m_containerItems[slot] = i; }
    void addContainerItem(const ItemPtr& i) { m_containerItems.push_back(i); }
    void removeContainerItem(int slot) { m_containerItems[slot] = nullptr; }
    void clearContainerItems() { m_containerItems.clear(); }
#endif

private:
    void internalDraw(int animationPhase, const Point& dest, const Color& color, bool isMarked, uint32_t flags, LightView* lightView = nullptr);
    void setConductor();

    uint8_t m_countOrSubType{ 0 };

    Color m_color{ Color::white };

    uint8_t m_phase{ 0 };
    ticks_t m_lastPhase{ 0 };

    bool m_async{ true };

#ifdef FRAMEWORK_EDITOR
    uint16_t m_serverId{ 0 };
    stdext::dynamic_storage<ItemAttr> m_attribs;
    ItemVector m_containerItems;
#endif
};

#pragma pack(pop)
