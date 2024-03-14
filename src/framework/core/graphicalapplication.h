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

#include "application.h"

#include <framework/graphics/declarations.h>
#include <framework/core/adaptativeframecounter.h>
#include <framework/core/inputevent.h>
#include <framework/core/timer.h>
#include <framework/platform/platformwindow.h>

class ApplicationDrawEvents
{
protected:
    virtual void preLoad() = 0;
    virtual void drawMap() = 0;
    virtual void drawForgroundMap() = 0;

    virtual bool canDraw(DrawPoolType type) const = 0;
    virtual bool isLoadingAsyncTexture() = 0;
    virtual bool isUsingProtobuf() = 0;
    virtual void onLoadingAsyncTextureChanged(bool loadingAsync) = 0;

    friend class GraphicalApplication;
};

class GraphicalApplicationContext : public ApplicationContext
{
public:
    GraphicalApplicationContext(uint8_t asyncDispatchMaxThreads, uint8_t spriteSize, ApplicationDrawEventsPtr drawEvents) :
        ApplicationContext(asyncDispatchMaxThreads),
        m_spriteSize(spriteSize),
        m_drawEvents(drawEvents)
    {}

    void setSpriteSize(uint8_t size) { m_spriteSize = size; }
    uint8_t getSpriteSize() { return m_spriteSize; }

    void setDrawEvents(ApplicationDrawEventsPtr drawEvents) { m_drawEvents = drawEvents; }
    ApplicationDrawEventsPtr getDrawEvents() { return m_drawEvents; }

protected:
    uint8_t m_spriteSize;
    ApplicationDrawEventsPtr m_drawEvents;
};

class GraphicalApplication : public Application
{
public:
    void init(std::vector<std::string>& args, ApplicationContext* context) override;
    void deinit() override;
    void terminate() override;
    void run() override;
    void poll() override;
    void mainPoll();
    void close() override;

    void setMaxFps(uint16_t maxFps) { m_graphicFrameCounter.setMaxFps(maxFps); }
    void setTargetFps(uint16_t targetFps) { m_graphicFrameCounter.setTargetFps(targetFps); }

    uint16_t getFps() { return m_graphicFrameCounter.getFps(); }
    uint8_t getMaxFps() { return m_graphicFrameCounter.getMaxFps(); }
    uint8_t getTargetFps() { return m_graphicFrameCounter.getTargetFps(); }

    void resetTargetFps() { m_graphicFrameCounter.resetTargetFps(); }

    bool isOnInputEvent() { return m_onInputEvent; }
    bool mustOptimize() {
#ifdef NDEBUG
        return m_optimize && getMaxFps() >= getFps() && getFps() < 58u;
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
    bool isDrawingTexts() { return m_drawText; }

    float getCreatureInformationScale() const { return m_creatureInformationScale; }
    void setCreatureInformationScale(float v) { m_creatureInformationScale = v; }

    float getAnimatedTextScale() const { return m_animatedTextScale; }
    void setAnimatedTextScale(float v) { m_animatedTextScale = v; }

    float getStaticTextScale() const { return m_staticTextScale; }
    void setStaticTextScale(float v) { m_staticTextScale = v; }

    bool isLoadingAsyncTexture();
    void setLoadingAsyncTexture(bool v);

    bool isScaled() { return g_window.getDisplayDensity() != PlatformWindow::DEFAULT_DISPLAY_DENSITY; }

    bool isEncrypted() {
#if ENABLE_ENCRYPTION == 1
        return true;
#else
        return false;
#endif
    }

    void repaint();
    void repaintMap();

    void setDrawEvents(const ApplicationDrawEventsPtr& drawEvents) { m_drawEvents = drawEvents; }

protected:
    void resize(const Size& size);
    void inputEvent(const InputEvent& event);

private:
    bool m_onInputEvent{ false };
    bool m_optimize{ true };
    bool m_forceEffectOptimization{ false };
    bool m_drawEffectOnTop{ false };
    bool m_drawText{ true };
    bool m_loadingAsyncTexture{ false };

    float m_creatureInformationScale{ PlatformWindow::DEFAULT_DISPLAY_DENSITY };
    float m_animatedTextScale{ PlatformWindow::DEFAULT_DISPLAY_DENSITY };
    float m_staticTextScale{ PlatformWindow::DEFAULT_DISPLAY_DENSITY };

    AdaptativeFrameCounter m_mapProcessFrameCounter;
    AdaptativeFrameCounter m_graphicFrameCounter;

    ApplicationDrawEventsPtr m_drawEvents;
};

extern GraphicalApplication g_app;
