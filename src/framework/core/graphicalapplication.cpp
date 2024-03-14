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

#include "graphicalapplication.h"

#include <framework/core/asyncdispatcher.h>
#include <framework/core/clock.h>
#include <framework/core/eventdispatcher.h>
#include <framework/graphics/drawpool.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/graphics.h>
#include <framework/graphics/particlemanager.h>
#include <framework/graphics/texturemanager.h>
#include <framework/input/mouse.h>
#include <framework/platform/platformwindow.h>
#include <framework/ui/uimanager.h>
#include <framework/ui/uiwidget.h>
#include "framework/stdext/time.h"

#ifdef FRAMEWORK_SOUND
#include <framework/sound/soundmanager.h>
#endif

#include <thread>

GraphicalApplication g_app;

void GraphicalApplication::init(std::vector<std::string>& args, ApplicationContext* context)
{
    Application::init(args, context);

    GraphicalApplicationContext* graphicalContext = static_cast<GraphicalApplicationContext*>(context);
    setDrawEvents(graphicalContext->getDrawEvents());

    // setup platform window
    g_window.init();
    g_window.hide();

    g_window.setOnResize([this](auto&& PH1) {
        if (!m_running) resize(PH1);
        else g_dispatcher.addEvent([&, PH1] { resize(PH1); });
    });

    g_window.setOnInputEvent([this](auto&& PH1) {
        if (!m_running) inputEvent(PH1);
        else g_dispatcher.addEvent([&, PH1]() { inputEvent(PH1); });
    });

    g_window.setOnClose([this] { g_dispatcher.addEvent([&]() { close(); }); });

    g_mouse.init();

    // initialize ui
    g_ui.init();

    // initialize graphics
    g_graphics.init();
    g_drawPool.init(graphicalContext->getSpriteSize());

    // fire first resize event
    resize(g_window.getSize());

#ifdef FRAMEWORK_SOUND
    // initialize sound
    g_sounds.init();
#endif

    m_mapProcessFrameCounter.init();
    m_graphicFrameCounter.init();
}

void GraphicalApplication::deinit()
{
    // hide the window because there is no render anymore
    g_window.hide();

    Application::deinit();
}

void GraphicalApplication::terminate()
{
    // destroy particles
    g_particles.terminate();

    // destroy any remaining widget
    g_ui.terminate();

    Application::terminate();
    m_terminated = false;

#ifdef FRAMEWORK_SOUND
    // terminate sound
    g_sounds.terminate();
#endif

    g_mouse.terminate();

    // terminate graphics
    g_drawPool.terminate();
    g_graphics.terminate();
    g_window.terminate();

    m_terminated = true;
}

void GraphicalApplication::run()
{
    // run the first poll
    mainPoll();
    poll();

    // show window
    g_window.show();

    // run the second poll
    mainPoll();
    poll();

    g_lua.callGlobalField("g_app", "onRun");

    std::condition_variable foregroundUICondition, foregroundMapCondition;
    std::atomic_bool mapThreadStopping = false;
    std::atomic_uint8_t threadsOppeneds = 0;

    const auto& FPS = [&] {
        m_mapProcessFrameCounter.setTargetFps(g_window.vsyncEnabled() || getMaxFps() || getTargetFps() ? 500u : 999u);
        return m_graphicFrameCounter.getFps();
    };

    const auto& drawForeground = [&] {
        const auto& foregroundUI = g_drawPool.get(DrawPoolType::FOREGROUND);
        const auto& foregroundMap = g_drawPool.get(DrawPoolType::FOREGROUND_MAP);

        if (foregroundUI->canRepaint()) {
            if (m_drawEvents && m_drawEvents->canDraw(DrawPoolType::FOREGROUND))
                foregroundUICondition.notify_one();
            else
                g_ui.render(DrawPoolType::FOREGROUND);
        }

        if (m_drawEvents && m_drawEvents->canDraw(DrawPoolType::FOREGROUND_MAP) && foregroundMap->canRepaint())
            foregroundMapCondition.notify_one();
    };

    const auto& stopThread = [&]() {
        threadsOppeneds.fetch_sub(1);
        if (threadsOppeneds.load() == 0) {
            mapThreadStopping.store(true);
            mapThreadStopping.notify_one();
        }
    };

    // THREAD - FOREGROUND UI
    g_asyncDispatcher.dispatch([&] {
        threadsOppeneds.fetch_add(1);

        const auto& pool = g_drawPool.get(DrawPoolType::FOREGROUND);
        std::unique_lock lock(pool->getMutexPreDraw());
        foregroundUICondition.wait(lock, [this]() -> bool {
            if (m_drawEvents && m_drawEvents->canDraw(DrawPoolType::FOREGROUND))
                g_ui.render(DrawPoolType::FOREGROUND);
            return m_stopping;
        });

        stopThread();
    });

    // THREAD - FOREGROUND MAP
    g_asyncDispatcher.dispatch([&] {
        threadsOppeneds.fetch_add(1);

        const auto& pool = g_drawPool.get(DrawPoolType::FOREGROUND_MAP);
        std::unique_lock lock(pool->getMutexPreDraw());
        foregroundMapCondition.wait(lock, [this]() -> bool {
            if (m_drawEvents)
                m_drawEvents->drawForgroundMap();
            return m_stopping;
        });

        stopThread();
    });

    // THREAD - POOL & MAP
    g_asyncDispatcher.dispatch([&] {
        threadsOppeneds.fetch_add(1);

        g_eventThreadId = EventDispatcher::getThreadId();
        while (!m_stopping) {
            poll();

            if (!g_window.isVisible()) {
                stdext::millisleep(10);
                continue;
            }

            if (m_drawEvents)
                m_drawEvents->preLoad();

            drawForeground();

            if (m_drawEvents)
                m_drawEvents->drawMap();

            m_mapProcessFrameCounter.update();
        }

        foregroundUICondition.notify_one();
        foregroundMapCondition.notify_one();

        stopThread();
    });

    m_running = true;
    while (!m_stopping) {
        mainPoll();

        if (!g_window.isVisible()) {
            stdext::millisleep(10);
            continue;
        }

        g_drawPool.draw();

        // update screen pixels
        g_window.swapBuffers();

        if (m_graphicFrameCounter.update()) {
            g_dispatcher.addEvent([this, fps = FPS()] {
                g_lua.callGlobalField("g_app", "onFps", fps);
            });
        }
    }

    mapThreadStopping.wait(false);
    m_running = false;
    m_stopping = false;
}

void GraphicalApplication::poll()
{
    Application::poll();

#ifdef FRAMEWORK_SOUND
    g_sounds.poll();
#endif

    g_particles.poll();

    if (!g_window.isVisible()) {
        g_textDispatcher.poll();
    }
}
void GraphicalApplication::mainPoll()
{
    g_clock.update();
    g_mainDispatcher.poll();
    g_window.poll();
    g_textures.poll();
}

void GraphicalApplication::close()
{
    m_onInputEvent = true;
    Application::close();
    m_onInputEvent = false;
}

static constexpr bool USE_FRAMEBUFFER = false;
void GraphicalApplication::resize(const Size& size)
{
    const float scale = g_window.getDisplayDensity();
    g_graphics.resize(size);

    m_onInputEvent = true;
    g_ui.resize(size / scale);
    m_onInputEvent = false;

    g_mainDispatcher.addEvent([size, scale] {
        g_drawPool.get(DrawPoolType::FOREGROUND)->setFramebuffer(size / scale);

        if (USE_FRAMEBUFFER) {
            g_drawPool.get(DrawPoolType::CREATURE_INFORMATION)->setFramebuffer(size);
            g_drawPool.get(DrawPoolType::FOREGROUND_MAP)->setFramebuffer(size);
        }
    });
}

void GraphicalApplication::inputEvent(const InputEvent& event)
{
    m_onInputEvent = true;
    g_ui.inputEvent(event);
    m_onInputEvent = false;
}

void GraphicalApplication::repaintMap() { g_drawPool.get(DrawPoolType::MAP)->repaint(); }
void GraphicalApplication::repaint() { g_drawPool.get(DrawPoolType::FOREGROUND)->repaint(); }
bool GraphicalApplication::isLoadingAsyncTexture() { return m_loadingAsyncTexture || (m_drawEvents && m_drawEvents->isLoadingAsyncTexture()); }

void GraphicalApplication::setLoadingAsyncTexture(bool v) {
    if (m_drawEvents && m_drawEvents->isUsingProtobuf())
        v = true;
    else if (isEncrypted())
        v = false;

    m_loadingAsyncTexture = v;

    if (m_drawEvents)
        m_drawEvents->onLoadingAsyncTextureChanged(v);
}