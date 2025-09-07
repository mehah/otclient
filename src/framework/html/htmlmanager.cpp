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

#include "htmlmanager.h"
#include <framework/ui/uimanager.h>
#include <framework/ui/ui.h>

#include "htmlnode.h"
#include "htmlparser.h"
#include "cssparser.h"
#include <framework/core/resourcemanager.h>
#include <ranges>
#include <framework/core/modulemanager.h>

HtmlManager g_html;
css::StyleSheet GLOBAL_STYLE;

static const std::unordered_map<std::string, std::string> IMG_ATTR_TRANSLATED = {
    {"offset-x", "image-offset-x"},
    {"offset-y", "image-offset-y"},
    {"offset", "image-offset"},
    {"width", "image-width"},
    {"height", "image-height"},
    {"size", "image-size"},
    {"rect", "image-rect"},
    {"clip", "image-clip"},
    {"fixed-ratio", "image-fixed-ratio"},
    {"repeated", "image-repeated"},
    {"smooth", "image-smooth"},
    {"color", "image-color"},
    {"border-top", "image-border-top"},
    {"border-right", "image-border-right"},
    {"border-bottom", "image-border-bottom"},
    {"border-left", "image-border-left"},
    {"border", "image-border"},
    {"auto-resize", "image-auto-resize"},
    {"individual-animation", "image-individual-animation"},
    {"src", "image-source"}
};

static const std::unordered_map<std::string, std::string> cssMap = {
    {"active", "active"},
    {"focus", "focus"},
    {"hover", "hover"},
    {"pressed", "pressed"},
    {"checked", "checked"},
    {"disabled", "disabled"},
    {"first-child", "first"},
    {"middle", "middle"},
    {"last-child", "last"},
    {"nth-child(even)", "alternate"},
    {"nth-child(odd)", "alternate"},
    {"on", "on"},
    {"[aria-pressed='true']", "on"},
    {"[data-on]", "on"},
    {"dragging", "dragging"},
    {"hidden", "hidden"},
    {"[hidden]", "hidden"},
    {"mobile", "mobile"},
    {"@media", "mobile"}
};

static constexpr std::array<std::string_view, 19> kProps = {
    "color",
    "cursor",
    "direction",
    "font",
    "font-family",
    "font-size",
    "font-style",
    "font-variant",
    "font-weight",
    "letter-spacing",
    "line-height",
    "text-align",
    "text-indent",
    "text-transform",
    "unicode-bidi",
    "visibility",
    "white-space",
    "word-spacing",
    "writing-mode"
};

static inline bool isInheritable(std::string_view prop) {
    return std::binary_search(kProps.begin(), kProps.end(), prop);
}

std::string cssToState(const std::string& css) {
    if (auto it = cssMap.find(css); it != cssMap.end())
        return it->second;
    return "";
}

void parseAttrPropList(const std::string& attrsStr, std::map<std::string, std::string>& attrsMap) {
    for (auto& data : stdext::split(attrsStr, ";")) {
        stdext::trim(data);
        auto attr = stdext::split(data, ":");
        if (attr.size() > 1) {
            stdext::trim(attr[0]);
            stdext::trim(attr[1]);
            attrsMap[attr[0]] = attr[1];
        }
    }
}

void translateAttribute(const std::string& styleName, const std::string& tagName, std::string& attr, std::string& value) {
    if (attr == "*style") {
        attr = "*mergeStyle";
    } else if (attr == "*if") {
        attr = "*visible";
    } else if (attr == "disabled") {
        attr = "enabled";
        if (value == "disabled" || value == "true")
            value = "false";
    }

    if (styleName != "CheckBox" && styleName != "ComboBox") {
        if (attr == "*value") {
            attr = "*text";
        } else if (attr == "value") {
            attr = "text";
        }
    }

    if (tagName == "img") {
        auto it = IMG_ATTR_TRANSLATED.find(attr);
        if (it != IMG_ATTR_TRANSLATED.end()) {
            attr = it->second;
        }
    }
}

std::string translateStyleName(const std::string& styleName, const HtmlNodePtr& el) {
    if (styleName == "select") {
        return "QtComboBox";
    }

    if (styleName == "hr") {
        return "HorizontalSeparator";
    }

    if (styleName == "input") {
        const auto& type = el->getAttr("type");
        if (type == "checkbox" || type == "radio") {
            return "QtCheckBox";
        }
        return "TextEdit";
    }

    if (styleName == "textarea") {
        return "MultilineTextEdit";
    }

    return styleName;
}

void createRadioGroup(const HtmlNodePtr& node, std::unordered_map<std::string, UIWidgetPtr>& groups) {
    const auto& name = node->getAttr("name");
    if (name.empty())
        return;

    UIWidgetPtr group;
    auto it = groups.find(name);
    if (it == groups.end()) {
        group = groups
            .emplace(name, g_lua.callGlobalField<UIWidgetPtr>("UIRadioGroup", "create"))
            .first->second;
    } else group = it->second;

    group->callLuaField("addWidget", node->getWidget());
}

UIWidgetPtr readNode(const HtmlNodePtr& node, const UIWidgetPtr& parent) {
    if (node->getType() == NodeType::Comment || node->getType() == NodeType::Doctype)
        return nullptr;

    const auto& styleName = g_ui.getStyleName(translateStyleName(node->getTag(), node));

    auto widget = g_ui.createWidget(styleName.empty() ? "UIWidget" : styleName, parent);
    node->setWidget(widget);
    widget->setHtmlNode(node);

    widget->callLuaField("onCreateByHTML", node->getAttributesMap());

    for (const auto [key, v] : node->getAttributesMap()) {
        auto attr = key;
        auto value = v;
        translateAttribute(styleName, node->getTag(), attr, value);

        if (attr.starts_with("on")) {
            // lua call
        } else if (attr == "anchor") {
            // ignore
        } else if (attr == "style") {
            parseAttrPropList(value, node->getAttrStyles());
        } else if (attr == "layout") {
            auto otml = std::make_shared<OTMLNode>();
            auto layout = std::make_shared<OTMLNode>();

            std::map<std::string, std::string> styles;
            parseAttrPropList(value, styles);
            for (const auto [tag, value] : styles) {
                auto nodeAttr = std::make_shared<OTMLNode>();
                nodeAttr->setTag(tag);
                nodeAttr->setValue(value);
                layout->addChild(nodeAttr);
            }

            layout->setTag("layout");
            otml->addChild(layout);
            widget->mergeStyle(otml);
        } else if (attr == "class") {
            for (const auto& className : stdext::split(value, " ")) {
                if (const auto& style = g_ui.getStyle(className))
                    widget->mergeStyle(style);
            }
        } else {
            widget->callLuaField("__applyOrBindHtmlAttribute", attr, value);
        }
    }

    if (!node->getText().empty()) {
        widget->setTextAutoResize(true);
        widget->setText(node->getText());
    }

    if (node->getChildren().size() && node->getChildren()[0]->getType() == NodeType::Text) {
        widget->setText(node->getChildren()[0]->getText());
    } else for (const auto& child : node->getChildren()) {
        readNode(child, widget);
    }

    return widget;
}

uint32_t HtmlManager::load(const std::string& moduleName, const std::string& htmlPath, UIWidgetPtr parent) {
    auto path = "/modules/" + moduleName + "/";
    auto htmlContent = g_resources.readFileContents(path + htmlPath);
    auto root = parseHtml(htmlContent);
    if (root->getChildren().empty())
        return 0;

    std::vector<css::StyleSheet> sheets;

    if (!parent)
        parent = g_ui.getRootWidget();

    for (const auto& node : root->getChildren()) {
        if (node->getTag() == "style") {
            sheets.emplace_back(css::parse(node->textContent()));
        } else if (node->getTag() == "link") {
            if (node->hasAttr("href")) {
                sheets.emplace_back(css::parse(g_resources.readFileContents(path + node->getAttr("href"))));
            }
        } else readNode(node, parent);
    }

    auto parseStyle = [&](const css::StyleSheet& sheet, bool checkRuleExist) {
        static const auto setChildrenStyles = [](const HtmlNodePtr& n, const css::Declaration& decl, const std::string& style, const auto& self) -> void {
            for (const auto& child : n->getChildren()) {
                if (!child->hasAttr("id")) {
                    child->getStyles()[style][decl.property] = decl.value;
                }
                self(child, decl, style, self);
            }
        };

        for (const auto& rule : sheet.rules) {
            const auto& selectors = stdext::join(rule.selectors);
            const auto& nodes = root->querySelectorAll(selectors);

            if (checkRuleExist && nodes.empty()) {
                g_logger.warning("[{}][style] selector({}) no element was found.", htmlPath, selectors);
                continue;
            }

            for (const auto& node : nodes) {
                if (node->getWidget()) {
                    bool hasMeta = false;
                    for (const auto& metas : rule.selectorMeta) {
                        for (const auto& state : metas.pseudos) {
                            for (const auto& decl : rule.decls) {
                                std::string style = "$";
                                if (state.negated)
                                    style += "!";
                                style += state.name;

                                node->getStyles()[style][decl.property] = decl.value;
                                if (isInheritable(decl.property)) {
                                    setChildrenStyles(node, decl, style, setChildrenStyles);
                                }
                            }
                            hasMeta = true;
                        }
                    }

                    if (hasMeta)
                        continue;

                    for (const auto& decl : rule.decls) {
                        node->getStyles()["styles"][decl.property] = decl.value;
                        if (isInheritable(decl.property)) {
                            setChildrenStyles(node, decl, "styles", setChildrenStyles);
                        }
                    }
                }
            }
        }
    };

    parseStyle(GLOBAL_STYLE, false);
    for (const auto& sheet : sheets)
        parseStyle(sheet, true);

    std::unordered_map<std::string, UIWidgetPtr> groups;
    const auto& all = root->querySelectorAll("*");
    for (const auto& node : std::views::reverse(all)) {
        if (node->getWidget()) {
            auto styles = std::make_shared<OTMLNode>();

            for (const auto [key, stylesMap] : node->getStyles()) {
                auto meta = styles;
                if (key != "styles") {
                    meta = std::make_shared<OTMLNode>();
                    meta->setTag(key);
                    styles->addChild(meta);
                }

                for (const auto [tag, value] : stylesMap) {
                    auto nodeAttr = std::make_shared<OTMLNode>();
                    nodeAttr->setTag(tag);
                    nodeAttr->setValue(value);
                    meta->addChild(nodeAttr);
                }
            }

            for (const auto [tag, value] : node->getAttrStyles()) {
                auto nodeAttr = std::make_shared<OTMLNode>();
                nodeAttr->setTag(tag);
                nodeAttr->setValue(value);
                styles->addChild(nodeAttr);
            }

            node->getWidget()->mergeStyle(styles);

            if (node->getTag() == "input" && node->getAttr("type") == "radio")
                createRadioGroup(node, groups);
        }
    }

    static uint32_t ID = 0;
    return m_nodes.emplace(++ID, root).first->first;
}

void HtmlManager::destroy(uint32_t id) {
    auto it = m_nodes.find(id);
    if (it == m_nodes.end())
        return;

    for (const auto& node : it->second->getChildren()) {
        if (node->getWidget())
            node->getWidget()->destroy();
    }

    m_nodes.erase(it);
}

void HtmlManager::setGlobalStyle(const std::string& stylePath) {
    GLOBAL_STYLE = css::parse(g_resources.readFileContents(stylePath));
}

UIWidgetPtr HtmlManager::getWidget(uint32_t id) {
    auto it = m_nodes.find(id);
    if (it != m_nodes.end()) {
        for (const auto& node : it->second->getChildren()) {
            if (node->getWidget())
                return node->getWidget();
        }
    }

    return nullptr;
}