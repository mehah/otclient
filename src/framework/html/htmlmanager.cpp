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
#include <framework/core/resourcemanager.h>
#include <ranges>
#include <framework/core/modulemanager.h>

HtmlManager g_html;
std::vector<css::StyleSheet> GLOBAL_STYLES;

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

static const std::unordered_set<std::string_view> kProps = {
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

static inline bool isInheritable(std::string_view prop) noexcept {
    return kProps.find(prop) != kProps.end();
}

std::string cssToState(const std::string& css) {
    if (auto it = cssMap.find(css); it != cssMap.end())
        return it->second;
    return "";
}

void parseAttrPropList(std::string_view attrsStr, std::map<std::string, std::string>& attrsMap) {
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

void translateAttribute(std::string_view styleName, std::string_view tagName, std::string& attr, std::string& value) {
    if (attr == "*style") {
        attr = "*mergeStyle";
    } else if (attr == "*if") {
        attr = "*visible";
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

std::string_view translateStyleName(std::string_view styleName, const HtmlNodePtr& el) {
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

void createRadioGroup(const HtmlNode* node, std::unordered_map<std::string, UIWidgetPtr>& groups) {
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

void applyStyleSheet(HtmlNode* node, std::string_view htmlPath, const css::StyleSheet& sheet, bool checkRuleExist) {
    static const auto setChildrenStyles = [](const HtmlNodePtr& n, const css::Declaration& decl, const std::string& style, const auto& self) -> void {
        for (const auto& child : n->getChildren()) {
            child->getStyles()[style][decl.property] = decl.value;
            self(child, decl, style, self);
        }
    };

    for (const auto& rule : sheet.rules) {
        const auto& selectors = stdext::join(rule.selectors);
        const auto& nodes = node->querySelectorAll(selectors);

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

UIWidgetPtr createWidgetFromNode(const HtmlNodePtr& node, const UIWidgetPtr& parent, std::vector<HtmlNodePtr>& textNodes, uint32_t htmlId, const std::string& moduleName) {
    if (node->getType() == NodeType::Comment || node->getType() == NodeType::Doctype)
        return nullptr;

    const auto& styleName = g_ui.getStyleName(translateStyleName(node->getTag(), node));

    auto widget = g_ui.createWidget(styleName.empty() ? "UIWidget" : styleName, parent);
    node->setWidget(widget);
    widget->setHtmlNode(node);
    widget->setHtmlId(htmlId);

    widget->callLuaField("onCreateByHTML", node->getAttributesMap(), moduleName);

    if (!node->getText().empty()) {
        widget->setTextAutoResize(true);
        widget->setText(node->getText());
    }

    for (const auto& child : node->getChildren()) {
        createWidgetFromNode(child, widget, textNodes, htmlId, moduleName);
    }

    if (node->getType() == NodeType::Text)
        textNodes.emplace_back(node);

    return widget;
}

void applyAttributesAndStyles(UIWidget* widget, HtmlNode* node, std::unordered_map<std::string, UIWidgetPtr>& groups, const std::string& moduleName) {
    for (const auto [key, v] : node->getAttributesMap()) {
        auto attr = key;
        auto value = v;
        translateAttribute(widget->getStyleName(), node->getTag(), attr, value);

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
            for (const auto& [tag, value] : styles) {
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
            widget->callLuaField("__applyOrBindHtmlAttribute", attr, value, moduleName);
        }
    }

    auto styles = std::make_shared<OTMLNode>();

    std::map<std::string, std::string> stylesMerge;

    for (const auto [key, stylesMap] : node->getStyles()) {
        if (key != "styles") {
            auto meta = std::make_shared<OTMLNode>();
            meta->setTag(key);
            styles->addChild(meta);

            for (const auto [prop, value] : stylesMap) {
                auto nodeAttr = std::make_shared<OTMLNode>();
                nodeAttr->setTag(prop);
                nodeAttr->setValue(value);
                meta->addChild(nodeAttr);
            }
        } else for (const auto [prop, value] : stylesMap) {
            stylesMerge[prop] = value;
        }
    }

    for (const auto& [prop, value] : node->getAttrStyles()) {
        stylesMerge[prop] = value;
    }

    for (const auto [prop, value] : stylesMerge) {
        auto nodeAttr = std::make_shared<OTMLNode>();
        nodeAttr->setTag(prop);
        nodeAttr->setValue(value);
        styles->addChild(nodeAttr);
    }

    widget->mergeStyle(styles);

    if (node->getTag() == "input" && node->getAttr("type") == "radio")
        createRadioGroup(node, groups);
}

UIWidgetPtr HtmlManager::readNode(DataRoot& root, const HtmlNodePtr& node, const UIWidgetPtr& parent, const std::string& moduleName, const std::string& htmlPath, bool checkRuleExist, uint32_t htmlId) {
    static std::vector<HtmlNodePtr> textNodes;
    textNodes.clear();

    auto path = "/modules/" + moduleName + "/";

    UIWidgetPtr widget;
    for (const auto& node : node->getChildren()) {
        if (node->getTag() == "style") {
            root.sheets.emplace_back(css::parse(node->textContent()));
        } else if (node->getTag() == "link") {
            if (node->hasAttr("href")) {
                root.sheets.emplace_back(css::parse(g_resources.readFileContents(path + node->getAttr("href"))));
            }
        } else widget = createWidgetFromNode(node, parent, textNodes, htmlId, moduleName);
    }

    for (const auto& sheet : GLOBAL_STYLES)
        applyStyleSheet(node.get(), htmlPath, sheet, false);
    for (const auto& sheet : root.sheets)
        applyStyleSheet(node.get(), htmlPath, sheet, checkRuleExist);

    auto all = node->querySelectorAll("*");
    all.reserve(all.size() + textNodes.size());
    all.insert(all.end(), textNodes.begin(), textNodes.end());
    for (const auto& node : std::views::reverse(all)) {
        if (const auto widget = node->getWidget().get()) {
            applyAttributesAndStyles(widget, node.get(), root.groups, moduleName);
        }
    }

    return widget;
}

uint32_t HtmlManager::load(const std::string& moduleName, const std::string& htmlPath, UIWidgetPtr parent) {
    auto path = "/modules/" + moduleName + "/";
    auto htmlContent = g_resources.readFileContents(path + htmlPath);

    auto root = DataRoot{ parseHtml(htmlContent), moduleName };

    if (root.node->getChildren().empty())
        return 0;

    if (!parent)
        parent = g_ui.getRootWidget();

    static uint32_t ID = 0;
    ++ID;
    readNode(root, root.node, parent, moduleName, htmlPath, false, ID);
    return m_nodes.emplace(ID, root).first->first;
}

UIWidgetPtr HtmlManager::createWidgetFromHTML(const std::string& html, const UIWidgetPtr& parent, uint32_t htmlId) {
    auto it = m_nodes.find(htmlId);
    if (it == m_nodes.end()) {
        nullptr;
    }

    return readNode(it->second, parseHtml(html), parent, it->second.moduleName, "", false, htmlId);
}

void HtmlManager::destroy(uint32_t id) {
    auto it = m_nodes.find(id);
    if (it == m_nodes.end())
        return;

    for (const auto& node : it->second.node->getChildren()) {
        if (node->getWidget())
            node->getWidget()->destroy();
    }

    for (const auto& [name, group] : it->second.groups) {
        group->destroy();
    }

    m_nodes.erase(it);
}

void HtmlManager::addGlobalStyle(const std::string& stylePath) {
    GLOBAL_STYLES.emplace_back(css::parse(g_resources.readFileContents(stylePath)));
}

UIWidgetPtr HtmlManager::getRootWidget(uint32_t id) {
    auto it = m_nodes.find(id);
    if (it != m_nodes.end()) {
        for (const auto& node : it->second.node->getChildren()) {
            if (node->getWidget())
                return node->getWidget();
        }
    }

    return nullptr;
}