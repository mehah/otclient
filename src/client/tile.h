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

#include "declarations.h"
#include "effect.h"
#include "item.h"
#include "mapview.h"
#include <framework/luaengine/luaobject.h>

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

enum class TileSelectType
{
    NONE, FILTERED, NO_FILTERED
};

class Tile : public LuaObject
{
public:
    Tile(const Position& position);

    void onAddInMapView();
    void draw(const Point& dest, const MapPosInfo& mapRect, float scaleFactor, int flags, bool isCovered, LightView* lightView = nullptr);

    void clean();

    void addWalkingCreature(const CreaturePtr& creature);
    void removeWalkingCreature(const CreaturePtr& creature);

    void addThing(const ThingPtr& thing, int stackPos);
    bool removeThing(ThingPtr thing);
    ThingPtr getThing(int stackPos);
    EffectPtr getEffect(uint16_t id);
    bool hasThing(const ThingPtr& thing);
    int getThingStackPos(const ThingPtr& thing);
    ThingPtr getTopThing();

    ThingPtr getTopLookThing();
    ThingPtr getTopUseThing();
    CreaturePtr getTopCreature(bool checkAround = false);
    ThingPtr getTopMoveThing();
    ThingPtr getTopMultiUseThing();

    int getDrawElevation() { return m_drawElevation; }
    const Position& getPosition() { return m_position; }
    const std::vector<CreaturePtr>& getWalkingCreatures() { return m_walkingCreatures; }
    const std::vector<ThingPtr>& getThings() { return m_things; }
    const std::vector<EffectPtr>& getEffects() { return m_effects; }
    std::vector<CreaturePtr> getCreatures();

    std::vector<ItemPtr> getItems();
    ItemPtr getGround() { return m_ground; }
    int getGroundSpeed();
    uint8_t getMinimapColorByte();
    int getThingCount() { return m_things.size() + m_effects.size(); }

    bool isWalkable(bool ignoreCreatures = false);
    bool isClickable();

    bool isPathable() { return m_countFlag.notPathable == 0; }
    bool isFullGround() { return m_countFlag.fullGround > 0; }
    bool isFullyOpaque() { return m_countFlag.opaque > 0; }
    bool isSingleDimension() { return m_countFlag.notSingleDimension == 0 && m_walkingCreatures.empty(); }
    bool isLookPossible() { return m_countFlag.blockProjectile == 0; }
    bool isEmpty() { return m_things.empty(); }
    bool isDrawable() { return !isEmpty() || !m_walkingCreatures.empty() || !m_effects.empty(); }
    bool hasCreature() { return m_countFlag.hasCreature > 0; }
    bool isTopGround() const { return m_ground && m_ground->isTopGround(); }
    bool isCovered(int8_t firstFloor);
    bool isCompletelyCovered(uint8_t firstFloor, bool resetCache);

    bool hasBlockingCreature();

    bool hasEffect() { return !m_effects.empty(); }
    bool hasGround() { return (m_ground && m_ground->isSingleGround()) || m_countFlag.hasGroundBorder; };
    bool hasTopGround(bool ignoreBorder = false) { return (m_ground && m_ground->isTopGround()) || (!ignoreBorder && m_countFlag.hasTopGroundBorder); }
    bool hasSurface() { return m_countFlag.hasTopItem || !m_effects.empty() || m_countFlag.hasBottomItem || m_countFlag.hasCommonItem || m_countFlag.hasCreature || !m_walkingCreatures.empty() || hasTopGround(); }
    bool hasTopItem() { return m_countFlag.hasTopItem; }

    bool hasDisplacement() { return m_countFlag.hasDisplacement > 0; }
    bool hasLight() { return m_countFlag.hasLight > 0; }
    bool hasTallThings() { return m_countFlag.hasTallThings; }
    bool hasWideThings() { return m_countFlag.hasWideThings; }
    bool hasWall() { return m_countFlag.hasWall; }

    bool mustHookSouth() { return m_countFlag.hasHookSouth > 0; }
    bool mustHookEast() { return m_countFlag.hasHookEast > 0; }

    bool limitsFloorsView(bool isFreeView = false);

    bool canShade(const MapViewPtr& mapView);
    bool canRender(uint32_t& flags, const Position& cameraPosition, AwareRange viewPort, LightView* lightView);
    bool canErase() { return m_walkingCreatures.empty() && m_effects.empty() && isEmpty() && m_flags == 0 && m_minimapColor == 0; }

    bool hasElevation(int elevation = 1) { return m_countFlag.elevation >= elevation; }
    void overwriteMinimapColor(uint8_t color) { m_minimapColor = color; }

    void remFlag(uint32_t flag) { m_flags &= ~flag; }
    void setFlag(uint32_t flag) { m_flags |= flag; }
    void setFlags(uint32_t flags) { m_flags = flags; }
    bool hasFlag(uint32_t flag) { return (m_flags & flag) == flag; }
    uint32_t getFlags() { return m_flags; }

    void setHouseId(uint32_t hid) { m_houseId = hid; }
    uint32_t getHouseId() { return m_houseId; }
    bool isHouseTile() { return m_houseId != 0 && (m_flags & TILESTATE_HOUSE) == TILESTATE_HOUSE; }

    void select(TileSelectType selectType = TileSelectType::NO_FILTERED);
    void unselect();
    bool isSelected() { return m_selectType != TileSelectType::NONE; }

    TilePtr asTile() { return static_self_cast<Tile>(); }

    void analyzeThing(const ThingPtr& thing, bool add);

private:
    struct CountFlag
    {
        int fullGround{ 0 };
        int notWalkable{ 0 };
        int notPathable{ 0 };
        int notSingleDimension{ 0 };
        int blockProjectile{ 0 };
        int hasDisplacement{ 0 };
        int isNotPathable{ 0 };
        int elevation{ 0 };
        int opaque{ 0 };
        int hasLight{ 0 };
        int hasTallThings{ 0 };
        int hasWideThings{ 0 };
        int hasWall{ 0 };
        int hasHookEast{ 0 };
        int hasHookSouth{ 0 };
        int hasCreature{ 0 };
        int hasCommonItem{ 0 };
        int hasTopItem{ 0 };
        int hasBottomItem{ 0 };
        int hasGroundBorder{ 0 };
        int hasTopGroundBorder{ 0 };
        int hasThingWithElevation{ 0 };
        int correctCorpse{ 0 };
    };

    void drawTop(const Point& dest, float scaleFactor, int flags, bool forceDraw, LightView* lightView = nullptr);
    void drawCreature(const Point& dest, const MapPosInfo& mapRect, float scaleFactor, int flags, bool isCovered, bool forceDraw, LightView* lightView = nullptr);
    void drawThing(const ThingPtr& thing, const Point& dest, float scaleFactor, int flags, LightView* lightView);

    bool checkForDetachableThing();
    bool hasThingWithElevation() { return hasElevation() && m_countFlag.hasThingWithElevation > 0; }

    Position m_position;
    Point m_lastDrawDest;

    uint8_t m_drawElevation{ 0 };
    uint8_t m_minimapColor{ 0 };
    uint8_t m_elevation{ 0 };

    int8_t m_lastFloorMin{ -1 };

    std::array<int8_t, MAX_Z + 1> m_completelyCoveredCache;

    uint32_t m_flags{ 0 };
    uint32_t m_houseId{ 0 };

    std::vector<CreaturePtr> m_walkingCreatures;
    std::vector<ThingPtr> m_things;
    std::vector<EffectPtr> m_effects;
    std::vector<TilePtr> m_tilesRedraw;

    ItemPtr m_ground;

    CountFlag m_countFlag;
    ThingPtr m_highlightThing;

    TileSelectType m_selectType{ TileSelectType::NONE };

    bool m_covered{ false };
    bool m_drawTopAndCreature{ true };
};
