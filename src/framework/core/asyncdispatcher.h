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

#include <asio.hpp>
#include <thread>

class AsyncDispatcher
{
public:
    void init(uint8_t maxThreads = 0);
    void terminate();

    void stop();

    template<class F>
    std::shared_future<std::invoke_result_t<F>> schedule(const F& task)
    {
        const auto& prom = std::make_shared<std::promise<std::invoke_result_t<F>>>();
        dispatch([=] { prom->set_value(task()); });
        return std::shared_future<std::invoke_result_t<F>>(prom->get_future());
    }

    void dispatch(std::function<void()>&& f)
    {
        asio::post(m_ioService, [this, f = std::move(f)]() {
            if (!m_ioService.stopped())
                f();
        });
    }

    inline auto getNumberOfThreads() const {
        return m_threads.size();
    }

private:
    asio::io_context m_ioService;
    std::vector<std::thread> m_threads;
    asio::io_context::work m_work{ m_ioService };
};

extern AsyncDispatcher g_asyncDispatcher;
