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
#include <thread>
#include <client/game.h>
#include <client/map.h>
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

GraphicalApplication g_app;

void GraphicalApplication::init(std::vector<std::string>& args, uint8_t asyncDispatchMaxThreads)
{
    Application::init(args, asyncDispatchMaxThreads);

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
    g_drawPool.init(g_gameConfig.getSpriteSize());

    // fire first resize event
    resize(g_window.getSize());

#ifdef FRAMEWORK_SOUND
    // initialize sound
    g_sounds.init();
#endif

    m_frameCounter.init();
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

    const auto& foreground = g_drawPool.get(DrawPoolType::FOREGROUND);
    const auto& txt = g_drawPool.get(DrawPoolType::TEXT);
    const auto& map = g_drawPool.get(DrawPoolType::MAP);

    std::condition_variable foreCondition, txtCondition;

    UIWidgetPtr mapWidget;

    // clang c++20 dont support jthread
    std::thread t1([&]() {
        while (!m_stopping) {
            poll();

            if (!g_window.isVisible()) {
                stdext::millisleep(10);
                continue;
            }

            g_particles.poll();

            if (foreground->canRepaint())
                foreCondition.notify_one();

            if (g_game.isOnline()) {
                if (!mapWidget)
                    mapWidget = g_ui.getRootWidget()->recursiveGetChildById("gameMapPanel");

                if (txt->canRepaint())
                    txtCondition.notify_one();

                {
                    std::scoped_lock l(map->getMutex());
                    mapWidget->drawSelf(DrawPoolType::MAP);
                }
            } else mapWidget = nullptr;

            stdext::millisleep(1);
        }

        foreCondition.notify_one();
        txtCondition.notify_one();
    });

    std::thread t2([&]() {
        std::unique_lock lock(foreground->getMutex());
        foreCondition.wait(lock, [&]() -> bool {
            g_ui.render(DrawPoolType::FOREGROUND);
            return m_stopping;
        });
    });

    std::thread t3([&]() {
        std::unique_lock lock(txt->getMutex());
        txtCondition.wait(lock, [&]() -> bool {
            g_textDispatcher.poll();

            txt->setEnable(canDrawTexts());
            if (mapWidget && txt->isEnabled())
                mapWidget->drawSelf(DrawPoolType::TEXT);

            return m_stopping;
        });
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
        m_frameCounter.update();
    }

    t1.join();
    t2.join();
    t3.join();

    m_stopping = false;
    m_running = false;
}

void GraphicalApplication::poll()
{
    Application::poll();

#ifdef FRAMEWORK_SOUND
    g_sounds.poll();
#endif
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
            g_drawPool.get(DrawPoolType::TEXT)->setFramebuffer(size);
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
bool GraphicalApplication::canDrawTexts() const { return m_drawText && (!g_map.getStaticTexts().empty() || !g_map.getAnimatedTexts().empty()); }

bool GraphicalApplication::isLoadingAsyncTexture() { return m_loadingAsyncTexture || g_game.isUsingProtobuf(); }

void GraphicalApplication::setLoadingAsyncTexture(bool v) {
    if (g_game.isUsingProtobuf())
        v = true;
    else if (isEncrypted())
        v = false;

    m_loadingAsyncTexture = v;
    g_sprites.reload();
}