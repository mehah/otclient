#include "htmlmanager.h"
#include <framework/ui/uimanager.h>
#include <framework/ui/ui.h>

#include "htmlnode.h"
#include "htmlparser.h"
#include "cssparser.h"
#include <framework/core/resourcemanager.h>
#include <ranges>

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

void parseAttrPropList(const std::string& attrStr, std::unordered_map<std::string, std::string>& parent) {
    auto attrs = stdext::split(attrStr, ";");

    for (auto data : attrs) {
        stdext::trim(data);

        const auto& attr = stdext::split(data, ":");
        if (attr.size() > 1) {
            auto nodeAttr = std::make_shared<OTMLNode>();
            auto tag = attr[0];
            auto value = attr[1];

            stdext::trim(tag);
            stdext::trim(value);

            parent[tag] = value;
        }
    }
}

std::string translateAttribute(const std::string& styleName, const std::string& tagName, const std::string& attr) {
    if (attr == "*style") {
        return "*mergeStyle";
    }

    if (attr == "*if") {
        return "*visible";
    }

    if (styleName != "CheckBox" && styleName != "ComboBox") {
        if (attr == "*value") {
            return "*text";
        }

        if (attr == "value") {
            return "text";
        }
    }

    if (tagName == "img") {
        auto it = IMG_ATTR_TRANSLATED.find(attr);
        if (it != IMG_ATTR_TRANSLATED.end()) {
            return it->second;
        }
    }

    return attr;
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

void parseStyle(const UIWidgetPtr& widget, const HtmlNodePtr& node) {
    if (!node->hasAttr("style")) return;

    auto style = node->getAttr("style");
    stdext::trim(style);
}

UIWidgetPtr readNode(const HtmlNodePtr& node, const UIWidgetPtr& parent) {
    const auto& styleName = g_ui.getStyleName(translateStyleName(node->getTag(), node));

    auto widget = g_ui.createWidget(styleName.empty() ? "UIWidget" : styleName, parent);
    node->setWidget(widget);
    widget->setHtmlNode(node);

    if (node->getType() == NodeType::Text) {
        widget->setTextAutoResize(true);
    }

    widget->setText(node->getText());

    for (const auto [key, value] : node->getAttributesMap()) {
        const auto& attr = translateAttribute(styleName, node->getTag(), key);

        if (attr.starts_with("on")) {
        } else if (attr == "anchor") {
            // ignore
        } else if (attr == "style") {
            parseAttrPropList(value, node->getAttrStyles());
        } else if (attr == "layout") {
            std::unordered_map<std::string, std::string> styles;
            parseAttrPropList(value, styles);

            auto otml = std::make_shared<OTMLNode>();
            auto layout = std::make_shared<OTMLNode>();
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
                const auto& style = g_ui.getStyle(className);
                if (style) widget->mergeStyle(style);
            }
        }
    }

    for (const auto& child : node->getChildren()) {
        readNode(child, widget);
    }

    return widget;
}

static uint32_t ID = 0;

uint32_t HtmlManager::load(const std::string& htmlPath, UIWidgetPtr parent) {
    auto html = g_resources.readFileContents(htmlPath);
    auto root = parseHtml(html);
    if (root->getChildren().empty())
        return 0;

    std::vector<css::StyleSheet> sheets;

    if (!parent)
        parent = g_ui.createWidget("UIWidget", nullptr);

    for (const auto& node : root->getChildren()) {
        if (node->getTag() == "style") {
            sheets.emplace_back(css::parse(node->textContent()));
        } else if (node->getTag() == "link") {
            if (node->hasAttr("href")) {
                sheets.emplace_back(css::parse(g_resources.readFileContents(node->getAttr("href"))));
            }
        } else readNode(node, parent);
    }

    auto parseStyle = [&](const css::StyleSheet& sheet, bool checkRuleExist) {
        for (const auto& rule : sheet.rules) {
            const auto& selectors = stdext::join(rule.selectors);
            const auto& nodes = root->querySelectorAll(selectors);

            if (checkRuleExist && nodes.empty()) {
                g_logger.warning("[{}][style] selector({}) no element was found.", htmlPath, selectors);
                continue;
            }

            for (const auto& node : nodes) {
                if (node->getWidget()) {
                    for (const auto& decl : rule.decls) {
                        node->getStyles()[decl.property] = decl.value;
                    }
                }
            }
        }
    };

    parseStyle(GLOBAL_STYLE, false);
    for (const auto& sheet : sheets)
        parseStyle(sheet, true);

    const auto& all = root->querySelectorAll("*");
    for (const auto& node : std::views::reverse(all)) {
        if (node->getWidget()) {
            auto styles = std::make_shared<OTMLNode>();

            for (const auto [tag, value] : node->getStyles()) {
                auto nodeAttr = std::make_shared<OTMLNode>();
                nodeAttr->setTag(tag);
                nodeAttr->setValue(value);
                styles->addChild(nodeAttr);
            }

            for (const auto [tag, value] : node->getAttrStyles()) {
                auto nodeAttr = std::make_shared<OTMLNode>();
                nodeAttr->setTag(tag);
                nodeAttr->setValue(value);
                styles->addChild(nodeAttr);
            }

            node->getWidget()->mergeStyle(styles);
        }
    }

    auto id = ++ID;
    m_nodes.emplace(id, root);

    return id;
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

void HtmlManager::setGlobalStyle(const std::string& style) {
    GLOBAL_STYLE = css::parse(style);
}