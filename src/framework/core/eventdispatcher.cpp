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
#include "asyncdispatcher.h"

#include <framework/core/clock.h>
#include "timer.h"

EventDispatcher g_dispatcher, g_textDispatcher, g_mainDispatcher;
int16_t g_mainThreadId = EventDispatcher::getThreadId();
int16_t g_eventThreadId = -1;

void EventDispatcher::init() {
    m_threads.reserve(g_asyncDispatcher.getNumberOfThreads() + 1);
    for (uint_fast16_t i = 0, s = m_threads.capacity(); i < s; ++i) {
        m_threads.emplace_back(std::make_unique<ThreadTask>());
    }
};

void EventDispatcher::shutdown()
{
    do {
        executeEvents();
        mergeEvents();
    } while (!m_eventList.empty());

    m_scheduledEventList.clear();
    m_deferEventList.clear();
    m_threads.clear();

    m_disabled = true;
}

void EventDispatcher::poll()
{
    mergeEvents();
    executeEvents();
    executeScheduledEvents();
    executeDeferEvents();
}

void EventDispatcher::startEvent(const ScheduledEventPtr& event)
{
    if (m_disabled)
        return;

    if (!event) {
        g_logger.error("EventDispatcher::startEvent called with null event");
        return;
    }

    const auto& thread = getThreadTask();
    std::scoped_lock lock(thread->mutex);
    thread->scheduledEventList.emplace_back(event);
}

ScheduledEventPtr EventDispatcher::scheduleEvent(const std::function<void()>& callback, int delay)
{
    if (m_disabled)
        return std::make_shared<ScheduledEvent>(nullptr, delay, 1);

    assert(delay >= 0);

    const auto& thread = getThreadTask();
    std::scoped_lock lock(thread->mutex);
    return thread->scheduledEventList.emplace_back(std::make_shared<ScheduledEvent>(callback, delay, 1));
}

ScheduledEventPtr EventDispatcher::cycleEvent(const std::function<void()>& callback, int delay)
{
    if (m_disabled)
        return std::make_shared<ScheduledEvent>(nullptr, delay, 0);

    assert(delay > 0);

    const auto& thread = getThreadTask();
    std::scoped_lock lock(thread->mutex);
    return thread->scheduledEventList.emplace_back(std::make_shared<ScheduledEvent>(callback, delay, 0));
}

EventPtr EventDispatcher::addEvent(const std::function<void()>& callback)
{
    if (m_disabled)
        return std::make_shared<Event>(nullptr);

    if (&g_mainDispatcher == this && g_mainThreadId == getThreadId()) {
        callback();
        return std::make_shared<Event>(nullptr);
    }

    const auto& thread = getThreadTask();
    std::scoped_lock lock(thread->mutex);
    return thread->events.emplace_back(std::make_shared<Event>(callback));
}

void EventDispatcher::deferEvent(const std::function<void()>& callback) {
    if (m_disabled)
        return;

    const auto& thread = getThreadTask();
    std::scoped_lock lock(thread->mutex);
    thread->deferEvents.emplace_back(callback);
}

void EventDispatcher::executeEvents() {
    if (m_eventList.empty()) {
        return;
    }

    for (const auto& event : m_eventList)
        event->execute();

    m_eventList.clear();
}

void EventDispatcher::executeDeferEvents() {
    do {
        for (auto& event : m_deferEventList)
            event.execute();
        m_deferEventList.clear();

        for (const auto& thread : m_threads) {
            std::scoped_lock lock(thread->mutex);
            if (!thread->deferEvents.empty()) {
                m_deferEventList.insert(m_deferEventList.end(), make_move_iterator(thread->deferEvents.begin()), make_move_iterator(thread->deferEvents.end()));
                thread->deferEvents.clear();
            }
        }
    } while (!m_deferEventList.empty());
}

void EventDispatcher::executeScheduledEvents() {
    auto& threadScheduledTasks = getThreadTask()->scheduledEventList;

    auto it = m_scheduledEventList.begin();
    while (it != m_scheduledEventList.end()) {
        const auto& scheduledEvent = *it;
        if (scheduledEvent->remainingTicks() > 0)
            break;

        scheduledEvent->execute();

        if (scheduledEvent->nextCycle())
            threadScheduledTasks.emplace_back(scheduledEvent);

        ++it;
    }

    if (it != m_scheduledEventList.begin()) {
        m_scheduledEventList.erase(m_scheduledEventList.begin(), it);
    }
}

void EventDispatcher::mergeEvents() {
    for (const auto& thread : m_threads) {
        std::scoped_lock lock(thread->mutex);
        if (!thread->events.empty()) {
            m_eventList.insert(m_eventList.end(), make_move_iterator(thread->events.begin()), make_move_iterator(thread->events.end()));
            thread->events.clear();
        }

        if (!thread->scheduledEventList.empty()) {
            m_scheduledEventList.insert(make_move_iterator(thread->scheduledEventList.begin()), make_move_iterator(thread->scheduledEventList.end()));
            thread->scheduledEventList.clear();
        }
    }
}