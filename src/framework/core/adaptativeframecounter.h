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

 /**
  * Class that help counting and limiting frames per second in a application,
  */
class AdaptativeFrameCounter
{
public:
    AdaptativeFrameCounter() : m_interval(stdext::millis()) { }

    void init() { m_timer.restart(); }
    void update();

    uint16_t getFps() const { return m_fps; }
    uint8_t getMaxFps() const { return m_maxFps; }
    uint8_t getTargetFps() const { return m_targetFps; }

    void setMaxFps(const uint16_t max) { m_maxFps = max; }
    void setTargetFps(const uint16_t target) { m_targetFps = target; }

    void resetTargetFps() { m_targetFps = 0; }

private:
    uint32_t getMaxPeriod(uint16_t fps) const { return 1000000u / fps; }

    uint8_t m_maxFps{};
    uint8_t m_targetFps{ 60u };

    uint16_t m_fps{};
    uint16_t m_fpsCount{};

    uint32_t m_interval{};

    stdext::timer m_timer;
};
