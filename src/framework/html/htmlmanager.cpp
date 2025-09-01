#include "htmlmanager.h"
#include <framework/ui/uimanager.h>
#include <framework/ui/ui.h>

#include "htmlnode.h"
#include "htmlparser.h"
#include "cssparser.h"
#include <framework/core/resourcemanager.h>

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

void parseAttrPropList(const std::string& attrStr, const OTMLNodePtr& parent) {
    auto attrs = stdext::split(attrStr, ";");

    for (auto data : attrs) {
        stdext::trim(data);

        const auto& attr = stdext::split(data, ":");
        if (attr.size() > 1) {
            auto nodeAttr = std::make_shared<OTMLNode>();
            nodeAttr->setTag(attr[0]);
            nodeAttr->setValue(attr[1]);
            parent->addChild(nodeAttr);
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
    widget->setOnHtml(true);
    node->setWidget(widget);

    for (const auto [key, value] : node->getAttributesMap()) {
        const auto& attr = translateAttribute(styleName, node->getTag(), key);

        if (attr.starts_with("on")) {
        } else if (attr == "anchor") {
            // ignore
        } else if (attr == "style") {
            auto otml = std::make_shared<OTMLNode>();
            parseAttrPropList(value, otml);
            widget->mergeStyle(otml);
        } else if (attr == "layout") {
            auto otml = std::make_shared<OTMLNode>();
            otml->setTag("layout");
            parseAttrPropList(value, otml);
            widget->mergeStyle(otml);
        } else if (attr == "class") {
            for (const auto& className : stdext::split(value, " ")) {
                const auto& style = g_ui.getStyle(className);
                if (style) widget->mergeStyle(style);
            }
        }
    }

    return widget;
}

UIWidgetPtr HtmlManager::createWidgetFromHTML(const std::string& htmlPath, const UIWidgetPtr& parent) {
    auto html = g_resources.readFileContents(htmlPath);
    auto dom = parseHtml(html);
    if (dom->getChildren().empty())
        return nullptr;

    css::StyleSheet sheet;

    auto root = g_ui.createWidget("UIWidget", parent);

    for (const auto& node : dom->getChildren()) {
        if (node->getTag() == "style") {
            sheet = css::parse(node->getText());
        } else if (node->getTag() == "link") {
        } else readNode(node, root);
    }

    for (const auto& rule : sheet.rules) {
        const auto& selectors = stdext::join(rule.selectors);
        const auto& nodes = dom->querySelectorAll(selectors);

        if (nodes.empty()) {
            g_logger.warning("[{}][style] selector({}) no element was found.", htmlPath, selectors);
            continue;
        }

        for (const auto& node : dom->querySelectorAll(stdext::join(rule.selectors))) {
            if (node->getWidget()) {
                auto otml = std::make_shared<OTMLNode>();
                for (const auto& decl : rule.decls) {
                    auto declOtml = std::make_shared<OTMLNode>();
                    declOtml->setTag(decl.property);
                    declOtml->setValue(decl.value);
                    otml->addChild(declOtml);
                }
                node->getWidget()->mergeStyle(otml);
            }
        }
    }

    return root;
}

void HtmlManager::setGlobalStyle(const std::string& style) {
    GLOBAL_STYLE = css::parse(style);
}