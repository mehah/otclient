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

    std::string getAttr(const std::string& name) const;

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
};



inline void invalidateIndexCachesUp(HtmlNode* n) {
    while (n) {
        n->cacheIndexAmongElements = -1;
        n->cacheIndexAmongType = -1;
        auto p = n->parent.lock();
        n = p ? p.get() : nullptr;
    }
}
