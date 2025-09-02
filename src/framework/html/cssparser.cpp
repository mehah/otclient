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

#include "cssparser.h"
#include "htmlnode.h"
#include "queryselector.h"

namespace css {
    namespace detail {
        static std::vector<std::string> split_selector_list(const std::string&);

        static inline void trim_inplace(std::string& s) {
            size_t a = 0; while (a < s.size() && (unsigned char)s[a] <= ' ') ++a;
            size_t b = s.size(); while (b > a && (unsigned char)s[b - 1] <= ' ') --b;
            s = s.substr(a, b - a);
        }

        static inline void ascii_tolower_inplace_local(std::string& s) {
            for (auto& c : s) if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
        }

        static uint32_t name_to_flag(const std::string& lower) { if (lower == "hover")return SEF_Hover; if (lower == "focus")return SEF_Focus; if (lower == "active")return SEF_Active; if (lower == "focus-within")return SEF_FocusWithin; if (lower == "focus-visible")return SEF_FocusVisible; if (lower == "visited")return SEF_Visited; if (lower == "checked")return SEF_Checked; if (lower == "disabled")return SEF_Disabled; if (lower == "enabled")return SEF_Enabled; return SEF_None; }
        static std::tuple<int, int, int> specificity_of(const std::string& sel);

        static bool is_ident_start(char c) {
            return std::isalpha((unsigned char)c) || c == '_' || c == '-';
        }
        static std::tuple<int, int, int> specificity_max(const std::vector<std::string>& list) {
            std::tuple<int, int, int> best{ 0,0,0 };
            for (const auto& s : list) {
                auto sp = specificity_of(s);
                if (sp > best) best = sp;
            }
            return best;
        }

        static uint32_t collect_event_flags(const std::string& sel, std::vector<std::string>* outPseudos = nullptr);
        static std::vector<std::string> split_selector_list(const std::string& s) {
            std::vector<std::string> parts;
            std::string cur;
            int paren = 0, brack = 0, brace = 0;
            bool in_str = false;
            char q = 0;
            for (size_t i = 0; i < s.size(); ++i) {
                char c = s[i];
                if (in_str) {
                    cur.push_back(c);
                    if (c == q) {
                        in_str = false;
                    } else if (c == '\\' && i + 1 < s.size()) {
                        cur.push_back(s[i + 1]);
                        ++i;
                    }
                    continue;
                }
                if (c == '"' || c == '\'') { in_str = true; q = c; cur.push_back(c); continue; }
                if (c == '(') { ++paren; cur.push_back(c); continue; }
                if (c == ')') { --paren; cur.push_back(c); continue; }
                if (c == '[') { ++brack; cur.push_back(c); continue; }
                if (c == ']') { --brack; cur.push_back(c); continue; }
                if (c == '{') { ++brace; cur.push_back(c); continue; }
                if (c == '}') { --brace; cur.push_back(c); continue; }
                if (c == ',' && paren == 0 && brack == 0 && brace == 0) {
                    trim_inplace(cur);
                    if (!cur.empty()) parts.push_back(cur);
                    cur.clear();
                } else {
                    cur.push_back(c);
                }
            }
            trim_inplace(cur);
            if (!cur.empty()) parts.push_back(cur);
            return parts;
        }

        static uint32_t collect_event_flags(const std::string& sel, std::vector<std::string>* outPseudos) {
            uint32_t flags = SEF_None;
            const std::string& sref = sel;
            for (size_t i = 0; i < sref.size();) {
                char ch = sref[i];
                if (ch == '"' || ch == '\'') {
                    char qq = ch; ++i;
                    while (i < sref.size() && sref[i] != qq) {
                        if (sref[i] == '\\' && i + 1 < sref.size()) i += 2;
                        else ++i;
                    }
                    if (i < sref.size()) ++i;
                    continue;
                }
                if (ch == '[') {
                    ++i; int depth = 1;
                    while (i < sref.size() && depth > 0) {
                        if (sref[i] == '"' || sref[i] == '\'') {
                            char qq = sref[i++];
                            while (i < sref.size() && sref[i] != qq) {
                                if (sref[i] == '\\' && i + 1 < sref.size()) i += 2;
                                else ++i;
                            }
                            if (i < sref.size()) ++i;
                        } else if (sref[i] == '[') { ++depth; ++i; } else if (sref[i] == ']') { --depth; ++i; } else { ++i; }
                    }
                    continue;
                }
                if (ch == ':') {
                    size_t col = 1; ++i;
                    if (i < sref.size() && sref[i] == ':') { ++col; ++i; }
                    size_t ns = i;
                    while (i < sref.size() && (std::isalnum((unsigned char)sref[i]) || sref[i] == '-' || sref[i] == '_')) ++i;
                    std::string name = sref.substr(ns, i - ns);
                    ascii_tolower_inplace_local(name);
                    if (outPseudos) outPseudos->push_back(name);
                    if (col == 1) {
                        flags |= name_to_flag(name);
                        if (i < sref.size() && sref[i] == '(') {
                            ++i; size_t cs = i; int depth = 1; bool in_str = false; char qq = 0;
                            for (; i < sref.size(); ++i) {
                                char ch2 = sref[i];
                                if (in_str) {
                                    if (ch2 == qq) in_str = false;
                                    else if (ch2 == '\\' && i + 1 < sref.size()) ++i;
                                    continue;
                                }
                                if (ch2 == '"' || ch2 == '\'') { in_str = true; qq = ch2; continue; }
                                if (ch2 == '(') ++depth;
                                else if (ch2 == ')') { if (--depth == 0) { ++i; break; } }
                            }
                            std::string inside = sref.substr(cs, (i - cs - 1));
                            if (name == "not" || name == "is" || name == "has" || name == "where") {
                                auto parts = split_selector_list(inside);
                                for (const auto& part : parts) {
                                    flags |= collect_event_flags(part, outPseudos);
                                }
                            }
                        }
                    }
                    continue;
                }
                ++i;
            }
            return flags;
        }

        static std::string strip_comments(const std::string& in) {
            std::string out; out.reserve(in.size());
            size_t i = 0, N = in.size();
            while (i < N) {
                if (i + 1 < N && in[i] == '/' && in[i + 1] == '*') {
                    i += 2;
                    while (i + 1 < N && !(in[i] == '*' && in[i + 1] == '/')) ++i;
                    if (i + 1 < N) i += 2;
                } else {
                    out.push_back(in[i++]);
                }
            }
            return out;
        }

        static std::vector<std::string> split_top_commas(const std::string& s) {
            std::vector<std::string> parts; std::string cur;
            int paren = 0, brack = 0, brace = 0; bool in_str = false; char q = 0;
            for (size_t i = 0; i < s.size(); ++i) {
                char c = s[i];
                if (in_str) {
                    cur.push_back(c);
                    if (c == q) in_str = false;
                    else if (c == '\\' && i + 1 < s.size()) cur.push_back(s[++i]);
                    continue;
                }
                if (c == '"' || c == '\'') { in_str = true; q = c; cur.push_back(c); continue; }
                if (c == '(') ++paren; else if (c == ')') --paren;
                else if (c == '[') ++brack; else if (c == ']') --brack;
                else if (c == '{') ++brace; else if (c == '}') --brace;
                if (c == ',' && paren == 0 && brack == 0 && brace == 0) { if (!cur.empty()) { parts.push_back(cur); cur.clear(); } continue; }
                cur.push_back(c);
            }
            if (!cur.empty()) parts.push_back(cur);
            return parts;
        }

        struct RawBlock { std::string selectors; std::string block; bool is_at_media{ false }; std::string at_prelude; };

        static std::vector<RawBlock> extract_blocks(const std::string& css) {
            std::vector<RawBlock> items;
            const std::string& s = css;
            size_t i = 0, N = s.size();
            auto skip_ws = [&]() { while (i < N && (unsigned char)s[i] <= ' ') ++i; };
            while (i < N) {
                skip_ws(); if (i >= N) break;
                if (s[i] == '@') {
                    size_t start = i;
                    while (i < N && s[i] != '{' && s[i] != ';') ++i;
                    std::string prelude = s.substr(start, i - start);
                    trim_inplace(prelude);
                    if (i < N && s[i] == ';') { ++i; continue; }
                    if (i >= N || s[i] != '{') break;
                    int depth = 1; size_t blockStart = ++i;
                    for (; i < N; ++i) {
                        char c = s[i];
                        if (c == '"' || c == '\'') {
                            char q = c; ++i; while (i < N && s[i] != q) { if (s[i] == '\\' && i + 1 < N) i += 2; else ++i; }
                            continue;
                        }
                        if (c == '{') ++depth;
                        else if (c == '}') { if (--depth == 0) { ++i; break; } }
                    }
                    std::string inner = s.substr(blockStart, (i - blockStart - 1));
                    items.push_back({ "", inner, true, prelude });
                    continue;
                }
                size_t selStart = i;
                while (i < N && s[i] != '{') ++i;
                if (i >= N) break;
                std::string selectors = s.substr(selStart, i - selStart);
                ++i; size_t blockStart = i; int depth = 1;
                for (; i < N; ++i) {
                    char c = s[i];
                    if (c == '"' || c == '\'') {
                        char q = c; ++i; while (i < N && s[i] != q) { if (s[i] == '\\' && i + 1 < N) i += 2; else ++i; }
                        continue;
                    }
                    if (c == '{') ++depth;
                    else if (c == '}') { if (--depth == 0) { ++i; break; } }
                }
                std::string block = s.substr(blockStart, (i - blockStart - 1));
                items.push_back({ selectors, block, false, {} });
            }
            return items;
        }

        static std::vector<Declaration> parse_decls(const std::string& block) {
            std::vector<Declaration> out;
            const std::string& s = block; size_t i = 0, N = s.size();
            auto skip_ws = [&]() { while (i < N && (unsigned char)s[i] <= ' ') ++i; };
            while (i < N) {
                skip_ws(); if (i >= N) break;
                size_t p0 = i; while (i < N && s[i] != ':' && s[i] != ';' && s[i] != '{' && s[i] != '}') ++i;
                std::string prop = s.substr(p0, i - p0); trim_inplace(prop); ascii_tolower_inplace_local(prop);
                if (prop.empty()) { while (i < N && s[i] != ';') ++i; if (i < N) ++i; continue; }
                if (i >= N || s[i] != ':') { while (i < N && s[i] != ';') ++i; if (i < N) ++i; continue; }
                ++i;
                size_t v0 = i; int paren = 0, brack = 0, brace = 0; bool in_str = false; char q = 0;
                for (; i < N; ++i) {
                    char c = s[i];
                    if (in_str) { if (c == q) in_str = false; else if (c == '\\' && i + 1 < N) ++i; continue; }
                    if (c == '"' || c == '\'') { in_str = true; q = c; continue; }
                    if (c == '(') ++paren; else if (c == ')') --paren;
                    else if (c == '[') ++brack; else if (c == ']') --brack;
                    else if (c == '{') ++brace; else if (c == '}') --brace;
                    if (c == ';' && paren == 0 && brack == 0 && brace == 0) break;
                }
                std::string val = s.substr(v0, i - v0);
                {
                    std::string tmp = val; trim_inplace(tmp);
                    auto ends_with_ci = [&](const std::string& needle)->bool {
                        if (needle.size() > tmp.size()) return false;
                        size_t off = tmp.size() - needle.size();
                        for (size_t k = 0; k < needle.size(); ++k) {
                            char a = tmp[off + k], b = needle[k];
                            if (a >= 'A' && a <= 'Z') a = char(a - 'A' + 'a');
                            if (b >= 'A' && b <= 'Z') b = char(b - 'A' + 'a');
                            if (a != b) return false;
                        }
                        return true;
                    };
                    bool important = false;
                    if (ends_with_ci("!important")) {
                        important = true;
                        size_t ip = tmp.rfind('!');
                        if (ip != std::string::npos) tmp = tmp.substr(0, ip);
                    }
                    trim_inplace(tmp);
                    val = tmp;

                    if (prop.starts_with("--"))
                        prop.erase(0, 2);

                    out.push_back({ prop, val, important });
                }
                if (i < N && s[i] == ';') ++i;
            }
            return out;
        }

        static std::tuple<int, int, int> specificity_of(const std::string& sel) {
            int a = 0, b = 0, c = 0;
            const char* s = sel.c_str();
            size_t n = sel.size();
            for (size_t i = 0; i < n;) {
                char ch = s[i];
                if (ch == '#') { ++a; ++i; while (i < n && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i; } else if (ch == '.') { ++b; ++i; while (i < n && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i; } else if (ch == '[') { ++b; int depth = 1; ++i; while (i < n && depth>0) { if (s[i] == '[') ++depth; else if (s[i] == ']') --depth; ++i; } } else if (ch == ':') { ++i; if (i < n && s[i] == ':') { ++c; ++i; } else { ++b; } while (i < n && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i; } else if (std::isalpha((unsigned char)ch) || ch == '*') { if (ch != '*') ++c; while (i < n && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i; } else { ++i; }
            }
            return { a,b,c };
        }
    }

    StyleSheet parse(const std::string& cssText) {
        StyleSheet sheet;
        using namespace css::detail;
        std::string no_comments = strip_comments(cssText);
        auto blocks = extract_blocks(no_comments);
        int order = 0;
        std::function<void(const std::vector<RawBlock>&)> processBlocks;
        processBlocks = [&](const std::vector<RawBlock>& items) {
            for (const auto& rb : items) {
                if (rb.is_at_media) {
                    auto inner = extract_blocks(rb.block);
                    processBlocks(inner);
                    continue;
                }
                auto selectors = split_selector_list(rb.selectors);
                if (selectors.empty()) continue;
                Rule r;
                r.selectors = selectors;
                r.selectorMeta.reserve(selectors.size());
                for (const auto& s : selectors) {
                    SelectorMeta meta;
                    meta.events = collect_event_flags(s, &meta.pseudos);
                    r.selectorMeta.push_back(std::move(meta));
                }
                r.decls = parse_decls(rb.block);
                r.order = order++;
                sheet.rules.push_back(std::move(r));
            }
        };
        processBlocks(blocks);
        return sheet;
    }

    std::vector<Declaration> parseDeclarationList(const std::string& block) {
        return css::detail::parse_decls(block);
    }
}