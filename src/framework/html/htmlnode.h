#pragma once
#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include <algorithm>

inline void ascii_tolower_inplace(std::string& s) { for (auto& c : s) if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a'); }
inline std::string ascii_tolower_copy(std::string s) { ascii_tolower_inplace(s); return s; }

enum class NodeType { Element, Text, Comment, Doctype };

class HtmlNode : public std::enable_shared_from_this<HtmlNode>
{
public:
    // === Public accessors to private state ===
    NodeType getType() const { return type; }
    const std::string& getTag() const { return tag; }
    const std::unordered_map<std::string, std::string>& getAttributesMap() const { return attributes; }
    const std::vector<std::string>& getClassList() const { return classList; }
    const std::vector<std::shared_ptr<HtmlNode>>& getChildren() const { return children; }
    const std::weak_ptr<HtmlNode>& getParent() const { return parent; }
    const std::string& getRawText() const { return text; }

    // Indexed lookup helpers (read‑only views over the document root indices)
    std::shared_ptr<HtmlNode> getById(const std::string& id) const {
        auto root = documentRoot();
        auto it = root->idIndex.find(id);
        if (it == root->idIndex.end()) return nullptr;
        return it->second.lock();
    }
    std::vector<std::shared_ptr<HtmlNode>> getByClass(const std::string& cls) const {
        std::vector<std::shared_ptr<HtmlNode>> out;
        auto root = documentRoot();
        auto it = root->classIndex.find(cls);
        if (it == root->classIndex.end()) return out;
        out.reserve(it->second.size());
        for (auto& w : it->second) { if (auto sp = w.lock()) out.push_back(sp); }
        return out;
    }
    std::vector<std::shared_ptr<HtmlNode>> getByTag(const std::string& t) const {
        std::vector<std::shared_ptr<HtmlNode>> out;
        auto root = documentRoot();
        auto it = root->tagIndex.find(t);
        if (it == root->tagIndex.end()) return out;
        out.reserve(it->second.size());
        for (auto& w : it->second) { if (auto sp = w.lock()) out.push_back(sp); }
        return out;
    }
std::string getAttr(const std::string& name) const;
    std::string getText() const;

    bool hasAttr(const std::string& name) const;

    size_t indexInParent() const;
    bool isOnlyChild() const;
    bool isLastChild() const;
    bool isEmpty() const;

    int indexAmongElements() const;
    int indexAmongType() const;

    std::shared_ptr<HtmlNode> documentRoot() const;

    std::vector<std::shared_ptr<HtmlNode>> querySelectorAll(const std::string& selector);
    std::shared_ptr<HtmlNode> querySelector(const std::string& selector);


    // Friends allowed to build/maintain internal structures efficiently
    friend std::shared_ptr<HtmlNode> parseHtml(const std::string& html);
    friend void invalidateIndexCachesUp(HtmlNode* n);

private:
    NodeType type{ NodeType::Element };
    std::string tag;
    std::unordered_map<std::string, std::string> attributes;
    std::vector<std::string> classList;
    std::vector<std::shared_ptr<HtmlNode>> children;
    std::string text;
    std::weak_ptr<HtmlNode> parent;

    std::unordered_map<std::string, std::weak_ptr<HtmlNode>> idIndex;
    std::unordered_map<std::string, std::vector<std::weak_ptr<HtmlNode>>> classIndex;
    std::unordered_map<std::string, std::vector<std::weak_ptr<HtmlNode>>> tagIndex;

    mutable int cacheIndexAmongElements = -1;
    mutable int cacheIndexAmongType = -1;
};

inline void invalidateIndexCachesUp(HtmlNode* n) {
    while (n) {
        n->cacheIndexAmongElements = -1;
        n->cacheIndexAmongType = -1;
        auto p = n->parent.lock();
        n = p ? p.get() : nullptr;
    }
}
