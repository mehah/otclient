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

#include <algorithm>
#include <vector>

#include "exception.h"
#include "format.h"
#include "types.h"

#ifdef _MSC_VER
#pragma warning(disable:4267) // '?' : conversion from 'A' to 'B', possible loss of data
#endif

namespace stdext
{
    std::string resolve_path(const std::string_view filePath, std::string_view sourcePath)
    {
        if (filePath.starts_with("/"))
            return filePath.data();

        std::string _sourcePath(sourcePath);
        if (!sourcePath.ends_with("/")) {
            const std::size_t slashPos = sourcePath.find_last_of('/');
            if (slashPos == std::string::npos)
                throw Exception("invalid source path '%s', for file '%s'", sourcePath, filePath);
            _sourcePath = sourcePath.substr(0, slashPos + 1);
        }
        return _sourcePath + filePath.data();
    }

    std::string date_time_string(const char* format/* = "%b %d %Y %H:%M:%S"*/)
    {
        char date[100];
        std::time_t tnow;
        std::time(&tnow);
        const std::tm* ts = std::localtime(&tnow);
        std::strftime(date, 100, format, ts);
        return std::string(date);
    }

    std::string dec_to_hex(uint64_t num)
    {
        std::ostringstream o;
        o << std::hex << num;
        return o.str();
    }

    uint64_t hex_to_dec(const std::string_view str)
    {
        uint64_t num;
        std::istringstream i(str.data());
        i >> std::hex >> num;
        return num;
    }

    bool is_valid_utf8(const std::string_view src)
    {
        int c, i, ix, n, j;
        for (i = 0, ix = src.length(); i < ix; i++) {
            c = (unsigned char)src[i];
            //if (c==0x09 || c==0x0a || c==0x0d || (0x20 <= c && c <= 0x7e) ) n = 0; // is_printable_ascii
            if (0x00 <= c && c <= 0x7f) n = 0; // 0bbbbbbb
            else if ((c & 0xE0) == 0xC0) n = 1; // 110bbbbb
            else if (c == 0xed && i < (ix - 1) && ((unsigned char)src[i + 1] & 0xa0) == 0xa0) return false; //U+d800 to U+dfff
            else if ((c & 0xF0) == 0xE0) n = 2; // 1110bbbb
            else if ((c & 0xF8) == 0xF0) n = 3; // 11110bbb
            //else if (($c & 0xFC) == 0xF8) n=4; // 111110bb //byte 5, unnecessary in 4 byte UTF-8
            //else if (($c & 0xFE) == 0xFC) n=5; // 1111110b //byte 6, unnecessary in 4 byte UTF-8
            else return false;
            for (j = 0; j < n && i < ix; j++) { // n bytes matching 10bbbbbb follow ?
                if ((++i == ix) || (((unsigned char)src[i] & 0xC0) != 0x80))
                    return false;
            }
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
        std::wstring res;
        wchar_t out[4096];
        if (MultiByteToWideChar(CP_UTF8, 0, src.data(), -1, out, 4096))
            res = out;
        return res;
    }

    std::string utf16_to_utf8(const std::wstring_view src)
    {
        std::string res;
        char out[4096];
        if (WideCharToMultiByte(CP_UTF8, 0, src.data(), -1, out, 4096, nullptr, nullptr))
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

    void tolower(std::string& str)
    {
        std::transform(str.begin(), str.end(), str.begin(), [](int c) -> char { return static_cast<char>(::tolower(c)); });
    }

    void toupper(std::string& str)
    {
        std::transform(str.begin(), str.end(), str.begin(), [](int c) -> char { return static_cast<char>(::toupper(c)); });
    }

    void ltrim(std::string& s)
    {
        s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](uint8_t ch) {
            return !std::isspace(ch);
        }));
    }

    void rtrim(std::string& s)
    {
        s.erase(std::find_if(s.rbegin(), s.rend(), [](uint8_t ch) {
            return !std::isspace(ch);
        }).base(), s.end());
    }

    void trim(std::string& s)
    {
        ltrim(s);
        rtrim(s);
    }

    void ucwords(std::string& str)
    {
        const uint32_t strLen = str.length();
        if (strLen == 0)
            return;

        str[0] = static_cast<char>(std::toupper(str[0]));
        for (uint32_t i = 1; i < strLen; ++i) {
            if (str[i - 1] == ' ')
                str[i] = static_cast<char>(std::toupper(str[i]));
        }
    }

    void replace_all(std::string& str, const std::string_view search, const std::string_view replacement)
    {
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

    std::vector<std::string> split(const std::string_view str, const std::string_view separators)
    {
        std::vector<std::string> result;

        size_t found = str.find(separators);
        size_t startIndex = 0;

        while (found != std::string::npos) {
            result.emplace_back(str.begin() + startIndex, str.begin() + found);
            startIndex = found + separators.size();
            found = str.find(separators, startIndex);
        }
        if (startIndex != str.size())
            result.emplace_back(str.begin() + startIndex, str.end());

        return result;
    }
}