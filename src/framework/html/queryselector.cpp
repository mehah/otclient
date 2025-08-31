#include "queryselector.h"
#include <sstream>
#include <functional>
#include <cstdlib>
#include <algorithm>
#include <cctype>
#include <unordered_set>
#include <vector>
#include <string>

static inline bool isSpace(unsigned char c) { return std::isspace(c); }
static inline bool isAlphaNum_(unsigned char c) { return std::isalnum(c) || c == '-' || c == '_'; }
static inline bool isElement(const std::shared_ptr<HtmlNode>& n) { return n && n->tag != "text"; }

struct PtrHash { size_t operator()(const HtmlNode* p) const noexcept { return std::hash<const void*>{}(p); } };
struct PtrEq { bool operator()(const HtmlNode* a, const HtmlNode* b) const noexcept { return a == b; } };

struct AttrTest
{
    enum class Op { Present, Equals, Includes, Prefix, Suffix, Substr, DashMatch };
    std::string key;
    std::string val;
    Op op = Op::Present;
};

struct SimpleSelector
{
    std::string tag;
    std::string id;
    std::vector<std::string> classes;
    std::vector<AttrTest> attrs;
    std::string pseudo;
};

struct SelectorStep
{
    enum class Combinator { Descendant, Child, Adjacent, Sibling };
    SimpleSelector simple;
    Combinator combinatorToNext = Combinator::Descendant;
};

struct Selector
{
    std::vector<SelectorStep> steps;

    static bool classContains(const std::string& classAttr, const std::string& cls) {
        std::istringstream ss(classAttr);
        for (std::string tok; ss >> tok; )
            if (tok == cls) return true;
        return false;
    }

    static bool matchesNth(int idx1Based, const std::string& expr) {
        std::string s;
        for (char c : expr) if (!isSpace((unsigned char)c)) s.push_back((char)c);
        stdext::tolower(s);
        if (s == "odd")  return (idx1Based % 2) == 1;
        if (s == "even") return (idx1Based % 2) == 0;
        int a = 0, b = 0;
        auto npos = s.find('n');
        if (npos == std::string::npos) {
            try { b = std::stoi(s); } catch (...) { return false; }
            return idx1Based == b;
        } else {
            std::string aStr = s.substr(0, npos);
            std::string bStr = s.substr(npos + 1);
            if (aStr.empty() || aStr == "+") a = 1;
            else if (aStr == "-") a = -1;
            else { try { a = std::stoi(aStr); } catch (...) { return false; } }
            if (!bStr.empty()) { try { b = std::stoi(bStr); } catch (...) { return false; } }
            if (a == 0) return idx1Based == b;
            int diff = idx1Based - b;
            if (diff % a != 0) return false;
            return diff / a >= 0;
        }
    }

    static std::vector<std::string> splitSelectorList(const std::string& s) {
        std::vector<std::string> parts; std::string cur;
        int paren = 0, bracket = 0;
        for (char ch : s) {
            if (ch == '(') ++paren;
            else if (ch == ')') --paren;
            else if (ch == '[') ++bracket;
            else if (ch == ']') --bracket;
            if (ch == ',' && paren == 0 && bracket == 0) {
                if (!cur.empty()) { parts.push_back(cur); cur.clear(); }
            } else cur.push_back(ch);
        }
        if (!cur.empty()) parts.push_back(cur);
        return parts;
    }

    static std::vector<std::string> tokenize(const std::string& s) {
        std::vector<std::string> tokens; std::string cur;
        int paren = 0, bracket = 0;
        auto flush = [&]() { if (!cur.empty()) { tokens.push_back(cur); cur.clear(); } };
        for (size_t i = 0; i < s.size(); ++i) {
            char ch = s[i];
            if (ch == '(') ++paren;
            else if (ch == ')') --paren;
            else if (ch == '[') ++bracket;
            else if (ch == ']') --bracket;
            if (paren == 0 && bracket == 0 && (ch == '>' || ch == '+' || ch == '~')) {
                flush();
                tokens.emplace_back(1, ch);
            } else if (paren == 0 && bracket == 0 && isSpace((unsigned char)ch)) {
                flush();
            } else {
                cur.push_back(ch);
            }
        }
        flush();
        return tokens;
    }

    static Selector parse(const std::string& selectorStr) {
        Selector sel;
        auto tokens = tokenize(selectorStr);
        SelectorStep::Combinator lastComb = SelectorStep::Combinator::Descendant;

        auto parseCompound = [](const std::string& tok)->SimpleSelector {
            SimpleSelector s;
            size_t i = 0;
            auto readIdent = [&](std::string& out) {
                size_t start = i;
                while (i < tok.size() && isAlphaNum_((unsigned char)tok[i])) ++i;
                out = tok.substr(start, i - start);
            };
            if (i < tok.size()) {
                if (tok[i] == '*') {
                    ++i;
                } else if (std::isalpha((unsigned char)tok[i])) {
                    readIdent(s.tag);
                    stdext::tolower(s.tag);
                }
            }
            while (i < tok.size()) {
                char c = tok[i];
                if (c == '.') {
                    ++i; std::string cls; readIdent(cls);
                    if (!cls.empty()) s.classes.push_back(cls);
                } else if (c == '#') {
                    ++i; std::string id; readIdent(id);
                    s.id = id;
                } else if (c == '[') {
                    ++i;
                    while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                    size_t keyStart = i;
                    while (i < tok.size() && !isSpace((unsigned char)tok[i]) && tok[i] != ']' && tok[i] != '=' && tok[i] != '~' && tok[i] != '^' && tok[i] != '$' && tok[i] != '*' && tok[i] != '|') ++i;
                    std::string key = tok.substr(keyStart, i - keyStart);
                    stdext::tolower(key);
                    while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                    AttrTest::Op op = AttrTest::Op::Present;
                    std::string val;
                    if (i < tok.size() && (tok[i] == '=' || tok[i] == '~' || tok[i] == '^' || tok[i] == '$' || tok[i] == '*' || tok[i] == '|')) {
                        std::string opStr;
                        if (i + 1 < tok.size() && tok[i + 1] == '=') { opStr = tok.substr(i, 2); i += 2; } else if (tok[i] == '=') { opStr = "="; ++i; }
                        if (opStr == "=")  op = AttrTest::Op::Equals;
                        if (opStr == "~=") op = AttrTest::Op::Includes;
                        if (opStr == "^=") op = AttrTest::Op::Prefix;
                        if (opStr == "$=") op = AttrTest::Op::Suffix;
                        if (opStr == "*=") op = AttrTest::Op::Substr;
                        if (opStr == "|=") op = AttrTest::Op::DashMatch;
                        while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                        if (i < tok.size() && (tok[i] == '\"' || tok[i] == '\'')) {
                            char q = tok[i++]; size_t vs = i;
                            while (i < tok.size() && tok[i] != q) ++i;
                            val = tok.substr(vs, i - vs);
                            if (i < tok.size()) ++i;
                        } else {
                            size_t vs = i;
                            while (i < tok.size() && tok[i] != ']') ++i;
                            val = tok.substr(vs, i - vs);
                            while (!val.empty() && isSpace((unsigned char)val.back())) val.pop_back();
                        }
                    }
                    while (i < tok.size() && tok[i] != ']') ++i;
                    if (i < tok.size()) ++i;
                    s.attrs.push_back({ key,val,op });
                } else if (c == ':') {
                    s.pseudo = tok.substr(i + 1);
                    break;
                } else ++i;
            }
            return s;
        };

        for (auto& token : tokens) {
            if (token == ">") { lastComb = SelectorStep::Combinator::Child; continue; }
            if (token == "+") { lastComb = SelectorStep::Combinator::Adjacent; continue; }
            if (token == "~") { lastComb = SelectorStep::Combinator::Sibling; continue; }
            SelectorStep step;
            step.combinatorToNext = lastComb;
            lastComb = SelectorStep::Combinator::Descendant;
            step.simple = parseCompound(token);
            sel.steps.push_back(step);
        }
        return sel;
    }

    static bool classTokenIncludes(const std::string& v, const std::string& needle) {
        std::istringstream ss(v);
        for (std::string t; ss >> t;) if (t == needle) return true;
        return false;
    }

    static bool attrMatch(const std::string& v, const AttrTest& a) {
        switch (a.op) {
            case AttrTest::Op::Present:  return !v.empty();
            case AttrTest::Op::Equals:   return v == a.val;
            case AttrTest::Op::Includes: {
                std::istringstream ss(v);
                for (std::string t; ss >> t;) if (t == a.val) return true;
                return false;
            }
            case AttrTest::Op::Prefix:   return v.rfind(a.val, 0) == 0;
            case AttrTest::Op::Suffix:   return v.size() >= a.val.size() && v.compare(v.size() - a.val.size(), a.val.size(), a.val) == 0;
            case AttrTest::Op::Substr:   return v.find(a.val) != std::string::npos;
            case AttrTest::Op::DashMatch:return v == a.val || (v.size() > a.val.size() && v.rfind(a.val + "-", 0) == 0);
        }
        return false;
    }

    bool matchesSimple(const std::shared_ptr<HtmlNode>& node, const SimpleSelector& s) const {
        if (!s.tag.empty() && node->tag != s.tag) return false;
        if (!s.id.empty() && node->getAttr("id") != s.id) return false;
        for (const auto& cls : s.classes)
            if (!classTokenIncludes(node->getAttr("class"), cls)) return false;
        for (const auto& a : s.attrs)
            if (!attrMatch(node->getAttr(a.key), a)) return false;
        if (!s.pseudo.empty()) {
            if (s.pseudo == "first-child") {
                if (auto p = node->parent.lock()) {
                    for (const auto& c : p->children)
                        if (c->tag != "text") return c.get() == node.get();
                } return false;
            }
            if (s.pseudo == "last-child") {
                if (auto p = node->parent.lock()) {
                    for (auto it = p->children.rbegin(); it != p->children.rend(); ++it)
                        if ((*it)->tag != "text") return (*it).get() == node.get();
                } return false;
            }
            if (s.pseudo == "only-child") {
                if (auto p = node->parent.lock()) {
                    int cnt = 0; for (const auto& c : p->children) if (c->tag != "text") ++cnt;
                    return cnt == 1;
                } return false;
            }
            if (s.pseudo == "empty") {
                for (const auto& c : node->children) if (c->tag != "text") return false;
                return node->text.empty();
            }
            if (s.pseudo.rfind("nth-child(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(10, s.pseudo.size() - 11);
                if (auto p = node->parent.lock()) {
                    int idx = 0;
                    for (const auto& c : p->children) if (c->tag != "text") { ++idx; if (c.get() == node.get()) break; }
                    return matchesNth(idx, inside);
                } return false;
            }
            if (s.pseudo == "first-of-type") {
                if (auto p = node->parent.lock()) {
                    for (const auto& c : p->children) if (c->tag == node->tag) return c.get() == node.get();
                } return false;
            }
            if (s.pseudo == "last-of-type") {
                if (auto p = node->parent.lock()) {
                    for (auto it = p->children.rbegin(); it != p->children.rend(); ++it)
                        if ((*it)->tag == node->tag) return (*it).get() == node.get();
                } return false;
            }
            if (s.pseudo.rfind("nth-of-type(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(12, s.pseudo.size() - 13);
                if (auto p = node->parent.lock()) {
                    int idx = 0;
                    for (const auto& c : p->children) if (c->tag == node->tag) { ++idx; if (c.get() == node.get()) break; }
                    return matchesNth(idx, inside);
                } return false;
            }
            if (s.pseudo.rfind("not(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(4, s.pseudo.size() - 5);
                for (auto& part : splitSelectorList(inside)) {
                    Selector neg = Selector::parse(part);
                    if (!neg.steps.empty() && matchesSimple(node, neg.steps[0].simple)) return false;
                }
            }
            if (s.pseudo.rfind("is(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(3, s.pseudo.size() - 4);
                for (auto& part : splitSelectorList(inside)) {
                    Selector tmp = Selector::parse(part);
                    if (!tmp.steps.empty() && matchesSimple(node, tmp.steps[0].simple)) return true;
                }
                return false;
            }
            if (s.pseudo.rfind("where(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(6, s.pseudo.size() - 7);
                for (auto& part : splitSelectorList(inside)) {
                    Selector tmp = Selector::parse(part);
                    if (!tmp.steps.empty() && matchesSimple(node, tmp.steps[0].simple)) return true;
                }
                return false;
            }
            if (s.pseudo.rfind("has(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(4, s.pseudo.size() - 5);
                Selector inner = Selector::parse(inside);
                if (inner.steps.empty()) return false;
                std::vector<std::shared_ptr<HtmlNode>> stack;
                for (auto& c : node->children) if (isElement(c)) stack.push_back(c);
                while (!stack.empty()) {
                    auto cur = stack.back(); stack.pop_back();
                    if (matchSelectorFrom(cur, inner, 0)) return true;
                    for (auto& c : cur->children) if (isElement(c)) stack.push_back(c);
                }
                return false;
            }
        }
        return true;
    }

    static bool matchSelectorFrom(const std::shared_ptr<HtmlNode>& start, const Selector& sel, size_t depth) {
        if (!start || depth >= sel.steps.size()) return false;
        const auto& step = sel.steps[depth];
        if (!isElement(start)) return false;
        if (!sel.matchesSimple(start, step.simple)) return false;
        if (depth + 1 == sel.steps.size()) return true;
        switch (step.combinatorToNext) {
            case SelectorStep::Combinator::Child:
                for (auto& c : start->children) if (isElement(c))
                    if (matchSelectorFrom(c, sel, depth + 1)) return true;
                break;
            case SelectorStep::Combinator::Descendant:
                for (auto& c : start->children) if (isElement(c)) {
                    if (matchSelectorFrom(c, sel, depth + 1)) return true;
                    if (matchSelectorFrom(c, sel, depth)) return true;
                }
                break;
            case SelectorStep::Combinator::Adjacent:
                if (auto p = start->parent.lock()) {
                    bool takeNext = false;
                    for (auto& s : p->children) {
                        if (!isElement(s)) continue;
                        if (takeNext) { if (matchSelectorFrom(s, sel, depth + 1)) return true; break; }
                        if (s.get() == start.get()) takeNext = true;
                    }
                }
                break;
            case SelectorStep::Combinator::Sibling:
                if (auto p = start->parent.lock()) {
                    bool after = false;
                    for (auto& s : p->children) {
                        if (!isElement(s)) continue;
                        if (after && matchSelectorFrom(s, sel, depth + 1)) return true;
                        if (s.get() == start.get()) after = true;
                    }
                }
                break;
        }
        return false;
    }

    bool matches(const std::shared_ptr<HtmlNode>& node, const SelectorStep& step) const {
        return matchesSimple(node, step.simple);
    }
};

static void queryInternal(std::shared_ptr<HtmlNode> node,
                          const Selector& sel, size_t depth, bool findAll,
                          std::vector<std::shared_ptr<HtmlNode>>& out,
                          std::unordered_set<const HtmlNode*, PtrHash, PtrEq>* seen)
{
    if (!node || depth >= sel.steps.size()) return;
    const auto& step = sel.steps[depth];
    bool matched = isElement(node) && sel.matches(node, step);
    if (matched) {
        if (depth + 1 == sel.steps.size()) {
            if (!seen || seen->insert(node.get()).second) out.push_back(node);
            if (!findAll) return;
        } else {
            switch (step.combinatorToNext) {
                case SelectorStep::Combinator::Child:
                    for (auto& c : node->children) if (isElement(c))
                        queryInternal(c, sel, depth + 1, findAll, out, seen);
                    break;
                case SelectorStep::Combinator::Descendant:
                    for (auto& c : node->children) if (isElement(c)) {
                        queryInternal(c, sel, depth + 1, findAll, out, seen);
                        queryInternal(c, sel, depth, findAll, out, seen);
                    }
                    break;
                case SelectorStep::Combinator::Adjacent:
                    if (auto p = node->parent.lock()) {
                        bool takeNext = false;
                        for (auto& s : p->children) {
                            if (!isElement(s)) continue;
                            if (takeNext) { queryInternal(s, sel, depth + 1, findAll, out, seen); break; }
                            if (s.get() == node.get()) takeNext = true;
                        }
                    }
                    break;
                case SelectorStep::Combinator::Sibling:
                    if (auto p = node->parent.lock()) {
                        bool after = false;
                        for (auto& s : p->children) {
                            if (!isElement(s)) continue;
                            if (after) queryInternal(s, sel, depth + 1, findAll, out, seen);
                            if (s.get() == node.get()) after = true;
                        }
                    }
                    break;
            }
        }
    }
    if (depth == 0 && (findAll || out.empty())) {
        for (auto& c : node->children)
            queryInternal(c, sel, 0, findAll, out, seen);
    }
}

std::vector<std::shared_ptr<HtmlNode>> querySelectorAll(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    std::vector<std::shared_ptr<HtmlNode>> res;
    std::unordered_set<const HtmlNode*, PtrHash, PtrEq> seen;
    for (auto& part : Selector::splitSelectorList(selectorStr)) {
        if (part.empty()) continue;
        Selector sel = Selector::parse(part);
        queryInternal(root, sel, 0, true, res, &seen);
    }
    return res;
}

std::shared_ptr<HtmlNode> querySelector(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    auto lists = Selector::splitSelectorList(selectorStr);
    if (lists.empty()) return nullptr;
    std::vector<std::shared_ptr<HtmlNode>> res;
    for (auto& part : lists) {
        Selector sel = Selector::parse(part);
        queryInternal(root, sel, 0, false, res, nullptr);
        if (!res.empty()) break;
    }
    return res.empty() ? nullptr : res[0];
}