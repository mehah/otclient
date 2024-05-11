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

#include <framework/core/clock.h>
#include <framework/graphics/drawpool.h>
#include <framework/luaengine/luaobject.h>
#include "declarations.h"
#include "spritemanager.h"
#include "thingtype.h"
#include "thingtypemanager.h"
#include "attachableobject.h"

 // @bindclass
#pragma pack(push,1) // disable memory alignment
class Thing : public AttachableObject
{
public:
    virtual void draw(const Point& /*dest*/, bool drawThings = true, LightView* /*lightView*/ = nullptr) {}

    LuaObjectPtr attachedObjectToLuaObject() override { return asLuaObject(); }
    bool isThing() override { return true; }

    virtual void setId(uint32_t /*id*/) {}
    virtual void setPosition(const Position& position, uint8_t stackPos = 0, bool hasElevation = false);

    virtual uint32_t getId() { return m_clientId; }
    uint16_t getClientId() const { return m_clientId; }

    Position getPosition() { return m_position; }

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

    Animator* getAnimator() const { return getThingType()->getAnimator(); }
    Animator* getIdleAnimator() const { return getThingType()->getIdleAnimator(); }

    virtual Point getDisplacement() const { return getThingType()->getDisplacement(); }
    virtual int getDisplacementX() const { return getThingType()->getDisplacementX(); }
    virtual int getDisplacementY() const { return getThingType()->getDisplacementY(); }
    virtual int getExactSize(int layer = 0, int xPattern = 0, int yPattern = 0, int zPattern = 0, int animationPhase = 0) { return getThingType()->getExactSize(layer, xPattern, yPattern, zPattern, animationPhase); }

    virtual const Light& getLight() const { return getThingType()->getLight(); }
    virtual bool hasLight() const { return getThingType()->hasLight(); }

    const MarketData& getMarketData() { return getThingType()->getMarketData(); }
    const Size& getSize() const { return getThingType()->getSize(); }

    int getWidth() const { return getThingType()->getWidth(); }
    int getHeight() const { return getThingType()->getHeight(); }
    int getRealSize()const { return getThingType()->getRealSize(); }
    int getLayers() const { return getThingType()->getLayers(); }
    int getNumPatternX()const { return getThingType()->getNumPatternX(); }
    int getNumPatternY()const { return getThingType()->getNumPatternY(); }
    int getNumPatternZ()const { return getThingType()->getNumPatternZ(); }
    int getAnimationPhases()const { return getThingType()->getAnimationPhases(); }
    int getGroundSpeed() const { return getThingType()->getGroundSpeed(); }
    int getMaxTextLength()const { return getThingType()->getMaxTextLength(); }
    int getMinimapColor()const { return getThingType()->getMinimapColor(); }
    int getLensHelp()const { return getThingType()->getLensHelp(); }
    int getElevation() const { return getThingType()->getElevation(); }

    int getClothSlot() { return getThingType()->getClothSlot(); }

    bool blockProjectile() const { return getThingType()->blockProjectile(); }

    virtual bool isContainer() { return getThingType()->isContainer(); }

    bool isCommon() { return !isGround() && !isGroundBorder() && !isOnTop() && !isCreature() && !isOnBottom(); }

    bool isTopGround() { return !isCreature() && getThingType()->isTopGround(); }
    bool isTopGroundBorder() { return !isCreature() && getThingType()->isTopGroundBorder(); }
    bool isSingleGround() { return !isCreature() && getThingType()->isSingleGround(); }
    bool isSingleGroundBorder() { return !isCreature() && getThingType()->isSingleGroundBorder(); }
    bool isGround() { return !isCreature() && getThingType()->isGround(); }
    bool isGroundBorder() { return !isCreature() && getThingType()->isGroundBorder(); }
    bool isOnBottom() { return !isCreature() && getThingType()->isOnBottom(); }
    bool isOnTop() { return !isCreature() && getThingType()->isOnTop(); }

    bool isMarketable() { return getThingType()->isMarketable(); }
    bool isStackable() { return getThingType()->isStackable(); }
    bool isFluidContainer() { return getThingType()->isFluidContainer(); }
    bool isForceUse() { return getThingType()->isForceUse(); }
    bool isMultiUse() { return getThingType()->isMultiUse(); }
    bool isWritable() { return getThingType()->isWritable(); }
    bool isChargeable() { return getThingType()->isChargeable(); }
    bool isWritableOnce() { return getThingType()->isWritableOnce(); }
    bool isSplash() { return getThingType()->isSplash(); }
    bool isNotWalkable() { return getThingType()->isNotWalkable(); }
    bool isNotMoveable() { return getThingType()->isNotMoveable(); }
    bool isMoveable() { return !getThingType()->isNotMoveable(); }
    bool isNotPathable() { return getThingType()->isNotPathable(); }
    bool isPickupable() { return getThingType()->isPickupable(); }
    bool isHangable() { return getThingType()->isHangable(); }
    bool isHookSouth() { return getThingType()->isHookSouth(); }
    bool isHookEast() { return getThingType()->isHookEast(); }
    bool isRotateable() { return getThingType()->isRotateable(); }
    bool isDontHide() { return getThingType()->isDontHide(); }
    bool isTranslucent() { return getThingType()->isTranslucent(); }
    bool isLyingCorpse() { return getThingType()->isLyingCorpse(); }
    bool isAnimateAlways() { return getThingType()->isAnimateAlways(); }
    bool isFullGround() { return getThingType()->isFullGround(); }
    bool isIgnoreLook() { return getThingType()->isIgnoreLook(); }
    bool isCloth() { return getThingType()->isCloth(); }
    bool isUsable() { return getThingType()->isUsable(); }
    bool isWrapable() { return getThingType()->isWrapable(); }
    bool isUnwrapable() { return getThingType()->isUnwrapable(); }
    bool isTopEffect() { return getThingType()->isTopEffect(); }
    bool isPodium() const { return getThingType()->isPodium(); }
    bool isOpaque() const { return getThingType()->isOpaque(); }
    bool isSingleDimension() const { return getThingType()->isSingleDimension(); }
    bool isTall(const bool useRealSize = false) const { return getThingType()->isTall(useRealSize); }

    bool hasMiniMapColor() const { return getThingType()->hasMiniMapColor(); }
    bool hasLensHelp() const { return getThingType()->hasLensHelp(); }
    bool hasDisplacement() const { return getThingType()->hasDisplacement(); }
    bool hasElevation() const { return getThingType()->hasElevation(); }
    bool hasAction() const { return getThingType()->hasAction(); }
    bool hasWearOut() const { return getThingType()->hasWearOut(); }
    bool hasClockExpire() const { return getThingType()->hasClockExpire(); }
    bool hasExpire() const { return getThingType()->hasExpire(); }
    bool hasExpireStop() const { return getThingType()->hasExpireStop(); }
    bool hasAnimationPhases() const { return getThingType()->getAnimationPhases() > 1; }
    bool isDecoKit() const { return getThingType()->isDecoKit(); }

    PLAYER_ACTION getDefaultAction() { return getThingType()->getDefaultAction(); }

    uint16_t getClassification() { return getThingType()->getClassification(); }

    void canDraw(bool canDraw) { m_canDraw = canDraw; }
    inline bool canDraw(const Color& color = Color::white) const {
        return m_canDraw && m_clientId > 0 && color.aF() > Fw::MIN_ALPHA && getThingType() && getThingType()->getOpacity() > Fw::MIN_ALPHA;
    }

    void setShader(const std::string_view name);
    bool hasShader() { return m_shaderId > 0; }

    void ungroup() { m_drawConductor.agroup = false; }

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

protected:
    virtual ThingType* getThingType() const = 0;

    void setAttachedEffectDirection(Otc::Direction dir) const
    {
        if (!hasAttachedEffects()) return;

        for (const auto& effect : m_data->attachedEffects) {
            if (effect->getThingType() && (effect->getThingType()->isCreature() || effect->getThingType()->isMissile()))
                effect->m_direction = dir;
        }
    }

    Color m_markedColor{ Color::white };
    Color m_highlightColor{ Color::white };

    Position m_position;
    DrawConductor m_drawConductor{ false, DrawOrder::THIRD };

    uint16_t m_clientId{ 0 };

    int8_t m_stackPos{ -1 };
    uint8_t m_numPatternX{ 0 };
    uint8_t m_numPatternY{ 0 };
    uint8_t m_numPatternZ{ 0 };

    // Shader
    uint8_t m_shaderId{ 0 };

private:
    void lua_setMarked(std::string_view color) { setMarked(Color(color)); }
    void lua_setHighlight(std::string_view color) { setHighlight(Color(color)); }

    bool m_canDraw{ true };

    friend class Client;
    friend class Tile;
};
#pragma pack(pop)
