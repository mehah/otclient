#include "queryselector.h"
#include <sstream>
#include <functional>
#include <algorithm>
#include <unordered_set>
#include <vector>
#include <string>
#include <cctype>

static inline bool isSpace(unsigned char c) { return std::isspace(c); }
static inline bool isAlphaNum_(unsigned char c) { return std::isalnum(c) || c == '-' || c == '_'; }
static inline bool isElement(const std::shared_ptr<HtmlNode>& n) { return n && n->type == NodeType::Element; }

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
    Combinator combinatorToPrev = Combinator::Descendant; 
};

struct Selector
{
    std::vector<SelectorStep> steps; 

    static std::vector<std::string> splitSelectorList(const std::string& s) {
        std::vector<std::string> parts; std::string cur; int paren = 0, bracket = 0;
        for (char ch : s) {
            if (ch == '(') ++paren; else if (ch == ')') --paren;
            else if (ch == '[') ++bracket; else if (ch == ']') --bracket;
            if (ch == ',' && paren == 0 && bracket == 0) { if (!cur.empty()) { parts.push_back(cur); cur.clear(); } }
            else cur.push_back(ch);
        }
        if (!cur.empty()) parts.push_back(cur);
        return parts;
    }

    static std::vector<std::string> tokenize(const std::string& s) {
        std::vector<std::string> tokens; std::string cur; int paren = 0, bracket = 0;
        auto flush = [&]() { if (!cur.empty()) { tokens.push_back(cur); cur.clear(); } };
        for (size_t i = 0; i < s.size(); ++i) {
            char ch = s[i];
            if (ch == '(') ++paren; else if (ch == ')') --paren;
            else if (ch == '[') ++bracket; else if (ch == ']') --bracket;
            if (paren == 0 && bracket == 0 && (ch == '>' || ch == '+' || ch == '~')) { flush(); tokens.emplace_back(1, ch); }
            else if (paren == 0 && bracket == 0 && isSpace((unsigned char)ch)) { flush(); }
            else { cur.push_back(ch); }
        }
        flush(); return tokens;
    }

    static SimpleSelector parseCompound(const std::string& tok) {
        SimpleSelector s; size_t i = 0;
        auto readIdent = [&](std::string& out) {
            size_t start = i; while (i < tok.size() && isAlphaNum_((unsigned char)tok[i])) ++i;
            out = tok.substr(start, i - start);
        };
        if (i < tok.size()) {
            if (tok[i] == '*') { ++i; }
            else if (std::isalpha((unsigned char)tok[i])) { readIdent(s.tag); ascii_tolower_inplace(s.tag); }
        }
        while (i < tok.size()) {
            char c = tok[i];
            if (c == '.') { ++i; std::string cls; readIdent(cls); if (!cls.empty()) s.classes.push_back(cls); }
            else if (c == '#') { ++i; std::string id; readIdent(id); s.id = id; }
            else if (c == '[') {
                ++i; while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                size_t keyStart = i;
                while (i < tok.size() && !isSpace((unsigned char)tok[i]) && tok[i] != ']' && tok[i] != '=' && tok[i] != '~' && tok[i] != '^' && tok[i] != '$' && tok[i] != '*' && tok[i] != '|') ++i;
                std::string key = tok.substr(keyStart, i - keyStart); ascii_tolower_inplace(key);
                while (i < tok.size() && isSpace((unsigned char)tok[i])) ++i;
                AttrTest::Op op = AttrTest::Op::Present; std::string val;
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
                        char q = tok[i++]; size_t vs = i; while (i < tok.size() && tok[i] != q) ++i; val = tok.substr(vs, i - vs); if (i < tok.size()) ++i;
                    } else {
                        size_t vs = i; while (i < tok.size() && tok[i] != ']') ++i; val = tok.substr(vs, i - vs);
                        while (!val.empty() && isSpace((unsigned char)val.back())) val.pop_back();
                    }
                }
                while (i < tok.size() && tok[i] != ']') ++i; if (i < tok.size()) ++i;
                s.attrs.push_back({ key,val,op });
            } else if (c == ':') { s.pseudo = tok.substr(i + 1); break; }
            else { ++i; }
        }
        return s;
    }

    static Selector parse(const std::string& selectorStr) {
        auto tokens = tokenize(selectorStr);
        struct LStep { SimpleSelector ss; char combAfter = ' '; };
        std::vector<LStep> left; char lastComb = ' ';
        for (auto& t : tokens) {
            if (t == ">" || t == "+" || t == "~") { lastComb = t[0]; continue; }
            LStep ls; ls.ss = parseCompound(t); ls.combAfter = lastComb; lastComb = ' '; left.push_back(std::move(ls));
        }
        Selector sel;
        for (int i = int(left.size()) - 1; i >= 0; --i) {
            SelectorStep step; step.simple = std::move(left[i].ss);
            char c = (i > 0) ? left[i-1].combAfter : ' ';
            switch (c) { case '>': step.combinatorToPrev = SelectorStep::Combinator::Child; break;
                         case '+': step.combinatorToPrev = SelectorStep::Combinator::Adjacent; break;
                         case '~': step.combinatorToPrev = SelectorStep::Combinator::Sibling; break;
                         default:  step.combinatorToPrev = SelectorStep::Combinator::Descendant; break; }
            sel.steps.push_back(std::move(step));
        }
        return sel;
    }

    static bool matchesNth(int idx1Based, const std::string& expr) {
        std::string s; for (char c : expr) if (!isSpace((unsigned char)c)) s.push_back((char)c);
        ascii_tolower_inplace(s);
        if (s == "odd")  return (idx1Based % 2) == 1;
        if (s == "even") return (idx1Based % 2) == 0;
        int a = 0, b = 0; auto npos = s.find('n');
        if (npos == std::string::npos) { try { b = std::stoi(s); } catch (...) { return false; } return idx1Based == b; }
        std::string aStr = s.substr(0, npos), bStr = s.substr(npos + 1);
        if (aStr.empty() || aStr == "+") a = 1; else if (aStr == "-") a = -1; else { try { a = std::stoi(aStr); } catch (...) { return false; } }
        if (!bStr.empty()) { try { b = std::stoi(bStr); } catch (...) { return false; } }
        if (a == 0) return idx1Based == b;
        int diff = idx1Based - b; if (diff % a != 0) return false; return diff / a >= 0;
    }

    static bool classListContains(const std::vector<std::string>& list, const std::string& cls) {
        for (const auto& c : list) if (c == cls) return true;
        return false;
    }

    static bool attrMatch(const std::string& v, const AttrTest& a) {
        switch (a.op) {
            case AttrTest::Op::Present:  return !v.empty();
            case AttrTest::Op::Equals:   return v == a.val;
            case AttrTest::Op::Includes: { std::istringstream ss(v); for (std::string t; ss >> t;) if (t == a.val) return true; return false; }
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
        for (const auto& cls : s.classes) if (!classListContains(node->classList, cls)) return false;
        for (const auto& a : s.attrs) if (!attrMatch(node->getAttr(a.key), a)) return false;

        if (!s.pseudo.empty()) {
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
                for (const auto& c : node->children) if (c->type == NodeType::Element) return false;
                return node->text.empty();
            }
            if (s.pseudo.rfind("nth-child(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(10, s.pseudo.size() - 11);
                return matchesNth(node->indexAmongElementsCached(), inside);
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
                return matchesNth(node->indexAmongTypeCached(), inside);
            }
            if (!s.pseudo.empty() && s.pseudo.rfind("not(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(4, s.pseudo.size() - 5);
                for (auto& part : splitSelectorList(inside)) {
                    Selector neg = Selector::parse(part);
                    if (!neg.steps.empty() && matchesSimple(node, neg.steps[0].simple)) return false;
                }
            }
            if (!s.pseudo.empty() && s.pseudo.rfind("is(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(3, s.pseudo.size() - 4);
                for (auto& part : splitSelectorList(inside)) {
                    Selector tmp = Selector::parse(part);
                    if (!tmp.steps.empty() && matchesSimple(node, tmp.steps[0].simple)) return true;
                }
                return false;
            }
            if (!s.pseudo.empty() && s.pseudo.rfind("where(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(6, s.pseudo.size() - 7);
                for (auto& part : splitSelectorList(inside)) {
                    Selector tmp = Selector::parse(part);
                    if (!tmp.steps.empty() && matchesSimple(node, tmp.steps[0].simple)) return true;
                }
                return false;
            }
            if (!s.pseudo.empty() && s.pseudo.rfind("has(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(4, s.pseudo.size() - 5);
                Selector inner = Selector::parse(inside);
                if (inner.steps.empty()) return false;
                std::vector<std::shared_ptr<HtmlNode>> dfs;
                dfs.reserve(node->children.size());
                for (auto& c : node->children) if (isElement(c)) dfs.push_back(c);
                while (!dfs.empty()) {
                    auto cur = dfs.back(); dfs.pop_back();
                    if (matchFrom(cur, inner, 0)) return true;
                    for (auto& c : cur->children) if (isElement(c)) dfs.push_back(c);
                }
                return false;
            }
        }
        return true;
    }

    static bool matchFrom(const std::shared_ptr<HtmlNode>& node, const Selector& sel, size_t stepIdx) {
        if (!node || stepIdx >= sel.steps.size()) return false;
        const auto& step = sel.steps[stepIdx];
        if (!sel.matchesSimple(node, step.simple)) return false;
        if (stepIdx + 1 == sel.steps.size()) return true;
        const auto& next = sel.steps[stepIdx + 1];
        switch (next.combinatorToPrev) {
            case SelectorStep::Combinator::Descendant: {
                auto p = node->parent.lock();
                while (p) { if (matchFrom(p, sel, stepIdx + 1)) return true; p = p->parent.lock(); }
                return false;
            }
            case SelectorStep::Combinator::Child: {
                auto p = node->parent.lock(); return matchFrom(p, sel, stepIdx + 1);
            }
            case SelectorStep::Combinator::Adjacent: {
                if (auto p = node->parent.lock()) {
                    const auto& kids = p->children;
                    for (size_t i = 0; i < kids.size(); ++i) {
                        if (kids[i].get() == node.get()) {
                            for (int j = int(i) - 1; j >= 0; --j) {
                                if (kids[j]->type == NodeType::Element) return matchFrom(kids[j], sel, stepIdx + 1);
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
                            for (int j = int(i) - 1; j >= 0; --j) {
                                if (kids[j]->type == NodeType::Element) { if (matchFrom(kids[j], sel, stepIdx + 1)) return true; }
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
};

static inline bool isUniversal(const std::string& tag){ return tag.empty() || tag == "*"; }

static void collectElementsDFS(const std::shared_ptr<HtmlNode>& root, std::vector<std::shared_ptr<HtmlNode>>& out) {
    std::vector<std::shared_ptr<HtmlNode>> st; st.push_back(root);
    while (!st.empty()) {
        auto n = st.back(); st.pop_back();
        if (!n) continue;
        if (n->type == NodeType::Element) out.push_back(n);
        for (auto& c : n->children) st.push_back(c);
    }
}

static std::vector<std::shared_ptr<HtmlNode>> seedCandidates(std::shared_ptr<HtmlNode> root, const Selector& sel) {
    std::vector<std::shared_ptr<HtmlNode>> out;
    if (!root) return out;
    if (sel.steps.empty()) return out;
    const auto& s = sel.steps[0].simple;

    if (!s.id.empty()) {
        auto it = root->idIndex.find(s.id);
        if (it != root->idIndex.end()) {
            if (auto sp = it->second.lock()) if (isElement(sp)) out.push_back(sp);
        }
        return out;
    }

    if (!s.classes.empty()) {
        auto it = root->classIndex.find(s.classes[0]);
        if (it != root->classIndex.end()) {
            const auto& vec = it->second;
            out.reserve(vec.size());
            for (auto& wp : vec) if (auto sp = wp.lock()) if (isElement(sp)) out.push_back(sp);
            if (s.classes.size() > 1) {
                std::vector<std::shared_ptr<HtmlNode>> filtered;
                for (auto& n : out) {
                    bool ok = true;
                    for (size_t i = 1; i < s.classes.size(); ++i) {
                        bool has = false;
                        for (const auto& cls : n->classList) if (cls == s.classes[i]) { has = true; break; }
                        if (!has) { ok = false; break; }
                    }
                    if (ok) filtered.push_back(n);
                }
                out.swap(filtered);
            }
            if (!isUniversal(s.tag)) {
                std::vector<std::shared_ptr<HtmlNode>> filtered;
                for (auto& n : out) if (n->tag == s.tag) filtered.push_back(n);
                out.swap(filtered);
            }
            return out;
        }
    }

    if (!isUniversal(s.tag)) {
        auto it = root->tagIndex.find(s.tag);
        if (it != root->tagIndex.end()) {
            const auto& vec = it->second;
            out.reserve(vec.size());
            for (auto& wp : vec) if (auto sp = wp.lock()) if (isElement(sp)) out.push_back(sp);
            return out;
        }
    }

    collectElementsDFS(root, out);
    return out;
}

std::vector<std::shared_ptr<HtmlNode>> querySelectorAll(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    std::vector<std::shared_ptr<HtmlNode>> results;
    std::unordered_set<const HtmlNode*, PtrHash, PtrEq> seen;
    auto lists = Selector::splitSelectorList(selectorStr);
    if (lists.empty()) return results;

    for (auto& part : lists) {
        Selector sel = Selector::parse(part);
        if (sel.steps.empty()) continue;
        auto seeds = seedCandidates(root, sel);
        for (auto& node : seeds) {
            if (Selector::matchFrom(node, sel, 0)) {
                if (seen.insert(node.get()).second) results.push_back(node);
            }
        }
    }
    return results;
}

std::shared_ptr<HtmlNode> querySelector(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    auto lists = Selector::splitSelectorList(selectorStr);
    if (lists.empty()) return nullptr;
    for (auto& part : lists) {
        Selector sel = Selector::parse(part);
        if (sel.steps.empty()) continue;
        auto seeds = seedCandidates(root, sel);
        for (auto& node : seeds) {
            if (Selector::matchFrom(node, sel, 0)) return node;
        }
    }
    return nullptr;
}
