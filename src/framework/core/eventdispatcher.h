/*
 * Copyright (c) 2010-2024 OTClient <https://github.com/edubart/otclient>
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

#include "scheduledevent.h"

// @bindsingleton g_dispatcher
class EventDispatcher
{
public:
    EventDispatcher() {
        m_threads.emplace_back(std::make_unique<ThreadTask>());
    }

    void init();
    void shutdown();
    void poll();

    EventPtr addEvent(const std::function<void()>& callback);
    void asyncEvent(std::function<void()>&& callback);
    void deferEvent(const std::function<void()>& callback);
    ScheduledEventPtr scheduleEvent(const std::function<void()>& callback, int delay);
    ScheduledEventPtr cycleEvent(const std::function<void()>& callback, int delay);

    void startEvent(const ScheduledEventPtr& event);

private:
    inline void mergeEvents();
    inline void executeEvents();
    inline void executeAsyncEvents();
    inline void executeDeferEvents();
    inline void executeScheduledEvents();

    const auto& getThreadTask() const {
        const auto id = stdext::getThreadId();
        bool grow = false;

        {
            std::shared_lock l(m_sharedLock);
            grow = id >= static_cast<int16_t>(m_threads.size());
        }

        if (grow) {
            std::unique_lock l(m_sharedLock);
            for (auto i = static_cast<int16_t>(m_threads.size()); i <= id; ++i)
                m_threads.emplace_back(std::make_unique<ThreadTask>());
        }

        return m_threads[id];
    }

    size_t m_pollEventsSize{};
    bool m_disabled{ false };

    // Thread Events
    struct ThreadTask
    {
        ThreadTask() {
            events.reserve(2000);
            scheduledEventList.reserve(2000);
        }

        std::vector<EventPtr> events;
        std::vector<Event> deferEvents;
        std::vector<Event> asyncEvents;
        std::vector<ScheduledEventPtr> scheduledEventList;
        std::mutex mutex;
    };
    mutable std::vector<std::unique_ptr<ThreadTask>> m_threads;
    mutable std::shared_mutex m_sharedLock;

    // Main Events
    std::vector<EventPtr> m_eventList;
    std::vector<Event> m_deferEventList;
    std::vector<Event> m_asyncEventList;
    phmap::btree_multiset<ScheduledEventPtr, ScheduledEvent::Compare> m_scheduledEventList;
};

extern EventDispatcher g_dispatcher, g_textDispatcher, g_mainDispatcher;
extern int16_t g_mainThreadId;
extern int16_t g_eventThreadId;
