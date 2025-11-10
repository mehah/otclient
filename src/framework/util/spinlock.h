#pragma once

#if defined(__x86_64__) || defined(_M_X64) || defined(__i386) || defined(_M_IX86)
#endif

class SpinLock
{
    alignas(64) std::atomic_bool m_flag{ false };

public:
    SpinLock() noexcept = default;
    SpinLock(const SpinLock&) = delete;
    SpinLock& operator=(const SpinLock&) = delete;

    void lock() noexcept {
        for (;;) {
            if (!m_flag.exchange(true, std::memory_order_acquire))
                return;
            while (m_flag.load(std::memory_order_relaxed))
                cpu_relax();
        }
    }

    void unlock() noexcept {
        m_flag.store(false, std::memory_order_release);
    }

    bool try_lock() noexcept {
        return !m_flag.exchange(true, std::memory_order_acquire);
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
    static inline void cpu_relax() {
#if defined(__x86_64__) || defined(_M_X64) || defined(__i386) || defined(_M_IX86)
        _mm_pause();
#elif defined(__aarch64__) || defined(__arm__)
        __asm__ __volatile__("yield");
#else
        std::this_thread::yield();
#endif
    }
};
