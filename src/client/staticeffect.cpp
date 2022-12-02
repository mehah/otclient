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

#include "staticeffect.h"
#include "thingtypemanager.h"
#include "spritemanager.h"

StaticEffectPtr StaticEffect::create(uint16_t id, uint16_t thingId, ThingCategory category) {
    if (!g_things.isValidDatId(thingId, category)) {
        g_logger.error(stdext::format("invalid thing with id %d on create StaticEffect.", thingId));
        return nullptr;
    }

    const StaticEffectPtr& obj(new StaticEffect);
    obj->m_id = id;
    obj->m_thingType = g_things.getThingType(thingId, category).get();
    return obj;
}

void StaticEffect::draw(const Point& dest, bool isOnTop, LightView* lightView) {
    const auto& dirControl = m_offsetDirections[m_direction];
    if (dirControl.onTop != isOnTop)
        return;

    const auto* animator = m_thingType->getIdleAnimator();
    if (!animator) {
        if (!m_thingType->isAnimateAlways())
            return;

        animator = m_thingType->getAnimator();
    }

    m_thingType->draw(dest - (dirControl.offset * g_sprites.getScaleFactor()), 0, m_direction, 0, 0, animator->getPhaseAt(m_animationTimer, m_speed), Otc::DrawThingsAndLights, TextureType::NONE, Color::white, lightView);
    if (m_shader) g_drawPool.setShaderProgram(m_shader, true);
}
