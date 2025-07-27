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

#include <framework/luaengine/luaobject.h>

#include "attachableobject.h"
#include "declarations.h"
#include "item.h"
#include "mapview.h"
#include "statictext.h"

#ifdef FRAMEWORK_EDITOR
enum tileflags_t : uint32_t
{
    TILESTATE_NONE = 0,
    TILESTATE_PROTECTIONZONE = 1 << 0,
    TILESTATE_TRASHED = 1 << 1,
    TILESTATE_OPTIONALZONE = 1 << 2,
    TILESTATE_NOLOGOUT = 1 << 3,
    TILESTATE_HARDCOREZONE = 1 << 4,
    TILESTATE_REFRESH = 1 << 5,

    // internal usage
    TILESTATE_HOUSE = 1 << 6,
    TILESTATE_TELEPORT = 1 << 17,
    TILESTATE_MAGICFIELD = 1 << 18,
    TILESTATE_MAILBOX = 1 << 19,
    TILESTATE_TRASHHOLDER = 1 << 20,
    TILESTATE_BED = 1 << 21,
    TILESTATE_DEPOT = 1 << 22,
    TILESTATE_TRANSLUECENT_LIGHT = 1 << 23,

    TILESTATE_LAST = 1 << 24
};
#endif

enum class TileSelectType : uint8_t
{
    NONE, FILTERED, NO_FILTERED
};

enum TileThingType : uint32_t
{
    FULL_GROUND = 1 << 0,
    NOT_WALKABLE = 1 << 1,
    NOT_PATHABLE = 1 << 2,
    NOT_SINGLE_DIMENSION = 1 << 3,
    BLOCK_PROJECTTILE = 1 << 4,
    HAS_DISPLACEMENT = 1 << 5,
    IS_NOT_PATHAB = 1 << 6,
    ELEVATION = 1 << 7,
    IS_OPAQUE = 1 << 8,
    HAS_LIGHT = 1 << 9,
    HAS_TALL_THINGS = 1 << 10,
    HAS_WIDE_THINGS = 1 << 11,
    HAS_TALL_THINGS_2 = 1 << 12,
    HAS_WIDE_THINGS_2 = 1 << 13,
    HAS_WALL = 1 << 14,
    HAS_HOOK_EAST = 1 << 15,
    HAS_HOOK_SOUTH = 1 << 16,
    HAS_CREATURE = 1 << 17,
    HAS_COMMON_ITEM = 1 << 18,
    HAS_TOP_ITEM = 1 << 19,
    HAS_BOTTOM_ITEM = 1 << 20,
    HAS_GROUND_BORDER = 1 << 21,
    HAS_TOP_GROUND_BORDER = 1 << 22,
    HAS_THING_WITH_ELEVATION = 1 << 23,
    IGNORE_LOOK = 1 << 24,
    CORRECT_CORPSE = 1 << 25
};

class Tile final : public AttachableObject
{
public:
    Tile(const Position& position);

    LuaObjectPtr attachedObjectToLuaObject() override { return asLuaObject(); }
    bool isTile() override { return true; }

    void onAddInMapView();
    void draw(const Point& dest, int flags, const LightViewPtr& lightView = nullptr);
    void drawLight(const Point& dest, const LightViewPtr& lightView);

    void clean();

    void addWalkingCreature(const CreaturePtr& creature);
    void removeWalkingCreature(const CreaturePtr& creature);

    void addThing(const ThingPtr& thing, int stackPos);
    bool removeThing(ThingPtr thing);
    ThingPtr getThing(int stackPos);
    EffectPtr getEffect(uint16_t id) const;
    bool hasThing(const ThingPtr& thing) { return std::ranges::find(m_things, thing) != m_things.end(); }
    int getThingStackPos(const ThingPtr& thing);
    ThingPtr getTopThing();

    ThingPtr getTopLookThing();
    ThingPtr getTopUseThing();
    CreaturePtr getTopCreature(bool checkAround = false);
    ThingPtr getTopMoveThing();
    ThingPtr getTopMultiUseThing();

    int getDrawElevation() const { return m_drawElevation; }
    const Position& getPosition() { return m_position; }
    const std::vector<CreaturePtr>& getWalkingCreatures() { return m_walkingCreatures; }
    const std::vector<ThingPtr>& getThings() { return m_things; }
    std::vector<CreaturePtr> getCreatures();

    std::vector<ItemPtr> getItems();
    ItemPtr getGround() { const auto& ground = getThing(0); return ground && ground->isGround() ? ground->static_self_cast<Item>() : nullptr; }
    int getGroundSpeed();
    uint8_t getMinimapColorByte();
    int getThingCount() { return m_things.size(); }

    bool isWalkable(bool ignoreCreatures = false);
    bool isClickable();
    bool isPathable() { return (m_thingTypeFlag & NOT_PATHABLE) == 0; }
    bool isFullGround() { return m_thingTypeFlag & FULL_GROUND; }
    bool isFullyOpaque() { return m_thingTypeFlag & IS_OPAQUE; }
    bool isSingleDimension() { return (m_thingTypeFlag & NOT_SINGLE_DIMENSION) == 0 && m_walkingCreatures.empty(); }
    bool isLookPossible() { return (m_thingTypeFlag & BLOCK_PROJECTTILE) == 0; }
    bool isEmpty() { return m_things.empty(); }
    bool isDrawable() { return !isEmpty() || !m_walkingCreatures.empty() || hasEffect() || hasAttachedEffects(); }
    bool isCovered(int8_t firstFloor);
    bool isCompletelyCovered(uint8_t firstFloor, bool resetCache);

    bool hasBlockingCreature() const;

    bool hasEffect() const { return m_effects && !m_effects->empty(); }
    bool hasGround() { return (getGround() && getGround()->isSingleGround()) || m_thingTypeFlag & HAS_GROUND_BORDER; };
    bool hasTopGround(const bool ignoreBorder = false) { return (getGround() && getGround()->isTopGround()) || (!ignoreBorder && m_thingTypeFlag & HAS_TOP_GROUND_BORDER); }

    bool hasCreatures() { return m_thingTypeFlag & HAS_CREATURE; }

    bool hasTopItem() const { return m_thingTypeFlag & HAS_TOP_ITEM; }
    bool hasCommonItem() const { return m_thingTypeFlag & HAS_COMMON_ITEM; }
    bool hasBottomItem() const { return m_thingTypeFlag & HAS_BOTTOM_ITEM; }

    bool hasIgnoreLook() { return m_thingTypeFlag & IGNORE_LOOK; }
    bool hasDisplacement() const { return m_thingTypeFlag & HAS_DISPLACEMENT; }
    bool hasLight() const { return m_thingTypeFlag & HAS_LIGHT; }
    bool hasTallThings() const { return m_thingTypeFlag & HAS_TALL_THINGS; }
    bool hasWideThings() const { return m_thingTypeFlag & HAS_WIDE_THINGS; }
    bool hasTallThings2() const { return m_thingTypeFlag & HAS_TALL_THINGS_2; }
    bool hasWideThings2() const { return m_thingTypeFlag & HAS_WIDE_THINGS_2; }
    bool hasWall() const { return m_thingTypeFlag & HAS_WALL; }

    bool mustHookSouth() const { return m_thingTypeFlag & HAS_HOOK_SOUTH; }
    bool mustHookEast() const { return m_thingTypeFlag & HAS_HOOK_EAST; }

    bool limitsFloorsView(bool isFreeView = false);

    bool canShade() { return isFullyOpaque() || hasTopGround() || isFullGround(); }
    bool canRender(uint32_t& flags, const Position& cameraPosition, AwareRange viewPort);
    bool canErase()
    {
        return !isDrawable() && m_minimapColor == 0
#ifdef FRAMEWORK_EDITOR
            && m_flags == 0
#endif
            ;
    }

    bool hasElevation(const int elevation = 1) { return m_elevation >= elevation; }

#ifdef FRAMEWORK_EDITOR
    void overwriteMinimapColor(uint8_t color) { m_minimapColor = color; }

    void remFlag(uint32_t flag) { m_flags &= ~flag; }
    void setFlag(uint32_t flag) { m_flags |= flag; }
    void setFlags(uint32_t flags) { m_flags = flags; }
    bool hasFlag(uint32_t flag) { return (m_flags & flag) == flag; }
    uint32_t getFlags() { return m_flags; }

    void setHouseId(uint32_t hid) { m_houseId = hid; }
    uint32_t getHouseId() { return m_houseId; }
    bool isHouseTile() { return m_houseId != 0 && hasFlag(TILESTATE_HOUSE); }
#endif

    void select(TileSelectType selectType = TileSelectType::NO_FILTERED);
    void unselect();
    bool isSelected() { return m_selectType != TileSelectType::NONE; }

    TilePtr asTile() { return static_self_cast<Tile>(); }

    bool checkForDetachableThing(TileSelectType selectType = TileSelectType::FILTERED);

    void drawTexts(Point dest);
    void setText(const std::string& text, Color color);
    std::string getText();
    void setTimer(int time, Color color);
    int getTimer();
    void setFill(Color color);
    void resetFill() { m_fill = Color::alpha; }
    bool canShoot(int distance);

private:
    void updateThingStackPos();
    void drawTop(const Point& dest, int flags, bool forceDraw, uint8_t drawElevation);
    void drawCreature(const Point& dest, int flags, bool forceDraw, uint8_t drawElevation, const LightViewPtr& lightView = nullptr);

    void setThingFlag(const ThingPtr& thing);

    void recalculateThingFlag()
    {
        m_thingTypeFlag = 0;
        for (const auto& thing : m_things)
            setThingFlag(thing);
    }

    bool hasThingWithElevation() { return hasElevation() && m_thingTypeFlag & HAS_THING_WITH_ELEVATION; }
    void markHighlightedThing(const Color& color) {
        if (m_highlightThingStackPos > -1 && m_highlightThingStackPos < static_cast<int8_t>(m_things.size())) {
            m_things[m_highlightThingStackPos]->setMarked(color);
        }
    }

    std::vector<CreaturePtr> m_walkingCreatures;
    std::vector<ThingPtr> m_things;

    std::unique_ptr<std::vector<EffectPtr>> m_effects;
    std::unique_ptr<std::vector<TilePtr>> m_tilesRedraw;

    std::unique_ptr<StaticText> m_timerText;
    std::unique_ptr<StaticText> m_text;
    Color m_fill = Color::alpha;
    ticks_t m_timer = 0;

    uint32_t m_isCompletelyCovered{ 0 };
    uint32_t m_isCovered{ 0 };
    uint32_t m_thingTypeFlag{ 0 };

#ifdef FRAMEWORK_EDITOR
    uint32_t m_houseId{ 0 };
    uint32_t m_flags{ 0 };
#endif

    Position m_position;
    Point m_lastDrawDest;

    uint8_t m_drawElevation{ 0 };
    uint8_t m_minimapColor{ 0 };
    uint8_t m_elevation{ 0 };

    int8_t m_highlightThingStackPos = -1;

    TileSelectType m_selectType{ TileSelectType::NONE };

    bool m_drawTopAndCreature{ true };
};
