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
#include <ranges>
#include <vector>
#include <format>
#include <charconv>

#include "exception.h"
#include "format.h"
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
            throw std::runtime_error(std::format("Invalid source path '{}' for file '{}'", sourcePath, filePath));

        return std::string(sourcePath.substr(0, slashPos + 1)) + std::string(filePath);
    }

    [[nodiscard]] std::string date_time_string(const char* format/* = "%b %d %Y %H:%M:%S"*/) {
        std::time_t tnow = std::time(nullptr);
        std::tm ts{};
        localtime_s(&ts, &tnow);
        char date[100];
        std::strftime(date, sizeof(date), format, &ts);
        return std::string(date);
    }

    [[nodiscard]] std::string dec_to_hex(uint64_t num) {
        return std::format("{:x}", num);
    }

    [[nodiscard]] uint64_t hex_to_dec(std::string_view str) {
        uint64_t num = 0;
        auto [ptr, ec] = std::from_chars(str.data(), str.data() + str.size(), num, 16);
        if (ec != std::errc())
            throw std::runtime_error("Invalid hexadecimal input");
        return num;
    }

    [[nodiscard]] constexpr bool is_valid_utf8(std::string_view src) {
        for (size_t i = 0; i < src.size();) {
            unsigned char c = src[i];
            size_t bytes = (c < 0x80) ? 1 : (c < 0xE0) ? 2 : (c < 0xF0) ? 3 : (c < 0xF5) ? 4 : 0;
            if (!bytes || i + bytes > src.size() || (bytes > 1 && (src[i + 1] & 0xC0) != 0x80))
                return false;
            i += bytes;
        }
        return true;
    }

    std::string utf8_to_latin1(const std::string_view src)
    {
        std::string out;
        for (int i = -1, s = src.length(); ++i < s;) {
            const uint8_t c = src[i];
            if ((c >= 32 && c < 128) || c == 0x0d || c == 0x0a || c == 0x09)
                out += c;
            else if (c == 0xc2 || c == 0xc3) {
                const uint8_t c2 = src[++i];
                if (c == 0xc2) {
                    if (c2 > 0xa1 && c2 < 0xbb)
                        out += c2;
                } else if (c == 0xc3)
                    out += 64 + c2;
            } else if (c >= 0xc4 && c <= 0xdf)
                i += 1;
            else if (c >= 0xe0 && c <= 0xed)
                i += 2;
            else if (c >= 0xf0 && c <= 0xf4)
                i += 3;
        }
        return out;
    }

    std::string latin1_to_utf8(const std::string_view src)
    {
        std::string out;
        for (const uint8_t c : src) {
            if ((c >= 32 && c < 128) || c == 0x0d || c == 0x0a || c == 0x09)
                out += c;
            else {
                out += 0xc2 + (c > 0xbf);
                out += 0x80 + (c & 0x3f);
            }
        }
        return out;
    }

#ifdef WIN32
#include <winsock2.h>
#include <windows.h>

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

    std::wstring latin1_to_utf16(const std::string_view src)
    {
        return utf8_to_utf16(latin1_to_utf8(src));
    }

    std::string utf16_to_latin1(const std::wstring_view src)
    {
        return utf8_to_latin1(utf16_to_utf8(src));
    }
#endif

    void tolower(std::string& str) {
        std::ranges::transform(str, str.begin(), ::tolower);
    }

    void toupper(std::string& str) {
        std::ranges::transform(str, str.begin(), ::toupper);
    }

    void ltrim(std::string& s)
    {
        s.erase(s.begin(), std::ranges::find_if(s, [](unsigned char ch) { return !std::isspace(ch); }));
    }

    void rtrim(std::string& s)
    {
        s.erase(std::ranges::find_if(s | std::views::reverse, [](unsigned char ch) { return !std::isspace(ch); }).base(), s.end());
    }

    void trim(std::string& s)
    {
        ltrim(s);
        rtrim(s);
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

    void eraseWhiteSpace(std::string& str)
    {
        std::erase_if(str, isspace);
    }

    [[nodiscard]] std::vector<std::string> split(std::string_view str, std::string_view separators) {
        std::vector<std::string> result;
        for (auto&& part : str | std::views::split(separators)) {
            result.emplace_back(part.begin(), part.end());
        }
        return result;
    }
}