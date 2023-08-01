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

#include "eventdispatcher.h"

#include <framework/core/clock.h>
#include "timer.h"

EventDispatcher g_dispatcher, g_textDispatcher, g_mainDispatcher;
std::thread::id g_mainThreadId = std::this_thread::get_id();

void EventDispatcher::shutdown()
{
    while (!m_eventList.empty())
        poll();

    while (!m_scheduledEventList.empty()) {
        m_scheduledEventList.top()->cancel();
        m_scheduledEventList.pop();
    }

    m_disabled = true;
}

void EventDispatcher::poll()
{
    {
        std::scoped_lock l(m_mutex);
        for (int count = 0, max = m_scheduledEventList.size(); count < max && !m_scheduledEventList.empty(); ++count) {
            const auto scheduledEvent = m_scheduledEventList.top();
            if (scheduledEvent->remainingTicks() > 0)
                break;

            m_scheduledEventList.pop();
            scheduledEvent->execute();

            if (scheduledEvent->nextCycle())
                m_scheduledEventList.push(scheduledEvent);
        }
    }

    const bool isMainDispatcher = &g_mainDispatcher == this;
    std::unique_lock ul(m_mutex);

    // execute events list until all events are out, this is needed because some events can schedule new events that would
    // change the UIWidgets layout, in this case we must execute these new events before we continue rendering,
    m_pollEventsSize = m_eventList.size();
    int_fast32_t loops = 0;
    while (m_pollEventsSize > 0) {
        if (loops > 50) {
            static Timer reportTimer;
            if (reportTimer.running() && reportTimer.ticksElapsed() > 100) {
                g_logger.error("ATTENTION the event list is not getting empty, this could be caused by some bad code");
                reportTimer.restart();
            }
            break;
        }

        for (int_fast32_t i = -1; ++i < static_cast<int_fast32_t>(m_pollEventsSize);) {
            const auto event = m_eventList.front();
            m_eventList.pop_front();
            if (isMainDispatcher) ul.unlock();
            event->execute();
            if (isMainDispatcher) ul.lock();
        }
        m_pollEventsSize = m_eventList.size();

        ++loops;
    }
}

ScheduledEventPtr EventDispatcher::scheduleEvent(const std::function<void()>& callback, int delay)
{
    if (m_disabled)
        return std::make_shared<ScheduledEvent>(nullptr, delay, 1);

    std::scoped_lock<std::recursive_mutex> lock(m_mutex);

    assert(delay >= 0);
    const auto& scheduledEvent = std::make_shared<ScheduledEvent>(callback, delay, 1);
    m_scheduledEventList.emplace(scheduledEvent);
    return scheduledEvent;
}

ScheduledEventPtr EventDispatcher::cycleEvent(const std::function<void()>& callback, int delay)
{
    if (m_disabled)
        return std::make_shared<ScheduledEvent>(nullptr, delay, 0);

    std::scoped_lock<std::recursive_mutex> lock(m_mutex);

    assert(delay > 0);
    const auto& scheduledEvent = std::make_shared<ScheduledEvent>(callback, delay, 0);
    m_scheduledEventList.emplace(scheduledEvent);
    return scheduledEvent;
}

EventPtr EventDispatcher::addEvent(const std::function<void()>& callback, bool pushFront)
{
    if (m_disabled)
        return std::make_shared<Event>(nullptr);

    if (&g_mainDispatcher == this && g_mainThreadId == std::this_thread::get_id()) {
        callback();
        return std::make_shared<Event>(nullptr);
    }

    std::scoped_lock<std::recursive_mutex> lock(m_mutex);

    const auto& event = std::make_shared<Event>(callback);
    // front pushing is a way to execute an event before others
    if (pushFront) {
        m_eventList.emplace_front(event);
        // the poll event list only grows when pushing into front
        ++m_pollEventsSize;
    } else
        m_eventList.emplace_back(event);
    return event;
}