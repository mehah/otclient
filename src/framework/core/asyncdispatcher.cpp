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

uint8_t getThreadCount() {
    /*
    * -1 = Graphic (Main Thread)
    * 1 = Map and (Connection, Particle and Sound) Pool
    * 2 = Foreground UI
    * 3 = Foreground MAP
    * 4 = Extra (pathfinder, lighting system, async texture loading)
    */

    static constexpr auto MIN_THREADS = 4u;
    static constexpr auto MAX_THREADS = 12u;

    return std::clamp<int_fast8_t>(std::thread::hardware_concurrency() + 1, MIN_THREADS, MAX_THREADS);
}

BS::thread_pool g_asyncDispatcher{ getThreadCount() };