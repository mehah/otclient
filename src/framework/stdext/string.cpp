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

        char date[20];
        if (std::strftime(date, sizeof(date), format, &ts) == 0)
            throw std::runtime_error("Failed to format date-time string");

        return std::string(date);
    }

    [[nodiscard]] std::string dec_to_hex(uint64_t num) {
        char buffer[17];
        auto [ptr, ec] = std::to_chars(buffer, buffer + sizeof(buffer) - 1, num, 16);
        *ptr = '\0';
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
        for (size_t i = 0; i < src.size();) {
            unsigned char c = src[i];
            size_t bytes = (c < 0x80) ? 1 : (c < 0xE0) ? 2 : (c < 0xF0) ? 3 : (c < 0xF5) ? 4 : 0;
            if (!bytes || i + bytes > src.size() || (bytes > 1 && (src[i + 1] & 0xC0) != 0x80))
                return false;
            i += bytes;
        }
        return true;
    }

    [[nodiscard]] std::string utf8_to_latin1(std::string_view src) {
        std::string out;
        out.reserve(src.size());
        for (size_t i = 0; i < src.size(); ++i) {
            uint8_t c = static_cast<uint8_t>(src[i]);
            if ((c >= 32 && c < 128) || c == 0x0d || c == 0x0a || c == 0x09) {
                out += c;
            } else if (c == 0xc2 || c == 0xc3) {
                if (i + 1 < src.size()) {
                    uint8_t c2 = static_cast<uint8_t>(src[++i]);
                    out += (c == 0xc2) ? c2 : (c2 + 64);
                }
            } else {
                while (i + 1 < src.size() && (src[i + 1] & 0xC0) == 0x80) {
                    ++i;
                }
            }
        }
        return out;
    }

    [[nodiscard]] std::string latin1_to_utf8(std::string_view src) {
        std::string out;
        out.reserve(src.size() * 2);
        for (uint8_t c : src) {
            if ((c >= 32 && c < 128) || c == 0x0d || c == 0x0a || c == 0x09) {
                out += c;
            } else {
                out.push_back(0xc2 + (c > 0xbf));
                out.push_back(0x80 + (c & 0x3f));
            }
        }
        return out;
    }

#ifdef WIN32
#include <windows.h>
#include <winsock2.h>

    std::wstring utf8_to_utf16(const std::string_view src)
    {
        constexpr size_t BUFFER_SIZE = 65536;

        std::wstring res;
        wchar_t out[BUFFER_SIZE];
        if (MultiByteToWideChar(CP_UTF8, 0, src.data(), -1, out, BUFFER_SIZE))
            res = out;
        return res;
    }

    std::string utf16_to_utf8(const std::wstring_view src)
    {
        constexpr size_t BUFFER_SIZE = 65536;

        std::string res;
        char out[BUFFER_SIZE];
        if (WideCharToMultiByte(CP_UTF8, 0, src.data(), -1, out, BUFFER_SIZE, nullptr, nullptr))
            res = out;
        return res;
    }

    std::wstring latin1_to_utf16(const std::string_view src) { return utf8_to_utf16(latin1_to_utf8(src)); }

    std::string utf16_to_latin1(const std::wstring_view src) { return utf8_to_latin1(utf16_to_utf8(src)); }
#endif

    void tolower(std::string& str) { std::ranges::transform(str, str.begin(), ::tolower); }

    void toupper(std::string& str) { std::ranges::transform(str, str.begin(), ::toupper); }

    void ltrim(std::string& s) { s.erase(s.begin(), std::ranges::find_if(s, [](unsigned char ch) { return !std::isspace(ch); })); }

    void rtrim(std::string& s) { s.erase(std::ranges::find_if(s | std::views::reverse, [](unsigned char ch) { return !std::isspace(ch); }).base(), s.end()); }

    void trim(std::string& s) { ltrim(s); rtrim(s); }

    void trimSpacesAndNewlines(std::string& s) {
        if (s.empty()) return;

        const unsigned char* data = reinterpret_cast<const unsigned char*>(s.data());
        size_t start = 0;
        size_t end = s.size();

        while (start < end && std::isspace(data[start]))
            ++start;

        while (end > start && std::isspace(data[end - 1]))
            --end;

        if (start > 0 || end < s.size()) {
            const size_t newSize = end - start;
            if (start > 0)
                s.erase(0, start);
            if (newSize < s.size())
                s.resize(newSize);
        }
    }

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

    std::string join(const std::vector<std::string>& vec, const std::string& sep) {
        if (vec.empty()) return {};

        size_t total_size = (vec.size() - 1) * sep.size();
        for (const auto& s : vec) total_size += s.size();

        std::string result;
        result.reserve(total_size);

        for (size_t i = 0; i < vec.size(); ++i) {
            if (i > 0) result += sep;
            result += vec[i];
        }
        return result;
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

    long long to_number(std::string_view s) {
        const char* p = s.data();
        const char* end = p + s.size();

        long long num = 0;
        bool found = false;
        bool negative = false;
        int frac = 0;
        bool hasFrac = false;

        while (p < end) {
            unsigned char c = static_cast<unsigned char>(*p++);
            if (!found && c == '-') {
                negative = true;
            } else if (c >= '0' && c <= '9') {
                found = true;
                if (!hasFrac) {
                    num = num * 10 + (c - '0');
                } else {
                    if (frac == 0) frac = c - '0';
                }
            } else if (c == '.') {
                hasFrac = true;
            }
        }

        if (!found) return 0;

        if (hasFrac && frac >= 5) {
            num += 1;
        }

        return negative ? -num : num;
    }

    std::vector<long long> extractNumbers(std::string_view s) {
        std::vector<long long> out;
        out.reserve(s.size() / 3);

        const char* p = s.data();
        const char* end = p + s.size();

        long long val = 0;
        bool building = false;
        bool neg = false;

        while (p < end) {
            unsigned char c = static_cast<unsigned char>(*p);

            if (c >= '0' && c <= '9') {
                if (!building) { building = true; val = 0; }
                val = val * 10 + (c - '0');
            } else {
                if (building) {
                    out.emplace_back(neg ? -val : val);
                    building = false;
                    neg = false;
                    val = 0;
                } else {
                    neg = (c == '-');
                }
            }
            ++p;
        }

        if (building) out.emplace_back(neg ? -val : val);
        if (out.empty()) out.emplace_back(0);

        return out;
    }
}