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

#include "attachedeffect.h"
#include "shadermanager.h"
#include "spritemanager.h"
#include "thingtypemanager.h"

#include <framework/core/clock.h>

AttachedEffectPtr AttachedEffect::clone() const
{
    auto obj = std::make_shared<AttachedEffect>();
    *(obj.get()) = *this;
    return obj;
}

AttachedEffectPtr AttachedEffect::create(uint16_t id, uint16_t thingId, ThingCategory category) {
    if (!g_things.isValidDatId(thingId, category)) {
        g_logger.error(stdext::format("invalid thing with id %d on create AttachedEffect.", thingId));
        return nullptr;
    }

    const auto& obj = std::make_shared<AttachedEffect>();
    obj->m_id = id;
    obj->m_thingType = g_things.getThingType(thingId, category).get();
    return obj;
}

void AttachedEffect::draw(const Point& dest, bool isOnTop, LightView* lightView) {
    if (m_transform)
        return;

    const auto& dirControl = m_offsetDirections[m_direction];
    if (dirControl.onTop != isOnTop)
        return;

    if (!m_canDrawOnUI && g_drawPool.getCurrentType() == DrawPoolType::FOREGROUND)
        return;

    const int animation = getCurrentAnimationPhase();
    if (m_loop > -1 && animation != m_lastAnimation) {
        m_lastAnimation = animation;
        if (animation == 0) {
            --m_loop;
            g_logger.info(std::to_string(getLoop()));
        }
    }

    if (m_shader) g_drawPool.setShaderProgram(m_shader, true);
    if (m_opacity < 100) g_drawPool.setOpacity(getOpacity(), true);
    m_thingType->draw(dest - (dirControl.offset * g_drawPool.getScaleFactor()), 0, m_direction, 0, 0, animation, Otc::DrawThingsAndLights, Color::white, lightView);
}

int AttachedEffect::getCurrentAnimationPhase()
{
    const auto* animator = m_thingType->getIdleAnimator();
    if (!animator && m_thingType->isAnimateAlways())
        animator = m_thingType->getAnimator();

    if (animator)
        return animator->getPhaseAt(m_animationTimer, getSpeed());

    if (m_thingType->isEffect()) {
        const int lastPhase = m_thingType->getAnimationPhases() - 1;
        const int phase = std::min<int>(static_cast<int>(m_animationTimer.ticksElapsed() / (EFFECT_TICKS_PER_FRAME / getSpeed())), lastPhase);
        if (phase == lastPhase) m_animationTimer.restart();
        return phase;
    }

    if (m_thingType->isCreature() && m_thingType->isAnimateAlways()) {
        const int ticksPerFrame = std::round(1000 / m_thingType->getAnimationPhases()) / getSpeed();
        return (g_clock.millis() % (static_cast<long long>(ticksPerFrame) * m_thingType->getAnimationPhases())) / ticksPerFrame;
    }

    return 0;
}

void AttachedEffect::setShader(const std::string_view name) { m_shader = g_shaders.getShader(name); }
