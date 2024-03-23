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

#include "asyncdispatcher.h"

AsyncDispatcher g_asyncDispatcher;

void AsyncDispatcher::init(uint8_t maxThreads)
{
    /*
    * -1 = Graphic
    *  1 = Map and (Connection, Particle and Sound) Pool
    *  2 = Foreground UI
    *  3 = Foreground MAP
    *  4 = Extra, ex: pathfinder and lighting system
    */
    const uint8_t minThreads = 4;

    if (maxThreads == 0)
        maxThreads = 6;

    // 2 = Min Threads
    int_fast8_t threads = std::clamp<int_fast8_t>(std::thread::hardware_concurrency() - 1, minThreads, maxThreads);
    while (--threads >= 0)
        m_threads.emplace_back([this] { m_ioService.run(); });
}

void AsyncDispatcher::terminate() { stop(); }

void AsyncDispatcher::stop()
{
    if (m_ioService.stopped()) {
        return;
    }

    m_ioService.stop();

    for (auto& thread : m_threads) {
        if (thread.joinable())
            thread.join();
    }
};