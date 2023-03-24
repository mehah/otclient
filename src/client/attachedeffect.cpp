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
#include <framework/graphics/animatedtexture.h>
#include <framework/graphics/texturemanager.h>

AttachedEffectPtr AttachedEffect::clone() const
{
    auto obj = std::make_shared<AttachedEffect>();
    *(obj.get()) = *this;
    return obj;
}

AttachedEffectPtr AttachedEffect::create(uint16_t id, uint16_t thingId, ThingCategory category) {
    if (!g_things.isValidDatId(thingId, category)) {
        g_logger.error(stdext::format("AttachedEffect::create(%d): invalid thing with id %d.", id, thingId));
        return nullptr;
    }

    const auto& obj = std::make_shared<AttachedEffect>();
    obj->m_id = id;
    obj->m_thingType = g_things.getThingType(thingId, category).get();
    return obj;
}

AttachedEffectPtr AttachedEffect::createUsingImage(uint16_t id, const std::string_view path, bool smooth) {
    const auto& texture = g_textures.getTexture(path.data(), smooth);
    if (!texture)
        return nullptr;

    if (!texture->isAnimatedTexture()) {
        g_logger.error(stdext::format("AttachedEffect::createUsingImage(%d): only animated texture is allowed.", id));
        return nullptr;
    }

    const auto& animatedTexture = std::static_pointer_cast<AnimatedTexture>(texture);
    animatedTexture->setOnMap(true);
    animatedTexture->restart();

    const auto& obj = std::make_shared<AttachedEffect>();
    obj->m_id = id;
    obj->m_texture = texture;
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
        if (animation == 0)
            --m_loop;
    }

    if (m_shader) g_drawPool.setShaderProgram(m_shader, true);
    if (m_opacity < 100) g_drawPool.setOpacity(getOpacity(), true);

    const auto& point = dest - (dirControl.offset * g_drawPool.getScaleFactor());

    if (m_texture) {
        g_drawPool.addTexturedRect(Rect(point, m_texture->getSize()), m_texture);
    } else {
        m_thingType->draw(point, 0, m_direction, 0, 0, animation, Otc::DrawThingsAndLights, Color::white, lightView);
    }
}

int AttachedEffect::getCurrentAnimationPhase()
{
    if (m_texture)
        return 0;

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

int8_t AttachedEffect::getLoop() {
    return m_texture ? std::static_pointer_cast<AnimatedTexture>(m_texture)->running() ? -1 : 0 : m_loop;
}

void AttachedEffect::setLoop(int8_t v) {
    if (m_texture) {
        std::static_pointer_cast<AnimatedTexture>(m_texture)->setNumPlays(v);
        return;
    }

    m_loop = v;
}
