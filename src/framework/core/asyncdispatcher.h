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

#ifndef ASYNCDISPATCHER_H
#define ASYNCDISPATCHER_H

#include <future>

class AsyncDispatcher
{
public:
    void init();
    void terminate();

    void spawn_thread();
    void stop();

    template<class F>
    std::shared_future<typename std::invoke_result<F>::type> schedule(const F& task)
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        auto prom = std::make_shared<std::promise<typename std::invoke_result<F>::type>>();
        m_tasks.push_back([=]() { prom->set_value(task()); });
        m_condition.notify_all();
        return std::shared_future<typename std::invoke_result<F>::type>(prom->get_future());
    }

    void dispatch(std::function<void()> f)
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_tasks.push_back(f);
        m_condition.notify_all();
    }

protected:
    void exec_loop();

private:
    std::list<std::function<void()>> m_tasks;
    std::list<std::thread> m_threads;
    std::mutex m_mutex;
    std::condition_variable m_condition;
    bool m_running{ false };
};

extern AsyncDispatcher g_asyncDispatcher;

#endif
