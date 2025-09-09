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

#pragma once

#include "declarations.h"
#include <framework/ui/declarations.h>
#include "cssparser.h"

struct DataRoot
{
    HtmlNodePtr node;
    std::string moduleName;
    std::vector<css::StyleSheet> sheets;
    std::unordered_map<std::string, UIWidgetPtr> groups;
};

class HtmlManager
{
public:
    uint32_t load(const std::string& moduleName, const std::string& htmlPath, UIWidgetPtr parent);
    void destroy(uint32_t id);
    void addGlobalStyle(const std::string& style);
    UIWidgetPtr getRootWidget(uint32_t htmlId);
    void terminate() { m_nodes.clear(); }
    UIWidgetPtr createWidgetFromHTML(const std::string& html, const UIWidgetPtr& parent, uint32_t htmlId);

private:
    DataRoot readNode(DataRoot& root, const HtmlNodePtr& node, const UIWidgetPtr& parent, const std::string& moduleName, const std::string& htmlPath, bool checkRuleExist, uint32_t htmlId);

    stdext::map<uint32_t, DataRoot> m_nodes;
};

extern HtmlManager g_html;
