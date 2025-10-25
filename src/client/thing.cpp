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

#include "thing.h"

#include "attachedeffect.h"
#include "game.h"
#include "map.h"
#include "thingtype.h"
#include "framework/core/clock.h"
#include "framework/graphics/paintershaderprogram.h"
#include "framework/graphics/shadermanager.h"

void Thing::setPosition(const Position& position, uint8_t /*stackPos*/)
{
    if (m_position == position)
        return;

    const Position oldPos = m_position;
    m_position = position;
    onPositionChange(position, oldPos);
}

int Thing::getStackPriority()
{
    // Bug fix for old versions
    if (g_game.getClientVersion() <= 800 && isSplash())
        return GROUND;

    if (isGround())
        return GROUND;

    if (isGroundBorder())
        return GROUND_BORDER;

    if (isOnBottom())
        return ON_BOTTOM;

    if (isOnTop())
        return ON_TOP;

    if (isCreature())
        return CREATURE;

    // common items
    return COMMON_ITEMS;
}

const TilePtr& Thing::getTile()
{
    return g_map.getTile(m_position);
}

ContainerPtr Thing::getParentContainer()
{
    if (m_position.x == 0xffff && m_position.y & 0x40) {
        const int containerId = m_position.y ^ 0x40;
        return g_game.getContainer(containerId);
    }

    return nullptr;
}

int Thing::getStackPos()
{
    if (m_position.x == UINT16_MAX && isItem()) // is inside a container
        return m_position.z;

    if (m_stackPos >= 0)
        return m_stackPos;

    g_logger.traceError("got a thing with invalid stackpos");
    return -1;
}

PainterShaderProgramPtr Thing::getShader() const {
    return g_shaders.getShaderById(m_shaderId);
}

void Thing::setShader(const std::string_view name) {
    m_shaderId = 0;
    if (name.empty())
        return;

    if (const auto& shader = g_shaders.getShader(name))
        m_shaderId = shader->getId();
}
void Thing::setAttachedEffectDirection(const Otc::Direction dir) const
{
    if (!hasAttachedEffects()) return;

    for (const auto& effect : m_data->attachedEffects) {
        if (effect->getThingType() && (effect->getThingType()->isCreature() || effect->getThingType()->isMissile()))
            effect->m_direction = dir;
    }
}

Animator* Thing::getAnimator() const { return getThingType()->getAnimator(); }
Animator* Thing::getIdleAnimator() const { return getThingType()->getIdleAnimator(); }

Point Thing::getDisplacement() const { return getThingType()->getDisplacement(); }
int Thing::getDisplacementX() const { return getThingType()->getDisplacementX(); }
int Thing::getDisplacementY() const { return getThingType()->getDisplacementY(); }
int Thing::getExactSize(const int layer, const int xPattern, const int yPattern, const int zPattern, const int animationPhase) {
    return getThingType()->getExactSize(layer, xPattern, yPattern, zPattern, animationPhase);
}

const Light& Thing::getLight() const { return getThingType()->getLight(); }
bool Thing::hasLight() const { return getThingType()->hasLight(); }

const MarketData& Thing::getMarketData() { return getThingType()->getMarketData(); }
const std::vector<NPCData>& Thing::getNpcSaleData() { return getThingType()->getNpcSaleData(); }
int Thing::getMeanPrice() { return getThingType()->getMeanPrice(); }
const Size& Thing::getSize() const { return getThingType()->getSize(); }

int Thing::getWidth() const { return getThingType()->getWidth(); }
int Thing::getHeight() const { return getThingType()->getHeight(); }
int Thing::getRealSize() const { return getThingType()->getRealSize(); }
int Thing::getLayers() const { return getThingType()->getLayers(); }
int Thing::getNumPatternX() const { return getThingType()->getNumPatternX(); }
int Thing::getNumPatternY() const { return getThingType()->getNumPatternY(); }
int Thing::getNumPatternZ() const { return getThingType()->getNumPatternZ(); }
int Thing::getAnimationPhases() const { return getThingType()->getAnimationPhases(); }
int Thing::getGroundSpeed() const { return getThingType()->getGroundSpeed(); }
int Thing::getMaxTextLength() const { return getThingType()->getMaxTextLength(); }
int Thing::getMinimapColor() const { return getThingType()->getMinimapColor(); }
int Thing::getLensHelp() const { return getThingType()->getLensHelp(); }
int Thing::getElevation() const { return getThingType()->getElevation(); }

int Thing::getClothSlot() { return getThingType()->getClothSlot(); }

bool Thing::blockProjectile() const { return getThingType()->blockProjectile(); }

bool Thing::isContainer() { return getThingType()->isContainer(); }

bool Thing::isTopGround() { return !isCreature() && getThingType()->isTopGround(); }
bool Thing::isTopGroundBorder() { return !isCreature() && getThingType()->isTopGroundBorder(); }
bool Thing::isSingleGround() { return !isCreature() && getThingType()->isSingleGround(); }
bool Thing::isSingleGroundBorder() { return !isCreature() && getThingType()->isSingleGroundBorder(); }
bool Thing::isGround() { return !isCreature() && getThingType()->isGround(); }
bool Thing::isGroundBorder() { return !isCreature() && getThingType()->isGroundBorder(); }
bool Thing::isOnBottom() { return !isCreature() && getThingType()->isOnBottom(); }
bool Thing::isOnTop() { return !isCreature() && getThingType()->isOnTop(); }

bool Thing::isMarketable() { return getThingType()->isMarketable(); }
bool Thing::isStackable() { return getThingType()->isStackable(); }
bool Thing::isFluidContainer() { return getThingType()->isFluidContainer(); }
bool Thing::isForceUse() { return getThingType()->isForceUse(); }
bool Thing::isMultiUse() { return getThingType()->isMultiUse(); }
bool Thing::isWritable() { return getThingType()->isWritable(); }
bool Thing::isChargeable() { return getThingType()->isChargeable(); }
bool Thing::isWritableOnce() { return getThingType()->isWritableOnce(); }
bool Thing::isSplash() { return getThingType()->isSplash(); }
bool Thing::isNotWalkable() { return getThingType()->isNotWalkable(); }
bool Thing::isNotMoveable() { return getThingType()->isNotMoveable(); }
bool Thing::isMoveable() { return !getThingType()->isNotMoveable(); }
bool Thing::isNotPathable() { return getThingType()->isNotPathable(); }
bool Thing::isPickupable() { return getThingType()->isPickupable(); }
bool Thing::isHangable() { return getThingType()->isHangable(); }
bool Thing::isHookSouth() { return getThingType()->isHookSouth(); }
bool Thing::isHookEast() { return getThingType()->isHookEast(); }
bool Thing::isRotateable() { return getThingType()->isRotateable(); }
bool Thing::isDontHide() { return getThingType()->isDontHide(); }
bool Thing::isTranslucent() { return getThingType()->isTranslucent(); }
bool Thing::isLyingCorpse() { return getThingType()->isLyingCorpse(); }
bool Thing::isAnimateAlways() { return getThingType()->isAnimateAlways(); }
bool Thing::isFullGround() { return getThingType()->isFullGround(); }
bool Thing::isIgnoreLook() { return getThingType()->isIgnoreLook(); }
bool Thing::isCloth() { return getThingType()->isCloth(); }
bool Thing::isUsable() { return getThingType()->isUsable(); }
bool Thing::isWrapable() { return getThingType()->isWrapable(); }
bool Thing::isUnwrapable() { return getThingType()->isUnwrapable(); }
bool Thing::isTopEffect() { return getThingType()->isTopEffect(); }
bool Thing::isPodium() const { return getThingType()->isPodium(); }
bool Thing::isOpaque() const { return getThingType()->isOpaque(); }
bool Thing::isLoading() const { return getThingType()->isLoading(); }
bool Thing::isSingleDimension() const { return getThingType()->isSingleDimension(); }
bool Thing::isTall(const bool useRealSize) const { return getThingType()->isTall(useRealSize); }

bool Thing::hasMiniMapColor() const { return getThingType()->hasMiniMapColor(); }
bool Thing::hasLensHelp() const { return getThingType()->hasLensHelp(); }
bool Thing::hasDisplacement() const { return getThingType()->hasDisplacement(); }
bool Thing::hasElevation() const { return getThingType()->hasElevation(); }
bool Thing::hasAction() const { return getThingType()->hasAction(); }
bool Thing::hasWearOut() const { return getThingType()->hasWearOut(); }
bool Thing::hasClockExpire() const { return getThingType()->hasClockExpire(); }
bool Thing::hasExpire() const { return getThingType()->hasExpire(); }
bool Thing::hasExpireStop() const { return getThingType()->hasExpireStop(); }
bool Thing::hasAnimationPhases() const { return getThingType()->getAnimationPhases() > 1; }
bool Thing::isDecoKit() const { return getThingType()->isDecoKit(); }
bool Thing::isAmmo() { return getThingType()->isAmmo(); }

PLAYER_ACTION Thing::getDefaultAction() { return getThingType()->getDefaultAction(); }

uint16_t Thing::getClassification() { return getThingType()->getClassification(); }

bool Thing::canDraw(const Color& color) const {
    return m_canDraw && m_clientId > 0 && color.aF() > Fw::MIN_ALPHA && getThingType() && getThingType()->getOpacity() > Fw::MIN_ALPHA;
}

const Color& Thing::getMarkedColor() {
    if (m_markedColor == Color::white)
        return Color::white;

    m_markedColor.setAlpha(0.1f + std::abs(500 - g_clock.millis() % 1000) / 1000.0f);
    return m_markedColor;
}

const Color& Thing::getHighlightColor() {
    if (m_highlightColor == Color::white)
        return Color::white;

    m_highlightColor.setAlpha(0.1f + std::abs(500 - g_clock.millis() % 1000) / 1000.0f);
    return m_highlightColor;
}