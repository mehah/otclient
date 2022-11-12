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
#include "thingtype.h"
#include "thingtypemanager.h"
#include <framework/luaengine/luaobject.h>
#include <framework/graphics/drawpool.h>
#include <framework/core/clock.h>

 // @bindclass
#pragma pack(push,1) // disable memory alignment
class Thing : public LuaObject
{
public:
    virtual void draw(const Point& /*dest*/, float /*scaleFactor*/, bool /*animate*/, uint32_t flags, TextureType /*textureType*/ = TextureType::NONE, bool isMarked = false, LightView* /*lightView*/ = nullptr) {}

    virtual void setId(uint32_t /*id*/) {}
    virtual void setPosition(const Position& position, uint8_t stackPos = 0, bool hasElevation = false);

    virtual uint32_t getId() { return 0; }

    Position getPosition() { return m_position; }

    const TilePtr& getTile();
    ContainerPtr getParentContainer();

    int getStackPriority();
    int getStackPos();

    virtual bool isItem() { return false; }
    virtual bool isEffect() { return false; }
    virtual bool isMissile() { return false; }
    virtual bool isCreature() { return false; }

    virtual bool isNpc() { return false; }
    virtual bool isMonster() { return false; }
    virtual bool isPlayer() { return false; }
    virtual bool isLocalPlayer() { return false; }
    virtual bool isAnimatedText() { return false; }
    virtual bool isStaticText() { return false; }

    ThingType* getThingType() { return m_thingType; }
    Animator* getAnimator() { return m_thingType->getAnimator(); }
    Animator* getIdleAnimator() { return m_thingType->getIdleAnimator(); }

    virtual Point getDisplacement() { return m_thingType->getDisplacement(); }
    virtual int getDisplacementX() { return m_thingType->getDisplacementX(); }
    virtual int getDisplacementY() { return m_thingType->getDisplacementY(); }
    virtual int getExactSize() { return m_thingType->getExactSize(0, 0, 0, 0, 0); }
    virtual int getExactSize(int layer, int xPattern, int yPattern, int zPattern, int animationPhase) { return m_thingType->getExactSize(layer, xPattern, yPattern, zPattern, animationPhase); }

    virtual Light getLight() { return m_thingType->getLight(); }
    virtual bool hasLight() { return m_thingType->hasLight(); }

    Size getSize() { return m_thingType->getSize(); }

    int getWidth() { return m_thingType->getWidth(); }
    int getHeight() { return m_thingType->getHeight(); }
    int getRealSize() { return m_thingType->getRealSize(); }
    int getLayers() { return m_thingType->getLayers(); }
    int getNumPatternX() { return m_thingType->getNumPatternX(); }
    int getNumPatternY() { return m_thingType->getNumPatternY(); }
    int getNumPatternZ() { return m_thingType->getNumPatternZ(); }
    int getAnimationPhases() { return m_thingType->getAnimationPhases(); }
    int getGroundSpeed() { return m_thingType->getGroundSpeed(); }
    int getMaxTextLength() { return m_thingType->getMaxTextLength(); }
    int getMinimapColor() { return m_thingType->getMinimapColor(); }
    int getLensHelp() { return m_thingType->getLensHelp(); }
    int getClothSlot() { return m_thingType->getClothSlot(); }
    int getElevation() { return m_thingType->getElevation(); }

    virtual bool isContainer() { return m_thingType->isContainer(); }

    bool hasAnimationPhases() { return m_thingType->getAnimationPhases() > 1; }
    bool isGround() { return m_thingType->isGround(); }
    bool isGroundBorder() { return m_thingType->isGroundBorder(); }
    bool isTopGround() { return m_thingType->isTopGround(); }
    bool isTopGroundBorder() { return m_thingType->isTopGroundBorder(); }
    bool isSingleGround() { return m_thingType->isSingleGround(); }
    bool isSingleGroundBorder() { return m_thingType->isSingleGroundBorder(); }
    bool isOnBottom() { return m_thingType->isOnBottom(); }
    bool isOnTop() { return m_thingType->isOnTop(); }
    bool isCommon() { return !isGround() && !isGroundBorder() && !isOnTop() && !isCreature() && !isOnBottom(); }
    bool isStackable() { return m_thingType->isStackable(); }
    bool isForceUse() { return m_thingType->isForceUse(); }
    bool isMultiUse() { return m_thingType->isMultiUse(); }
    bool isWritable() { return m_thingType->isWritable(); }
    bool isChargeable() { return m_thingType->isChargeable(); }
    bool isWritableOnce() { return m_thingType->isWritableOnce(); }
    bool isFluidContainer() { return m_thingType->isFluidContainer(); }
    bool isSplash() { return m_thingType->isSplash(); }
    bool isNotWalkable() { return m_thingType->isNotWalkable(); }
    bool isNotMoveable() { return m_thingType->isNotMoveable(); }
    bool isMoveable() { return !m_thingType->isNotMoveable(); }
    bool blockProjectile() { return m_thingType->blockProjectile(); }
    bool isNotPathable() { return m_thingType->isNotPathable(); }
    bool isPickupable() { return m_thingType->isPickupable(); }
    bool isHangable() { return m_thingType->isHangable(); }
    bool isHookSouth() { return m_thingType->isHookSouth(); }
    bool isHookEast() { return m_thingType->isHookEast(); }
    bool isRotateable() { return m_thingType->isRotateable(); }
    bool isDontHide() { return m_thingType->isDontHide(); }
    bool isTranslucent() { return m_thingType->isTranslucent(); }
    bool hasDisplacement() { return m_thingType->hasDisplacement(); }
    bool hasElevation() { return m_thingType->hasElevation(); }
    bool isLyingCorpse() { return m_thingType->isLyingCorpse(); }
    bool isAnimateAlways() { return m_thingType->isAnimateAlways(); }
    bool hasMiniMapColor() { return m_thingType->hasMiniMapColor(); }
    bool hasLensHelp() { return m_thingType->hasLensHelp(); }
    bool isFullGround() { return m_thingType->isFullGround(); }
    bool isIgnoreLook() { return m_thingType->isIgnoreLook(); }
    bool isCloth() { return m_thingType->isCloth(); }
    bool isMarketable() { return m_thingType->isMarketable(); }
    bool isUsable() { return m_thingType->isUsable(); }
    bool isWrapable() { return m_thingType->isWrapable(); }
    bool isUnwrapable() { return m_thingType->isUnwrapable(); }
    bool isTopEffect() { return m_thingType->isTopEffect(); }
    bool hasAction() { return m_thingType->hasAction(); }
    bool hasWearOut() { return m_thingType->hasWearOut(); }
    bool hasClockExpire() { return m_thingType->hasClockExpire(); }
    bool hasExpire() { return m_thingType->hasExpire(); }
    bool hasExpireStop() { return m_thingType->hasExpireStop(); }
    bool isPodium() { return m_thingType->isPodium(); }
    bool isOpaque() { return m_thingType->isOpaque(); }
    bool isSingleDimension() { return m_thingType->isSingleDimension(); }
    bool isTall(const bool useRealSize = false) { return m_thingType->isTall(useRealSize); }
    uint16_t getClassification() { return m_thingType->getClassification(); }

    void canDraw(bool canDraw) { m_canDraw = canDraw; }
    bool canDraw()  const { return m_canDraw; }

    void destroyBuffer() { m_drawBuffer = nullptr; }

    const MarketData& getMarketData() { return m_thingType->getMarketData(); }

    void setShader(const PainterShaderProgramPtr& shader) { m_shader = shader; }

    virtual void onPositionChange(const Position& /*newPos*/, const Position& /*oldPos*/) {}
    virtual void onAppear() {}
    virtual void onDisappear() {}

    const Color& getMarkedColor() { m_markedColor.setAlpha(0.1f + std::abs(500 - g_clock.millis() % 1000) / 1000.0f); return m_markedColor; }

protected:
    uint8_t m_numPatternX{ 0 };
    uint8_t m_numPatternY{ 0 };
    uint8_t m_numPatternZ{ 0 };

    Position m_position;
    ThingType* m_thingType{ nullptr };
    DrawBufferPtr m_drawBuffer;

    Color m_markedColor{ Color::yellow };

    // Shader
    PainterShaderProgramPtr m_shader;
    std::function<void()> m_shaderAction{ nullptr };

private:
    bool m_canDraw{ true };
};
#pragma pack(pop)
