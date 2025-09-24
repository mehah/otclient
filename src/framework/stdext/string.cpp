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

#include <algorithm>
#include <ranges>
#include <vector>
#include <charconv>
#include <boost/locale/encoding.hpp>
#include <boost/locale/encoding_utf.hpp>

#include "exception.h"
#include "types.h"

#ifdef _MSC_VER
#pragma warning(disable:4267) // '?' : conversion from 'A' to 'B', possible loss of data
#endif

namespace stdext
{
    [[nodiscard]] std::string resolve_path(std::string_view filePath, std::string_view sourcePath) {
        if (filePath.starts_with("/"))
            return std::string(filePath);

        auto slashPos = sourcePath.find_last_of('/');
        if (slashPos == std::string::npos)
            throw std::runtime_error("Invalid source path '" + std::string(sourcePath) + "' for file '" + std::string(filePath) + "'");

        return std::string(sourcePath.substr(0, slashPos + 1)) + std::string(filePath);
    }

    [[nodiscard]] std::string date_time_string(const char* format) {
        std::time_t tnow = std::time(nullptr);
        std::tm ts{};

        // Platform-specific time handling
#ifdef _WIN32
        localtime_s(&ts, &tnow);
#else
        localtime_r(&tnow, &ts);
#endif

        char date[20];  // Reduce buffer size based on expected format
        if (std::strftime(date, sizeof(date), format, &ts) == 0)
            throw std::runtime_error("Failed to format date-time string");

        return std::string(date);
    }

    [[nodiscard]] std::string dec_to_hex(uint64_t num) {
        char buffer[17]; // 16 characters for a uint64_t in hex + null terminator
        auto [ptr, ec] = std::to_chars(buffer, buffer + sizeof(buffer) - 1, num, 16);
        *ptr = '\0'; // Null-terminate the string
        return std::string(buffer);
    }

    [[nodiscard]] uint64_t hex_to_dec(std::string_view str) {
        uint64_t num = 0;
        auto [ptr, ec] = std::from_chars(str.data(), str.data() + str.size(), num, 16);
        if (ec != std::errc())
            throw std::runtime_error("Invalid hexadecimal input");
        return num;
    }

    [[nodiscard]] bool is_valid_utf8(std::string_view src) {
        try {
            boost::locale::conv::utf_to_utf<char32_t>(src.data(), src.data() + src.size(), boost::locale::conv::stop);
            return true;
        } catch (const boost::locale::conv::conversion_error&) {
            return false;
        }
    }

    [[nodiscard]] std::string utf8_to_latin1(std::string_view src) {
        try {
            return boost::locale::conv::between(src.data(), src.data() + src.size(), "ISO-8859-1", "UTF-8", boost::locale::conv::skip);
        } catch (const boost::locale::conv::conversion_error&) {
            return {};
        } catch (const boost::locale::conv::invalid_charset_error&) {
            return {};
        }
    }

    [[nodiscard]] std::string latin1_to_utf8(std::string_view src) {
        try {
            return boost::locale::conv::between(src.data(), src.data() + src.size(), "UTF-8", "ISO-8859-1", boost::locale::conv::stop);
        } catch (const boost::locale::conv::conversion_error&) {
            return {};
        } catch (const boost::locale::conv::invalid_charset_error&) {
            return {};
        }
    }

#ifdef WIN32
    std::wstring utf8_to_utf16(const std::string_view src)
    {
        try {
            return boost::locale::conv::utf_to_utf<wchar_t>(src.data(), src.data() + src.size(), boost::locale::conv::stop);
        } catch (const boost::locale::conv::conversion_error&) {
            return {};
        }
    }

    std::string utf16_to_utf8(const std::wstring_view src)
    {
        try {
            return boost::locale::conv::utf_to_utf<char>(src.data(), src.data() + src.size(), boost::locale::conv::stop);
        } catch (const boost::locale::conv::conversion_error&) {
            return {};
        }
    }

    std::wstring latin1_to_utf16(const std::string_view src)
    {
        try {
            return boost::locale::conv::to_utf<wchar_t>(src.data(), src.data() + src.size(), "ISO-8859-1", boost::locale::conv::stop);
        } catch (const boost::locale::conv::conversion_error&) {
            return {};
        } catch (const boost::locale::conv::invalid_charset_error&) {
            return {};
        }
    }

    std::string utf16_to_latin1(const std::wstring_view src)
    {
        try {
            return boost::locale::conv::from_utf(src.data(), src.data() + src.size(), "ISO-8859-1", boost::locale::conv::skip);
        } catch (const boost::locale::conv::conversion_error&) {
            return {};
        } catch (const boost::locale::conv::invalid_charset_error&) {
            return {};
        }
    }
#endif

    void tolower(std::string& str) { std::ranges::transform(str, str.begin(), ::tolower); }

    void toupper(std::string& str) { std::ranges::transform(str, str.begin(), ::toupper); }

    void ltrim(std::string& s) { s.erase(s.begin(), std::ranges::find_if(s, [](unsigned char ch) { return !std::isspace(ch); })); }

    void rtrim(std::string& s) { s.erase(std::ranges::find_if(s | std::views::reverse, [](unsigned char ch) { return !std::isspace(ch); }).base(), s.end()); }

    void trim(std::string& s) { ltrim(s);       rtrim(s); }

    void ucwords(std::string& str) {
        bool capitalize = true;
        for (char& c : str) {
            if (std::isspace(static_cast<unsigned char>(c)))
                capitalize = true;
            else if (capitalize) {
                c = std::toupper(static_cast<unsigned char>(c));
                capitalize = false;
            }
        }
    }

    void replace_all(std::string& str, std::string_view search, std::string_view replacement) {
        size_t pos = 0;
        while ((pos = str.find(search, pos)) != std::string::npos) {
            str.replace(pos, search.length(), replacement);
            pos += replacement.length();
        }
    }

    void eraseWhiteSpace(std::string& str) { std::erase_if(str, isspace); }

    [[nodiscard]] std::vector<std::string> split(std::string_view str, std::string_view separators) {
        std::vector<std::string> result;

        const char* begin = str.data();
        const char* end = begin + str.size();
        const char* p = begin;

        while (p < end) {
            const char* token_start = p;
            while (p < end && separators.find(*p) == std::string_view::npos)
                ++p;

            if (p > token_start)
                result.emplace_back(token_start, p - token_start);

            while (p < end && separators.find(*p) != std::string_view::npos)
                ++p;
        }

        return result;
    }
}