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

#include "adaptativeframecounter.h"

bool AdaptativeFrameCounter::canRefresh()
{
    if (m_maxFps == 0) return true;

    m_currentTime = stdext::millis();
    return m_currentTime - m_lastTime >= 1000 / m_maxFps;
}

bool AdaptativeFrameCounter::update()
{
    ++m_fpsCount;

    m_lastTime = m_currentTime;

    const uint tickCount = stdext::millis();
    if (tickCount - m_interval <= 1000)
        return false;

    const bool fpsChanged = m_fps != m_fpsCount;
    if (fpsChanged) {
        m_fps = m_fpsCount;
        m_fpsCount = 0;
        m_interval = tickCount;
    }

    return fpsChanged;
}
