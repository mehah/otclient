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

#include "htmlnode.h"
#include <framework/otml/otml.h>

std::string HtmlNode::getAttr(const std::string& name) const {
    auto key = ascii_tolower_copy(name);
    auto it = attributes.find(key);
    return (it != attributes.end()) ? it->second : "";
}

void HtmlNode::setAttr(const std::string& name, const std::string& value) {
    auto key = ascii_tolower_copy(name);
    attributes[key] = value;
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

HtmlNodePtr HtmlNode::documentRoot() const {
    HtmlNodePtr cur = const_cast<HtmlNode*>(this)->shared_from_this();
    while (cur->parent.lock()) cur = cur->parent.lock();
    return cur;
}

std::string HtmlNode::getStyle(std::string_view styleName) const {
    auto name = std::string{ styleName };
    {
        auto it = m_attrStyles.find(name);
        if (it != m_attrStyles.end())
            return it->second;
    }

    for (const auto& [key, styles] : m_styles) {
        auto it = styles.find(name);
        if (it != styles.end())
            return it->second;
    }

    return "";
}

std::vector<HtmlNodePtr> HtmlNode::querySelectorAll(const std::string& selector) {
    return ::querySelectorAll(this->shared_from_this(), selector);
}

HtmlNodePtr HtmlNode::querySelector(const std::string& selector) {
    return ::querySelector(this->shared_from_this(), selector);
}

std::string HtmlNode::textContent() const {
    switch (type) {
        case NodeType::Text:
            return text;
        case NodeType::Element: {
            std::string out = text;
            for (const auto& c : children) {
                out += c->textContent();
            }
            return out;
        }
        default:
            return "";
    }
}

void HtmlNode::append(const HtmlNodePtr& child) {
    attachChild(child, children.size());
}

void HtmlNode::prepend(const HtmlNodePtr& child) {
    attachChild(child, 0);
}

void HtmlNode::insert(const HtmlNodePtr& child, size_t pos) {
    if (pos > children.size()) pos = children.size();
    attachChild(child, pos);
}

void HtmlNode::detachFromCurrentParent(const HtmlNodePtr& child) {
    if (!child) return;
    auto oldParent = child->parent.lock();
    if (!oldParent) return;

    auto& vec = oldParent->children;
    for (size_t i = 0; i < vec.size(); ++i) {
        if (vec[i].get() == child.get()) {
            auto left = (i > 0) ? vec[i - 1] : nullptr;
            auto right = (i + 1 < vec.size()) ? vec[i + 1] : nullptr;
            if (left)  left->next.reset();
            if (right) right->prev.reset();
            if (left && right) {
                left->next = right;
                right->prev = left;
            }
            vec.erase(vec.begin() + i);
            break;
        }
    }
    child->parent.reset();
    child->prev.reset();
    child->next.reset();

    invalidateIndexCachesUp(oldParent.get());
}

void HtmlNode::attachChild(const HtmlNodePtr& child, size_t pos) {
    if (!child) return;

    if (auto oldParent = child->parent.lock()) {
        if (oldParent.get() != this) {
            detachFromCurrentParent(child);
        } else {
            auto& vec = children;
            for (size_t i = 0; i < vec.size(); ++i) {
                if (vec[i].get() == child.get()) {
                    auto left = (i > 0) ? vec[i - 1] : nullptr;
                    auto right = (i + 1 < vec.size()) ? vec[i + 1] : nullptr;
                    if (left)  left->next.reset();
                    if (right) right->prev.reset();
                    if (left && right) {
                        left->next = right;
                        right->prev = left;
                    }
                    vec.erase(vec.begin() + i);
                    if (pos > vec.size()) pos = vec.size();
                    break;
                }
            }
        }
    }

    if (!children.empty()) {
        if (pos == 0) {
            child->next = children.front();
            children.front()->prev = child;
        } else if (pos == children.size()) {
            child->prev = children.back();
            children.back()->next = child;
        } else {
            auto before = children[pos - 1];
            auto after = children[pos];
            child->prev = before;
            child->next = after;
            before->next = child;
            after->prev = child;
        }
    }

    child->parent = shared_from_this();
    children.insert(children.begin() + pos, child);

    registerInIndexes(child);
    invalidateIndexCachesUp(this);
}

void HtmlNode::registerInIndexes(const HtmlNodePtr& child) {
    if (!child || child->type != NodeType::Element) return;
    auto root = documentRoot();

    if (!child->tag.empty() && child->tag != "root")
        root->tagIndex[child->tag].push_back(child);

    std::string idv = child->getAttr("id");
    if (!idv.empty())
        root->idIndex[idv] = child;

    if (!child->classList.empty())
        for (auto& cls : child->classList)
            root->classIndex[cls].push_back(child);
}

void HtmlNode::unregisterSubtreeFromIndexes(const HtmlNodePtr& node) {
    if (!node) return;
    auto root = documentRoot();

    auto prune_vec = [](auto& vec, const HtmlNode* target) {
        vec.erase(std::remove_if(vec.begin(), vec.end(),
                  [&](const std::weak_ptr<HtmlNode>& w) {
            auto sp = w.lock();
            return !sp || sp.get() == target;
        }), vec.end());
    };

    std::vector<HtmlNodePtr> stack{ node };
    while (!stack.empty()) {
        auto cur = stack.back(); stack.pop_back();

        if (cur->type == NodeType::Element) {
            if (!cur->tag.empty() && cur->tag != "root") {
                auto it = root->tagIndex.find(cur->tag);
                if (it != root->tagIndex.end()) prune_vec(it->second, cur.get());
            }
            std::string idv = cur->getAttr("id");
            if (!idv.empty()) {
                auto it = root->idIndex.find(idv);
                if (it != root->idIndex.end() && !it->second.expired() && it->second.lock().get() == cur.get())
                    root->idIndex.erase(it);
            }
            if (!cur->classList.empty()) {
                for (auto& cls : cur->classList) {
                    auto it = root->classIndex.find(cls);
                    if (it != root->classIndex.end()) prune_vec(it->second, cur.get());
                }
            }
        }

        for (auto& c : cur->children) stack.push_back(c);
    }
}

void HtmlNode::destroy() {
    auto self = shared_from_this();
    auto p = parent.lock();
    if (!p) return;

    unregisterSubtreeFromIndexes(self);

    auto& vec = p->children;
    for (size_t i = 0; i < vec.size(); ++i) {
        if (vec[i].get() == this) {
            auto left = (i > 0) ? vec[i - 1] : nullptr;
            auto right = (i + 1 < vec.size()) ? vec[i + 1] : nullptr;
            if (left)  left->next.reset();
            if (right) right->prev.reset();
            if (left && right) {
                left->next = right;
                right->prev = left;
            }
            vec.erase(vec.begin() + i);
            break;
        }
    }

    parent.reset();
    prev.reset();
    next.reset();

    invalidateIndexCachesUp(p.get());
}

void HtmlNode::remove(const HtmlNodePtr& child) {
    if (!child) return;
    auto it = std::find_if(children.begin(), children.end(),
        [&](const HtmlNodePtr& c) { return c.get() == child.get(); });
    if (it == children.end()) return;

    child->unregisterSubtreeFromIndexes(child);

    auto left = (it != children.begin()) ? *(it - 1) : nullptr;
    auto right = (std::next(it) != children.end()) ? *(it + 1) : nullptr;
    if (left)  left->next.reset();
    if (right) right->prev.reset();
    if (left && right) {
        left->next = right;
        right->prev = left;
    }

    children.erase(it);

    child->parent.reset();
    child->prev.reset();
    child->next.reset();

    invalidateIndexCachesUp(this);
}

void HtmlNode::clear() {
    if (children.empty()) return;

    auto root = documentRoot();
    for (auto& child : children) {
        unregisterSubtreeFromIndexes(child);
        child->parent.reset();
        child->prev.reset();
        child->next.reset();
    }

    children.clear();

    invalidateIndexCachesUp(this);
}