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

#include <algorithm>
#include <climits>
#include <cmath>
#include <random>

#ifdef _MSC_VER
#pragma warning(disable:4267) // '?' : conversion from 'A' to 'B', possible loss of data
#endif

namespace stdext
{
    uint32_t adler32(const uint8_t* buffer, size_t size)
    {
        constexpr uint32_t MOD_ADLER = 65521;
        uint32_t a = 1, b = 0;

        while (size > 0) {
            size_t tlen = std::min<size_t>(size, size_t(5552));
            size -= tlen;

            for (size_t i = 0; i < tlen; ++i) {
                a += buffer[i];
                b += a;
            }
            buffer += tlen; // Avança o ponteiro do buffer

            a %= MOD_ADLER;
            b %= MOD_ADLER;
        }

        return (b << 16) | a;
    }

    int random_range(const int min, const int max)
    {
        thread_local std::mt19937 gen(std::random_device{}());
        std::uniform_int_distribution<int> dis(std::min<int>(min, max), std::max<int>(min, max));
        return dis(gen);
    }

    float random_range(const float min, const float max)
    {
        thread_local std::mt19937 gen(std::random_device{}());
        std::uniform_real_distribution<float> dis(min, max);
        return dis(gen);
    }

    std::mt19937& random_gen()
    {
        thread_local std::mt19937 generator(std::random_device{}());
        return generator;
    }

    bool random_bool(const double probability)
    {
        thread_local std::mt19937& gen = random_gen();
        return std::bernoulli_distribution(probability)(gen);
    }

    int32_t normal_random(const int32_t minNumber, const int32_t maxNumber)
    {
        thread_local std::mt19937& gen = random_gen();
        static std::normal_distribution<float> normalRand(0.5f, 0.25f);

        float v;
        while ((v = normalRand(gen)) < 0.0 || v > 1.0);

        auto [a, b] = std::minmax(minNumber, maxNumber);
        return static_cast<int32_t>(std::round(a + v * (b - a)));
    }
}