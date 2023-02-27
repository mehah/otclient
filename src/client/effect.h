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

#include <framework/global.h>
#include <framework/core/timer.h>
#include "thing.h"

 // @bindclass
class Effect : public Thing
{
public:
    void drawEffect(const Point& dest, uint32_t flags, int offsetX, int offsetY, LightView* lightView = nullptr);

    void setId(uint32_t id) override;
    void setPosition(const Position& position, uint8_t stackPos = 0, bool hasElevation = false) override;

    bool isEffect() override { return true; }
    bool waitFor(const EffectPtr&);

    EffectPtr asEffect() { return static_self_cast<Effect>(); }

protected:
    void onAppear() override;

private:
    Timer m_animationTimer;

    uint16_t m_duration{ 0 };
    uint16_t m_timeToStartDrawing{ 0 };
};
