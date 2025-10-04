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

    virtual bool isItem() const { return false; }
    virtual bool isEffect() const { return false; }
    virtual bool isMissile() const { return false; }
    virtual bool isCreature() const { return false; }

    virtual bool isNpc() const { return false; }
    virtual bool isMonster() const { return false; }
    virtual bool isPlayer() const { return false; }
    virtual bool isLocalPlayer() const { return false; }

    Animator* getAnimator() const {
        if (const auto t = getThingType(); t)
            return t->getAnimator();
        return nullptr;
    }
    Animator* getIdleAnimator() const {
        if (const auto t = getThingType(); t)
            return t->getIdleAnimator();
        return nullptr;
    }

    virtual Point getDisplacement() const {
        if (const auto t = getThingType(); t)
            return t->getDisplacement();
        return Point();
    }
    virtual int getDisplacementX() const {
        if (const auto t = getThingType(); t)
            return t->getDisplacementX();
        return 0;
    }
    virtual int getDisplacementY() const {
        if (const auto t = getThingType(); t)
            return t->getDisplacementY();
        return 0;
    }
    virtual int getExactSize(const int layer = 0, const int xPattern = 0, const int yPattern = 0, const int zPattern = 0, const int animationPhase = 0) {
        if (const auto t = getThingType(); t)
            return t->getExactSize(layer, xPattern, yPattern, zPattern, animationPhase);
        return 0;
    }

    virtual const Light& getLight() const {
        if (const auto t = getThingType(); t)
            return t->getLight();
        static const Light kEmptyLight;
        return kEmptyLight;
    }
    virtual bool hasLight() const {
        if (const auto t = getThingType(); t)
            return t->hasLight();
        return false;
    }

    const MarketData& getMarketData() const {
        if (const auto t = getThingType(); t)
            return t->getMarketData();
        static const MarketData kEmptyMarketData{};
        return kEmptyMarketData;
    }
    const std::vector<NPCData>& getNpcSaleData() const {
        if (const auto t = getThingType(); t)
            return t->getNpcSaleData();
        static const std::vector<NPCData> kEmptyNpcData;
        return kEmptyNpcData;
    }
    int getMeanPrice() const {
        if (const auto t = getThingType(); t)
            return t->getMeanPrice();
        return 0;
    }
    const Size& getSize() const {
        if (const auto t = getThingType(); t)
            return t->getSize();
        static const Size kEmptySize;
        return kEmptySize;
    }
    int getWidth() const {
        if (const auto t = getThingType(); t)
            return t->getWidth();
        return 0;
    }
    int getHeight() const {
        if (const auto t = getThingType(); t)
            return t->getHeight();
        return 0;
    }
    int getRealSize() const {
        if (const auto t = getThingType(); t)
            return t->getRealSize();
        return 0;
    }
    int getLayers() const {
        if (const auto t = getThingType(); t)
            return t->getLayers();
        return 0;
    }
    int getNumPatternX() const {
        if (const auto t = getThingType(); t)
            return t->getNumPatternX();
        return 0;
    }
    int getNumPatternY() const {
        if (const auto t = getThingType(); t)
            return t->getNumPatternY();
        return 0;
    }
    int getNumPatternZ() const {
        if (const auto t = getThingType(); t)
            return t->getNumPatternZ();
        return 0;
    }
    int getAnimationPhases() const {
        if (const auto t = getThingType(); t)
            return t->getAnimationPhases();
        return 0;
    }
    int getGroundSpeed() const {
        if (const auto t = getThingType(); t)
            return t->getGroundSpeed();
        return 0;
    }
    int getMaxTextLength() const {
        if (const auto t = getThingType(); t)
            return t->getMaxTextLength();
        return 0;
    }
    int getMinimapColor() const {
        if (const auto t = getThingType(); t)
            return t->getMinimapColor();
        return 0;
    }
    int getLensHelp() const {
        if (const auto t = getThingType(); t)
            return t->getLensHelp();
        return 0;
    }
    int getElevation() const {
        if (const auto t = getThingType(); t)
            return t->getElevation();
        return 0;
    }

    int getClothSlot() const {
        if (const auto t = getThingType(); t)
            return t->getClothSlot();
        return 0;
    }

    bool blockProjectile() const {
        if (const auto t = getThingType(); t)
            return t->blockProjectile();
        return false;
    }

    virtual bool isContainer() const {
        if (const auto t = getThingType(); t)
            return t->isContainer();
        return false;
    }

    bool isCommon() const { return !isGround() && !isGroundBorder() && !isOnTop() && !isCreature() && !isOnBottom(); }

    bool isTopGround() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isTopGround();
        return false;
    }
    bool isTopGroundBorder() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isTopGroundBorder();
        return false;
    }
    bool isSingleGround() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isSingleGround();
        return false;
    }
    bool isSingleGroundBorder() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isSingleGroundBorder();
        return false;
    }
    bool isGround() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isGround();
        return false;
    }
    bool isGroundBorder() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isGroundBorder();
        return false;
    }
    bool isOnBottom() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isOnBottom();
        return false;
    }
    bool isOnTop() const {
        if (const auto t = getThingType(); !isCreature() && t)
            return t->isOnTop();
        return false;
    }

    bool isMarketable() const {
        if (const auto t = getThingType(); t)
            return t->isMarketable();
        return false;
    }
    bool isStackable() const {
        if (const auto t = getThingType(); t)
            return t->isStackable();
        return false;
    }
    bool isFluidContainer() const {
        if (const auto t = getThingType(); t)
            return t->isFluidContainer();
        return false;
    }
    bool isForceUse() const {
        if (const auto t = getThingType(); t)
            return t->isForceUse();
        return false;
    }
    bool isMultiUse() const {
        if (const auto t = getThingType(); t)
            return t->isMultiUse();
        return false;
    }
    bool isWritable() const {
        if (const auto t = getThingType(); t)
            return t->isWritable();
        return false;
    }
    bool isChargeable() const {
        if (const auto t = getThingType(); t)
            return t->isChargeable();
        return false;
    }
    bool isWritableOnce() const {
        if (const auto t = getThingType(); t)
            return t->isWritableOnce();
        return false;
    }
    bool isSplash() const {
        if (const auto t = getThingType(); t)
            return t->isSplash();
        return false;
    }
    bool isNotWalkable() const {
        if (const auto t = getThingType(); t)
            return t->isNotWalkable();
        return false;
    }
    bool isNotMoveable() const {
        if (const auto t = getThingType(); t)
            return t->isNotMoveable();
        return false;
    }
    bool isMoveable() const {
        if (const auto t = getThingType(); t)
            return !t->isNotMoveable();
        return false;
    }
    bool isNotPathable() const {
        if (const auto t = getThingType(); t)
            return t->isNotPathable();
        return false;
    }
    bool isPickupable() const {
        if (const auto t = getThingType(); t)
            return t->isPickupable();
        return false;
    }
    bool isHangable() const {
        if (const auto t = getThingType(); t)
            return t->isHangable();
        return false;
    }
    bool isHookSouth() const {
        if (const auto t = getThingType(); t)
            return t->isHookSouth();
        return false;
    }
    bool isHookEast() const {
        if (const auto t = getThingType(); t)
            return t->isHookEast();
        return false;
    }
    bool isRotateable() const {
        if (const auto t = getThingType(); t)
            return t->isRotateable();
        return false;
    }
    bool isDontHide() const {
        if (const auto t = getThingType(); t)
            return t->isDontHide();
        return false;
    }
    bool isTranslucent() const {
        if (const auto t = getThingType(); t)
            return t->isTranslucent();
        return false;
    }
    bool isLyingCorpse() const {
        if (const auto t = getThingType(); t)
            return t->isLyingCorpse();
        return false;
    }
    bool isAnimateAlways() const {
        if (const auto t = getThingType(); t)
            return t->isAnimateAlways();
        return false;
    }
    bool isFullGround() const {
        if (const auto t = getThingType(); t)
            return t->isFullGround();
        return false;
    }
    bool isIgnoreLook() const {
        if (const auto t = getThingType(); t)
            return t->isIgnoreLook();
        return false;
    }
    bool isCloth() const {
        if (const auto t = getThingType(); t)
            return t->isCloth();
        return false;
    }
    bool isUsable() const {
        if (const auto t = getThingType(); t)
            return t->isUsable();
        return false;
    }
    bool isWrapable() const {
        if (const auto t = getThingType(); t)
            return t->isWrapable();
        return false;
    }
    bool isUnwrapable() const {
        if (const auto t = getThingType(); t)
            return t->isUnwrapable();
        return false;
    }
    bool isTopEffect() const {
        if (const auto t = getThingType(); t)
            return t->isTopEffect();
        return false;
    }
    bool isPodium() const {
        if (const auto t = getThingType(); t)
            return t->isPodium();
        return false;
    }
    bool isOpaque() const {
        if (const auto t = getThingType(); t)
            return t->isOpaque();
        return false;
    }
    bool isLoading() const {
        if (const auto t = getThingType(); t)
            return t->isLoading();
        return false;
    }
    bool isSingleDimension() const {
        if (const auto t = getThingType(); t)
            return t->isSingleDimension();
        return false;
    }
    bool isTall(const bool useRealSize = false) const {
        if (const auto t = getThingType(); t)
            return t->isTall(useRealSize);
        return false;
    }

    bool hasMiniMapColor() const {
        if (const auto t = getThingType(); t)
            return t->hasMiniMapColor();
        return false;
    }
    bool hasLensHelp() const {
        if (const auto t = getThingType(); t)
            return t->hasLensHelp();
        return false;
    }
    bool hasDisplacement() const {
        if (const auto t = getThingType(); t)
            return t->hasDisplacement();
        return false;
    }
    bool hasElevation() const {
        if (const auto t = getThingType(); t)
            return t->hasElevation();
        return false;
    }
    bool hasAction() const {
        if (const auto t = getThingType(); t)
            return t->hasAction();
        return false;
    }
    bool hasWearOut() const {
        if (const auto t = getThingType(); t)
            return t->hasWearOut();
        return false;
    }
    bool hasClockExpire() const {
        if (const auto t = getThingType(); t)
            return t->hasClockExpire();
        return false;
    }
    bool hasExpire() const {
        if (const auto t = getThingType(); t)
            return t->hasExpire();
        return false;
    }
    bool hasExpireStop() const {
        if (const auto t = getThingType(); t)
            return t->hasExpireStop();
        return false;
    }
    bool hasAnimationPhases() const {
        if (const auto t = getThingType(); t)
            return t->getAnimationPhases() > 1;
        return false;
    }
    bool isDecoKit() const {
        if (const auto t = getThingType(); t)
            return t->isDecoKit();
        return false;
    }

    PLAYER_ACTION getDefaultAction() const {
        if (const auto t = getThingType(); t)
            return t->getDefaultAction();
        return static_cast<PLAYER_ACTION>(0);
    }

    uint16_t getClassification() const {
        if (const auto t = getThingType(); t)
            return t->getClassification();
        return 0;
    }

    void canDraw(const bool canDraw) { m_canDraw = canDraw; }

    bool canDraw(const Color& color = Color::white) const {
        if (const auto t = getThingType(); t) {
            return m_canDraw && m_clientId > 0 && color.aF() > Fw::MIN_ALPHA && t->getOpacity() > Fw::MIN_ALPHA;
        }
        return false;
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
