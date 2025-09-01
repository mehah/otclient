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

void parseAttrPropList(const std::string& attrStr, const OTMLNodePtr& parent) {
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

            nodeAttr->setTag(tag);
            nodeAttr->setValue(value);
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

void  parseAndSetDisplayAttr(const HtmlNodePtr& node) {
    const auto& widget = node->getWidget();
    if (widget->hasAnchoredLayout()) {
        if (widget->getWidth() == 0)
            widget->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);

        if (widget->getChildIndex() == 1 || node->getAttr("anchor") == "parent") {
            node->getWidget()->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
            node->getWidget()->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        } else {
            auto prev = node->getPrev();
            if (prev && prev->getStyle("display") == "block") {
                widget->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
                widget->addAnchor(Fw::AnchorTop, "prev", Fw::AnchorBottom);
            } else {
                widget->addAnchor(Fw::AnchorLeft, "prev", Fw::AnchorRight);
                widget->addAnchor(Fw::AnchorTop, "prev", Fw::AnchorTop);
            }
        }
    }

    if (!node->getStyle())
        return;

    const auto& display = node->getStyle("display");
    if (display == "none")
        widget->setVisible(false);
}

void parseAndSetFloatStyle(const HtmlNodePtr& node) {
    if (!node->getStyle())
        return;

    const auto& propFloat = node->getStyle("float");

    if (propFloat.empty() || !node->getWidget()->hasAnchoredLayout()) {
        return;
    }

    if (propFloat == "right") {
        std::string anchor = "parent";
        auto anchorType = Fw::AnchorRight;
        for (auto& child : node->getParent()->getChildren()) {
            if (child != node && child->getStyle()) {
                const auto& chield_propFloat = child->getStyle("float");
                if (chield_propFloat == "right") {
                    anchor = child->getWidget()->getId();
                    anchorType = Fw::AnchorLeft;
                    break;
                }
            }
        }

        node->getWidget()->removeAnchor(Fw::AnchorLeft);
        node->getWidget()->removeAnchor(Fw::AnchorRight);

        node->getWidget()->addAnchor(Fw::AnchorRight, anchor, anchorType);
    } else if (propFloat == "left") {
        std::string anchor = "parent";
        auto anchorType = Fw::AnchorLeft;
        for (auto& child : node->getParent()->getChildren()) {
            const auto& chield_propFloat = child->getStyle("float");
            if (chield_propFloat == "right") {
                anchor = child->getWidget()->getId();
                anchorType = Fw::AnchorRight;
                break;
            }
        }

        node->getWidget()->removeAnchor(Fw::AnchorLeft);
        node->getWidget()->removeAnchor(Fw::AnchorRight);
        node->getWidget()->addAnchor(Fw::AnchorLeft, anchor, anchorType);
    }
}

UIWidgetPtr readNode(const HtmlNodePtr& node, const UIWidgetPtr& parent) {
    const auto& styleName = g_ui.getStyleName(translateStyleName(node->getTag(), node));

    auto widget = g_ui.createWidget(styleName.empty() ? "UIWidget" : styleName, parent);
    widget->setOnHtml(true);
    node->setWidget(widget);

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
            auto otml = std::make_shared<OTMLNode>();
            parseAttrPropList(value, otml);
            node->setStyle(otml);
        } else if (attr == "layout") {
            auto otml = std::make_shared<OTMLNode>();
            auto layout = std::make_shared<OTMLNode>();
            layout->setTag("layout");
            parseAttrPropList(value, layout);
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

UIWidgetPtr HtmlManager::load(const std::string& htmlPath, UIWidgetPtr parent) {
    auto html = g_resources.readFileContents(htmlPath);
    auto root = parseHtml(html);
    if (root->getChildren().empty())
        return nullptr;

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
                    if (!node->getStyle())
                        node->setStyle(std::make_shared<OTMLNode>());

                    for (const auto& decl : rule.decls) {
                        auto declOtml = std::make_shared<OTMLNode>();
                        declOtml->setTag(decl.property);
                        declOtml->setValue(decl.value);
                        node->getStyle()->addChild(declOtml);
                    }
                }
            }
        }
    };

    parseStyle(GLOBAL_STYLE, false);
    for (const auto& sheet : sheets)
        parseStyle(sheet, true);

    const auto& all = root->querySelectorAll("*");
    for (const auto& node : all) {
        if (node->getWidget() && node->getStyle()) {
            node->getWidget()->mergeStyle(node->getStyle());
        }
    }

    for (const auto& node : std::ranges::reverse_view(all)) {
        if (node->getWidget()) {
            parseAndSetDisplayAttr(node);
            parseAndSetFloatStyle(node);
        }
    }

    return parent;
}

void HtmlManager::setGlobalStyle(const std::string& style) {
    GLOBAL_STYLE = css::parse(style);
}