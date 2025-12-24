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

#include "paperdoll.h"
#include "animator.h"
#include "thingtype.h"

#include <framework/graphics/paintershaderprogram.h>
#include <framework/graphics/shadermanager.h>
#include <framework/core/clock.h>
#include <framework/graphics/drawpoolmanager.h>

PaperdollPtr Paperdoll::clone()
{
    auto obj = std::make_shared<Paperdoll>();
    *(obj.get()) = *this;

    return obj;
}

void Paperdoll::draw(const Point& dest, uint16_t animationPhase, bool mount, bool isOnTop, bool drawThings, LightView* lightView) {
    if (!m_thingType)
        return;

    const auto& dirControl = m_offsetDirections[m_direction];
    if (dirControl.onTop != isOnTop)
        return;

    if (!m_canDrawOnUI && g_drawPool.getCurrentType() == DrawPoolType::FOREGROUND)
        return;

    if (m_shader) g_drawPool.setShaderProgram(m_shader, true);
    if (m_opacity < 100) g_drawPool.setOpacity(getOpacity(), true);

    const auto& point = dest - (dirControl.offset * g_drawPool.getScaleFactor());
    const int animation = animationPhase == 0 ? getCurrentAnimationPhase() : animationPhase;

    if (!drawThings) {
        m_thingType->draw(point, 0, m_direction, 0, 0, animation, Color::white, false, lightView);
    } else {
        if (!m_onlyAddon)
            m_thingType->draw(point, 0, m_direction, 0, 0, animation, Color::white, drawThings, lightView);

        for (int yPattern = 0; yPattern < m_thingType->getNumPatternY(); ++yPattern) {
            if (yPattern == 0 && m_onlyAddon)
                continue;

            // continue if we dont have this addon
            if (yPattern > 0 && !(m_addons & (1 << (yPattern - 1))))
                continue;

            if (m_shader)
                g_drawPool.setShaderProgram(m_shader, true);

            m_thingType->draw(point, 0, m_direction, yPattern, static_cast<uint8_t>(mount), animation, Color::white);

            if (m_thingType->getLayers() > 1) {
                g_drawPool.setCompositionMode(CompositionMode::MULTIPLY);
                m_thingType->draw(dest, SpriteMaskYellow, m_direction, yPattern, static_cast<uint8_t>(mount), animationPhase, getHeadColor());
                m_thingType->draw(dest, SpriteMaskRed, m_direction, yPattern, static_cast<uint8_t>(mount), animationPhase, getBodyColor());
                m_thingType->draw(dest, SpriteMaskGreen, m_direction, yPattern, static_cast<uint8_t>(mount), animationPhase, getLegsColor());
                m_thingType->draw(dest, SpriteMaskBlue, m_direction, yPattern, static_cast<uint8_t>(mount), animationPhase, getFeetColor());
                g_drawPool.resetCompositionMode();
            }
        }
    }
}

void Paperdoll::drawLight(const Point& dest, bool mount, LightView* lightView) {
    if (!lightView) return;

    const auto& dirControl = m_offsetDirections[m_direction];
    draw(dest, 0, mount, dirControl.onTop, false, lightView);
}

int Paperdoll::getCurrentAnimationPhase()
{
    const auto* animator = m_thingType->getIdleAnimator();
    if (!animator && m_thingType->isAnimateAlways())
        animator = m_thingType->getAnimator();

    if (animator)
        return animator->getPhaseAt(m_animationTimer, getSpeed());

    if (m_thingType->isCreature() && m_thingType->isAnimateAlways()) {
        const int ticksPerFrame = std::round(1000 / m_thingType->getAnimationPhases()) / getSpeed();
        return (g_clock.millis() % (static_cast<long long>(ticksPerFrame) * m_thingType->getAnimationPhases())) / ticksPerFrame;
    }

    return 0;
}

void Paperdoll::setShader(const std::string_view name) { m_shader = g_shaders.getShader(name); }