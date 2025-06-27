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

#include "creature.h"
#include "game.h"
#include "lightview.h"
#include "localplayer.h"
#include "luavaluecasts_client.h"
#include "map.h"
#include "thingtypemanager.h"
#include "tile.h"

#include <framework/core/clock.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/graphicalapplication.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/shadermanager.h>
#include <framework/graphics/texturemanager.h>
#include <framework/ui/uiwidget.h>

#include "statictext.h"

double Creature::speedA = 0;
double Creature::speedB = 0;
double Creature::speedC = 0;

Creature::Creature() :m_type(Proto::CreatureTypeUnknown)
{
    m_name.setFont(g_gameConfig.getCreatureNameFont());
    m_name.setAlign(Fw::AlignTopCenter);
    m_typingIconTexture = g_textures.getTexture(g_gameConfig.getTypingIcon());
}

Creature::~Creature() {
    setWidgetInformation(nullptr);
}

void Creature::onCreate() {
    callLuaField("onCreate");
}

void Creature::draw(const Point& dest, const bool drawThings, const LightViewPtr& /*lightView*/)
{
    if (!canBeSeen() || !canDraw())
        return;

    if (drawThings) {
        if (m_showTimedSquare) {
            g_drawPool.addBoundingRect(Rect(dest + (m_walkOffset - getDisplacement() + 2) * g_drawPool.getScaleFactor(), Size(28 * g_drawPool.getScaleFactor())), m_timedSquareColor, std::max<int>(static_cast<int>(2 * g_drawPool.getScaleFactor()), 1));
        }

        if (m_showStaticSquare) {
            g_drawPool.addBoundingRect(Rect(dest + (m_walkOffset - getDisplacement()) * g_drawPool.getScaleFactor(), Size(g_gameConfig.getSpriteSize() * g_drawPool.getScaleFactor())), m_staticSquareColor, std::max<int>(static_cast<int>(2 * g_drawPool.getScaleFactor()), 1));
        }

        auto _dest = dest + m_walkOffset * g_drawPool.getScaleFactor();

        auto oldScaleFactor = g_drawPool.getScaleFactor();

        g_drawPool.setScaleFactor(getScaleFactor() + (oldScaleFactor - 1.f));

        if (oldScaleFactor != g_drawPool.getScaleFactor()) {
            _dest -= ((Point(g_gameConfig.getSpriteSize()) + getDisplacement()) / 2) * (g_drawPool.getScaleFactor() - oldScaleFactor);
        }

        internalDraw(_dest);

        if (isMarked())
            internalDraw(_dest, getMarkedColor());
        else if (isHighlighted())
            internalDraw(_dest, getHighlightColor());

        g_drawPool.setScaleFactor(oldScaleFactor);
    }

    // drawLight(dest, lightView);
}

void Creature::drawLight(const Point& dest, const LightViewPtr& lightView) {
    if (!lightView) return;

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

    drawAttachedLightEffect(dest + m_walkOffset * g_drawPool.getScaleFactor(), lightView);
}

void Creature::draw(const Rect& destRect, const uint8_t size, const bool center)
{
    if (!canDraw())
        return;

    uint8_t frameSize = getExactSize();
    if (size > 0)
        frameSize = std::max<int>(frameSize * (size / 100.f), 2 * g_gameConfig.getSpriteSize() * (size / 100.f));

    g_drawPool.bindFrameBuffer(frameSize); {
        auto p = Point(frameSize - g_gameConfig.getSpriteSize()) + getDisplacement();
        if (center)
            p /= 2;

        internalDraw(p);
        if (isMarked())
            internalDraw(p, getMarkedColor());
        else if (isHighlighted())
            internalDraw(p, getHighlightColor());
    } g_drawPool.releaseFrameBuffer(destRect);
}

void Creature::drawInformation(const MapPosInfo& mapRect, const Point& dest, const int drawFlags)
{
    static constexpr Color
        DEFAULT_COLOR(96, 96, 96),
        NPC_COLOR(0x66, 0xcc, 0xff);

    if (isDead() || !canBeSeen() || !(drawFlags & Otc::DrawCreatureInfo) || !mapRect.isInRange(getPosition()))
        return;

    if (g_gameConfig.isDrawingInformationByWidget()) {
        if (m_widgetInformation)
            m_widgetInformation->draw(mapRect.rect, DrawPoolType::FOREGROUND);
        return;
    }

    const auto displacementX = g_game.getFeature(Otc::GameNegativeOffset) ? 0 : getDisplacementX();
    const auto displacementY = g_game.getFeature(Otc::GameNegativeOffset) ? 0 : getDisplacementY();

    const auto& parentRect = mapRect.rect;
    const auto& creatureOffset = Point(16 - displacementX, -displacementY - 2) + getDrawOffset();

    Point p = dest - mapRect.drawOffset;
    p += (creatureOffset - Point(std::round(m_jumpOffset.x), std::round(m_jumpOffset.y))) * mapRect.scaleFactor;
    p.x *= mapRect.horizontalStretchFactor;
    p.y *= mapRect.verticalStretchFactor;
    p += parentRect.topLeft();

    auto fillColor = DEFAULT_COLOR;

    if (!isCovered()) {
        if (g_game.getFeature(Otc::GameBlueNpcNameColor) && isNpc() && isFullHealth())
            fillColor = NPC_COLOR;
        else fillColor = m_informationColor;
    }

    // calculate main rects

    const auto& nameSize = m_name.getTextSize();
    const int cropSizeText = g_gameConfig.isAdjustCreatureInformationBasedCropSize() ? getExactSize() : 12;
    const int cropSizeBackGround = g_gameConfig.isAdjustCreatureInformationBasedCropSize() ? cropSizeText - nameSize.height() : 0;

    const bool isScaled = g_app.getCreatureInformationScale() != PlatformWindow::DEFAULT_DISPLAY_DENSITY;
    if (isScaled) {
        p.scale(g_app.getCreatureInformationScale());
    }

    auto backgroundRect = Rect(p.x - (13.5), p.y - cropSizeBackGround, 27, 4);
    auto textRect = Rect(p.x - nameSize.width() / 2.0, p.y - cropSizeText, nameSize);

    if (!isScaled) {
        backgroundRect.bind(parentRect);
        textRect.bind(parentRect);
    }

    // distance them
    uint8_t offset = 12 * mapRect.scaleFactor;
    if (isLocalPlayer()) {
        offset *= 2 * mapRect.scaleFactor;
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

        if (m_text) {
            auto extraTextSize = m_text->getTextSize();
            Rect extraTextRect = Rect(p.x - extraTextSize.width() / 2.0, p.y + 15, extraTextSize);
            m_text->drawText(extraTextRect.center(), extraTextRect);
        }
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

    if (g_gameConfig.drawTyping() && getTyping() && m_typingIconTexture)
        g_drawPool.addTexturedPos(m_typingIconTexture, p.x + (nameSize.width() / 2.0) + 2, textRect.y() - 4);

    if (g_game.getClientVersion() >= 1281 && m_icons && !m_icons->atlasGroups.empty()) {
        int iconOffset = 0;
        for (const auto& iconTex : m_icons->atlasGroups) {
            if (!iconTex.texture) continue;
            const Rect dest(backgroundRect.x() + 13.5 + 12, backgroundRect.y() + 5 + iconOffset * 14, iconTex.clip.size());
            g_drawPool.addTexturedRect(dest, iconTex.texture, iconTex.clip);
            m_icons->numberText.setText(std::to_string(iconTex.count));
            const auto textSize = m_icons->numberText.getTextSize();
            const Rect numberRect(dest.right() + 2, dest.y() + (dest.height() - textSize.height()) / 2, textSize);
            m_icons->numberText.draw(numberRect, Color::white);
            ++iconOffset;
        }
    }
}

void Creature::internalDraw(Point dest, const Color& color)
{
    // Example of how to send a UniformValue to shader
    /*const auto& shaderAction = [this]()-> void {
        const int id = m_outfit.isCreature() ? m_outfit.getId() : m_outfit.getAuxId();
        m_shader->bind();
        m_shader->setUniformValue(ShaderManager::OUTFIT_ID_UNIFORM, id);
    };*/

    const bool replaceColorShader = color != Color::white;
    if (replaceColorShader)
        g_drawPool.setShaderProgram(g_painter->getReplaceColorShader());
    else
        drawAttachedEffect(dest, nullptr, false); // On Bottom

    if (!isHided()) {
        // outfit is a real creature
        if (m_outfit.isCreature()) {
            if (m_outfit.hasMount()) {
                dest -= getMountThingType()->getDisplacement() * g_drawPool.getScaleFactor();

                if (!replaceColorShader && hasMountShader()) {
                    g_drawPool.setShaderProgram(g_shaders.getShaderById(m_mountShaderId), true/*, [this]()-> void {
                        m_mountShader->bind();
                        m_mountShader->setUniformValue(ShaderManager::MOUNT_ID_UNIFORM, m_outfit.getMount());
                    }*/);
                }
                getMountThingType()->draw(dest, 0, m_numPatternX, 0, 0, getCurrentAnimationPhase(true), color);

                dest += getDisplacement() * g_drawPool.getScaleFactor();
            }

            if (!m_jumpOffset.isNull()) {
                const auto& jumpOffset = m_jumpOffset * g_drawPool.getScaleFactor();
                dest -= Point(std::round(jumpOffset.x), std::round(jumpOffset.y));
            } else if (m_bounce.height > 0 && m_bounce.speed > 0) {
                const auto minHeight = m_bounce.minHeight * g_drawPool.getScaleFactor();
                const auto height = m_bounce.height * g_drawPool.getScaleFactor();
                dest -= (minHeight * 1.f) + std::abs((m_bounce.speed / 2) - g_clock.millis() % m_bounce.speed) / (m_bounce.speed * 1.f) * height;
            }

            const auto& datType = getThingType();
            const int animationPhase = getCurrentAnimationPhase();
            const bool useFramebuffer = !replaceColorShader && hasShader() && g_shaders.getShaderById(m_shaderId)->useFramebuffer();

            const auto& drawCreature = [&](const Point& dest) {
                // yPattern => creature addon
                for (int yPattern = 0; yPattern < getNumPatternY(); ++yPattern) {
                    // continue if we dont have this addon
                    if (yPattern > 0 && !(m_outfit.getAddons() & (1 << (yPattern - 1))))
                        continue;

                    if (!replaceColorShader && hasShader() && !useFramebuffer) {
                        g_drawPool.setShaderProgram(g_shaders.getShaderById(m_shaderId), true/*, shaderAction*/);
                    }

                    datType->draw(dest, 0, m_numPatternX, yPattern, m_numPatternZ, animationPhase, color);

                    if (m_drawOutfitColor && !replaceColorShader && getLayers() > 1) {
                        g_drawPool.setCompositionMode(CompositionMode::MULTIPLY);
                        datType->draw(dest, SpriteMaskYellow, m_numPatternX, yPattern, m_numPatternZ, animationPhase, m_outfit.getHeadColor());
                        datType->draw(dest, SpriteMaskRed, m_numPatternX, yPattern, m_numPatternZ, animationPhase, m_outfit.getBodyColor());
                        datType->draw(dest, SpriteMaskGreen, m_numPatternX, yPattern, m_numPatternZ, animationPhase, m_outfit.getLegsColor());
                        datType->draw(dest, SpriteMaskBlue, m_numPatternX, yPattern, m_numPatternZ, animationPhase, m_outfit.getFeetColor());
                        g_drawPool.resetCompositionMode();
                    }
                }
            };

            if (useFramebuffer) {
                const int size = static_cast<int>(g_gameConfig.getSpriteSize() * std::max<int>(datType->getSize().area(), 2) * g_drawPool.getScaleFactor());
                const auto& p = (Point(size) - Point(datType->getExactHeight())) / 2;
                const auto& destFB = Rect(dest - p, Size{ size });

                g_drawPool.setShaderProgram(g_shaders.getShaderById(m_shaderId), true/*, shaderAction*/);

                g_drawPool.bindFrameBuffer(destFB.size());
                drawCreature(p);
                g_drawPool.releaseFrameBuffer(destFB);
                g_drawPool.resetShaderProgram();
            } else drawCreature(dest);

            // outfit is a creature imitating an item or the invisible effect
        } else {
            int animationPhases = getThingType()->getAnimationPhases();
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

            if (!replaceColorShader && hasShader())
                g_drawPool.setShaderProgram(g_shaders.getShaderById(m_shaderId), true/*, shaderAction*/);
            getThingType()->draw(dest - (getDisplacement() * g_drawPool.getScaleFactor()), 0, 0, 0, 0, animationPhase, color);
        }
    }

    if (replaceColorShader)
        g_drawPool.resetShaderProgram();
    else {
        drawAttachedEffect(dest, nullptr, true); // On Top
        drawAttachedParticlesEffect(dest);
    }
}

void Creature::turn(const Otc::Direction direction)
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

void Creature::jump(const int height, const int duration)
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

    if (isCameraFollowing()) {
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

    if (isCameraFollowing() && m_position != m_oldPosition) {
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

    int footAnimPhases = m_outfit.hasMount() ? getMountThingType()->getAnimationPhases() : getAnimationPhases();
    if (!g_game.getFeature(Otc::GameEnhancedAnimations) && footAnimPhases > 2) {
        --footAnimPhases;
    }

    // looktype has no animations
    if (footAnimPhases == 0)
        return;

    // diagonal walk is taking longer than the animation, thus why don't animate continously
    if (m_walkTimer.ticksElapsed() < getStepDuration() && m_walkedPixels == g_gameConfig.getSpriteSize()) {
        m_walkAnimationPhase = 0;
        return;
    }

    int minFootDelay = 20;
    const int maxFootDelay = footAnimPhases > 2 ? 80 : 205;
    int footAnimDelay = footAnimPhases;

    if (g_game.getFeature(Otc::GameEnhancedAnimations) && footAnimPhases > 2) {
        minFootDelay += 10;
        if (footAnimDelay > 1)
            footAnimDelay /= 1.5;
    }

    const auto walkSpeed = m_walkingAnimationSpeed > 0 ? m_walkingAnimationSpeed : m_stepCache.getDuration(m_lastStepDirection);
    const int footDelay = std::clamp<int>(walkSpeed / footAnimDelay, minFootDelay, maxFootDelay);

    if (m_footTimer.ticksElapsed() >= footDelay) {
        if (m_walkAnimationPhase == footAnimPhases) m_walkAnimationPhase = 1;
        else ++m_walkAnimationPhase;

        m_footTimer.restart();
    }
}

void Creature::updateWalkOffset(const uint8_t totalPixelsWalked)
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

    const auto displacementX = g_game.getFeature(Otc::GameNegativeOffset) ? 0 : getDisplacementX();
    const auto displacementY = g_game.getFeature(Otc::GameNegativeOffset) ? 0 : getDisplacementY();

    const Rect virtualCreatureRect(g_gameConfig.getSpriteSize() + (m_walkOffset.x - displacementX),
        g_gameConfig.getSpriteSize() + (m_walkOffset.y - displacementY),
        g_gameConfig.getSpriteSize(), g_gameConfig.getSpriteSize());

    for (int xi = -1; xi <= 1 && !newWalkingTile; ++xi) {
        for (int yi = -1; yi <= 1 && !newWalkingTile; ++yi) {
            Rect virtualTileRect((xi + 1) * g_gameConfig.getSpriteSize(), (yi + 1) * g_gameConfig.getSpriteSize(), g_gameConfig.getSpriteSize(), g_gameConfig.getSpriteSize());

            // only render creatures where bottom right is inside tile rect
            if (virtualTileRect.contains(virtualCreatureRect.bottomRight())) {
                newWalkingTile = g_map.getOrCreateTile(getPosition().translated(xi, yi, 0));
            }
        }
    }

    if (newWalkingTile == m_walkingTile) return;

    const auto& self = static_self_cast<Creature>();

    if (m_walkingTile)
        m_walkingTile->removeWalkingCreature(self);

    if (newWalkingTile) {
        newWalkingTile->addWalkingCreature(self);
        if (isCameraFollowing())
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
    onWalking();

    if (!m_walking) return;

    auto action = [self = static_self_cast<Creature>()] {
        self->m_walkUpdateEvent = nullptr;
        self->nextWalkUpdate();
    };

    m_walkUpdateEvent = isCameraFollowing() ? g_dispatcher.addEvent(action) : g_dispatcher.scheduleEvent(action, m_stepCache.walkDuration);
}

void Creature::updateWalk()
{
    const int stepDuration = getStepDuration(true);
    const float stabilizeCam = isCameraFollowing() && g_window.vsyncEnabled() ? 6.f : 0.f;
    const float walkTicksPerPixel = (stepDuration + stabilizeCam) / static_cast<float>(g_gameConfig.getSpriteSize());

    const int totalPixelsWalked = std::min<int>(m_walkTimer.ticksElapsed() / walkTicksPerPixel, g_gameConfig.getSpriteSize());

    // needed for paralyze effect
    m_walkedPixels = std::max<int>(m_walkedPixels, totalPixelsWalked);

    const auto oldWalkOffset = m_walkOffset;

    updateWalkAnimation();
    updateWalkOffset(m_walkedPixels);
    updateWalkingTile();

    if (isCameraFollowing() && oldWalkOffset != m_walkOffset) {
        g_map.notificateCameraMove(m_walkOffset);
    }

    if (m_walkedPixels == g_gameConfig.getSpriteSize()) {
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

void Creature::setHealthPercent(const uint8_t healthPercent)
{
    static constexpr Color
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

void Creature::setDirection(const Otc::Direction direction)
{
    if (direction == Otc::InvalidDirection)
        return;

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
    m_numPatternZ = 0;
    m_exactSize = 0;
    m_walkAnimationPhase = 0; // might happen when player is walking and outfit is changed.

    if (m_outfit.isInvalid())
        m_outfit.setCategory(m_outfit.getAuxId() > 0 ? ThingCategoryItem : ThingCategoryCreature);

    m_clientId = getThingType()->getId();

    if (m_outfit.hasMount()) {
        m_numPatternZ = std::min<int>(1, getNumPatternZ() - 1);
    }

    if ((g_game.getFeature(Otc::GameWingsAurasEffectsShader))) {
        m_outfit.setWing(0);
        m_outfit.setAura(0);
        m_outfit.setEffect(0);
        m_outfit.setShader("Outfit - Default");
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

void Creature::setBaseSpeed(const uint16_t baseSpeed)
{
    if (m_baseSpeed == baseSpeed)
        return;

    const uint16_t oldBaseSpeed = m_baseSpeed;
    m_baseSpeed = baseSpeed;

    callLuaField("onBaseSpeedChange", baseSpeed, oldBaseSpeed);
}

void Creature::setType(const uint8_t v) { if (m_type != v) callLuaField("onTypeChange", m_type = v); }
void Creature::setIcon(const uint8_t v) { if (m_icon != v) callLuaField("onIconChange", m_icon = v); }
void Creature::setIcons(const std::vector<std::tuple<uint8_t, uint8_t, uint16_t>>& icons)
{
    if (!m_icons) {
        m_icons = std::make_unique<IconRenderData>();
        m_icons->numberText.setFont(g_gameConfig.getStaticTextFont());
        m_icons->numberText.setAlign(Fw::AlignCenter);
    }

    m_icons->atlasGroups.clear();
    m_icons->iconEntries = icons;

    for (const auto& [icon, category, count] : icons) {
        callLuaField("onIconsChange", icon, category, count);
    }
}
void Creature::setSkull(const uint8_t v) { if (m_skull != v) callLuaField("onSkullChange", m_skull = v); }
void Creature::setShield(const uint8_t v) { if (m_shield != v) callLuaField("onShieldChange", m_shield = v); }
void Creature::setEmblem(const uint8_t v) { if (m_emblem != v) callLuaField("onEmblemChange", m_emblem = v); }

void Creature::setTypeTexture(const std::string& filename) { m_typeTexture = g_textures.getTexture(filename); }
void Creature::setIconTexture(const std::string& filename) { m_iconTexture = g_textures.getTexture(filename); }
void Creature::setIconsTexture(const std::string& filename, const Rect& clip, const uint16_t count)
{
    if (!m_icons) {
        m_icons = std::make_unique<IconRenderData>();
        m_icons->numberText.setFont(g_gameConfig.getStaticTextFont());
        m_icons->numberText.setAlign(Fw::AlignCenter);
    }

    m_icons->atlasGroups.emplace_back(IconRenderData::AtlasIconGroup{ g_textures.getTexture(filename), clip, count });
}
void Creature::setSkullTexture(const std::string& filename) { m_skullTexture = g_textures.getTexture(filename); }
void Creature::setEmblemTexture(const std::string& filename) { m_emblemTexture = g_textures.getTexture(filename); }

void Creature::setShieldTexture(const std::string& filename, const bool blink)
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

void Creature::addTimedSquare(const uint8_t color)
{
    m_showTimedSquare = true;
    m_timedSquareColor = Color::from8bit(color != 0 ? color : 1);

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

int getSmoothedElevation(const Creature* creature, const int currentElevation, const float factor) {
    const auto& fromPos = creature->getLastStepFromPosition();
    const auto& toPos = creature->getLastStepToPosition();
    const auto& fromTile = g_map.getTile(fromPos);
    const auto& toTile = g_map.getTile(toPos);

    if (!fromTile || !toTile) {
        return currentElevation;
    }

    const int fromElevation = fromTile->getDrawElevation();
    const int toElevation = toTile->getDrawElevation();

    return fromElevation != toElevation ? fromElevation + factor * (toElevation - fromElevation) : currentElevation;
}

int Creature::getDrawElevation() {
    int elevation = 0;
    if (m_walkingTile) {
        elevation = m_walkingTile->getDrawElevation();

        if (g_game.getFeature(Otc::GameSmoothWalkElevation)) {
            const float factor = std::clamp<float>(getWalkTicksElapsed() / static_cast<float>(m_stepCache.getDuration(m_lastStepDirection)), .0f, 1.f);
            elevation = getSmoothedElevation(this, elevation, factor);
        }
    } else if (const auto& tile = getTile())
        elevation = tile->getDrawElevation();

    return elevation;
}

bool Creature::hasSpeedFormula() { return g_game.getFeature(Otc::GameNewSpeedLaw) && speedA != 0 && speedB != 0 && speedC != 0; }

uint16_t Creature::getStepDuration(const bool ignoreDiagonal, const Otc::Direction dir)
{
    if (m_speed < 1)
        return 0;

    const auto& tilePos = dir == Otc::InvalidDirection ?
        m_lastStepToPosition : getPosition().translatedToDirection(dir);

    const auto& tile = g_map.getTile(tilePos.isValid() ? tilePos : getPosition());

    const int serverBeat = g_game.getServerBeat();

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
            stepDuration = ((stepDuration + serverBeat - 1) / serverBeat) * serverBeat;
        }

        m_stepCache.duration = stepDuration;

        m_stepCache.walkDuration = std::min<int>(stepDuration / g_gameConfig.getSpriteSize(), DrawPool::FPS60);

        m_stepCache.diagonalDuration = stepDuration *
            (g_game.getClientVersion() > 810 || g_gameConfig.isForcingNewWalkingFormula()
                ? (isPlayer() ? g_gameConfig.getPlayerDiagonalWalkSpeed() : g_gameConfig.getCreatureDiagonalWalkSpeed())
                : 2);
    }

    auto duration = ignoreDiagonal ? m_stepCache.duration : m_stepCache.getDuration(m_lastStepDirection);

    if (isCameraFollowing() && g_game.getFeature(Otc::GameLatencyAdaptiveCamera) && static_self_cast<LocalPlayer>()->isPreWalking()) {
        if (m_lastMapDuration == -1)
            m_lastMapDuration = ((g_game.mapUpdatedAt() + 9) / 10) * 10;

        // stabilizes camera transition with server response time to keep movement fluid.
        duration = std::max<int>(duration, m_lastMapDuration);
    }

    return duration;
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
        return getMountThingType()->getDisplacementX();

    return Thing::getDisplacementX();
}

int Creature::getDisplacementY() const
{
    if (m_outfit.isEffect())
        return 8;

    if (m_outfit.isItem())
        return 0;

    if (m_outfit.hasMount())
        return getMountThingType()->getDisplacementY();

    return Thing::getDisplacementY();
}

const Light& Creature::getLight() const
{
    const auto& light = Thing::getLight();
    return m_light.color > 0 && m_light.intensity >= light.intensity ? m_light : light;
}

ThingType* Creature::getThingType() const {
    return g_things.getRawThingType(m_outfit.isCreature() ? m_outfit.getId() : m_outfit.getAuxId(), m_outfit.getCategory());
}

ThingType* Creature::getMountThingType() const {
    return m_outfit.hasMount() ? g_things.getRawThingType(m_outfit.getMount(), ThingCategoryCreature) : nullptr;
}

uint16_t Creature::getCurrentAnimationPhase(const bool mount)
{
    if (!canAnimate()) return 0;

    const auto thingType = mount ? getMountThingType() : getThingType();

    if (const auto idleAnimator = thingType->getIdleAnimator()) {
        if (m_walkAnimationPhase == 0) return idleAnimator->getPhase();
        return m_walkAnimationPhase + idleAnimator->getAnimationPhases() - 1;
    }

    if (thingType->isAnimateAlways()) {
        const int ticksPerFrame = std::round(1000 / thingType->getAnimationPhases());
        return (g_clock.millis() % (static_cast<long long>(ticksPerFrame) * thingType->getAnimationPhases())) / ticksPerFrame;
    }

    return isDisabledWalkAnimation() ? 0 : m_walkAnimationPhase;
}

int Creature::getExactSize(int layer, int /*xPattern*/, int yPattern, int zPattern, int /*animationPhase*/)
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

            for (layer = 0; layer < layers; ++layer)
                exactSize = std::max<int>(exactSize, Thing::getExactSize(layer, 0, yPattern, zPattern, 0));
        }
    } else {
        exactSize = getThingType()->getExactSize();
    }

    return m_exactSize = std::max<uint8_t>(exactSize, g_gameConfig.getSpriteSize());
}

void Creature::setMountShader(const std::string_view name) {
    m_mountShaderId = 0;
    if (name.empty())
        return;

    if (const auto& shader = g_shaders.getShader(name))
        m_mountShaderId = shader->getId();
}

void Creature::setTypingIconTexture(const std::string& filename)
{
    m_typingIconTexture = g_textures.getTexture(filename);
}

void Creature::setTyping(const bool typing)
{
    m_typing = typing;
}

void Creature::sendTyping() {
    g_game.sendTyping(m_typing);
}

void Creature::onStartAttachEffect(const AttachedEffectPtr& effect) {
    if (effect->isDisabledWalkAnimation()) {
        setDisableWalkAnimation(true);
    }

    if (effect->getThingType() && (effect->getThingType()->isCreature() || effect->getThingType()->isMissile()))
        effect->m_direction = getDirection();
}

void Creature::onDispatcherAttachEffect(const AttachedEffectPtr& effect) {
    if (effect->isTransform() && effect->getThingType()) {
        const auto& outfit = getOutfit();
        if (outfit.isTemp())
            return;

        effect->m_outfitOwner = outfit;

        Outfit newOutfit = outfit;
        newOutfit.setTemp(true);
        newOutfit.setCategory(effect->getThingType()->getCategory());
        if (newOutfit.isCreature())
            newOutfit.setId(effect->getThingType()->getId());
        else
            newOutfit.setAuxId(effect->getThingType()->getId());

        setOutfit(newOutfit);
    }
}

void Creature::onStartDetachEffect(const AttachedEffectPtr& effect) {
    if (effect->isDisabledWalkAnimation())
        setDisableWalkAnimation(false);

    if (effect->isTransform() && !effect->m_outfitOwner.isInvalid()) {
        setOutfit(effect->m_outfitOwner);
    }
}

void Creature::setStaticWalking(const uint16_t v) {
    if (!canDraw())
        return;

    if (m_walkUpdateEvent) {
        m_walkUpdateEvent->cancel();
        m_walkUpdateEvent = nullptr;
    }

    m_walkingAnimationSpeed = v;

    if (v == 0) {
        m_walkAnimationPhase = 0;
        return;
    }

    m_walkUpdateEvent = g_dispatcher.cycleEvent([self = static_self_cast<Creature>()] {
        self->updateWalkAnimation();
        if (self.use_count() == 1) {
            self->m_walkUpdateEvent->cancel();
        }
    }, std::min<int>(v / g_gameConfig.getSpriteSize(), DrawPool::FPS60));
}

void Creature::setWidgetInformation(const UIWidgetPtr& info) {
    if (m_widgetInformation == info)
        return;

    if (m_widgetInformation && !m_widgetInformation->isDestroyed()) {
        g_map.removeAttachedWidgetFromObject(m_widgetInformation);
    }

    m_widgetInformation = info;

    if (!info)
        return;

    info->setDraggable(false);
    g_map.addAttachedWidgetToObject(info, std::static_pointer_cast<AttachableObject>(shared_from_this()));
}

void Creature::setName(const std::string_view name) {
    if (name == m_name.getText())
        return;

    const auto& oldName = m_name.getText();
    m_name.setText(name);
    callLuaField("onChangeName", name, oldName);
}

void Creature::setCovered(bool covered) {
    if (m_isCovered == covered)
        return;

    const auto oldCovered = m_isCovered;
    m_isCovered = covered;

    g_dispatcher.addEvent([self = static_self_cast<Creature>(), covered, oldCovered] {
        self->callLuaField("onCovered", covered, oldCovered);
    });
}

void Creature::setText(const std::string& text, const Color& color)
{
    if (!m_text) {
        m_text = std::make_shared<StaticText>();
    }
    m_text->setText(text);
    m_text->setColor(color);
}

std::string Creature::getText()
{
    if (!m_text) {
        return "";
    }
    return m_text->getText();
}

bool Creature::canShoot(int distance)
{
    return getTile() ? getTile()->canShoot(distance) : false;
}