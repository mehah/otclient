/*
 * Copyright (c) 2010-2020 OTClient <https://github.com/edubart/otclient>
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

#include "effect.h"
#include <framework/core/eventdispatcher.h>
#include <framework/core/graphicalapplication.h>
#include "game.h"
#include "map.h"

void Effect::drawEffect(const Point& dest, float scaleFactor, LightView* lightView)
{
    if (m_id == 0 || !canDraw()) return;

    // It only starts to draw when the first effect as it is about to end.
    if (m_animationTimer.ticksElapsed() < m_timeToStartDrawing)
        return;

    int animationPhase;
    if (g_game.getFeature(Otc::GameEnhancedAnimations)) {
        const auto& animator = rawGetThingType()->getIdleAnimator();
        if (!animator)
            return;

        // This requires a separate getPhaseAt method as using getPhase would make all magic effects use the same phase regardless of their appearance time
        animationPhase = rawGetThingType()->getIdleAnimator()->getPhaseAt(m_animationTimer);
    } else {
        // hack to fix some animation phases duration, currently there is no better solution
        int ticks = EFFECT_TICKS_PER_FRAME;
        if (m_id == 33) {
            ticks <<= 2;
        }

        animationPhase = std::min<int>(static_cast<int>(m_animationTimer.ticksElapsed() / ticks), getAnimationPhases() - 1);
    }

    const int xPattern = m_position.x % getNumPatternX();
    const int yPattern = m_position.y % getNumPatternY();

    rawGetThingType()->draw(dest, scaleFactor, 0, xPattern, yPattern, 0, animationPhase, TextureType::NONE, Color::white, lightView);
}

void Effect::onAppear()
{
    if (g_game.getFeature(Otc::GameEnhancedAnimations)) {
        const auto& animator = getThingType()->getIdleAnimator();
        if (!animator)
            return;

        m_duration = animator->getTotalDuration();
    } else {
        m_duration = EFFECT_TICKS_PER_FRAME;

        // hack to fix some animation phases duration, currently there is no better solution
        if (m_id == 33) {
            m_duration <<= 2;
        }

        m_duration *= getAnimationPhases();
    }

    m_animationTimer.restart();

    // schedule removal
    const auto self = asEffect();
    g_dispatcher.scheduleEvent([self]() { g_map.removeThing(self); }, m_duration);
}

void Effect::waitFor(const EffectPtr& effect)
{
    m_timeToStartDrawing = effect->m_duration * (g_app.canOptimize() || g_app.isForcedEffectOptimization() ? .7 : .5);
}

void Effect::setId(uint32 id)
{
    if (!g_things.isValidDatId(id, ThingCategoryEffect))
        id = 0;

    m_id = id;
}

const ThingTypePtr& Effect::getThingType()
{
    return g_things.getThingType(m_id, ThingCategoryEffect);
}

ThingType* Effect::rawGetThingType()
{
    return g_things.rawGetThingType(m_id, ThingCategoryEffect);
}
