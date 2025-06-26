/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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

#include "timer.h"

thread_local DispatcherContext EventDispatcher::dispacherContext;

EventDispatcher g_dispatcher, g_textDispatcher, g_mainDispatcher;
int16_t g_mainThreadId = stdext::getThreadId();
int16_t g_eventThreadId = -1;

void EventDispatcher::init() {
    for (size_t i = 0; i < g_asyncDispatcher.get_thread_count(); ++i) {
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
    executeAsyncEvents();
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
    thread->hasEvents.store(true, std::memory_order_release);
    std::scoped_lock l(thread->mutex);
    thread->scheduledEventList.emplace_back(event);
}

ScheduledEventPtr EventDispatcher::scheduleEvent(const std::function<void()>& callback, int delay)
{
    if (m_disabled)
        return std::make_shared<ScheduledEvent>(nullptr, delay, 1);

    assert(delay >= 0);

    const auto& thread = getThreadTask();
    thread->hasEvents.store(true, std::memory_order_release);
    std::scoped_lock l(thread->mutex);
    return thread->scheduledEventList.emplace_back(std::make_shared<ScheduledEvent>(callback, delay, 1));
}

ScheduledEventPtr EventDispatcher::cycleEvent(const std::function<void()>& callback, int delay)
{
    if (m_disabled)
        return std::make_shared<ScheduledEvent>(nullptr, delay, 0);

    assert(delay > 0);

    const auto& thread = getThreadTask();
    thread->hasEvents.store(true, std::memory_order_release);
    std::scoped_lock l(thread->mutex);
    return thread->scheduledEventList.emplace_back(std::make_shared<ScheduledEvent>(callback, delay, 0));
}

EventPtr EventDispatcher::addEvent(const std::function<void()>& callback)
{
    if (m_disabled)
        return std::make_shared<Event>(nullptr);

    if (&g_mainDispatcher == this && g_mainThreadId == stdext::getThreadId()) {
        callback();
        return std::make_shared<Event>(nullptr);
    }

    const auto& thread = getThreadTask();
    thread->hasEvents.store(true, std::memory_order_release);
    std::scoped_lock l(thread->mutex);
    return thread->events.emplace_back(std::make_shared<Event>(callback));
}

void EventDispatcher::asyncEvent(std::function<void()>&& callback) {
    if (m_disabled)
        return;

    const auto& thread = getThreadTask();
    thread->hasEvents.store(true, std::memory_order_release);
    std::scoped_lock l(thread->mutex);
    thread->asyncEvents.emplace_back(std::move(callback));
}

void EventDispatcher::deferEvent(const std::function<void()>& callback) {
    if (m_disabled)
        return;

    const auto& thread = getThreadTask();
    thread->hasDeferEvents.store(true, std::memory_order_release);
    std::scoped_lock l(thread->mutex);
    thread->deferEvents.emplace_back(callback);
}

void EventDispatcher::executeEvents() {
    if (m_eventList.empty()) {
        return;
    }

    dispacherContext.group = TaskGroup::Serial;
    dispacherContext.type = DispatcherType::Event;

    for (const auto& event : m_eventList)
        event->execute();

    m_eventList.clear();
    dispacherContext.reset();
}

std::vector<std::pair<uint64_t, uint64_t>> generatePartition(const size_t size) {
    if (size == 0)
        return {};

    static const int threads = g_asyncDispatcher.get_thread_count();
    std::vector<std::pair<uint64_t, uint64_t>> list;
    list.reserve(threads);

    const auto size_per_block = std::ceil(size / static_cast<float>(threads));
    for (uint_fast64_t i = 0; i < size; i += size_per_block)
        list.emplace_back(i, std::min<uint64_t >(size, i + size_per_block));

    return list;
}

void EventDispatcher::executeAsyncEvents() {
    if (m_asyncEventList.empty())
        return;

    const auto& partitions = generatePartition(m_asyncEventList.size());

    BS::multi_future<void> retFuture;

    if (partitions.size() > 1) {
        const auto min = partitions[1].first;
        const auto max = partitions[partitions.size() - 1].second;
        retFuture = g_asyncDispatcher.submit_loop(min, max, [&](const unsigned int i) {
            dispacherContext.type = DispatcherType::AsyncEvent;
            dispacherContext.group = TaskGroup::GenericParallel;
            m_asyncEventList[i].execute();
            dispacherContext.reset();
        });
    }

    dispacherContext.type = DispatcherType::AsyncEvent;
    dispacherContext.group = TaskGroup::GenericParallel;

    const auto& [min, max] = partitions[0];
    for (uint_fast64_t i = min; i < max; ++i)
        m_asyncEventList[i].execute();

    dispacherContext.reset();

    if (partitions.size() > 1)
        retFuture.wait();

    m_asyncEventList.clear();
}

void EventDispatcher::executeDeferEvents() {
    dispacherContext.group = TaskGroup::Serial;
    dispacherContext.type = DispatcherType::DeferEvent;

    do {
        for (auto& event : m_deferEventList)
            event.execute();
        m_deferEventList.clear();

        for (const auto& thread : m_threads) {
            if (!thread->hasDeferEvents.exchange(false, std::memory_order_acquire))
                continue;

            std::scoped_lock lock(thread->mutex);
            if (m_deferEventList.size() < thread->deferEvents.size())
                m_deferEventList.swap(thread->deferEvents);
            if (!thread->deferEvents.empty()) {
                m_deferEventList.insert(m_deferEventList.end(), make_move_iterator(thread->deferEvents.begin()), make_move_iterator(thread->deferEvents.end()));
                thread->deferEvents.clear();
            }
        }
    } while (!m_deferEventList.empty());

    dispacherContext.reset();
}

void EventDispatcher::executeScheduledEvents() {
    auto& threadScheduledTasks = getThreadTask()->scheduledEventList;

    auto it = m_scheduledEventList.begin();
    while (it != m_scheduledEventList.end()) {
        const auto& scheduledEvent = *it;
        if (scheduledEvent->remainingTicks() > 0)
            break;

        dispacherContext.type = scheduledEvent->maxCycles() > 0 ? DispatcherType::CycleEvent : DispatcherType::ScheduledEvent;
        dispacherContext.group = TaskGroup::Serial;

        scheduledEvent->execute();

        if (scheduledEvent->nextCycle())
            threadScheduledTasks.emplace_back(scheduledEvent);

        ++it;
    }

    if (it != m_scheduledEventList.begin()) {
        m_scheduledEventList.erase(m_scheduledEventList.begin(), it);
    }

    dispacherContext.reset();
}

void EventDispatcher::mergeEvents() {
    for (const auto& thread : m_threads) {
        if (!thread->hasEvents.exchange(false, std::memory_order_acquire))
            continue;

        std::scoped_lock l(thread->mutex);
        if (!thread->events.empty()) {
            if (m_eventList.size() < thread->events.size())
                m_eventList.swap(thread->events);

            if (!thread->events.empty()) {
                m_eventList.insert(m_eventList.end(), make_move_iterator(thread->events.begin()), make_move_iterator(thread->events.end()));
                thread->events.clear();
            }
        }

        if (!thread->asyncEvents.empty()) {
            if (m_asyncEventList.size() < thread->asyncEvents.size())
                m_asyncEventList.swap(thread->asyncEvents);

            if (!thread->asyncEvents.empty()) {
                m_asyncEventList.insert(m_asyncEventList.end(), make_move_iterator(thread->asyncEvents.begin()), make_move_iterator(thread->asyncEvents.end()));
                thread->asyncEvents.clear();
            }
        }

        if (!thread->scheduledEventList.empty()) {
            m_scheduledEventList.insert(make_move_iterator(thread->scheduledEventList.begin()), make_move_iterator(thread->scheduledEventList.end()));
            thread->scheduledEventList.clear();
        }
    }
}