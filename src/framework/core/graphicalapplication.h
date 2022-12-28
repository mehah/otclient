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

#include <framework/core/adaptativeframecounter.h>
#include <framework/core/inputevent.h>
#include <framework/core/timer.h>
#include <framework/graphics/declarations.h>

#include "application.h"

class GraphicalApplication : public Application
{
public:
    void init(std::vector<std::string>& args) override;
    void deinit() override;
    void terminate() override;
    void run() override;
    void poll() override;
    void close() override;

    void setMaxFps(int maxFps) { m_frameCounter.setMaxFps(maxFps); }

    int getFps() { return m_frameCounter.getFps(); }
    int getMaxFps() { return m_frameCounter.getMaxFps(); }

    bool isOnInputEvent() { return m_onInputEvent; }
    bool mustOptimize() {
#ifdef NDEBUG
        return m_optimize && getMaxFps() >= getFps() && getFps() < 58;
#else
        return false;
#endif
    }
    bool isForcedEffectOptimization() { return m_forceEffectOptimization; }

    void optimize(const bool optimize) { m_optimize = optimize; }

    void forceEffectOptimization(const bool optimize) { m_forceEffectOptimization = optimize; }
    void setDrawEffectOnTop(const bool draw) { m_drawEffectOnTop = draw; }
    bool isDrawingEffectsOnTop() { return m_drawEffectOnTop || mustOptimize(); }

    void setDrawTexts(bool v) { m_drawText = v; }
    bool isDrawingTexts();

    void repaint();

protected:
    void resize(const Size& size);
    void inputEvent(const InputEvent& event);

private:
    bool m_onInputEvent{ false };
    bool m_optimize{ true };
    bool m_forceEffectOptimization{ false };
    bool m_drawEffectOnTop{ false };
    bool m_drawText{ true };

    AdaptativeFrameCounter m_frameCounter;
};

extern GraphicalApplication g_app;
