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