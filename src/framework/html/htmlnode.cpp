#include "htmlnode.h"
#include "queryselector.h"

std::string HtmlNode::getAttr(const std::string& name) const {
    auto key = ascii_tolower_copy(name);
    auto it = attributes.find(key);
    return (it != attributes.end()) ? it->second : "";
}

bool HtmlNode::hasAttr(const std::string& name) const {
    auto key = ascii_tolower_copy(name);
    return attributes.find(key) != attributes.end();
}

size_t HtmlNode::indexInParent() const {
    if (auto p = parent.lock()) {
        for (size_t i = 0; i < p->children.size(); ++i) {
            if (p->children[i].get() == this) return i;
        }
    }
    return size_t(-1);
}

bool HtmlNode::isOnlyChild() const {
    if (auto p = parent.lock()) {
        size_t count = 0;
        for (const auto& child : p->children) if (child->type == NodeType::Element) ++count;
        return count == 1;
    }
    return false;
}

bool HtmlNode::isLastChild() const {
    if (auto p = parent.lock()) {
        for (int i = (int)p->children.size() - 1; i >= 0; --i) {
            if (p->children[i]->type == NodeType::Element) return p->children[i].get() == this;
        }
    }
    return false;
}

bool HtmlNode::isEmpty() const {
    for (const auto& c : children) {
        if (c->type == NodeType::Element) return false;
        if (c->type == NodeType::Text && !c->text.empty()) return false;
    }
    return true;
}

int HtmlNode::indexAmongElements() const {
    if (cacheIndexAmongElements >= 0) return cacheIndexAmongElements;
    int idx = 0;
    if (auto p = parent.lock()) {
        for (const auto& c : p->children) {
            if (c->type == NodeType::Element) {
                ++idx;
                if (c.get() == this) break;
            }
        }
    }
    cacheIndexAmongElements = idx;
    return idx;
}

int HtmlNode::indexAmongType() const {
    if (cacheIndexAmongType >= 0) return cacheIndexAmongType;
    int idx = 0;
    if (auto p = parent.lock()) {
        for (const auto& c : p->children) {
            if (c->type == NodeType::Element && c->tag == tag) {
                ++idx;
                if (c.get() == this) break;
            }
        }
    }
    cacheIndexAmongType = idx;
    return idx;
}

std::shared_ptr<HtmlNode> HtmlNode::documentRoot() const {
    std::shared_ptr<HtmlNode> cur = const_cast<HtmlNode*>(this)->shared_from_this();
    while (cur->parent.lock()) cur = cur->parent.lock();
    return cur;
}

std::vector<std::shared_ptr<HtmlNode>> HtmlNode::querySelectorAll(const std::string& selector) {
    return ::querySelectorAll(this->shared_from_this(), selector);
}

std::shared_ptr<HtmlNode> HtmlNode::querySelector(const std::string& selector) {
    return ::querySelector(this->shared_from_this(), selector);
}