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

#include "creature.h"
#include "game.h"
#include "lightview.h"
#include "localplayer.h"
#include "luavaluecasts.h"
#include "map.h"
#include "shadermanager.h"
#include "thingtypemanager.h"
#include "tile.h"

#include <framework/core/clock.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/graphicalapplication.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/graphics.h>
#include <framework/graphics/texturemanager.h>

double Creature::speedA = 0;
double Creature::speedB = 0;
double Creature::speedC = 0;

Creature::Creature() :m_type(Proto::CreatureTypeUnknown)
{
    m_name.setFont(g_gameConfig.getCreatureNameFont());
    m_name.setAlign(Fw::AlignTopCenter);

    // Example of how to send a UniformValue to shader
    /*
    m_shaderAction = [this]()-> void {
        const int id = m_outfit.isCreature() ? m_outfit.getId() : m_outfit.getAuxId();
        m_shader->bind();
        m_shader->setUniformValue(ShaderManager::OUTFIT_ID_UNIFORM, id);
    };

    m_mountShaderAction = [this]()-> void {
        m_mountShader->bind();
        m_mountShader->setUniformValue(ShaderManager::MOUNT_ID_UNIFORM, m_outfit.getMount());
    };
    */
}

void Creature::draw(const Point& dest, uint32_t flags, LightView* lightView)
{
    if (!canBeSeen() || !canDraw())
        return;

    if (flags & Otc::DrawThings) {
        if (m_showTimedSquare) {
            g_drawPool.addBoundingRect(Rect(dest + (m_walkOffset - getDisplacement() + 2) * g_drawPool.getScaleFactor(), Size(28 * g_drawPool.getScaleFactor())), m_timedSquareColor, std::max<int>(static_cast<int>(2 * g_drawPool.getScaleFactor()), 1));
        }

        if (m_showStaticSquare) {
            g_drawPool.addBoundingRect(Rect(dest + (m_walkOffset - getDisplacement()) * g_drawPool.getScaleFactor(), Size(g_gameConfig.getSpriteSize() * g_drawPool.getScaleFactor())), m_staticSquareColor, std::max<int>(static_cast<int>(2 * g_drawPool.getScaleFactor()), 1));
        }

        const auto& _dest = dest + m_walkOffset * g_drawPool.getScaleFactor();

        internalDraw(_dest, false, Color::white, lightView);

        if (isMarked())
            internalDraw(_dest, true, getMarkedColor());
    }

    if (lightView && flags & Otc::DrawLights) {
        auto light = getLight();

        if (isLocalPlayer() && (g_map.getLight().intensity < 64 || m_position.z > g_gameConfig.getMapSeaFloor())) {
            if (light.intensity == 0) {
                light.intensity = 2;
            } else if (light.color == 0 || light.color > 215) {
                light.color = 215;
            }
        }

        if (light.intensity > 0) {
            lightView->addLightSource(dest + (m_walkOffset + (Point(g_gameConfig.getSpriteSize() / 2))) * g_drawPool.getScaleFactor(), light);
        }
    }
}

void Creature::internalDraw(Point dest, bool isMarked, const Color& color, LightView* lightView)
{
    if (isMarked)
        g_drawPool.setShaderProgram(g_painter->getReplaceColorShader());
    else
        drawAttachedEffect(dest, lightView, false); // On Bottom

    if (!isHided()) {
        // outfit is a real creature
        if (m_outfit.isCreature()) {
            if (m_outfit.hasMount()) {
                dest -= m_mountType->getDisplacement() * g_drawPool.getScaleFactor();

                if (!isMarked && m_mountShader)
                    g_drawPool.setShaderProgram(m_mountShader, true, m_mountShaderAction);
                m_mountType->draw(dest, 0, m_numPatternX, 0, 0, getCurrentAnimationPhase(true), Otc::DrawThingsAndLights, color);

                dest += getDisplacement() * g_drawPool.getScaleFactor();
            }

            if (!m_jumpOffset.isNull()) {
                const auto& jumpOffset = m_jumpOffset * g_drawPool.getScaleFactor();
                dest -= Point(std::round(jumpOffset.x), std::round(jumpOffset.y));
            }

            const auto& datType = getThingType();
            const int animationPhase = getCurrentAnimationPhase();

            if (!isMarked && m_shader)
                g_drawPool.setShaderProgram(m_shader, m_shaderAction);

            // yPattern => creature addon
            for (int yPattern = 0; yPattern < getNumPatternY(); ++yPattern) {
                // continue if we dont have this addon
                if (yPattern > 0 && !(m_outfit.getAddons() & (1 << (yPattern - 1))))
                    continue;

                datType->draw(dest, 0, m_numPatternX, yPattern, m_numPatternZ, animationPhase, Otc::DrawThingsAndLights, color);

                if (m_drawOutfitColor && !isMarked && getLayers() > 1) {
                    g_drawPool.setCompositionMode(CompositionMode::MULTIPLY);
                    datType->draw(dest, SpriteMaskYellow, m_numPatternX, yPattern, m_numPatternZ, animationPhase, Otc::DrawThingsAndLights, m_outfit.getHeadColor());
                    datType->draw(dest, SpriteMaskRed, m_numPatternX, yPattern, m_numPatternZ, animationPhase, Otc::DrawThingsAndLights, m_outfit.getBodyColor());
                    datType->draw(dest, SpriteMaskGreen, m_numPatternX, yPattern, m_numPatternZ, animationPhase, Otc::DrawThingsAndLights, m_outfit.getLegsColor());
                    datType->draw(dest, SpriteMaskBlue, m_numPatternX, yPattern, m_numPatternZ, animationPhase, Otc::DrawThingsAndLights, m_outfit.getFeetColor());
                    g_drawPool.resetCompositionMode();
                }
            }

            if (!isMarked && m_shader)
                g_drawPool.resetShaderProgram();

            // outfit is a creature imitating an item or the invisible effect
        } else {
            int animationPhases = m_thingType->getAnimationPhases();
            int animateTicks = g_gameConfig.getItemTicksPerFrame();

            // when creature is an effect we cant render the first and last animation phase,
            // instead we should loop in the phases between
            if (m_outfit.isEffect()) {
                animationPhases = std::max<int>(1, animationPhases - 2);
                animateTicks = g_gameConfig.getInvisibleTicksPerFrame();
            }

            int animationPhase = 0;
            if (animationPhases > 1) {
                animationPhase = (g_clock.millis() % (static_cast<long long>(animateTicks) * animationPhases)) / animateTicks;
            }

            if (m_outfit.isEffect())
                animationPhase = std::min<int>(animationPhase + 1, animationPhases);

            if (!isMarked && m_shader)
                g_drawPool.setShaderProgram(m_shader, true, m_shaderAction);
            m_thingType->draw(dest - (getDisplacement() * g_drawPool.getScaleFactor()), 0, 0, 0, 0, animationPhase, Otc::DrawThingsAndLights, color);
        }
    }

    if (isMarked)
        g_drawPool.resetShaderProgram();
    else
        drawAttachedEffect(dest, lightView, true); // On Top
}

void Creature::drawOutfit(const Rect& destRect, uint8_t size, const Color& color)
{
    if (!m_thingType)
        return;

    uint8_t frameSize = getExactSize();
    if (size > 0)
        frameSize = std::max<int>(frameSize * (size / 100.f), 2 * g_gameConfig.getSpriteSize() * (size / 100.f));

    g_drawPool.bindFrameBuffer(frameSize);
    internalDraw(Point(frameSize - g_gameConfig.getSpriteSize()) + getDisplacement(), false, color);
    g_drawPool.releaseFrameBuffer(destRect);
}

void Creature::drawInformation(const MapPosInfo& mapRect, const Point& dest, bool useGray, int drawFlags)
{
    static const Color
        DEFAULT_COLOR(96, 96, 96),
        NPC_COLOR(0x66, 0xcc, 0xff);

    if (isDead() || !canBeSeen() || !(drawFlags & Otc::DrawCreatureInfo) || !mapRect.isInRange(m_position))
        return;

    const auto& jumpOffset = m_jumpOffset * g_drawPool.getScaleFactor();
    const auto& parentRect = mapRect.rect;
    const auto& creatureOffset = Point(16 - getDisplacementX(), -getDisplacementY() - 2) + m_walkOffset;

    Point p = dest - mapRect.drawOffset;
    p += creatureOffset * g_drawPool.getScaleFactor() - Point(std::round(jumpOffset.x), std::round(jumpOffset.y));
    p.x *= mapRect.horizontalStretchFactor;
    p.y *= mapRect.verticalStretchFactor;
    p += parentRect.topLeft();

    auto fillColor = DEFAULT_COLOR;

    if (!useGray) {
        if (g_game.getFeature(Otc::GameBlueNpcNameColor) && isNpc() && isFullHealth())
            fillColor = NPC_COLOR;
        else fillColor = m_informationColor;
    }

    // calculate main rects

    const auto& nameSize = m_name.getTextSize();
    const int cropSizeText = g_gameConfig.isAdjustCreatureInformationBasedCropSize() ? getExactSize() : 12;
    const int cropSizeBackGround = g_gameConfig.isAdjustCreatureInformationBasedCropSize() ? cropSizeText - nameSize.height() : 0;

    g_drawPool.select(DrawPoolType::CREATURE_INFORMATION);
    {
        bool isScaled = g_app.getCreatureInformationScale() != PlatformWindow::DEFAULT_DISPLAY_DENSITY;
        if (isScaled) {
            g_drawPool.scale(g_app.getCreatureInformationScale());
            p.scale(g_app.getCreatureInformationScale());
        }

        auto backgroundRect = Rect(p.x - (13.5), p.y - cropSizeBackGround, 27, 4);
        auto textRect = Rect(p.x - nameSize.width() / 2.0, p.y - cropSizeText, nameSize);

        if (!isScaled) {
            backgroundRect.bind(parentRect);
            textRect.bind(parentRect);
        }

        // distance them
        uint8_t offset = 12 * g_drawPool.getScaleFactor();
        if (isLocalPlayer()) {
            offset *= 2 * g_drawPool.getScaleFactor();
        }

        if (textRect.top() == parentRect.top())
            backgroundRect.moveTop(textRect.top() + offset);
        if (backgroundRect.bottom() == parentRect.bottom())
            textRect.moveTop(backgroundRect.top() - offset);

        // health rect is based on background rect, so no worries
        Rect healthRect = backgroundRect.expanded(-1);
        healthRect.setWidth((m_healthPercent / 100.0) * 25);

        if (drawFlags & Otc::DrawBars) {
            g_drawPool.addFilledRect(backgroundRect, Color::black);
            g_drawPool.addFilledRect(healthRect, fillColor);

            if (drawFlags & Otc::DrawManaBar && isLocalPlayer()) {
                if (const auto& player = g_game.getLocalPlayer()) {
                    backgroundRect.moveTop(backgroundRect.bottom());

                    g_drawPool.addFilledRect(backgroundRect, Color::black);

                    Rect manaRect = backgroundRect.expanded(-1);
                    const double maxMana = player->getMaxMana();
                    manaRect.setWidth((maxMana ? player->getMana() / maxMana : 1) * 25);

                    g_drawPool.addFilledRect(manaRect, Color::blue);
                }
            }
        }

        if (drawFlags & Otc::DrawNames) {
            m_name.draw(textRect, fillColor);
        }

        if (m_skull != Otc::SkullNone && m_skullTexture)
            g_drawPool.addTexturedPos(m_skullTexture, backgroundRect.x() + 13.5 + 12, backgroundRect.y() + 5);

        if (m_shield != Otc::ShieldNone && m_shieldTexture && m_showShieldTexture)
            g_drawPool.addTexturedPos(m_shieldTexture, backgroundRect.x() + 13.5, backgroundRect.y() + 5);

        if (m_emblem != Otc::EmblemNone && m_emblemTexture)
            g_drawPool.addTexturedPos(m_emblemTexture, backgroundRect.x() + 13.5 + 12, backgroundRect.y() + 16);

        if (m_type != Proto::CreatureTypeUnknown && m_typeTexture)
            g_drawPool.addTexturedPos(m_typeTexture, backgroundRect.x() + 13.5 + 12 + 12, backgroundRect.y() + 16);

        if (m_icon != Otc::NpcIconNone && m_iconTexture)
            g_drawPool.addTexturedPos(m_iconTexture, backgroundRect.x() + 13.5 + 12, backgroundRect.y() + 5);
    }
    // Go back to use map pool
    g_drawPool.select(DrawPoolType::MAP);
}

void Creature::turn(Otc::Direction direction)
{
    // schedules to set the new direction when walk ends
    if (m_walking) {
        m_walkTurnDirection = direction;
        return;
    }

    // if is not walking change the direction right away
    setDirection(direction);
}

void Creature::walk(const Position& oldPos, const Position& newPos)
{
    if (oldPos == newPos)
        return;

    // get walk direction
    m_lastStepDirection = oldPos.getDirectionFromPosition(newPos);
    m_lastStepFromPosition = oldPos;
    m_lastStepToPosition = newPos;

    // set current walking direction
    setDirection(m_lastStepDirection);

    // starts counting walk
    m_walking = true;
    m_walkTimer.restart();
    m_walkedPixels = 0;

    // no direction need to be changed when the walk ends
    m_walkTurnDirection = Otc::InvalidDirection;

    if (m_walkFinishAnimEvent) {
        m_walkFinishAnimEvent->cancel();
        m_walkFinishAnimEvent = nullptr;
    }

    // starts updating walk
    nextWalkUpdate();
}

void Creature::stopWalk()
{
    if (!m_walking)
        return;

    // stops the walk right away
    terminateWalk();
}

void Creature::jump(int height, int duration)
{
    if (!m_jumpOffset.isNull())
        return;

    m_jumpTimer.restart();
    m_jumpHeight = height;
    m_jumpDuration = duration;

    updateJump();
}

void Creature::updateJump()
{
    if (m_jumpTimer.ticksElapsed() >= m_jumpDuration) {
        m_jumpOffset = PointF();
        return;
    }

    const int t = m_jumpTimer.ticksElapsed();
    const double a = -4 * m_jumpHeight / (m_jumpDuration * m_jumpDuration);
    const double b = +4 * m_jumpHeight / m_jumpDuration;
    const double height = a * t * t + b * t;

    const int roundHeight = std::round(height);
    const int halfJumpDuration = m_jumpDuration / 2;

    m_jumpOffset = PointF(height, height);

    if (isLocalPlayer()) {
        g_map.notificateCameraMove(m_walkOffset);
    }

    int nextT = 0;
    int diff = 0;
    int i = 1;
    if (m_jumpTimer.ticksElapsed() < halfJumpDuration)
        diff = 1;
    else if (m_jumpTimer.ticksElapsed() > halfJumpDuration)
        diff = -1;

    do {
        nextT = std::round((-b + std::sqrt(std::max<double>(b * b + 4 * a * (roundHeight + diff * i), 0.0)) * diff) / (2 * a));
        ++i;

        if (nextT < halfJumpDuration)
            diff = 1;
        else if (nextT > halfJumpDuration)
            diff = -1;
    } while (nextT - m_jumpTimer.ticksElapsed() == 0 && i < 3);

    // schedules next update
    const auto self = static_self_cast<Creature>();
    g_dispatcher.scheduleEvent([self] {
        self->updateJump();
    }, nextT - m_jumpTimer.ticksElapsed());
}

void Creature::onPositionChange(const Position& newPos, const Position& oldPos)
{
    callLuaField("onPositionChange", newPos, oldPos);
}

void Creature::onAppear()
{
    // cancel any disappear event
    if (m_disappearEvent) {
        m_disappearEvent->cancel();
        m_disappearEvent = nullptr;
    }

    if (isLocalPlayer() && m_position != m_oldPosition) {
        g_map.notificateCameraMove(m_walkOffset);
    }

    // creature appeared the first time or wasn't seen for a long time
    if (m_removed) {
        stopWalk();
        m_removed = false;
        callLuaField("onAppear");
    } // walk
    else if (m_oldPosition != m_position && m_oldPosition.isInRange(m_position, 1, 1) && m_allowAppearWalk) {
        m_allowAppearWalk = false;
        walk(m_oldPosition, m_position);
        callLuaField("onWalk", m_oldPosition, m_position);
    } // teleport
    else if (m_oldPosition != m_position) {
        stopWalk();
        callLuaField("onDisappear");
        callLuaField("onAppear");
    } // else turn
}

void Creature::onDisappear()
{
    if (m_disappearEvent)
        m_disappearEvent->cancel();

    m_oldPosition = m_position;

    // a pair onDisappear and onAppear events are fired even when creatures walks or turns,
    // so we must filter
    const auto self = static_self_cast<Creature>();
    m_disappearEvent = g_dispatcher.addEvent([self] {
        self->m_removed = true;
        self->stopWalk();

        self->callLuaField("onDisappear");

        // invalidate this creature position
        if (!self->isLocalPlayer())
            self->setPosition(Position());

        self->m_oldPosition = {};
        self->m_disappearEvent = nullptr;

        if (g_game.getAttackingCreature() == self)
            g_game.cancelAttack();
        else if (g_game.getFollowingCreature() == self)
            g_game.cancelFollow();
    });

    Thing::onDisappear();
}

void Creature::onDeath()
{
    callLuaField("onDeath");
}

void Creature::updateWalkAnimation()
{
    if (!m_outfit.isCreature())
        return;

    int footAnimPhases = m_outfit.hasMount() ? m_mountType->getAnimationPhases() : getAnimationPhases();
    if (!g_game.getFeature(Otc::GameEnhancedAnimations) && footAnimPhases > 2) {
        --footAnimPhases;
    }

    // looktype has no animations
    if (footAnimPhases == 0)
        return;

    int minFootDelay = 20;
    int footAnimDelay = footAnimPhases;

    if (g_game.getFeature(Otc::GameEnhancedAnimations) && footAnimPhases > 2) {
        minFootDelay += 10;
        if (footAnimDelay > 1)
            footAnimDelay /= 1.5;
    }

    const int footDelay = std::clamp<int>(m_stepCache.getDuration(m_lastStepDirection) / footAnimDelay, minFootDelay, 80);

    if (m_footTimer.ticksElapsed() >= footDelay) {
        if (m_walkAnimationPhase == footAnimPhases) m_walkAnimationPhase = 1;
        else ++m_walkAnimationPhase;

        m_footTimer.restart();
    }
}

void Creature::updateWalkOffset(uint8_t totalPixelsWalked)
{
    m_walkOffset = {};
    if (m_direction == Otc::North || m_direction == Otc::NorthEast || m_direction == Otc::NorthWest)
        m_walkOffset.y = g_gameConfig.getSpriteSize() - totalPixelsWalked;
    else if (m_direction == Otc::South || m_direction == Otc::SouthEast || m_direction == Otc::SouthWest)
        m_walkOffset.y = totalPixelsWalked - g_gameConfig.getSpriteSize();

    if (m_direction == Otc::East || m_direction == Otc::NorthEast || m_direction == Otc::SouthEast)
        m_walkOffset.x = totalPixelsWalked - g_gameConfig.getSpriteSize();
    else if (m_direction == Otc::West || m_direction == Otc::NorthWest || m_direction == Otc::SouthWest)
        m_walkOffset.x = g_gameConfig.getSpriteSize() - totalPixelsWalked;
}

void Creature::updateWalkingTile()
{
    // determine new walking tile
    TilePtr newWalkingTile;

    const Rect virtualCreatureRect(g_gameConfig.getSpriteSize() + (m_walkOffset.x - getDisplacementX()),
                                   g_gameConfig.getSpriteSize() + (m_walkOffset.y - getDisplacementY()),
                                   g_gameConfig.getSpriteSize(), g_gameConfig.getSpriteSize());

    for (int xi = -1; xi <= 1 && !newWalkingTile; ++xi) {
        for (int yi = -1; yi <= 1 && !newWalkingTile; ++yi) {
            Rect virtualTileRect((xi + 1) * g_gameConfig.getSpriteSize(), (yi + 1) * g_gameConfig.getSpriteSize(), g_gameConfig.getSpriteSize(), g_gameConfig.getSpriteSize());

            // only render creatures where bottom right is inside tile rect
            if (virtualTileRect.contains(virtualCreatureRect.bottomRight())) {
                newWalkingTile = g_map.getOrCreateTile(m_position.translated(xi, yi, 0));
            }
        }
    }

    if (newWalkingTile == m_walkingTile) return;

    const auto& self = static_self_cast<Creature>();

    if (m_walkingTile)
        m_walkingTile->removeWalkingCreature(self);

    if (newWalkingTile) {
        newWalkingTile->addWalkingCreature(self);
        g_map.notificateTileUpdate(newWalkingTile->getPosition(), self, Otc::OPERATION_CLEAN);
    }

    m_walkingTile = newWalkingTile;
}

void Creature::nextWalkUpdate()
{
    // remove any previous scheduled walk updates
    if (m_walkUpdateEvent)
        m_walkUpdateEvent->cancel();

    // do the update
    updateWalk();
    if (isLocalPlayer()) {
        g_map.notificateCameraMove(m_walkOffset);
    }

    if (!m_walking) return;

    // schedules next update
    auto self = static_self_cast<Creature>();
    m_walkUpdateEvent = g_dispatcher.scheduleEvent([self] {
        self->m_walkUpdateEvent = nullptr;
        self->nextWalkUpdate();
    }, m_stepCache.walkDuration);
}

void Creature::updateWalk(const bool isPreWalking)
{
    const float walkTicksPerPixel = getStepDuration(true) / static_cast<float>(g_gameConfig.getSpriteSize());

    const int totalPixelsWalked = std::min<int>(m_walkTimer.ticksElapsed() / walkTicksPerPixel, g_gameConfig.getSpriteSize());

    // needed for paralyze effect
    m_walkedPixels = std::max<int>(m_walkedPixels, totalPixelsWalked);

    updateWalkAnimation();
    updateWalkOffset(m_walkedPixels);
    updateWalkingTile();

    if (!isPreWalking && m_walkedPixels == g_gameConfig.getSpriteSize()) {
        terminateWalk();
    }
}

void Creature::terminateWalk()
{
    // remove any scheduled walk update
    if (m_walkUpdateEvent) {
        m_walkUpdateEvent->cancel();
        m_walkUpdateEvent = nullptr;
    }

    // now the walk has ended, do any scheduled turn
    if (m_walkTurnDirection != Otc::InvalidDirection) {
        setDirection(m_walkTurnDirection);
        m_walkTurnDirection = Otc::InvalidDirection;
    }

    if (m_walkingTile) {
        m_walkingTile->removeWalkingCreature(static_self_cast<Creature>());
        m_walkingTile = nullptr;
    }

    m_walkedPixels = 0;
    m_walkOffset = {};
    m_walking = false;

    const auto self = static_self_cast<Creature>();
    m_walkFinishAnimEvent = g_dispatcher.scheduleEvent([self] {
        self->m_walkAnimationPhase = 0;
        self->m_walkFinishAnimEvent = nullptr;
    }, g_game.getServerBeat());
}

void Creature::setHealthPercent(uint8_t healthPercent)
{
    static const Color
        COLOR1(0x00, 0xBC, 0x00),
        COLOR2(0x50, 0xA1, 0x50),
        COLOR3(0xA1, 0xA1, 0x00),
        COLOR4(0xBF, 0x0A, 0x0A),
        COLOR5(0x91, 0x0F, 0x0F),
        COLOR6(0x85, 0x0C, 0x0C);

    if (m_healthPercent == healthPercent) return;

    if (healthPercent > 92)
        m_informationColor = COLOR1;
    else if (healthPercent > 60)
        m_informationColor = COLOR2;
    else if (healthPercent > 30)
        m_informationColor = COLOR3;
    else if (healthPercent > 8)
        m_informationColor = COLOR4;
    else if (healthPercent > 3)
        m_informationColor = COLOR5;
    else
        m_informationColor = COLOR6;

    const uint8_t oldHealthPercent = m_healthPercent;
    m_healthPercent = healthPercent;

    callLuaField("onHealthPercentChange", healthPercent, oldHealthPercent);

    if (isDead())
        onDeath();
}

void Creature::setDirection(Otc::Direction direction)
{
    assert(direction != Otc::InvalidDirection);
    m_direction = direction;

    // xPattern => creature direction
    if (direction == Otc::NorthEast || direction == Otc::SouthEast)
        m_numPatternX = Otc::East;
    else if (direction == Otc::NorthWest || direction == Otc::SouthWest)
        m_numPatternX = Otc::West;
    else
        m_numPatternX = direction;

    setAttachedEffectDirection(static_cast<Otc::Direction>(m_numPatternX));
}

void Creature::setOutfit(const Outfit& outfit)
{
    if (m_outfit == outfit)
        return;

    const Outfit oldOutfit = m_outfit;

    m_outfit = outfit;
    m_thingType = nullptr;
    m_mountType = nullptr;
    m_numPatternZ = 0;
    m_exactSize = 0;
    m_walkAnimationPhase = 0; // might happen when player is walking and outfit is changed.

    if (m_outfit.isInvalid())
        m_outfit.setCategory(m_outfit.getAuxId() > 0 ? ThingCategoryItem : ThingCategoryCreature);

    m_thingType = g_things.getThingType(m_outfit.isCreature() ? m_outfit.getId() : m_outfit.getAuxId(), m_outfit.getCategory()).get();
    m_clientId = m_thingType->getId();

    if (m_outfit.hasMount()) {
        m_mountType = g_things.getThingType(m_outfit.getMount(), ThingCategoryCreature).get();
        m_numPatternZ = std::min<int>(1, getNumPatternZ() - 1);
    }

    if (const auto& tile = getTile())
        tile->checkForDetachableThing();

    callLuaField("onOutfitChange", m_outfit, oldOutfit);
}

void Creature::setSpeed(uint16_t speed)
{
    if (speed == m_speed)
        return;

    const uint16_t oldSpeed = m_speed;
    m_speed = speed;

    // Cache for stepSpeed Law
    if (hasSpeedFormula()) {
        speed *= 2;

        if (speed > -speedB) {
            m_calculatedStepSpeed = std::max<int>(1, floor((speedA * log((speed / 2.) + speedB) + speedC) + .5));
        } else m_calculatedStepSpeed = 1;
    }

    // speed can change while walking (utani hur, paralyze, etc..)
    if (m_walking)
        nextWalkUpdate();

    callLuaField("onSpeedChange", m_speed, oldSpeed);
}

void Creature::setBaseSpeed(uint16_t baseSpeed)
{
    if (m_baseSpeed == baseSpeed)
        return;

    const uint16_t oldBaseSpeed = m_baseSpeed;
    m_baseSpeed = baseSpeed;

    callLuaField("onBaseSpeedChange", baseSpeed, oldBaseSpeed);
}

void Creature::setType(uint8_t type) { callLuaField("onTypeChange", m_type = type); }
void Creature::setIcon(uint8_t icon) { callLuaField("onIconChange", m_icon = icon); }
void Creature::setSkull(uint8_t skull) { callLuaField("onSkullChange", m_skull = skull); }
void Creature::setShield(uint8_t shield) { callLuaField("onShieldChange", m_shield = shield); }
void Creature::setEmblem(uint8_t emblem) { callLuaField("onEmblemChange", m_emblem = emblem); }

void Creature::setTypeTexture(const std::string& filename) { m_typeTexture = g_textures.getTexture(filename); }
void Creature::setIconTexture(const std::string& filename) { m_iconTexture = g_textures.getTexture(filename); }
void Creature::setSkullTexture(const std::string& filename) { m_skullTexture = g_textures.getTexture(filename); }
void Creature::setEmblemTexture(const std::string& filename) { m_emblemTexture = g_textures.getTexture(filename); }

void Creature::setShieldTexture(const std::string& filename, bool blink)
{
    m_shieldTexture = g_textures.getTexture(filename);
    m_showShieldTexture = true;

    if (blink && !m_shieldBlink) {
        auto self = static_self_cast<Creature>();
        g_dispatcher.scheduleEvent([self] {
            self->updateShield();
        }, g_gameConfig.getShieldBlinkTicks());
    }

    m_shieldBlink = blink;
}

void Creature::addTimedSquare(uint8_t color)
{
    m_showTimedSquare = true;
    m_timedSquareColor = Color::from8bit(color);

    // schedule removal
    const auto self = static_self_cast<Creature>();
    g_dispatcher.scheduleEvent([self] {
        self->removeTimedSquare();
    }, g_gameConfig.getVolatileSquareDuration());
}

void Creature::updateShield()
{
    m_showShieldTexture = !m_showShieldTexture;

    if (m_shield != Otc::ShieldNone && m_shieldBlink) {
        auto self = static_self_cast<Creature>();
        g_dispatcher.scheduleEvent([self] {
            self->updateShield();
        }, g_gameConfig.getShieldBlinkTicks());
    } else if (!m_shieldBlink)
        m_showShieldTexture = true;
}

bool Creature::hasSpeedFormula() { return g_game.getFeature(Otc::GameNewSpeedLaw) && speedA != 0 && speedB != 0 && speedC != 0; }

uint16_t Creature::getStepDuration(bool ignoreDiagonal, Otc::Direction dir)
{
    if (m_speed < 1)
        return 0;

    const auto& tilePos = dir == Otc::InvalidDirection ?
        m_lastStepToPosition : m_position.translatedToDirection(dir);

    const auto& tile = g_map.getTile(tilePos.isValid() ? tilePos : m_position);

    int groundSpeed = 0;
    if (tile) groundSpeed = tile->getGroundSpeed();
    if (groundSpeed == 0)
        groundSpeed = 150;

    if (groundSpeed != m_stepCache.groundSpeed || m_speed != m_stepCache.speed) {
        m_stepCache.speed = m_speed;
        m_stepCache.groundSpeed = groundSpeed;

        uint32_t stepDuration = 1000 * groundSpeed;
        if (hasSpeedFormula()) {
            stepDuration /= m_calculatedStepSpeed;
        } else stepDuration /= m_speed;

        if (g_gameConfig.isForcingNewWalkingFormula() || g_game.getClientVersion() >= 860) {
            const int serverBeat = g_game.getServerBeat();
            stepDuration = ((stepDuration + serverBeat - 1) / serverBeat) * serverBeat;
        }

        m_stepCache.duration = stepDuration + 10;
        m_stepCache.walkDuration = std::min<int>(stepDuration / g_gameConfig.getSpriteSize(), DrawPool::FPS60);
        m_stepCache.diagonalDuration = stepDuration * (g_game.getClientVersion() > 810 || g_gameConfig.isForcingNewWalkingFormula() ? 3 : 2);
    }

    return ignoreDiagonal ? m_stepCache.duration : m_stepCache.getDuration(m_lastStepDirection);
}

Point Creature::getDisplacement() const
{
    if (m_outfit.isEffect())
        return { 8 };

    if (m_outfit.isItem())
        return {};

    return Thing::getDisplacement();
}

int Creature::getDisplacementX() const
{
    if (m_outfit.isEffect())
        return 8;

    if (m_outfit.isItem())
        return 0;

    if (m_outfit.hasMount())
        return m_mountType->getDisplacementX();

    return Thing::getDisplacementX();
}

int Creature::getDisplacementY() const
{
    if (m_outfit.isEffect())
        return 8;

    if (m_outfit.isItem())
        return 0;

    if (m_outfit.hasMount())
        return m_mountType->getDisplacementY();

    return Thing::getDisplacementY();
}

const Light& Creature::getLight() const
{
    const auto& light = Thing::getLight();
    return m_light.color > 0 && m_light.intensity >= light.intensity ? m_light : light;
}

uint16_t Creature::getCurrentAnimationPhase(const bool mount)
{
    const auto& thingType = mount ? m_mountType : getThingType();

    auto* idleAnimator = thingType->getIdleAnimator();
    if (idleAnimator) {
        if (m_walkAnimationPhase == 0) return idleAnimator->getPhase();
        return m_walkAnimationPhase + idleAnimator->getAnimationPhases() - 1;
    }

    if (thingType->isAnimateAlways()) {
        const int ticksPerFrame = std::round(1000 / thingType->getAnimationPhases());
        return (g_clock.millis() % (static_cast<long long>(ticksPerFrame) * thingType->getAnimationPhases())) / ticksPerFrame;
    }

    return isDisabledWalkAnimation() ? 0 : m_walkAnimationPhase;
}

int Creature::getExactSize(int layer, int xPattern, int yPattern, int zPattern, int animationPhase)
{
    if (m_exactSize > 0)
        return m_exactSize;

    uint8_t exactSize = 0;
    if (m_outfit.isCreature()) {
        const int numPatternY = getNumPatternY();
        const int layers = getLayers();

        zPattern = m_outfit.hasMount() ? 1 : 0;

        for (yPattern = 0; yPattern < numPatternY; ++yPattern) {
            if (yPattern > 0 && !(m_outfit.getAddons() & (1 << (yPattern - 1))))
                continue;

            for (int layer = 0; layer < layers; ++layer)
                exactSize = std::max<int>(exactSize, Thing::getExactSize(layer, 0, yPattern, zPattern, 0));
        }
    } else {
        exactSize = m_thingType->getExactSize();
    }

    return m_exactSize = std::max<uint8_t>(exactSize, g_gameConfig.getSpriteSize());
}

void Creature::setMountShader(const std::string_view name) { m_mountShader = g_shaders.getShader(name); }