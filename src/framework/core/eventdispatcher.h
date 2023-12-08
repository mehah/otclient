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

#include "clock.h"
#include "scheduledevent.h"

#include <thread>

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
    void deferEvent(const std::function<void()>& callback);
    ScheduledEventPtr scheduleEvent(const std::function<void()>& callback, int delay);
    ScheduledEventPtr cycleEvent(const std::function<void()>& callback, int delay);

    void startEvent(const ScheduledEventPtr& event);

    static int16_t getThreadId() {
        static std::atomic_int16_t lastId = -1;
        thread_local static int16_t id = -1;

        if (id == -1) {
            lastId.fetch_add(1);
            id = lastId.load();
        }

        return id;
    };

private:
    inline void mergeEvents();
    inline void executeEvents();
    inline void executeDeferEvents();
    inline void executeScheduledEvents();

    const auto& getThreadTask() const {
        return m_threads[getThreadId()];
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
        std::vector<ScheduledEventPtr> scheduledEventList;
        std::mutex mutex;
    };
    std::vector<std::unique_ptr<ThreadTask>> m_threads;

    // Main Events
    std::vector<EventPtr> m_eventList;
    std::vector<Event> m_deferEventList;
    phmap::btree_multiset<ScheduledEventPtr, ScheduledEvent::Compare> m_scheduledEventList;
};

extern EventDispatcher g_dispatcher, g_textDispatcher, g_mainDispatcher;
extern int16_t g_mainThreadId;
extern int16_t g_eventThreadId;
