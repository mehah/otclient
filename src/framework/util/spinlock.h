#pragma once
#include <atomic>
#include <thread>
#include <chrono>

class SpinLock
{
    alignas(64) std::atomic_flag m_flag = ATOMIC_FLAG_INIT;
    char padding[64 - sizeof(std::atomic_flag)];

public:
    SpinLock() noexcept = default;
    SpinLock(const SpinLock&) = delete;
    SpinLock& operator=(const SpinLock&) = delete;

    void lock() {
        int spin = 1;
        int yield_count = 0;

        while (m_flag.test_and_set(std::memory_order_acquire)) {
            for (int i = 0; i < spin; ++i)
                cpu_relax();

            if (spin < 512) {
                spin *= 2;
            } else if (++yield_count < 20) {
                std::this_thread::yield();
            } else {
                std::this_thread::sleep_for(std::chrono::microseconds(100));
            }
        }
    }

    void unlock() {
        m_flag.clear(std::memory_order_release);
    }

    bool try_lock() noexcept {
        return !m_flag.test_and_set(std::memory_order_acquire);
    }

    class Guard
    {
    public:
        explicit Guard(SpinLock& lock) : m_lock(lock) { m_lock.lock(); }
        ~Guard() { m_lock.unlock(); }

        Guard(const Guard&) = delete;
        Guard& operator=(const Guard&) = delete;

    private:
        SpinLock& m_lock;
    };

private:
    static void cpu_relax() {
#if defined(__x86_64__) || defined(_M_X64) || defined(__i386) || defined(_M_IX86)
#include <immintrin.h>
        _mm_pause();
#elif defined(__aarch64__) || defined(__arm__)
        __asm__ __volatile__("yield");
#else
        std::this_thread::yield();
#endif
    }
};
