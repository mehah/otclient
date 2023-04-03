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
#include "attachedeffect.h"
#include "declarations.h"
#include "spritemanager.h"
#include "thingtype.h"
#include "thingtypemanager.h"

 // @bindclass
#pragma pack(push,1) // disable memory alignment
class Thing : public LuaObject
{
public:
    virtual void draw(const Point& /*dest*/, uint32_t flags, LightView* /*lightView*/ = nullptr) {}

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

    ThingType* getThingType() const { return m_thingType; }
    Animator* getAnimator() const { return m_thingType->getAnimator(); }
    Animator* getIdleAnimator() const { return m_thingType->getIdleAnimator(); }

    virtual Point getDisplacement() const { return m_thingType->getDisplacement(); }
    virtual int getDisplacementX() const { return m_thingType->getDisplacementX(); }
    virtual int getDisplacementY() const { return m_thingType->getDisplacementY(); }
    virtual int getExactSize(int layer = 0, int xPattern = 0, int yPattern = 0, int zPattern = 0, int animationPhase = 0) { return m_thingType->getExactSize(layer, xPattern, yPattern, zPattern, animationPhase); }

    virtual const Light& getLight() const { return m_thingType->getLight(); }
    virtual bool hasLight() const { return m_thingType->hasLight(); }

    const MarketData& getMarketData() { return m_thingType->getMarketData(); }
    const Size& getSize() const { return m_thingType->getSize(); }

    int getWidth() const { return m_thingType->getWidth(); }
    int getHeight() const { return m_thingType->getHeight(); }
    int getRealSize()const { return m_thingType->getRealSize(); }
    int getLayers() const { return m_thingType->getLayers(); }
    int getNumPatternX()const { return m_thingType->getNumPatternX(); }
    int getNumPatternY()const { return m_thingType->getNumPatternY(); }
    int getNumPatternZ()const { return m_thingType->getNumPatternZ(); }
    int getAnimationPhases()const { return m_thingType->getAnimationPhases(); }
    int getGroundSpeed() const { return m_thingType->getGroundSpeed(); }
    int getMaxTextLength()const { return m_thingType->getMaxTextLength(); }
    int getMinimapColor()const { return m_thingType->getMinimapColor(); }
    int getLensHelp()const { return m_thingType->getLensHelp(); }
    int getElevation() const { return m_thingType->getElevation(); }

    int getClothSlot() { return m_thingType->getClothSlot(); }

    bool blockProjectile() const { return m_thingType->blockProjectile(); }

    virtual bool isContainer() { return m_thingType->isContainer(); }

    bool isCommon() { return !isGround() && !isGroundBorder() && !isOnTop() && !isCreature() && !isOnBottom(); }

    bool isTopGround() { return !isCreature() && m_thingType->isTopGround(); }
    bool isTopGroundBorder() { return !isCreature() && m_thingType->isTopGroundBorder(); }
    bool isSingleGround() { return !isCreature() && m_thingType->isSingleGround(); }
    bool isSingleGroundBorder() { return !isCreature() && m_thingType->isSingleGroundBorder(); }
    bool isGround() { return !isCreature() && m_thingType->isGround(); }
    bool isGroundBorder() { return !isCreature() && m_thingType->isGroundBorder(); }
    bool isOnBottom() { return !isCreature() && m_thingType->isOnBottom(); }
    bool isOnTop() { return !isCreature() && m_thingType->isOnTop(); }

    bool isMarketable() { return m_thingType->isMarketable(); }
    bool isStackable() { return m_thingType->isStackable(); }
    bool isFluidContainer() { return m_thingType->isFluidContainer(); }
    bool isForceUse() { return m_thingType->isForceUse(); }
    bool isMultiUse() { return m_thingType->isMultiUse(); }
    bool isWritable() { return m_thingType->isWritable(); }
    bool isChargeable() { return m_thingType->isChargeable(); }
    bool isWritableOnce() { return m_thingType->isWritableOnce(); }
    bool isSplash() { return m_thingType->isSplash(); }
    bool isNotWalkable() { return m_thingType->isNotWalkable(); }
    bool isNotMoveable() { return m_thingType->isNotMoveable(); }
    bool isMoveable() { return !m_thingType->isNotMoveable(); }
    bool isNotPathable() { return m_thingType->isNotPathable(); }
    bool isPickupable() { return m_thingType->isPickupable(); }
    bool isHangable() { return m_thingType->isHangable(); }
    bool isHookSouth() { return m_thingType->isHookSouth(); }
    bool isHookEast() { return m_thingType->isHookEast(); }
    bool isRotateable() { return m_thingType->isRotateable(); }
    bool isDontHide() { return m_thingType->isDontHide(); }
    bool isTranslucent() { return m_thingType->isTranslucent(); }
    bool isLyingCorpse() { return m_thingType->isLyingCorpse(); }
    bool isAnimateAlways() { return m_thingType->isAnimateAlways(); }
    bool isFullGround() { return m_thingType->isFullGround(); }
    bool isIgnoreLook() { return m_thingType->isIgnoreLook(); }
    bool isCloth() { return m_thingType->isCloth(); }
    bool isUsable() { return m_thingType->isUsable(); }
    bool isWrapable() { return m_thingType->isWrapable(); }
    bool isUnwrapable() { return m_thingType->isUnwrapable(); }
    bool isTopEffect() { return m_thingType->isTopEffect(); }
    bool isPodium() const { return m_thingType->isPodium(); }
    bool isOpaque() const { return m_thingType->isOpaque(); }
    bool isSingleDimension() const { return m_thingType->isSingleDimension(); }
    bool isTall(const bool useRealSize = false) const { return m_thingType->isTall(useRealSize); }

    bool hasMiniMapColor() const { return m_thingType->hasMiniMapColor(); }
    bool hasLensHelp() const { return m_thingType->hasLensHelp(); }
    bool hasDisplacement() const { return m_thingType->hasDisplacement(); }
    bool hasElevation() const { return m_thingType->hasElevation(); }
    bool hasAction() const { return m_thingType->hasAction(); }
    bool hasWearOut() const { return m_thingType->hasWearOut(); }
    bool hasClockExpire() const { return m_thingType->hasClockExpire(); }
    bool hasExpire() const { return m_thingType->hasExpire(); }
    bool hasExpireStop() const { return m_thingType->hasExpireStop(); }
    bool hasAnimationPhases() const { return m_thingType->getAnimationPhases() > 1; }

    PLAYER_ACTION getDefaultAction() { return m_thingType->getDefaultAction(); }

    uint16_t getClassification() const { return m_thingType->getClassification(); }

    void canDraw(bool canDraw) { m_canDraw = canDraw; }
    inline bool canDraw(const Color& color = Color::white) const {
        return m_canDraw && m_clientId > 0 && color.aF() > Fw::MIN_ALPHA && m_thingType && m_thingType->getOpacity() > Fw::MIN_ALPHA;
    }

    void setShader(const std::string_view name);
    bool hasShader() { return m_shader != nullptr; }

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
    void setMarkColor(const Color& color) { if (m_markedColor != color) m_markedColor = color; }

    bool isHided() { return m_hidden > 0; }

    void attachEffect(const AttachedEffectPtr& obj);
    void clearAttachedEffects();
    bool detachEffectById(uint16_t id);
    AttachedEffectPtr getAttachedEffectById(uint16_t id);

    const std::vector<AttachedEffectPtr>& getAttachedEffects() { return m_attachedEffects; };

protected:
    void drawAttachedEffect(const Point& dest, LightView* lightView, bool isOnTop);

    void onDetachEffect(const AttachedEffectPtr& effect);
    void setAttachedEffectDirection(Otc::Direction dir) const
    {
        for (const auto& effect : m_attachedEffects) {
            if (effect->m_thingType && (effect->m_thingType->isCreature() || effect->m_thingType->isMissile()))
                effect->m_direction = dir;
        }
    }

    uint8_t m_hidden{ 0 };

    uint8_t m_numPatternX{ 0 };
    uint8_t m_numPatternY{ 0 };
    uint8_t m_numPatternZ{ 0 };

    uint16_t m_clientId{ 0 };

    Position m_position;
    ThingType* m_thingType{ nullptr };
    DrawConductor m_drawConductor{ false, DrawOrder::THIRD };

    Color m_markedColor{ Color::white };

    // Shader
    PainterShaderProgramPtr m_shader;
    std::function<void()> m_shaderAction{ nullptr };

    std::vector<AttachedEffectPtr> m_attachedEffects;

private:
    bool m_canDraw{ true };
};
#pragma pack(pop)
