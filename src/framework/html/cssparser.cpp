#include "cssparser.h"
#include "htmlnode.h"
#include "queryselector.h"

#include <algorithm>
#include <cctype>
#include <climits>
#include <tuple>
#include <unordered_set>

namespace css {
    namespace detail {
        static inline void ascii_tolower_inplace_local(std::string& s) {
            for (auto& c : s) if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
        }

        // Remove /* ... */ comments (no nesting per CSS)
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

        // Trim ASCII whitespace
        static inline void trim_inplace(std::string& s) {
            size_t a = 0; while (a < s.size() && (unsigned char)s[a] <= ' ') ++a;
            size_t b = s.size(); while (b > a && (unsigned char)s[b - 1] <= ' ') --b;
            s = s.substr(a, b - a);
        }

        // Split on top-level commas (ignoring (), [], {} and strings)
        static std::vector<std::string> split_top_commas(const std::string& s) {
            std::vector<std::string> parts; std::string cur;
            int paren = 0, brack = 0, brace = 0; bool in_str = false; char q = 0;
            for (size_t i = 0; i < s.size(); ++i) {
                char c = s[i];
                if (in_str) {
                    cur.push_back(c);
                    if (c == q) in_str = false;
                    else if (c == '\\\\' && i + 1 < s.size()) cur.push_back(s[++i]);
                    continue;
                }
                if (c == '\"' || c == '\'') { in_str = true; q = c; cur.push_back(c); continue; }
                if (c == '(') ++paren; else if (c == ')') --paren;
                else if (c == '[') ++brack; else if (c == ']') --brack;
                else if (c == '{') ++brace; else if (c == '}') --brace;
                if (c == ',' && paren == 0 && brack == 0 && brace == 0) { if (!cur.empty()) { parts.push_back(cur); cur.clear(); } continue; }
                cur.push_back(c);
            }
            if (!cur.empty()) parts.push_back(cur);
            return parts;
        }

        // Walk CSS text producing (selectors, block) pairs. Supports @media blocks (flattened).
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
                    if (i < N && s[i] == ';') { ++i; continue; } // ignore at-rule without block
                    if (i >= N || s[i] != '{') break;
                    int depth = 1; size_t blockStart = ++i;
                    for (; i < N; ++i) {
                        char c = s[i];
                        if (c == '\"' || c == '\'') {
                            char q = c; ++i; while (i < N && s[i] != q) { if (s[i] == '\\\\' && i + 1 < N) i += 2; else ++i; }
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
                    if (c == '\"' || c == '\'') {
                        char q = c; ++i; while (i < N && s[i] != q) { if (s[i] == '\\\\' && i + 1 < N) i += 2; else ++i; }
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

        // Parse a declaration block (content inside {...})
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
                ++i; // skip ':'
                size_t v0 = i; int paren = 0, brack = 0, brace = 0; bool in_str = false; char q = 0;
                for (; i < N; ++i) {
                    char c = s[i];
                    if (in_str) { if (c == q) in_str = false; else if (c == '\\\\' && i + 1 < N) ++i; continue; }
                    if (c == '\"' || c == '\'') { in_str = true; q = c; continue; }
                    if (c == '(') ++paren; else if (c == ')') --paren;
                    else if (c == '[') ++brack; else if (c == ']') --brack;
                    else if (c == '{') ++brace; else if (c == '}') --brace;
                    if (c == ';' && paren == 0 && brack == 0 && brace == 0) break;
                }
                std::string val = s.substr(v0, i - v0);
                // handle !important
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
                    out.push_back({ prop, val, important });
                }
                if (i < N && s[i] == ';') ++i;
            }
            return out;
        }

        // Specificity (a,b,c) calculation for one selector
        static std::tuple<int, int, int> specificity_of(const std::string& sel);

        static bool is_ident_start(char c) {
            return std::isalpha((unsigned char)c) || c == '_' || c == '-';
        }

        static std::vector<std::string> split_selector_list(const std::string& inside) {
            auto v = split_top_commas(inside); std::vector<std::string> out; out.reserve(v.size());
            for (auto t : v) { trim_inplace(t); if (!t.empty()) out.push_back(t); }
            return out;
        }

        static std::tuple<int, int, int> specificity_max(const std::vector<std::string>& list) {
            std::tuple<int, int, int> best{ 0,0,0 };
            for (const auto& s : list) {
                auto sp = specificity_of(s);
                if (sp > best) best = sp;
            }
            return best;
        }

        static std::tuple<int, int, int> specificity_of(const std::string& sel) {
            int a = 0, b = 0, c = 0; // IDs, classes/attrs/pseudo-classes, elements/pseudo-elements
            const std::string& s = sel;
            for (size_t i = 0; i < s.size();) {
                char ch = s[i];
                if (ch == '\"' || ch == '\'') { char q = ch; ++i; while (i < s.size() && s[i] != q) { if (s[i] == '\\\\' && i + 1 < s.size()) i += 2; else ++i; } if (i < s.size()) ++i; continue; }
                if (ch == '[') {
                    ++b; ++i; int depth = 1; while (i < s.size() && depth>0) {
                        if (s[i] == '\"' || s[i] == '\'') { char q = s[i++]; while (i < s.size() && s[i] != q) { if (s[i] == '\\\\' && i + 1 < s.size()) i += 2; else ++i; } if (i < s.size())++i; } else if (s[i] == '[') ++depth; else if (s[i] == ']') --depth; else ++i;
                    }
                    continue;
                }
                if (ch == '#') { ++a; ++i; while (i < s.size() && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i; continue; }
                if (ch == '.') { ++b; ++i; while (i < s.size() && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i; continue; }
                if (ch == ':') {
                    size_t col = 1; ++i; if (i < s.size() && s[i] == ':') { ++col; ++i; }
                    size_t nameStart = i; while (i < s.size() && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i;
                    std::string name = s.substr(nameStart, i - nameStart); std::string lower = name; ascii_tolower_inplace_local(lower);
                    if (col == 2) { ++c; continue; }
                    if (i < s.size() && s[i] == '(') {
                        ++i; size_t contentStart = i; int depth = 1; bool in_str = false; char q = 0;
                        for (; i < s.size(); ++i) {
                            char ch2 = s[i];
                            if (in_str) { if (ch2 == q) in_str = false; else if (ch2 == '\\\\' && i + 1 < s.size()) ++i; continue; }
                            if (ch2 == '\"' || ch2 == '\'') { in_str = true; q = ch2; continue; }
                            if (ch2 == '(') ++depth; else if (ch2 == ')') { if (--depth == 0) { ++i; break; } }
                        }
                        std::string inside = s.substr(contentStart, (i - contentStart - 1));
                        std::string lower2 = inside; // not used for tokenizing here
                        // :not() / :is() / :has() / :where() specificity handling
                        // We don't parse the inner selector; we only compute specificity impact per spec.
                        std::string nameLower = lower;
                        if (nameLower == "not" || nameLower == "is" || nameLower == "has") {
                            auto parts = split_selector_list(inside);
                            auto sp = specificity_max(parts);
                            a += std::get<0>(sp); b += std::get<1>(sp); c += std::get<2>(sp);
                        } else if (nameLower == "where") {
                            // zero specificity
                        } else {
                            ++b;
                        }
                        continue;
                    } else {
                        ++b; continue;
                    }
                }
                if (is_ident_start(ch)) {
                    size_t st = i; while (i < s.size() && (std::isalnum((unsigned char)s[i]) || s[i] == '-' || s[i] == '_')) ++i;
                    std::string ident = s.substr(st, i - st);
                    if (!(ident.size() == 1 && ident[0] == '*')) ++c;
                    continue;
                }
                ++i;
            }
            return { a,b,c };
        }

        struct Winner
        {
            bool important{ false };
            int a{ 0 }, b{ 0 }, c{ 0 };
            int order{ 0 };
            std::string value;
        };

        static inline bool better(const Winner& x, const Winner& y) {
            if (x.important != y.important) return x.important; // important beats non-important
            if (x.a != y.a) return x.a > y.a;
            if (x.b != y.b) return x.b > y.b;
            if (x.c != y.c) return x.c > y.c;
            return x.order > y.order; // later wins
        }
    } // namespace detail

    // --- Public parse() ---
    StyleSheet parse(const std::string& cssText) {
        using namespace detail;
        StyleSheet out;
        std::string no_comments = strip_comments(cssText);
        auto blocks = extract_blocks(no_comments);
        int order = 0;
        for (auto& b : blocks) {
            if (b.is_at_media) {
                // flatten inner blocks
                auto inner = extract_blocks(b.block);
                for (auto& ib : inner) {
                    if (ib.selectors.empty()) continue;
                    Rule r; r.order = order++;
                    auto sels = split_top_commas(ib.selectors);
                    for (auto s : sels) { trim_inplace(s); if (!s.empty()) r.selectors.push_back(s); }
                    r.decls = parse_decls(ib.block);
                    if (!r.selectors.empty() && !r.decls.empty()) out.rules.emplace_back(std::move(r));
                }
                continue;
            }
            if (b.selectors.empty()) continue;
            Rule r; r.order = order++;
            auto sels = split_top_commas(b.selectors);
            for (auto s : sels) { trim_inplace(s); if (!s.empty()) r.selectors.push_back(s); }
            r.decls = parse_decls(b.block);
            if (!r.selectors.empty() && !r.decls.empty()) out.rules.emplace_back(std::move(r));
        }
        return out;
    }

    std::vector<Declaration> parseDeclarationList(const std::string& block) {
        return detail::parse_decls(block);
    }

    // --- Cascade (sheet -> node styles) ---
    void applyStyleSheet(const std::shared_ptr<HtmlNode>& root,
                         const StyleSheet& sheet,
                         std::unordered_map<const HtmlNode*, StyleMap>& out,
                         const CascadeOptions& opts) {
        using namespace detail;

        struct PtrHash { size_t operator()(const HtmlNode* p) const noexcept { return std::hash<const void*>{}(p); } };
        struct PtrEq { bool operator()(const HtmlNode* a, const HtmlNode* b) const noexcept { return a == b; } };

        std::unordered_map<const HtmlNode*, std::unordered_map<std::string, Winner>, PtrHash, PtrEq> winners_by_node;

        // 1) apply rules
        for (const auto& rule : sheet.rules) {
            for (const auto& sel : rule.selectors) {
                auto sp = specificity_of(sel);
                auto matches = querySelectorAll(root, sel);
                for (auto& node : matches) {
                    if (!node || node->getType() != NodeType::Element) continue;
                    auto& propmap = winners_by_node[node.get()];
                    for (const auto& d : rule.decls) {
                        Winner cand{ d.important, std::get<0>(sp), std::get<1>(sp), std::get<2>(sp), rule.order, d.value };
                        auto it = propmap.find(d.property);
                        if (it == propmap.end() || better(cand, it->second)) propmap[d.property] = cand;
                    }
                }
            }
        }

        // 2) inline styles
        if (opts.parse_inline_style) {
            auto all = querySelectorAll(root, "*");
            for (auto& node : all) {
                if (!node || node->getType() != NodeType::Element) continue;
                std::string styleAttr = node->getAttr("style");
                if (styleAttr.empty()) continue;
                auto decls = detail::parse_decls(styleAttr);
                auto& propmap = winners_by_node[node.get()];
                for (const auto& d : decls) {
                    Winner cand{ d.important, 1000, 0, 0, INT_MAX / 2, d.value };
                    auto it = propmap.find(d.property);
                    if (it == propmap.end() || better(cand, it->second)) propmap[d.property] = cand;
                }
            }
        }

        // 3) write back StyleMap
        out.clear();
        out.reserve(winners_by_node.size());
        for (auto& kv : winners_by_node) {
            StyleMap sm;
            sm.reserve(kv.second.size());
            for (auto& pv : kv.second) sm.emplace(pv.first, std::move(pv.second.value));
            out.emplace(kv.first, std::move(sm));
        }
    }

    // Compute styles for a single element by running a targeted cascade
    StyleMap computeStyleFor(const std::shared_ptr<HtmlNode>& root,
                             const std::shared_ptr<HtmlNode>& element,
                             const StyleSheet& sheet,
                             const CascadeOptions& opts) {
        using namespace detail;
        std::unordered_map<std::string, Winner> winners;

        if (!element || element->getType() != NodeType::Element) return {};

        // 1) rules
        for (const auto& rule : sheet.rules) {
            for (const auto& sel : rule.selectors) {
                auto matches = querySelectorAll(root, sel);
                bool hit = false;
                for (auto& n : matches) { if (n.get() == element.get()) { hit = true; break; } }
                if (!hit) continue;
                auto sp = specificity_of(sel);
                for (const auto& d : rule.decls) {
                    Winner cand{ d.important, std::get<0>(sp), std::get<1>(sp), std::get<2>(sp), rule.order, d.value };
                    auto it = winners.find(d.property);
                    if (it == winners.end() || better(cand, it->second)) winners[d.property] = cand;
                }
            }
        }

        // 2) inline
        if (opts.parse_inline_style) {
            std::string styleAttr = element->getAttr("style");
            if (!styleAttr.empty()) {
                auto decls = detail::parse_decls(styleAttr);
                for (const auto& d : decls) {
                    Winner cand{ d.important, 1000, 0, 0, INT_MAX / 2, d.value };
                    auto it = winners.find(d.property);
                    if (it == winners.end() || better(cand, it->second)) winners[d.property] = cand;
                }
            }
        }

        StyleMap out;
        out.reserve(winners.size());
        for (auto& kv : winners) out.emplace(kv.first, std::move(kv.second.value));
        return out;
    }
} // namespace css