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

#ifndef THINGTYPE_H
#define THINGTYPE_H

#include "animator.h"
#include "declarations.h"

#include <framework/core/declarations.h>
#include <framework/graphics/texture.h>
#include <framework/luaengine/luaobject.h>
#include <framework/net/server.h>
#include <framework/otml/declarations.h>

using namespace tibia::protobuf;
using namespace tibia::protobuf::shared;

enum class TextureType {
    NONE,
    SMOOTH,
    ALL_BLANK
};

enum FrameGroupType : uint8 {
    FrameGroupDefault = 0,
    FrameGroupIdle = FrameGroupDefault,
    FrameGroupMoving,
    FrameGroupInitial
};

enum ThingCategory : uint8 {
    ThingCategoryItem = 0,
    ThingCategoryCreature,
    ThingCategoryEffect,
    ThingCategoryMissile,
    ThingInvalidCategory,
    ThingLastCategory = ThingInvalidCategory
};

enum ThingAttr : uint8 {
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

    // additional
    ThingAttrOpacity = 100,
    ThingAttrNotPreWalkable = 101,

    ThingAttrDefaultAction = 251,

    ThingAttrFloorChange = 252,
    ThingAttrNoMoveAnimation = 253, // 10.10: real value is 16, but we need to do this for backwards compatibility
    ThingAttrChargeable = 254, // deprecated
    ThingLastAttr = 255
};

enum SpriteMask {
    SpriteMaskRed = 1,
    SpriteMaskGreen,
    SpriteMaskBlue,
    SpriteMaskYellow
};

struct MarketData {
    std::string name;
    int category;
    uint16 requiredLevel;
    uint16 restrictVocation;
    uint16 showAs;
    uint16 tradeAs;
};

struct Light {
    Light() {}
    Light(uint8_t intensity, uint8_t color) : intensity(intensity), color(color) {}
    uint8 intensity = 0;
    uint8 color = 215;
};

class ThingType : public LuaObject
{
public:
    void unserializeAppearance(uint16 clientId, ThingCategory category, const appearances::Appearance& appearance);
    void unserialize(uint16 clientId, ThingCategory category, const FileStreamPtr& fin);
    void unserializeOtml(const OTMLNodePtr& node);

    void serialize(const FileStreamPtr& fin);
    void exportImage(const std::string& fileName);

    void draw(const Point& dest, float scaleFactor, int layer, int xPattern, int yPattern, int zPattern, int animationPhase, TextureType textureType, Color color = Color::white, LightView* lightView = nullptr);

    uint16 getId() { return m_id; }
    ThingCategory getCategory() { return m_category; }
    bool isNull() { return m_null; }
    bool hasAttr(ThingAttr attr) { return m_attribs.has(attr); }

    Size getSize() { return m_size; }
    int getWidth() { return m_size.width(); }
    int getHeight() { return m_size.height(); }
    int getExactSize(int layer = 0, int xPattern = 0, int yPattern = 0, int zPattern = 0, int animationPhase = 0);
    int getRealSize() { return m_realSize; }
    int getLayers() { return m_layers; }
    int getNumPatternX() { return m_numPatternX; }
    int getNumPatternY() { return m_numPatternY; }
    int getNumPatternZ() { return m_numPatternZ; }
    int getAnimationPhases();
    AnimatorPtr getAnimator() { return m_animator; }
    AnimatorPtr getIdleAnimator() { return m_idleAnimator; }

    Point getDisplacement() { return m_displacement; }
    int getDisplacementX() { return getDisplacement().x; }
    int getDisplacementY() { return getDisplacement().y; }
    int getElevation() { return m_elevation; }

    int getGroundSpeed() { return m_attribs.get<uint16>(ThingAttrGround); }
    int getMaxTextLength() { return m_attribs.has(ThingAttrWritableOnce) ? m_attribs.get<uint16>(ThingAttrWritableOnce) : m_attribs.get<uint16>(ThingAttrWritable); }
    Light getLight() { return m_attribs.get<Light>(ThingAttrLight); }
    int getMinimapColor() { return m_attribs.get<uint16>(ThingAttrMinimapColor); }
    int getLensHelp() { return m_attribs.get<uint16>(ThingAttrLensHelp); }
    int getClothSlot() { return m_attribs.get<uint16>(ThingAttrCloth); }
    MarketData getMarketData() { return m_attribs.get<MarketData>(ThingAttrMarket); }
    bool isGround() { return m_attribs.has(ThingAttrGround); }
    bool isGroundBorder() { return m_attribs.has(ThingAttrGroundBorder); }
    bool isTopGround() { return isGround() && !isSingleDimension(); }
    bool isTopGroundBorder() { return isGroundBorder() && !isSingleDimension(); }
    bool isSingleGround() { return isGround() && isSingleDimension(); }
    bool isSingleGroundBorder() { return isGroundBorder() && isSingleDimension(); }

    bool isOnBottom() { return m_attribs.has(ThingAttrOnBottom); }
    bool isOnTop() { return m_attribs.has(ThingAttrOnTop); }
    bool isContainer() { return m_attribs.has(ThingAttrContainer); }
    bool isStackable() { return m_attribs.has(ThingAttrStackable); }
    bool isForceUse() { return m_attribs.has(ThingAttrForceUse); }
    bool isMultiUse() { return m_attribs.has(ThingAttrMultiUse); }
    bool isWritable() { return m_attribs.has(ThingAttrWritable); }
    bool isChargeable() { return m_attribs.has(ThingAttrChargeable); }
    bool isWritableOnce() { return m_attribs.has(ThingAttrWritableOnce); }
    bool isFluidContainer() { return m_attribs.has(ThingAttrFluidContainer); }
    bool isSplash() { return m_attribs.has(ThingAttrSplash); }
    bool isNotWalkable() { return m_attribs.has(ThingAttrNotWalkable); }
    bool isNotMoveable() { return m_attribs.has(ThingAttrNotMoveable); }
    bool blockProjectile() { return m_attribs.has(ThingAttrBlockProjectile); }
    bool isNotPathable() { return m_attribs.has(ThingAttrNotPathable); }
    bool isPickupable() { return m_attribs.has(ThingAttrPickupable); }
    bool isHangable() { return m_attribs.has(ThingAttrHangable); }
    bool isHookSouth() { return m_attribs.has(ThingAttrHookSouth); }
    bool isHookEast() { return m_attribs.has(ThingAttrHookEast); }
    bool isRotateable() { return m_attribs.has(ThingAttrRotateable); }
    bool hasLight() { return m_attribs.has(ThingAttrLight); }
    bool isDontHide() { return m_attribs.has(ThingAttrDontHide); }
    bool isTranslucent() { return m_attribs.has(ThingAttrTranslucent); }
    bool hasDisplacement() { return m_attribs.has(ThingAttrDisplacement); }
    bool hasElevation() { return m_attribs.has(ThingAttrElevation); }
    bool isLyingCorpse() { return m_attribs.has(ThingAttrLyingCorpse); }
    bool isAnimateAlways() { return m_attribs.has(ThingAttrAnimateAlways); }
    bool hasMiniMapColor() { return m_attribs.has(ThingAttrMinimapColor); }
    bool hasLensHelp() { return m_attribs.has(ThingAttrLensHelp); }
    bool isFullGround() { return m_attribs.has(ThingAttrFullGround); }
    bool isIgnoreLook() { return m_attribs.has(ThingAttrLook); }
    bool isCloth() { return m_attribs.has(ThingAttrCloth); }
    bool isMarketable() { return m_attribs.has(ThingAttrMarket); }
    bool isUsable() { return m_attribs.has(ThingAttrUsable); }
    bool isWrapable() { return m_attribs.has(ThingAttrWrapable); }
    bool isUnwrapable() { return m_attribs.has(ThingAttrUnwrapable); }
    bool isTopEffect() { return m_attribs.has(ThingAttrTopEffect); }
    bool hasAction() { return m_attribs.has(ThingAttrDefaultAction); }
    bool isOpaque() { getTexture(0); return m_opaque; }
    bool isTall(const bool useRealSize = false) { return useRealSize ? getRealSize() > SPRITE_SIZE : getHeight() > 1; }
    uint16_t getClassification() { return m_attribs.get<uint16_t>(ThingAttrUpgradeClassification); }
    bool isSingleDimension() { return m_size.area() == 1; }
    std::vector<int> getSprites() { return m_spritesIndex; }

    // additional
    float getOpacity() { return m_opacity; }
    bool isNotPreWalkable() { return m_attribs.has(ThingAttrNotPreWalkable); }
    void setPathable(bool var);
    int getExactHeight();
    TexturePtr getTexture(int animationPhase, TextureType txtType = TextureType::NONE);

private:
    bool hasTexture() const { return !m_textures.empty(); }

    static Size getBestTextureDimension(int w, int h, int count);
    uint getSpriteIndex(int w, int h, int l, int x, int y, int z, int a);
    uint getTextureIndex(int l, int x, int y, int z);

    ThingCategory m_category{ ThingInvalidCategory };
    uint16 m_id{ 0 };

    bool m_null{ true },
        m_opaque{ false };

    stdext::dynamic_storage<uint8> m_attribs;

    Size m_size;
    Point m_displacement;
    AnimatorPtr m_animator;
    AnimatorPtr m_idleAnimator;
    int m_animationPhases;
    int m_exactSize{ 0 };
    int m_realSize{ 0 };
    int m_numPatternX{ 0 }, m_numPatternY{ 0 }, m_numPatternZ{ 0 };
    int m_layers{ 0 };
    int m_elevation{ 0 };
    int m_exactHeight{ 0 };
    float m_opacity{ 1.f };
    std::string m_customImage;

    std::vector<int> m_spritesIndex;

    std::vector<TexturePtr> m_textures,
        m_blankTextures,
        m_smoothTextures;

    std::vector<std::vector<Rect>> m_texturesFramesRects;
    std::vector<std::vector<Rect>> m_texturesFramesOriginRects;
    std::vector<std::vector<Point>> m_texturesFramesOffsets;
};

#endif
