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

#include "attachableobject.h"
#include "declarations.h"
#include "spritemanager.h"
#include "thingtype.h"
#include "thingtypemanager.h"
#include <framework/core/clock.h>
#include <framework/graphics/drawpool.h>
#include <framework/luaengine/luaobject.h>

// @bindclass
#pragma pack(push,1) // disable memory alignment
class Thing : public AttachableObject
{
public:
    virtual void draw(const Point& /*dest*/, bool /*drawThings*/ = true, const LightViewPtr & = nullptr) {}
    virtual void drawLight(const Point& /*dest*/, const LightViewPtr&) {}

    LuaObjectPtr attachedObjectToLuaObject() override { return asLuaObject(); }
    bool isThing() override { return true; }

    virtual void setId(uint32_t /*id*/) {}
    virtual void setPosition(const Position& position, uint8_t stackPos = 0);

    virtual uint32_t getId() { return m_clientId; }
    uint16_t getClientId() const { return m_clientId; }

    virtual Position getPosition() { return m_position; }
    Position getServerPosition() { return m_position; }

    const TilePtr& getTile();
    ContainerPtr getParentContainer();

    int getStackPos();
    int getStackPriority();

    virtual bool isItem() { return false; }
    virtual bool isEffect() { return false; }
    virtual bool isMissile() { return false; }
    virtual bool isCreature() { return false; }

    virtual bool isNpc() { return false; }
    virtual bool isMonster() { return false; }
    virtual bool isPlayer() { return false; }
    virtual bool isLocalPlayer() { return false; }

    Animator* getAnimator() const { auto t = getThingType(); return t ? t->getAnimator() : nullptr; }
    Animator* getIdleAnimator() const { auto t = getThingType(); return t ? t->getIdleAnimator() : nullptr; }

    virtual Point getDisplacement() const { auto t = getThingType(); return t ? t->getDisplacement() : Point(); }
    virtual int getDisplacementX() const { auto t = getThingType(); return t ? t->getDisplacementX() : 0; }
    virtual int getDisplacementY() const { auto t = getThingType(); return t ? t->getDisplacementY() : 0; }
    virtual int getExactSize(const int layer = 0, const int xPattern = 0, const int yPattern = 0, const int zPattern = 0, const int animationPhase = 0) { auto t = getThingType(); return t ? t->getExactSize(layer, xPattern, yPattern, zPattern, animationPhase) : 0; }

    virtual const Light& getLight() const { 
        auto t = getThingType(); 
        if (t) return t->getLight(); 
        static const Light kEmptyLight; 
        return kEmptyLight; 
    }
    virtual bool hasLight() const { auto t = getThingType(); return t ? t->hasLight() : false; }

    const MarketData& getMarketData() { 
        auto t = getThingType(); 
        if (t) return t->getMarketData(); 
        static const MarketData kEmptyMarketData{};
        return kEmptyMarketData; 
    }
    const std::vector<NPCData>& getNpcSaleData() { 
        auto t = getThingType(); 
        if (t) return t->getNpcSaleData(); 
        static const std::vector<NPCData> kEmptyNpcData; 
        return kEmptyNpcData; 
    }
    int getMeanPrice() { auto t = getThingType(); return t ? t->getMeanPrice() : 0; }
    const Size& getSize() const { 
        auto t = getThingType(); 
        if (t) return t->getSize(); 
        static const Size kEmptySize; 
        return kEmptySize; 
    }

    int getWidth() const { auto t = getThingType(); return t ? t->getWidth() : 0; }
    int getHeight() const { auto t = getThingType(); return t ? t->getHeight() : 0; }
    int getRealSize() const { auto t = getThingType(); return t ? t->getRealSize() : 0; }
    int getLayers() const { auto t = getThingType(); return t ? t->getLayers() : 0; }
    int getNumPatternX()const { auto t = getThingType(); return t ? t->getNumPatternX() : 0; }
    int getNumPatternY()const { auto t = getThingType(); return t ? t->getNumPatternY() : 0; }
    int getNumPatternZ()const { auto t = getThingType(); return t ? t->getNumPatternZ() : 0; }
    int getAnimationPhases()const { auto t = getThingType(); return t ? t->getAnimationPhases() : 0; }
    int getGroundSpeed() const { auto t = getThingType(); return t ? t->getGroundSpeed() : 0; }
    int getMaxTextLength()const { auto t = getThingType(); return t ? t->getMaxTextLength() : 0; }
    int getMinimapColor()const { auto t = getThingType(); return t ? t->getMinimapColor() : 0; }
    int getLensHelp()const { auto t = getThingType(); return t ? t->getLensHelp() : 0; }
    int getElevation() const { auto t = getThingType(); return t ? t->getElevation() : 0; }

    int getClothSlot() { auto t = getThingType(); return t ? t->getClothSlot() : 0; }

    bool blockProjectile() const { auto t = getThingType(); return t ? t->blockProjectile() : false; }

    virtual bool isContainer() { auto t = getThingType(); return t ? t->isContainer() : false; }

    bool isCommon() { return !isGround() && !isGroundBorder() && !isOnTop() && !isCreature() && !isOnBottom(); }

    bool isTopGround() { auto t = getThingType(); return !isCreature() && t && t->isTopGround(); }
    bool isTopGroundBorder() { auto t = getThingType(); return !isCreature() && t && t->isTopGroundBorder(); }
    bool isSingleGround() { auto t = getThingType(); return !isCreature() && t && t->isSingleGround(); }
    bool isSingleGroundBorder() { auto t = getThingType(); return !isCreature() && t && t->isSingleGroundBorder(); }
    bool isGround() { auto t = getThingType(); return !isCreature() && t && t->isGround(); }
    bool isGroundBorder() { auto t = getThingType(); return !isCreature() && t && t->isGroundBorder(); }
    bool isOnBottom() { auto t = getThingType(); return !isCreature() && t && t->isOnBottom(); }
    bool isOnTop() { auto t = getThingType(); return !isCreature() && t && t->isOnTop(); }

    bool isMarketable() { auto t = getThingType(); return t ? t->isMarketable() : false; }
    bool isStackable() { auto t = getThingType(); return t ? t->isStackable() : false; }
    bool isFluidContainer() { auto t = getThingType(); return t ? t->isFluidContainer() : false; }
    bool isForceUse() { auto t = getThingType(); return t ? t->isForceUse() : false; }
    bool isMultiUse() { auto t = getThingType(); return t ? t->isMultiUse() : false; }
    bool isWritable() { auto t = getThingType(); return t ? t->isWritable() : false; }
    bool isChargeable() { auto t = getThingType(); return t ? t->isChargeable() : false; }
    bool isWritableOnce() { auto t = getThingType(); return t ? t->isWritableOnce() : false; }
    bool isSplash() { auto t = getThingType(); return t ? t->isSplash() : false; }
    bool isNotWalkable() { auto t = getThingType(); return t ? t->isNotWalkable() : false; }
    bool isNotMoveable() { auto t = getThingType(); return t ? t->isNotMoveable() : false; }
    bool isMoveable() { auto t = getThingType(); return t ? !t->isNotMoveable() : false; }
    bool isNotPathable() { auto t = getThingType(); return t ? t->isNotPathable() : false; }
    bool isPickupable() { auto t = getThingType(); return t ? t->isPickupable() : false; }
    bool isHangable() { auto t = getThingType(); return t ? t->isHangable() : false; }
    bool isHookSouth() { auto t = getThingType(); return t ? t->isHookSouth() : false; }
    bool isHookEast() { auto t = getThingType(); return t ? t->isHookEast() : false; }
    bool isRotateable() { auto t = getThingType(); return t ? t->isRotateable() : false; }
    bool isDontHide() { auto t = getThingType(); return t ? t->isDontHide() : false; }
    bool isTranslucent() { auto t = getThingType(); return t ? t->isTranslucent() : false; }
    bool isLyingCorpse() { auto t = getThingType(); return t ? t->isLyingCorpse() : false; }
    bool isAnimateAlways() { auto t = getThingType(); return t ? t->isAnimateAlways() : false; }
    bool isFullGround() { auto t = getThingType(); return t ? t->isFullGround() : false; }
    bool isIgnoreLook() { auto t = getThingType(); return t ? t->isIgnoreLook() : false; }
    bool isCloth() { auto t = getThingType(); return t ? t->isCloth() : false; }
    bool isUsable() { auto t = getThingType(); return t ? t->isUsable() : false; }
    bool isWrapable() { auto t = getThingType(); return t ? t->isWrapable() : false; }
    bool isUnwrapable() { auto t = getThingType(); return t ? t->isUnwrapable() : false; }
    bool isTopEffect() { auto t = getThingType(); return t ? t->isTopEffect() : false; }
    bool isPodium() const { auto t = getThingType(); return t ? t->isPodium() : false; }
    bool isOpaque() const { auto t = getThingType(); return t ? t->isOpaque() : false; }
    bool isLoading() const { auto t = getThingType(); return t ? t->isLoading() : false; }
    bool isSingleDimension() const { auto t = getThingType(); return t ? t->isSingleDimension() : false; }
    bool isTall(const bool useRealSize = false) const { auto t = getThingType(); return t ? t->isTall(useRealSize) : false; }

    bool hasMiniMapColor() const { auto t = getThingType(); return t ? t->hasMiniMapColor() : false; }
    bool hasLensHelp() const { auto t = getThingType(); return t ? t->hasLensHelp() : false; }
    bool hasDisplacement() const { auto t = getThingType(); return t ? t->hasDisplacement() : false; }
    bool hasElevation() const { auto t = getThingType(); return t ? t->hasElevation() : false; }
    bool hasAction() const { auto t = getThingType(); return t ? t->hasAction() : false; }
    bool hasWearOut() const { auto t = getThingType(); return t ? t->hasWearOut() : false; }
    bool hasClockExpire() const { auto t = getThingType(); return t ? t->hasClockExpire() : false; }
    bool hasExpire() const { auto t = getThingType(); return t ? t->hasExpire() : false; }
    bool hasExpireStop() const { auto t = getThingType(); return t ? t->hasExpireStop() : false; }
    bool hasAnimationPhases() const { auto t = getThingType(); return t ? t->getAnimationPhases() > 1 : false; }
    bool isDecoKit() const { auto t = getThingType(); return t ? t->isDecoKit() : false; }

    PLAYER_ACTION getDefaultAction() { auto t = getThingType(); return t ? t->getDefaultAction() : static_cast<PLAYER_ACTION>(0); }

    uint16_t getClassification() { auto t = getThingType(); return t ? t->getClassification() : 0; }

    void canDraw(const bool canDraw) { m_canDraw = canDraw; }

    bool canDraw(const Color& color = Color::white) const {
        auto t = getThingType();
        return m_canDraw && m_clientId > 0 && color.aF() > Fw::MIN_ALPHA && t && t->getOpacity() > Fw::MIN_ALPHA;
    }

    void setShader(std::string_view name);
    uint8_t getShaderId() const { return m_shaderId; }
    PainterShaderProgramPtr getShader() const;

    bool hasShader() const { return m_shaderId > 0; }

    virtual void onPositionChange(const Position& /*newPos*/, const Position& /*oldPos*/) {}
    virtual void onAppear() {}
    virtual void onDisappear() {};
    const Color& getMarkedColor() {
        if (m_markedColor == Color::white)
            return Color::white;

        m_markedColor.setAlpha(0.1f + std::abs(500 - g_clock.millis() % 1000) / 1000.0f);
        return m_markedColor;
    }

    bool isMarked() { return m_markedColor != Color::white; }
    void setMarked(const Color& color) { if (m_markedColor != color) m_markedColor = color; }

    const Color& getHighlightColor() {
        if (m_highlightColor == Color::white)
            return Color::white;

        m_highlightColor.setAlpha(0.1f + std::abs(500 - g_clock.millis() % 1000) / 1000.0f);
        return m_highlightColor;
    }

    bool isHighlighted() { return m_highlightColor != Color::white; }
    void setHighlight(const Color& color) { if (m_highlightColor != color) m_highlightColor = color; }

    bool isHided() { return isOwnerHidden(); }

    uint8_t getPatternX()const { return m_numPatternX; }
    uint8_t getPatternY()const { return m_numPatternY; }
    uint8_t getPatternZ()const { return m_numPatternZ; }

    float getScaleFactor() {
        if (m_scale.value == 100)
            return 1.f;

        const auto scale = m_scale.value * (m_scale.speed == 0 ? 1.f : m_scale.timer.ticksElapsed() / static_cast<float>(m_scale.speed));
        return std::min<float>(scale, m_scale.value) / 100.f;
    }

    void setScaleFactor(float v, uint16_t ms = 0) {
        m_scale.value = v * 100;
        m_scale.speed = ms;
        m_scale.timer.restart();
    }

    bool canAnimate() { return m_animate; }
    void setAnimate(bool aniamte) { m_animate = aniamte; }

protected:
    virtual ThingType* getThingType() const = 0;

    void setAttachedEffectDirection(const Otc::Direction dir) const
    {
        if (!hasAttachedEffects()) return;

        for (const auto& effect : m_data->attachedEffects) {
            if (effect->getThingType() && (effect->getThingType()->isCreature() || effect->getThingType()->isMissile()))
                effect->m_direction = dir;
        }
    }

    Color m_markedColor{ Color::white };
    Color m_highlightColor{ Color::white };

    struct
    {
        Timer timer;
        uint16_t speed{ 0 };
        uint16_t value{ 100 };
    } m_scale;

    Position m_position;

    uint16_t m_clientId{ 0 };

    int8_t m_stackPos{ -1 };
    uint8_t m_numPatternX{ 0 };
    uint8_t m_numPatternY{ 0 };
    uint8_t m_numPatternZ{ 0 };

    // Shader
    uint8_t m_shaderId{ 0 };

private:
    void lua_setMarked(const std::string_view color) { setMarked(Color(color)); }
    void lua_setHighlight(const std::string_view color) { setHighlight(Color(color)); }

    bool m_canDraw{ true };
    bool m_animate{ true };

    friend class Client;
    friend class Tile;
};
#pragma pack(pop)
