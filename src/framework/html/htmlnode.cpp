#include "htmlnode.h"
#include "queryselector.h"

std::string HtmlNode::getAttr(const std::string& name) const {
    auto it = attributes.find(name);
    return (it != attributes.end()) ? it->second : "";
}

size_t HtmlNode::indexInParent() const {
    if (auto p = parent.lock()) {
        for (size_t i = 0; i < p->children.size(); ++i) {
            if (p->children[i].get() == this)
                return i;
        }
    }
    return 0;
}

bool HtmlNode::isOnlyChild() const {
    if (auto p = parent.lock()) {
        size_t count = 0;
        for (const auto& child : p->children) {
            if (child->tag != "text") ++count;
        }
        return count == 1;
    }
    return false;
}

bool HtmlNode::isLastChild() const {
    if (auto p = parent.lock()) {
        for (int i = static_cast<int>(p->children.size()) - 1; i >= 0; --i) {
            if (p->children[i]->tag != "text") {
                return p->children[i].get() == this;
            }
        }
    }
    return false;
}

bool HtmlNode::isEmpty() const {
    return text.empty() && children.empty();
}

std::vector<std::shared_ptr<HtmlNode>> HtmlNode::querySelectorAll(const std::string& selector) {
    return ::querySelectorAll(std::shared_ptr<HtmlNode>(this, [](HtmlNode*) {}), selector);
}

std::shared_ptr<HtmlNode> HtmlNode::querySelector(const std::string& selector) {
    return ::querySelector(std::shared_ptr<HtmlNode>(this, [](HtmlNode*) {}), selector);
}