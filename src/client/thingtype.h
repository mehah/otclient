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

#include "animator.h"
#include "declarations.h"
#include "gameconfig.h"

#include <variant>
#include <framework/core/declarations.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/texture.h>
#include <framework/luaengine/luaobject.h>
#include <framework/net/server.h>
#include <framework/otml/declarations.h>

using namespace otclient::protobuf;

enum FrameGroupType : uint8_t
{
    FrameGroupDefault = 0,
    FrameGroupIdle = FrameGroupDefault,
    FrameGroupMoving,
    FrameGroupInitial
};

enum ThingCategory : uint8_t
{
    ThingCategoryItem = 0,
    ThingCategoryCreature,
    ThingCategoryEffect,
    ThingCategoryMissile,
    ThingInvalidCategory,
    ThingExternalTexture,
    ThingLastCategory = ThingInvalidCategory,
};

enum ThingAttr : uint8_t
{
    ThingAttrGround = 0,
    ThingAttrGroundBorder = 1,
    ThingAttrOnBottom = 2,
    ThingAttrOnTop = 3,
    ThingAttrContainer = 4,
    ThingAttrStackable = 5,
    ThingAttrForceUse = 6,
    ThingAttrMultiUse = 7,
    ThingAttrWritable = 8,
    ThingAttrWritableOnce = 9,
    ThingAttrFluidContainer = 10,
    ThingAttrSplash = 11,
    ThingAttrNotWalkable = 12,
    ThingAttrNotMoveable = 13,
    ThingAttrBlockProjectile = 14,
    ThingAttrNotPathable = 15,
    ThingAttrPickupable = 16,
    ThingAttrHangable = 17,
    ThingAttrHookSouth = 18,
    ThingAttrHookEast = 19,
    ThingAttrRotateable = 20,
    ThingAttrLight = 21,
    ThingAttrDontHide = 22,
    ThingAttrTranslucent = 23,
    ThingAttrDisplacement = 24,
    ThingAttrElevation = 25,
    ThingAttrLyingCorpse = 26,
    ThingAttrAnimateAlways = 27,
    ThingAttrMinimapColor = 28,
    ThingAttrLensHelp = 29,
    ThingAttrFullGround = 30,
    ThingAttrLook = 31,
    ThingAttrCloth = 32,
    ThingAttrMarket = 33,
    ThingAttrUsable = 34,
    ThingAttrWrapable = 35,
    ThingAttrUnwrapable = 36,
    ThingAttrTopEffect = 37,
    ThingAttrUpgradeClassification = 38,
    ThingAttrWearOut = 39,
    ThingAttrClockExpire = 40,
    ThingAttrExpire = 41,
    ThingAttrExpireStop = 42,
    ThingAttrPodium = 43,

    // additional
    ThingAttrOpacity = 100,

    ThingAttrDefaultAction = 251,

    ThingAttrFloorChange = 252,
    ThingAttrNoMoveAnimation = 253, // 10.10: real value is 16, but we need to do this for backwards compatibility
    ThingAttrChargeable = 254, // deprecated
    ThingLastAttr = 255
};

enum ThingFlagAttr :uint64_t
{
    ThingFlagAttrNone = 0,
    ThingFlagAttrGround = 1 << 0,
    ThingFlagAttrGroundBorder = 1 << 1,
    ThingFlagAttrOnBottom = 1 << 2,
    ThingFlagAttrOnTop = 1 << 3,
    ThingFlagAttrContainer = 1 << 4,
    ThingFlagAttrStackable = 1 << 5,
    ThingFlagAttrForceUse = 1 << 6,
    ThingFlagAttrMultiUse = 1 << 7,
    ThingFlagAttrWritable = 1 << 8,
    ThingFlagAttrChargeable = 1 << 9,
    ThingFlagAttrWritableOnce = 1 << 10,
    ThingFlagAttrFluidContainer = 1 << 11,
    ThingFlagAttrSplash = 1 << 12,
    ThingFlagAttrNotWalkable = 1 << 13,
    ThingFlagAttrNotMoveable = 1 << 14,
    ThingFlagAttrBlockProjectile = 1 << 15,
    ThingFlagAttrNotPathable = 1 << 16,
    ThingFlagAttrPickupable = 1 << 17,
    ThingFlagAttrHangable = 1 << 18,
    ThingFlagAttrHookSouth = 1 << 19,
    ThingFlagAttrHookEast = 1 << 20,
    ThingFlagAttrRotateable = 1 << 21,
    ThingFlagAttrLight = 1 << 22,
    ThingFlagAttrDontHide = 1 << 23,
    ThingFlagAttrTranslucent = 1 << 24,
    ThingFlagAttrDisplacement = 1 << 25,
    ThingFlagAttrElevation = 1 << 26,
    ThingFlagAttrLyingCorpse = 1 << 27,
    ThingFlagAttrAnimateAlways = 1 << 28,
    ThingFlagAttrMinimapColor = 1 << 29,
    ThingFlagAttrLensHelp = 1 << 30,
    ThingFlagAttrFullGround = static_cast<uint64_t>(1) << 31,
    ThingFlagAttrLook = static_cast<uint64_t>(1) << 32,
    ThingFlagAttrCloth = static_cast<uint64_t>(1) << 33,
    ThingFlagAttrMarket = static_cast<uint64_t>(1) << 34,
    ThingFlagAttrUsable = static_cast<uint64_t>(1) << 35,
    ThingFlagAttrWrapable = static_cast<uint64_t>(1) << 36,
    ThingFlagAttrUnwrapable = static_cast<uint64_t>(1) << 37,
    ThingFlagAttrWearOut = static_cast<uint64_t>(1) << 38,
    ThingFlagAttrClockExpire = static_cast<uint64_t>(1) << 39,
    ThingFlagAttrExpire = static_cast<uint64_t>(1) << 40,
    ThingFlagAttrExpireStop = static_cast<uint64_t>(1) << 41,
    ThingFlagAttrPodium = static_cast<uint64_t>(1) << 42,
    ThingFlagAttrTopEffect = static_cast<uint64_t>(1) << 43,
    ThingFlagAttrDefaultAction = static_cast<uint64_t>(1) << 44
};

enum STACK_PRIORITY : uint8_t
{
    GROUND = 0,
    GROUND_BORDER = 1,
    ON_BOTTOM = 2,
    ON_TOP = 3,
    CREATURE = 4,
    COMMON_ITEMS = 5
};

enum PLAYER_ACTION : uint8_t
{
    PLAYER_ACTION_NONE = 0,
    PLAYER_ACTION_LOOK = 1,
    PLAYER_ACTION_USE = 2,
    PLAYER_ACTION_OPEN = 3,
    PLAYER_ACTION_AUTOWALK_HIGHLIGHT = 4
};

enum ITEM_CATEGORY : uint8_t
{
    ITEM_CATEGORY_ARMORS = 1,
    ITEM_CATEGORY_AMULETS = 2,
    ITEM_CATEGORY_BOOTS = 3,
    ITEM_CATEGORY_CONTAINERS = 4,
    ITEM_CATEGORY_DECORATION = 5,
    ITEM_CATEGORY_FOOD = 6,
    ITEM_CATEGORY_HELMETS_HATS = 7,
    ITEM_CATEGORY_LEGS = 8,
    ITEM_CATEGORY_OTHERS = 9,
    ITEM_CATEGORY_POTIONS = 10,
    ITEM_CATEGORY_RINGS = 11,
    ITEM_CATEGORY_RUNES = 12,
    ITEM_CATEGORY_SHIELDS = 13,
    ITEM_CATEGORY_TOOLS = 14,
    ITEM_CATEGORY_VALUABLES = 15,
    ITEM_CATEGORY_AMMUNITION = 16,
    ITEM_CATEGORY_AXES = 17,
    ITEM_CATEGORY_CLUBS = 18,
    ITEM_CATEGORY_DISTANCE_WEAPONS = 19,
    ITEM_CATEGORY_SWORDS = 20,
    ITEM_CATEGORY_WANDS_RODS = 21,
    ITEM_CATEGORY_PREMIUM_SCROLLS = 22,
    ITEM_CATEGORY_TIBIA_COINS = 23,
    ITEM_CATEGORY_CREATURE_PRODUCTS = 24
};

enum SpriteMask :uint8_t
{
    SpriteMaskRed = 1,
    SpriteMaskGreen,
    SpriteMaskBlue,
    SpriteMaskYellow
};

struct Imbuement
{
    uint32_t id;
    std::string name;
    std::string description;
    std::string group;
    uint16_t imageId;
    uint32_t duration;
    bool premiumOnly;
    std::vector<std::pair<ItemPtr, std::string>> sources;
    uint32_t cost;
    uint8_t successRate;
    uint32_t protectionCost;
};

struct MarketData
{
    std::string name;
    ITEM_CATEGORY category;
    uint16_t requiredLevel;
    uint16_t restrictVocation;
    uint16_t showAs;
    uint16_t tradeAs;
};

struct MarketOffer
{
    uint32_t timestamp = 0;
    uint16_t counter = 0;
    uint8_t action = 0;
    uint16_t itemId = 0;
    uint16_t amount = 0;
    uint64_t price = 0;
    std::string playerName;
    uint8_t state = 0;
    uint16_t var = 0;
};

struct Light
{
    Light() = default;
    Light(uint8_t intensity, uint8_t color) : intensity(intensity), color(color) {}
    uint8_t intensity = 0;
    uint8_t color = 215;
};

class ThingType : public LuaObject
{
public:
    void unserializeAppearance(uint16_t clientId, ThingCategory category, const appearances::Appearance& appearance);
    void unserialize(uint16_t clientId, ThingCategory category, const FileStreamPtr& fin);
    void unserializeOtml(const OTMLNodePtr& node);

#ifdef FRAMEWORK_EDITOR
    void serialize(const FileStreamPtr& fin);
    void exportImage(const std::string& fileName);
#endif

    void draw(const Point& dest, int layer, int xPattern, int yPattern, int zPattern, int animationPhase, uint32_t flags, const Color& color, LightView* lightView = nullptr, const DrawConductor& conductor = DEFAULT_DRAW_CONDUCTOR);

    uint16_t getId() { return m_id; }
    ThingCategory getCategory() { return m_category; }
    bool isNull() { return m_null; }
    bool hasAttr(ThingAttr attr) { return (m_flags & thingAttrToThingFlagAttr(attr)); }

    int getWidth() { return m_size.width(); }
    int getHeight() { return m_size.height(); }
    int getExactSize(int layer = 0, int xPattern = 0, int yPattern = 0, int zPattern = 0, int animationPhase = 0);
    int getRealSize() { return m_realSize; }
    int getLayers() { return m_layers; }
    int getNumPatternX() { return m_numPatternX; }
    int getNumPatternY() { return m_numPatternY; }
    int getNumPatternZ() { return m_numPatternZ; }
    int getAnimationPhases() { return m_animator ? m_animator->getAnimationPhases() : m_animationPhases; }
    Animator* getAnimator() const { return m_animator; }
    Animator* getIdleAnimator() const { return m_idleAnimator; }

    const Size& getSize() { return m_size; }
    const Point& getDisplacement() { return m_displacement; }
    const Light& getLight() { return m_light; }
    const MarketData& getMarketData() { return m_market; }

    int getDisplacementX() { return getDisplacement().x; }
    int getDisplacementY() { return getDisplacement().y; }
    int getElevation() { return m_elevation; }

    uint16_t getGroundSpeed() { return m_groundSpeed; }
    int getMaxTextLength() { return m_maxTextLength; }

    int getMinimapColor() { return m_minimapColor; }
    int getLensHelp() { return m_lensHelp; }
    int getClothSlot() { return m_clothSlot; }

    bool isTopGround() { return isGround() && !isSingleDimension(); }
    bool isTopGroundBorder() { return isGroundBorder() && !isSingleDimension(); }
    bool isSingleGround() { return isGround() && isSingleDimension(); }
    bool isSingleGroundBorder() { return isGroundBorder() && isSingleDimension(); }
    bool isTall(const bool useRealSize = false);
    bool isSingleDimension() { return m_size.area() == 1; }

    bool isGround() { return (m_flags & ThingFlagAttrGround); }
    bool isGroundBorder() { return (m_flags & ThingFlagAttrGroundBorder); }
    bool isOnBottom() { return (m_flags & ThingFlagAttrOnBottom); }
    bool isOnTop() { return (m_flags & ThingFlagAttrOnTop); }
    bool isContainer() { return (m_flags & ThingFlagAttrContainer); }
    bool isStackable() { return (m_flags & ThingFlagAttrStackable); }
    bool isForceUse() { return (m_flags & ThingFlagAttrForceUse); }
    bool isMultiUse() { return (m_flags & ThingFlagAttrMultiUse); }
    bool isWritable() { return (m_flags & ThingFlagAttrWritable); }
    bool isChargeable() { return (m_flags & ThingFlagAttrChargeable); }
    bool isWritableOnce() { return (m_flags & ThingFlagAttrWritableOnce); }
    bool isFluidContainer() { return (m_flags & ThingFlagAttrFluidContainer); }
    bool isSplash() { return (m_flags & ThingFlagAttrSplash); }
    bool isNotWalkable() { return (m_flags & ThingFlagAttrNotWalkable); }
    bool isNotMoveable() { return (m_flags & ThingFlagAttrNotMoveable); }
    bool blockProjectile() { return (m_flags & ThingFlagAttrBlockProjectile); }
    bool isNotPathable() { return (m_flags & ThingFlagAttrNotPathable); }
    bool isPickupable() { return (m_flags & ThingFlagAttrPickupable); }
    bool isHangable() { return (m_flags & ThingFlagAttrHangable); }
    bool isHookSouth() { return (m_flags & ThingFlagAttrHookSouth); }
    bool isHookEast() { return (m_flags & ThingFlagAttrHookEast); }
    bool isRotateable() { return (m_flags & ThingFlagAttrRotateable); }
    bool hasLight() { return (m_flags & ThingFlagAttrLight); }
    bool isDontHide() { return (m_flags & ThingFlagAttrDontHide); }
    bool isTranslucent() { return (m_flags & ThingFlagAttrTranslucent); }
    bool hasDisplacement() { return (m_flags & ThingFlagAttrDisplacement); }
    bool hasElevation() { return (m_flags & ThingFlagAttrElevation); }
    bool isLyingCorpse() { return (m_flags & ThingFlagAttrLyingCorpse); }
    bool isAnimateAlways() { return (m_flags & ThingFlagAttrAnimateAlways); }
    bool hasMiniMapColor() { return (m_flags & ThingFlagAttrMinimapColor); }
    bool hasLensHelp() { return (m_flags & ThingFlagAttrLensHelp); }
    bool isFullGround() { return (m_flags & ThingFlagAttrFullGround); }
    bool isIgnoreLook() { return (m_flags & ThingFlagAttrLook); }
    bool isCloth() { return (m_flags & ThingFlagAttrCloth); }
    bool isMarketable() { return (m_flags & ThingFlagAttrMarket); }
    bool isUsable() { return (m_flags & ThingFlagAttrUsable); }
    bool isWrapable() { return (m_flags & ThingFlagAttrWrapable); }
    bool isUnwrapable() { return (m_flags & ThingFlagAttrUnwrapable); }
    bool hasWearOut() { return (m_flags & ThingFlagAttrWearOut); }
    bool hasClockExpire() { return (m_flags & ThingFlagAttrClockExpire); }
    bool hasExpire() { return (m_flags & ThingFlagAttrExpire); }
    bool hasExpireStop() { return (m_flags & ThingFlagAttrExpireStop); }
    bool isPodium() { return (m_flags & ThingFlagAttrPodium); }
    bool isTopEffect() { return (m_flags & ThingFlagAttrTopEffect); }
    bool hasAction() { return (m_flags & ThingFlagAttrDefaultAction); }
    bool isOpaque() { if (m_opaque == -1) getTexture(0); return m_opaque == 1; }

    bool isItem() const { return m_category == ThingCategoryItem; }
    bool isEffect() const { return m_category == ThingCategoryEffect; }
    bool isMissile() const { return m_category == ThingCategoryMissile; }
    bool isCreature() const { return m_category == ThingCategoryCreature; }

    bool hasTexture() const { return !m_textureData.empty() && m_textureData[0].source != nullptr; }
    const Timer getLastTimeUsage() const { return m_lastTimeUsage; }

    void unload() {
        m_textureData.clear();
        m_textureData.resize(m_animationPhases);
    }

    PLAYER_ACTION getDefaultAction() { return m_defaultAction; }

    uint16_t getClassification() { return m_upgradeClassification; }
    std::vector<uint32_t> getSprites() { return m_spritesIndex; }

    // additional
    float getOpacity() { return m_opacity; }
    void setPathable(bool var);
    int getExactHeight();
    TexturePtr getTexture(int animationPhase);

private:
    static ThingFlagAttr thingAttrToThingFlagAttr(ThingAttr attr);
    static Size getBestTextureDimension(int w, int h, int count);

    void loadTexture(int animationPhase);

    struct TextureData
    {
        struct Pos
        {
            Rect rects;
            Rect originRects;
            Point offsets;
        };

        TexturePtr source;
        std::vector<Pos> pos;
    };

    void prepareTextureLoad(const std::vector<Size>& sizes, const std::vector<int>& total_sprites);

    uint32_t getSpriteIndex(int w, int h, int l, int x, int y, int z, int a) const;
    uint32_t getTextureIndex(int l, int x, int y, int z) const;

    ThingCategory m_category{ ThingInvalidCategory };

    bool m_null{ true };
    int8_t m_opaque{ -1 };

    Size m_size;
    Point m_displacement;

    Animator* m_animator{ nullptr };
    Animator* m_idleAnimator{ nullptr };

    uint8_t m_animationPhases{ 0 };
    uint8_t m_realSize{ 0 };
    uint8_t m_numPatternX{ 0 };
    uint8_t m_numPatternY{ 0 };
    uint8_t m_numPatternZ{ 0 };
    uint8_t m_layers{ 0 };
    uint8_t m_exactHeight{ 0 };
    uint8_t m_minimapColor{ 0 };
    uint8_t m_clothSlot{ 0 };
    uint8_t m_lensHelp{ 0 };
    uint8_t m_elevation{ 0 };

    PLAYER_ACTION m_defaultAction{ 0 };

    uint16_t m_id{ 0 };
    uint16_t m_groundSpeed{ 0 };
    uint16_t m_maxTextLength{ 0 };
    uint16_t m_upgradeClassification{ 0 };

    uint64_t m_flags{ 0 };

    MarketData m_market;
    Light m_light;

    float m_opacity{ 1.f };

    std::string m_customImage;

    std::vector<uint32_t> m_spritesIndex;
    std::vector<TextureData> m_textureData;

    std::atomic_bool m_loading;

    Timer m_lastTimeUsage;
};
