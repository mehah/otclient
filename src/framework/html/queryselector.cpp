#include "queryselector.h"
#include <algorithm>
#include <cctype>
#include <functional>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

// Forward declarations so methods can reference them
struct Selector;
static const Selector& getOrParseSelector(const std::string&);
static bool matchFrom(const std::shared_ptr<HtmlNode>&, const Selector&, size_t);

// Scope pseudo support
thread_local const HtmlNode* g_qs_scope = nullptr;

static inline bool isSpace(unsigned char c) { return std::isspace(c); }
static inline bool isAlphaNum_(unsigned char c) { return std::isalnum(c) || c == '-' || c == '_'; }
static inline bool isElement(const std::shared_ptr<HtmlNode>& n) { return n && n->type == NodeType::Element; }

struct PtrHash { size_t operator()(const HtmlNode* p) const noexcept { return std::hash<const void*>{}(p); } };
struct PtrEq { bool operator()(const HtmlNode* a, const HtmlNode* b) const noexcept { return a == b; } };

struct AttrTest
{
    enum class Op { Present, Equals, Includes, Prefix, Suffix, Substr, DashMatch };
    std::string key; // lowercased
    std::string val;
    Op op = Op::Present;
};

struct SimpleSelector
{
    std::string tag; // lowercased or "*"
    std::string id;
    std::vector<std::string> classes;
    std::vector<AttrTest> attrs;
    std::string pseudo;
};

struct SelectorStep
{
    enum class Combinator { Descendant, Child, Adjacent, Sibling };
    SimpleSelector simple;
    Combinator combinatorToPrev = Combinator::Descendant; // RIGHT-TO-LEFT
};

struct Selector
{
    // steps[0] = rightmost
    std::vector<SelectorStep> steps;

    static std::vector<std::string> splitSelectorList(const std::string& s) {
        std::vector<std::string> parts; std::string cur; int paren = 0, bracket = 0;
        for (char ch : s) {
            if (ch == '(') ++paren; else if (ch == ')') --paren;
            else if (ch == '[') ++bracket; else if (ch == ']') --bracket;
            if (ch == ',' && paren == 0 && bracket == 0) { if (!cur.empty()) { parts.push_back(cur); cur.clear(); } } else cur.push_back(ch);
        }
        if (!cur.empty()) parts.push_back(cur);
        return parts;
    }

    static std::vector<std::string> tokenize(const std::string& s) {
        std::vector<std::string> tokens; std::string cur; int paren = 0, bracket = 0;
        auto flush = [&] { if (!cur.empty()) { tokens.push_back(cur); cur.clear(); } };
        for (size_t i = 0; i < s.size(); ++i) {
            char ch = s[i];
            if (ch == '(') ++paren; else if (ch == ')') --paren;
            else if (ch == '[') ++bracket; else if (ch == ']') --bracket;
            if (paren == 0 && bracket == 0 && (ch == '>' || ch == '+' || ch == '~')) { flush(); tokens.emplace_back(1, ch); } else if (paren == 0 && bracket == 0 && isSpace((unsigned char)ch)) { flush(); } else cur.push_back(ch);
        }
        flush(); return tokens;
    }

    static SimpleSelector parseCompound(const std::string& tok) {
        SimpleSelector s; size_t i = 0;
        auto readIdent = [&](std::string& out) { size_t st = i; while (i < tok.size() && isAlphaNum_((unsigned char)tok[i])) ++i; out = tok.substr(st, i - st); };
        if (i < tok.size()) {
            if (tok[i] == '*') { ++i; } else if (std::isalpha((unsigned char)tok[i])) { readIdent(s.tag); ascii_tolower_inplace(s.tag); }
        }
        while (i < tok.size()) {
            char c = tok[i];
            if (c == '.') { ++i; std::string cls; readIdent(cls); if (!cls.empty()) s.classes.push_back(cls); } else if (c == '#') { ++i; std::string id; readIdent(id); s.id = id; } else if (c == '[') {
                ++i; while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                size_t ks = i; while (i < tok.size() && !isSpace((unsigned char)tok[i]) && tok[i] != ']' && tok[i] != '=' && tok[i] != '~' && tok[i] != '^' && tok[i] != '$' && tok[i] != '*' && tok[i] != '|') ++i;
                std::string key = tok.substr(ks, i - ks); ascii_tolower_inplace(key);
                while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                AttrTest::Op op = AttrTest::Op::Present; std::string val;
                if (i < tok.size() && (tok[i] == '=' || tok[i] == '~' || tok[i] == '^' || tok[i] == '$' || tok[i] == '*' || tok[i] == '|')) {
                    std::string opStr; if (i + 1 < tok.size() && tok[i + 1] == '=') { opStr = tok.substr(i, 2); i += 2; } else if (tok[i] == '=') { opStr = "="; ++i; }
                    if (opStr == "=")  op = AttrTest::Op::Equals;
                    if (opStr == "~=") op = AttrTest::Op::Includes;
                    if (opStr == "^=") op = AttrTest::Op::Prefix;
                    if (opStr == "$=") op = AttrTest::Op::Suffix;
                    if (opStr == "*=") op = AttrTest::Op::Substr;
                    if (opStr == "|=") op = AttrTest::Op::DashMatch;
                    while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                    if (i < tok.size() && (tok[i] == '\"' || tok[i] == '\'')) {
                        char q = tok[i++]; size_t vs = i; while (i < tok.size() && tok[i] != q) ++i;
                        val = tok.substr(vs, i - vs); if (i < tok.size()) ++i;
                    } else {
                        size_t vs = i; while (i < tok.size() && tok[i] != ']') ++i;
                        val = tok.substr(vs, i - vs); while (!val.empty() && isSpace((unsigned char)val.back())) val.pop_back();
                    }
                }
                while (i < tok.size() && tok[i] != ']') ++i; if (i < tok.size()) ++i;
                s.attrs.push_back({ key,val,op });
            } else if (c == ':') {
                s.pseudo = tok.substr(i + 1);
                break;
            } else ++i;
        }
        return s;
    }

    static Selector parse(const std::string& selectorStr) {
        auto tokens = tokenize(selectorStr);
        struct LStep { SimpleSelector ss; char comb = ' '; };
        std::vector<LStep> left; char lastComb = ' ';
        for (const auto& t : tokens) {
            if (t == ">" || t == "+" || t == "~") { lastComb = t[0]; continue; }
            LStep ls; ls.ss = parseCompound(t); ls.comb = lastComb; lastComb = ' '; left.push_back(std::move(ls));
        }
        Selector sel;
        for (int i = (int)left.size() - 1; i >= 0; --i) {
            SelectorStep step; step.simple = std::move(left[i].ss);
            char c = (i > 0) ? left[i - 1].comb : ' ';
            switch (c) {
                case '>': step.combinatorToPrev = SelectorStep::Combinator::Child; break;
                case '+': step.combinatorToPrev = SelectorStep::Combinator::Adjacent; break;
                case '~': step.combinatorToPrev = SelectorStep::Combinator::Sibling; break;
                default:  step.combinatorToPrev = SelectorStep::Combinator::Descendant; break;
            }
            sel.steps.push_back(std::move(step));
        }
        return sel;
    }

    static bool matchesNth(int idx1Based, const std::string& expr) {
        std::string s; for (char c : expr) if (!isSpace((unsigned char)c)) s.push_back(c);
        ascii_tolower_inplace(s);
        if (s == "odd") return (idx1Based % 2) == 1;
        if (s == "even") return (idx1Based % 2) == 0;
        int a = 0, b = 0; auto npos = s.find('n');
        if (npos == std::string::npos) {
            try { b = std::stoi(s); } catch (...) { return false; }
            return idx1Based == b;
        }
        std::string aStr = s.substr(0, npos), bStr = s.substr(npos + 1);
        if (aStr.empty() || aStr == "+") a = 1; else if (aStr == "-") a = -1; else { try { a = std::stoi(aStr); } catch (...) { return false; } }
        if (!bStr.empty()) { try { b = std::stoi(bStr); } catch (...) { return false; } }
        if (a == 0) return idx1Based == b;
        int diff = idx1Based - b;
        if (diff % a != 0) return false;
        return diff / a >= 0;
    }

    static bool attrMatch(const std::string& v, const AttrTest& a) {
        switch (a.op) {
            case AttrTest::Op::Present:  return !v.empty();
            case AttrTest::Op::Equals:   return v == a.val;
            case AttrTest::Op::Includes: {
                size_t i = 0; while (i < v.size()) {
                    while (i < v.size() && isSpace((unsigned char)v[i])) ++i;
                    size_t s = i; while (i < v.size() && !isSpace((unsigned char)v[i])) ++i;
                    if (s < i && v.substr(s, i - s) == a.val) return true;
                } return false;
            }
            case AttrTest::Op::Prefix:   return v.rfind(a.val, 0) == 0;
            case AttrTest::Op::Suffix:   return v.size() >= a.val.size() && v.compare(v.size() - a.val.size(), a.val.size(), a.val) == 0;
            case AttrTest::Op::Substr:   return v.find(a.val) != std::string::npos;
            case AttrTest::Op::DashMatch:return v == a.val || (v.size() > a.val.size() && v.rfind(a.val + "-", 0) == 0);
        }
        return false;
    }

    bool matchesSimple(const std::shared_ptr<HtmlNode>& node, const SimpleSelector& s) const {
        if (!node || node->type != NodeType::Element) return false;
        if (!s.tag.empty() && s.tag != "*" && node->tag != s.tag) return false;
        if (!s.id.empty() && node->getAttr("id") != s.id) return false;
        for (const auto& cls : s.classes) {
            bool ok = false; for (const auto& t : node->classList) { if (t == cls) { ok = true; break; } }
            if (!ok) return false;
        }
        for (const auto& a : s.attrs) {
            if (a.op == AttrTest::Op::Present) { if (!node->hasAttr(a.key)) return false; } else if (!attrMatch(node->getAttr(a.key), a)) return false;
        }

        if (!s.pseudo.empty()) {
            if (s.pseudo == "root") { return node->parent.expired(); }
            if (s.pseudo == "scope") { return g_qs_scope && node.get() == g_qs_scope; }
            if (s.pseudo == "first-child") {
                if (auto p = node->parent.lock()) {
                    for (const auto& c : p->children) if (c->type == NodeType::Element) return c.get() == node.get();
                } return false;
            }
            if (s.pseudo == "last-child") {
                if (auto p = node->parent.lock()) {
                    for (auto it = p->children.rbegin(); it != p->children.rend(); ++it) if ((*it)->type == NodeType::Element) return (*it).get() == node.get();
                } return false;
            }
            if (s.pseudo == "only-child") {
                if (auto p = node->parent.lock()) {
                    int cnt = 0; for (const auto& c : p->children) if (c->type == NodeType::Element) ++cnt;
                    return cnt == 1;
                } return false;
            }
            if (s.pseudo == "empty") {
                for (const auto& c : node->children) {
                    if (c->type == NodeType::Element) return false;
                    if (c->type == NodeType::Text && !c->text.empty()) return false;
                }
                return true;
            }
            if (s.pseudo.rfind("nth-child(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(10, s.pseudo.size() - 11);
                int idx = node->indexAmongElements();
                return matchesNth(idx, inside);
            }
            if (s.pseudo.rfind("nth-last-child(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(15, s.pseudo.size() - 16);
                int idx = 0, total = 0;
                if (auto p = node->parent.lock()) {
                    for (const auto& c : p->children) if (c->type == NodeType::Element) ++total;
                    for (const auto& c : p->children) if (c->type == NodeType::Element) {
                        ++idx;
                        if (c.get() == node.get()) break;
                    }
                }
                int lastIdx = (total - idx) + 1;
                return matchesNth(lastIdx, inside);
            }

            if (s.pseudo == "first-of-type") {
                if (auto p = node->parent.lock()) {
                    for (const auto& c : p->children) if (c->type == NodeType::Element && c->tag == node->tag) return c.get() == node.get();
                } return false;
            }
            if (s.pseudo == "last-of-type") {
                if (auto p = node->parent.lock()) {
                    for (auto it = p->children.rbegin(); it != p->children.rend(); ++it) if ((*it)->type == NodeType::Element && (*it)->tag == node->tag) return (*it).get() == node.get();
                } return false;
            }
            if (s.pseudo.rfind("nth-of-type(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(12, s.pseudo.size() - 13);
                int idx = node->indexAmongType();
                return matchesNth(idx, inside);
            }
            if (s.pseudo.rfind("nth-last-of-type(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(17, s.pseudo.size() - 18);
                int idx = 0, total = 0;
                if (auto p = node->parent.lock()) {
                    for (const auto& c : p->children) if (c->type == NodeType::Element && c->tag == node->tag) ++total;
                    for (const auto& c : p->children) if (c->type == NodeType::Element && c->tag == node->tag) {
                        ++idx;
                        if (c.get() == node.get()) break;
                    }
                }
                int lastIdx = (total - idx) + 1;
                return matchesNth(lastIdx, inside);
            }

            if (s.pseudo.rfind("not(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(4, s.pseudo.size() - 5);
                for (const auto& part : splitSelectorList(inside)) {
                    const Selector& neg = getOrParseSelector(part);
                    if (!neg.steps.empty() && matchesSimple(node, neg.steps[0].simple)) return false;
                }
            }
            if (s.pseudo.rfind("is(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(3, s.pseudo.size() - 4);
                for (const auto& part : splitSelectorList(inside)) {
                    const Selector& tmp = getOrParseSelector(part);
                    if (!tmp.steps.empty() && matchesSimple(node, tmp.steps[0].simple)) return true;
                } return false;
            }
            if (s.pseudo.rfind("where(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(6, s.pseudo.size() - 7);
                for (const auto& part : splitSelectorList(inside)) {
                    const Selector& tmp = getOrParseSelector(part);
                    if (!tmp.steps.empty() && matchesSimple(node, tmp.steps[0].simple)) return true;
                } return false;
            }
            if (s.pseudo.rfind("has(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(4, s.pseudo.size() - 5);
                const Selector& inner = getOrParseSelector(inside);
                if (inner.steps.empty()) return false;
                std::vector<std::shared_ptr<HtmlNode>> stack;
                for (auto& c : node->children) if (isElement(c)) stack.push_back(c);
                while (!stack.empty()) {
                    auto cur = stack.back(); stack.pop_back();
                    if (matchFrom(cur, inner, 0)) return true;
                    for (auto& c : cur->children) if (isElement(c)) stack.push_back(c);
                }
                return false;
            }
        }
        return true;
    }
};

// ---- Parse cache (must come AFTER Selector is defined) ----
static const Selector& getOrParseSelector(const std::string& s) {
    static std::unordered_map<std::string, Selector> cache;
    auto it = cache.find(s);
    if (it != cache.end()) return it->second;
    Selector parsed = Selector::parse(s);
    auto [pos, ok] = cache.emplace(s, std::move(parsed));
    return pos->second;
}

// Forward declaration
static bool matchFrom(const std::shared_ptr<HtmlNode>& node, const Selector& sel, size_t idx);

static inline bool isUniversal(const std::string& tag) { return tag.empty() || tag == "*"; }

static void seedCandidates(std::shared_ptr<HtmlNode> root, const Selector& sel, std::vector<std::shared_ptr<HtmlNode>>& out) {
    if (sel.steps.empty()) return;
    const auto& right = sel.steps[0].simple;
    auto doc = root->documentRoot();

    if (!right.id.empty()) {
        auto it = doc->idIndex.find(right.id);
        if (it != doc->idIndex.end()) { if (auto sp = it->second.lock()) if (isElement(sp)) out.push_back(sp); }
        return;
    }
    if (!right.classes.empty()) {
        auto it = doc->classIndex.find(right.classes[0]);
        if (it != doc->classIndex.end()) {
            for (auto& w : it->second) if (auto sp = w.lock()) if (isElement(sp)) out.push_back(sp);
            if (!out.empty()) {
                if (!isUniversal(right.tag)) {
                    std::vector<std::shared_ptr<HtmlNode>> filtered;
                    for (auto& n : out) if (n->tag == right.tag) filtered.push_back(n);
                    out.swap(filtered);
                }
                return;
            }
        }
    }
    if (!isUniversal(right.tag)) {
        auto it = doc->tagIndex.find(right.tag);
        if (it != doc->tagIndex.end()) {
            for (auto& w : it->second) if (auto sp = w.lock()) if (isElement(sp)) out.push_back(sp);
            if (!out.empty()) return;
        }
    }
    // Fallback: collect all elements under root
    std::vector<std::shared_ptr<HtmlNode>> st{ root };
    while (!st.empty()) {
        auto cur = st.back(); st.pop_back();
        if (isElement(cur)) out.push_back(cur);
        for (auto& c : cur->children) st.push_back(c);
    }
}

static bool matchFrom(const std::shared_ptr<HtmlNode>& node, const Selector& sel, size_t idx) {
    if (!node || idx >= sel.steps.size()) return false;
    const auto& step = sel.steps[idx];
    if (!sel.matchesSimple(node, step.simple)) return false;
    if (idx + 1 == sel.steps.size()) return true;
    const auto& next = sel.steps[idx + 1];
    switch (next.combinatorToPrev) {
        case SelectorStep::Combinator::Descendant: {
            auto p = node->parent.lock();
            while (p) { if (matchFrom(p, sel, idx + 1)) return true; p = p->parent.lock(); }
            return false;
        }
        case SelectorStep::Combinator::Child: {
            return matchFrom(node->parent.lock(), sel, idx + 1);
        }
        case SelectorStep::Combinator::Adjacent: {
            if (auto p = node->parent.lock()) {
                const auto& kids = p->children;
                for (size_t i = 0; i < kids.size(); ++i) {
                    if (kids[i].get() == node.get()) {
                        for (int j = (int)i - 1; j >= 0; --j) {
                            if (kids[j]->type == NodeType::Element) return matchFrom(kids[j], sel, idx + 1);
                        }
                        break;
                    }
                }
            }
            return false;
        }
        case SelectorStep::Combinator::Sibling: {
            if (auto p = node->parent.lock()) {
                const auto& kids = p->children;
                for (size_t i = 0; i < kids.size(); ++i) {
                    if (kids[i].get() == node.get()) {
                        for (int j = (int)i - 1; j >= 0; --j) {
                            if (kids[j]->type == NodeType::Element)
                                if (matchFrom(kids[j], sel, idx + 1)) return true;
                        }
                        break;
                    }
                }
            }
            return false;
        }
    }
    return false;
}

std::vector<std::shared_ptr<HtmlNode>> querySelectorAll(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    std::vector<std::shared_ptr<HtmlNode>> results;
    std::unordered_set<const HtmlNode*, PtrHash, PtrEq> seen;
    auto lists = Selector::splitSelectorList(selectorStr);
    if (lists.empty()) return results;

    g_qs_scope = root.get();
    for (const auto& part : lists) {
        const Selector& sel = getOrParseSelector(part);
        if (sel.steps.empty()) continue;
        std::vector<std::shared_ptr<HtmlNode>> seeds;
        seedCandidates(root, sel, seeds);
        for (auto& node : seeds) {
            if (matchFrom(node, sel, 0)) {
                if (seen.insert(node.get()).second) results.push_back(node);
            }
        }
    }
    g_qs_scope = nullptr;
    return results;
}

std::shared_ptr<HtmlNode> querySelector(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    auto lists = Selector::splitSelectorList(selectorStr);
    if (lists.empty()) return nullptr;

    g_qs_scope = root.get();
    for (const auto& part : lists) {
        const Selector& sel = getOrParseSelector(part);
        if (sel.steps.empty()) continue;
        std::vector<std::shared_ptr<HtmlNode>> seeds;
        seedCandidates(root, sel, seeds);
        for (auto& node : seeds) {
            if (matchFrom(node, sel, 0)) {
                g_qs_scope = nullptr;
                return node;
            }
        }
    }
    g_qs_scope = nullptr;
    return nullptr;
}