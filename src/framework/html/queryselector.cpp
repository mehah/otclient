#include "queryselector.h"
#include <sstream>
#include <functional>
#include <cstdlib>
#include <algorithm>
#include <cctype>

struct AttrTest
{
    std::string key;
    std::string val;
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
        for (char c : expr) if (!std::isspace((unsigned char)c)) s.push_back((char)c);
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

    static Selector parse(const std::string& selectorStr) {
        Selector sel;
        std::stringstream ss(selectorStr);
        std::string token;
        SelectorStep::Combinator lastComb = SelectorStep::Combinator::Descendant;

        auto parseCompound = [](const std::string& tok)->SimpleSelector {
            SimpleSelector s;
            size_t i = 0;
            auto readIdent = [&](std::string& out) {
                size_t start = i;
                while (i < tok.size() && (std::isalnum((unsigned char)tok[i]) || tok[i] == '-' || tok[i] == '_')) ++i;
                out = tok.substr(start, i - start);
            };
            if (i < tok.size() && std::isalpha((unsigned char)tok[i])) {
                readIdent(s.tag);
                stdext::tolower(s.tag);
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
                    ++i; size_t ks = i;
                    while (i < tok.size() && tok[i] != '=' && tok[i] != ']') ++i;
                    std::string key = tok.substr(ks, i - ks);
                    stdext::tolower(key);

                    std::string val;
                    if (i < tok.size() && tok[i] == '=') {
                        ++i;
                        if (i < tok.size() && (tok[i] == '\"' || tok[i] == '\'')) {
                            char q = tok[i++]; size_t vs = i;
                            while (i < tok.size() && tok[i] != q) ++i;
                            val = tok.substr(vs, i - vs);
                            if (i < tok.size()) ++i;
                        } else {
                            size_t vs = i;
                            while (i < tok.size() && tok[i] != ']') ++i;
                            val = tok.substr(vs, i - vs);
                        }
                    }
                    while (i < tok.size() && tok[i] != ']') ++i;
                    if (i < tok.size()) ++i;
                    s.attrs.push_back({ key,val });
                } else if (c == ':') {
                    s.pseudo = tok.substr(i + 1);
                    break;
                } else ++i;
            }
            return s;
        };

        while (ss >> token) {
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

    bool matchesSimple(const std::shared_ptr<HtmlNode>& node, const SimpleSelector& s) const {
        if (!s.tag.empty() && node->tag != s.tag) return false;
        if (!s.id.empty() && node->getAttr("id") != s.id) return false;
        for (auto& cls : s.classes)
            if (!classContains(node->getAttr("class"), cls)) return false;
        for (auto& a : s.attrs) {
            std::string v = node->getAttr(a.key);
            if (a.val.empty()) { if (v.empty()) return false; } else if (v != a.val) return false;
        }
        if (!s.pseudo.empty()) {
            if (s.pseudo == "first-child") {
                if (auto p = node->parent.lock()) {
                    for (auto& c : p->children)
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
                    int cnt = 0; for (auto& c : p->children) if (c->tag != "text") ++cnt;
                    return cnt == 1;
                } return false;
            }
            if (s.pseudo == "empty") {
                for (auto& c : node->children) if (c->tag != "text") return false;
                return node->text.empty();
            }
            if (s.pseudo.rfind("nth-child(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inside = s.pseudo.substr(10, s.pseudo.size() - 11);
                if (auto p = node->parent.lock()) {
                    int idx = 0;
                    for (auto& c : p->children) if (c->tag != "text") { ++idx; if (c.get() == node.get()) break; }
                    return matchesNth(idx, inside);
                } return false;
            }
            if (s.pseudo == "first-of-type") {
                if (auto p = node->parent.lock()) {
                    for (auto& c : p->children) if (c->tag == node->tag) return c.get() == node.get();
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
                    for (auto& c : p->children) if (c->tag == node->tag) { ++idx; if (c.get() == node.get()) break; }
                    return matchesNth(idx, inside);
                } return false;
            }
            if (s.pseudo.rfind("not(", 0) == 0 && s.pseudo.back() == ')') {
                std::string inner = s.pseudo.substr(4, s.pseudo.length() - 5);
                Selector neg = Selector::parse(inner);
                if (!neg.steps.empty() && matchesSimple(node, neg.steps[0].simple)) return false;
            }
        }
        return true;
    }

    bool matches(const std::shared_ptr<HtmlNode>& node, const SelectorStep& step) const {
        return matchesSimple(node, step.simple);
    }
};

static inline bool isElement(const std::shared_ptr<HtmlNode>& n) { return n && n->tag != "text"; }

static void queryInternal(std::shared_ptr<HtmlNode> node, const Selector& sel, size_t depth, bool findAll, std::vector<std::shared_ptr<HtmlNode>>& out) {
    if (!node || depth >= sel.steps.size()) return;
    const auto& step = sel.steps[depth];
    bool matched = isElement(node) && sel.matches(node, step);
    if (matched) {
        if (depth + 1 == sel.steps.size()) {
            out.push_back(node);
            if (!findAll) return;
        } else {
            switch (step.combinatorToNext) {
                case SelectorStep::Combinator::Child:
                    for (auto& c : node->children) if (isElement(c)) queryInternal(c, sel, depth + 1, findAll, out); break;
                case SelectorStep::Combinator::Descendant:
                    for (auto& c : node->children) if (isElement(c)) { queryInternal(c, sel, depth + 1, findAll, out); queryInternal(c, sel, depth, findAll, out); } break;
                case SelectorStep::Combinator::Adjacent:
                    if (auto p = node->parent.lock()) { bool take = false; for (auto& s : p->children) { if (!isElement(s))continue; if (take) { queryInternal(s, sel, depth + 1, findAll, out); break; } if (s.get() == node.get()) take = true; } } break;
                case SelectorStep::Combinator::Sibling:
                    if (auto p = node->parent.lock()) { bool after = false; for (auto& s : p->children) { if (!isElement(s))continue; if (after) queryInternal(s, sel, depth + 1, findAll, out); if (s.get() == node.get()) after = true; } } break;
            }
        }
    }
    if (depth == 0 && (findAll || out.empty())) for (auto& c : node->children) queryInternal(c, sel, 0, findAll, out);
}

std::vector<std::shared_ptr<HtmlNode>> querySelectorAll(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    Selector sel = Selector::parse(selectorStr);
    std::vector<std::shared_ptr<HtmlNode>> res;
    queryInternal(root, sel, 0, true, res);
    return res;
}

std::shared_ptr<HtmlNode> querySelector(std::shared_ptr<HtmlNode> root, const std::string& selectorStr) {
    Selector sel = Selector::parse(selectorStr);
    std::vector<std::shared_ptr<HtmlNode>> res;
    queryInternal(root, sel, 0, false, res);
    return res.empty() ? nullptr : res[0];
}