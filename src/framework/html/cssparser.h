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
#include <cstdint>

namespace css {
    enum SelectorEventFlags : uint32_t { SEF_None = 0, SEF_Hover = 1u << 0, SEF_Focus = 1u << 1, SEF_Active = 1u << 2, SEF_FocusWithin = 1u << 3, SEF_FocusVisible = 1u << 4, SEF_Visited = 1u << 5, SEF_Checked = 1u << 6, SEF_Disabled = 1u << 7, SEF_Enabled = 1u << 8 };
    struct SelectorMeta { uint32_t events{ SEF_None }; std::vector<std::string> pseudos; };
    struct Declaration
    {
        std::string property;
        std::string value;
        bool important{ false };
    };

    struct Rule
    {
        std::vector<std::string> selectors;
        std::vector<SelectorMeta> selectorMeta;
        std::vector<Declaration> decls;
        int order{ 0 };
    };

    struct StyleSheet
    {
        std::vector<Rule> rules;
    };

    using StyleMap = std::unordered_map<std::string, std::string>;

    struct CascadeOptions
    {
        bool parse_inline_style{ true };
        bool media_always_true{ true };
    };

    StyleSheet parse(const std::string& cssText);
    std::vector<Declaration> parseDeclarationList(const std::string& block);

    void applyStyleSheet(const HtmlNodePtr& root,
                         const StyleSheet& sheet,
                         std::unordered_map<const HtmlNode*, StyleMap>& out,
                         const CascadeOptions& opts = {});

    StyleMap computeStyleFor(const HtmlNodePtr& root,
                             const HtmlNodePtr& element,
                             const StyleSheet& sheet,
                             const CascadeOptions& opts = {});
}
