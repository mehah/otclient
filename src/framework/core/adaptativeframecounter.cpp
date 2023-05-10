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

#include "adaptativeframecounter.h"
#include <framework/core/eventdispatcher.h>
#include <framework/platform/platformwindow.h>

void AdaptativeFrameCounter::update()
{
    const uint8_t maxFps = m_targetFps == 0 ? m_maxFps : std::clamp<uint8_t>(m_targetFps, 1, std::max<uint8_t>(m_maxFps, m_targetFps));
    if (maxFps > 0) {
        const int32_t sleepPeriod = (getMaxPeriod(maxFps) - 1000) - m_timer.elapsed_micros();
        if (sleepPeriod > 0) stdext::microsleep(sleepPeriod);
    }

    m_timer.restart();

    ++m_fpsCount;

    const uint32_t tickCount = stdext::millis();
    if (tickCount - m_interval <= 1000)
        return;

    if (m_fps != m_fpsCount) {
        m_fps = m_fpsCount;
        m_fpsCount = 0;
        m_interval = tickCount;

        g_dispatcher.addEvent([this] { g_lua.callGlobalField("g_app", "onFps", getFps()); });
    }
}