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
#include "uiwidget.h"
#include <framework/html/htmlnode.h>
#include <framework/core/eventdispatcher.h>
#include "uimanager.h"
#include <framework/html/htmlmanager.h>

namespace {
    static uint32_t SIZE_VERSION_COUNTER = 1;
    static bool pendingFlush = false;
    static std::vector<UIWidgetPtr> pendingWidgets;

    static inline bool isInlineLike(DisplayType d) {
        switch (d) {
            case DisplayType::Inline:
            case DisplayType::InlineBlock:
            case DisplayType::InlineFlex:
            case DisplayType::InlineGrid: return true;
            default: return false;
        }
    }
    static inline bool isFlexContainer(DisplayType d) {
        return d == DisplayType::Flex || d == DisplayType::InlineFlex;
    }
    static inline bool isGridContainer(DisplayType d) {
        return d == DisplayType::Grid || d == DisplayType::InlineGrid;
    }

    static inline bool isTableBox(DisplayType d) {
        switch (d) {
            case DisplayType::Table:
            case DisplayType::TableRowGroup:
            case DisplayType::TableHeaderGroup:
            case DisplayType::TableFooterGroup:
            case DisplayType::TableRow:
            case DisplayType::TableCell:
            case DisplayType::TableColumnGroup:
            case DisplayType::TableColumn:
            case DisplayType::TableCaption:
                return true;
            default:
                return false;
        }
    }

    static inline bool breakLine(DisplayType d) {
        switch (d) {
            case DisplayType::Block:
            case DisplayType::Flex:
            case DisplayType::Grid:
            case DisplayType::ListItem:
            case DisplayType::Table:
            case DisplayType::TableCaption:
            case DisplayType::TableHeaderGroup:
            case DisplayType::TableRowGroup:
            case DisplayType::TableFooterGroup:
            case DisplayType::TableRow:
                return true;
            default:
                return false;
        }
    }

    static inline bool isTableContainer(DisplayType d) {
        return d == DisplayType::Table
            || d == DisplayType::TableRowGroup
            || d == DisplayType::TableHeaderGroup
            || d == DisplayType::TableFooterGroup
            || d == DisplayType::TableRow;
    }

    static inline FloatType mapLogicalFloat(FloatType f) {
        if (f == FloatType::InlineStart) return FloatType::Left;
        if (f == FloatType::InlineEnd)   return FloatType::Right;
        return f;
    }
    static inline ClearType mapLogicalClear(ClearType c) {
        if (c == ClearType::InlineStart) return ClearType::Left;
        if (c == ClearType::InlineEnd)   return ClearType::Right;
        return c;
    }

    struct FlowContext
    {
        UIWidget* lastNormalWidget = nullptr;
        UIWidget* lastLeftFloat = nullptr;
        UIWidget* lastRightFloat = nullptr;
        UIWidget* lastFloatOnSameSide = nullptr;

        int lastNormalIndex = -1;
        int lastLeftIndex = -1;
        int lastRightIndex = -1;
        bool hasLeftFloat = false;
        bool hasRightFloat = false;

        int lineWidthBefore = 0;
        UIWidget* tallestInlineWidget = nullptr;
    };

    static inline void setLeftAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->addAnchor(Fw::AnchorLeft, toId, edge);
    }

    static inline void setRightAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->addAnchor(Fw::AnchorRight, toId, edge);
    }

    static inline void setTopAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->addAnchor(Fw::AnchorTop, toId, edge);
    }

    static inline void setBottomAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->addAnchor(Fw::AnchorBottom, toId, edge);
    }

    static inline void anchorToParentTopLeft(UIWidget* self) {
        setLeftAnchor(self, "parent", Fw::AnchorLeft);
        setTopAnchor(self, "parent", Fw::AnchorTop);
    }

    static inline UIWidget* chooseLowerWidget(UIWidget* a, UIWidget* b) {
        if (!a) return b;
        if (!b) return a;
        const auto ay = a->getRect().bottomLeft().y;
        const auto by = b->getRect().bottomLeft().y;
        return (by > ay) ? b : a;
    }

    static inline bool skipInFlow(UIWidget* c) {
        return c->getDisplay() == DisplayType::None
            || !c->isAnchorable()
            || c->getPositionType() == PositionType::Absolute;
    }

    static inline int computeOuterSize(UIWidget* w, bool horizontal) {
        const auto textSz = w->getTextSize() + w->getTextOffset().toSize();
        const int contentPrimary = horizontal ? textSz.width() : textSz.height();
        const int widgetPrimary = horizontal ? w->getWidth() : w->getHeight();
        const int htmlPrimary = w->isOnHtml() ? (horizontal ? w->getWidthHtml().valueCalculed
                                                            : w->getHeightHtml().valueCalculed) : -1;
        const int base = std::max<int>(contentPrimary, std::max<int>(widgetPrimary, htmlPrimary));
        if (horizontal)
            return base + w->getMarginLeft() + w->getMarginRight() + w->getPaddingLeft() + w->getPaddingRight();
        return base + w->getMarginTop() + w->getMarginBottom() + w->getPaddingTop() + w->getPaddingBottom();
    }
    static inline int computeOuterWidth(UIWidget* w) { return computeOuterSize(w, true); }
    static inline int computeOuterHeight(UIWidget* w) { return computeOuterSize(w, false); }

    static inline int getParentInnerWidth(UIWidget* p) {
        const int pw = p->isOnHtml() ? p->getWidthHtml().valueCalculed : p->getWidth();
        return std::max<int>(0, pw - p->getPaddingLeft() - p->getPaddingRight());
    }

    static inline Unit detectUnit(std::string_view s) {
        if (s == "auto") return Unit::Auto;
        if (s == "fit-content") return Unit::FitContent;
        if (s.ends_with("px")) return Unit::Px;
        if (s.ends_with("em")) return Unit::Em;
        if (s.ends_with("%"))  return Unit::Percent;
        return Unit::Px;
    }

    static inline std::string_view numericPart(std::string_view s) {
        if (s.ends_with("px") || s.ends_with("em")) return s.substr(0, s.size() - 2);
        if (s.ends_with("%")) return s.substr(0, s.size() - 1);
        return s;
    }

    static FlowContext computeFlowContext(UIWidget* self, DisplayType /*parentDisplay*/, FloatType effFloat) {
        FlowContext ctx;
        if (self->getPositionType() == PositionType::Absolute) return ctx;
        auto* parent = self->getParent().get();
        if (!parent) return ctx;

        int runWidth = 0;
        int lastTop = INT_MIN;
        UIWidget* tallest = nullptr;
        int tallestH = -1;

        int i = 0;
        for (const auto& sp : parent->getChildren()) {
            UIWidget* c = sp.get();
            if (c == self) break;
            if (skipInFlow(c)) { ++i; continue; }

            const FloatType cf = mapLogicalFloat(c->getFloat());
            if (cf == FloatType::None) {
                ctx.lastNormalWidget = c; ctx.lastNormalIndex = i;
            } else if (cf == FloatType::Left) {
                ctx.lastLeftFloat = c; ctx.lastLeftIndex = i;
            } else if (cf == FloatType::Right) {
                ctx.lastRightFloat = c; ctx.lastRightIndex = i;
            }
            if (cf == effFloat) ctx.lastFloatOnSameSide = c;

            if (cf == FloatType::None) {
                if (breakLine(c->getDisplay())) {
                    runWidth = 0; lastTop = INT_MIN; tallest = nullptr; tallestH = -1;
                } else if (isInlineLike(c->getDisplay())) {
                    const int ct = c->getRect().topLeft().y;
                    if (lastTop == INT_MIN) lastTop = ct;
                    if (ct > lastTop) { runWidth = 0; lastTop = ct; tallest = nullptr; tallestH = -1; }
                    const int cw = computeOuterWidth(c);
                    const int ch = computeOuterHeight(c);
                    runWidth += cw;
                    if (ch > tallestH) { tallestH = ch; tallest = c; }
                } else {
                    runWidth = 0; lastTop = INT_MIN; tallest = nullptr; tallestH = -1;
                }
            }
            ++i;
        }

        ctx.hasLeftFloat = (ctx.lastLeftFloat != nullptr);
        ctx.hasRightFloat = (ctx.lastRightFloat != nullptr);
        ctx.lineWidthBefore = runWidth;
        ctx.tallestInlineWidget = tallest;
        return ctx;
    }

    bool applyClear(UIWidget* self, const FlowContext& ctx, ClearType effClear) {
        if (effClear == ClearType::None) return false;

        UIWidget* target = nullptr;
        if (effClear == ClearType::Both)      target = chooseLowerWidget(ctx.lastLeftFloat, ctx.lastRightFloat);
        else if (effClear == ClearType::Left) target = ctx.lastLeftFloat;
        else                                  target = ctx.lastRightFloat;

        if (target) {
            setTopAnchor(self, target->getId().c_str(), Fw::AnchorBottom);
            return true;
        }
        return false;
    }

    static inline void applyFloat(UIWidget* self, const FlowContext& ctx, FloatType effFloat, bool topCleared) {
        const bool isLeftF = (effFloat == FloatType::Left);

        const bool blockAfterLeftSameLine =
            (!isLeftF)
            && ctx.lastNormalWidget
            && (ctx.lastNormalIndex > ctx.lastLeftIndex)
            && (ctx.lastLeftIndex >= 0)
            && !isInlineLike(ctx.lastNormalWidget->getDisplay());

        if (ctx.lastFloatOnSameSide) {
            if (isLeftF) setLeftAnchor(self, ctx.lastFloatOnSameSide->getId().c_str(), Fw::AnchorRight);
            else         setRightAnchor(self, ctx.lastFloatOnSameSide->getId().c_str(), Fw::AnchorLeft);
            if (!topCleared) setTopAnchor(self, ctx.lastFloatOnSameSide->getId().c_str(), Fw::AnchorTop);
        } else if (!isLeftF && blockAfterLeftSameLine) {
            setRightAnchor(self, "parent", Fw::AnchorRight);
            if (!topCleared && ctx.lastNormalWidget)
                setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorTop);
        } else {
            if (isLeftF) setLeftAnchor(self, "parent", Fw::AnchorLeft);
            else         setRightAnchor(self, "parent", Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
        }
    }

    static inline void applyFlex(UIWidget* self, const FlowContext& ctx, bool topCleared) {
        if (!ctx.lastNormalWidget) {
            setLeftAnchor(self, "parent", Fw::AnchorLeft);
            if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
        } else {
            setLeftAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorTop);
        }
    }

    static inline void applyGridOrTable(UIWidget* self, const FlowContext& ctx, bool topCleared) {
        if (!ctx.lastNormalWidget) {
            anchorToParentTopLeft(self);
        } else {
            setLeftAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorTop);
        }
    }

    static inline void applyTableChild(UIWidget* self, const FlowContext& ctx, bool topCleared) {
        setLeftAnchor(self, "parent", Fw::AnchorLeft);
        setRightAnchor(self, "parent", Fw::AnchorRight);

        if (!ctx.lastNormalWidget) {
            setTopAnchor(self, "parent", Fw::AnchorTop);
        } else if (!topCleared) {
            setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorBottom);
        }
    }

    static inline void applyTableRowGroupChild(UIWidget* self, const FlowContext& ctx, bool topCleared) {
        setLeftAnchor(self, "parent", Fw::AnchorLeft);
        setRightAnchor(self, "parent", Fw::AnchorRight);

        if (!ctx.lastNormalWidget) {
            setTopAnchor(self, "parent", Fw::AnchorTop);
        } else if (!topCleared) {
            setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorBottom);
        }
    }

    static inline void applyTableRowChild(UIWidget* self, const FlowContext& ctx, bool topCleared) {
        setTopAnchor(self, "parent", Fw::AnchorTop);
        setBottomAnchor(self, "parent", Fw::AnchorBottom);

        if (!ctx.lastNormalWidget) {
            setLeftAnchor(self, "parent", Fw::AnchorLeft);
        } else {
            setLeftAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorRight);
        }
    }

    static inline void applyTableCaption(UIWidget* self, const FlowContext&, bool) {
        setLeftAnchor(self, "parent", Fw::AnchorLeft);
        setRightAnchor(self, "parent", Fw::AnchorRight);
        setTopAnchor(self, "parent", Fw::AnchorTop);
    }

    static inline void applyTableColumnLike(UIWidget* self) {
        setLeftAnchor(self, "parent", Fw::AnchorLeft);
        setTopAnchor(self, "parent", Fw::AnchorTop);
    }

    void applyInline(UIWidget* self, const FlowContext& ctx, bool topCleared) {
        if (auto* parent = self->getParent().get()) {
            const int innerW = getParentInnerWidth(parent);
            if (innerW > 0) {
                const int nextRun = ctx.lineWidthBefore + computeOuterWidth(self);
                if (nextRun > innerW) {
                    setLeftAnchor(self, "parent", Fw::AnchorLeft);
                    if (!topCleared) {
                        if (ctx.lastNormalWidget) setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorBottom);
                        else                      setTopAnchor(self, "parent", Fw::AnchorTop);
                    }
                    return;
                }
            }
        }

        if (!ctx.lastNormalWidget) {
            if (ctx.hasLeftFloat) {
                setLeftAnchor(self, ctx.lastLeftFloat->getId().c_str(), Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else if (ctx.hasRightFloat) {
                setRightAnchor(self, "parent", Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else {
                anchorToParentTopLeft(self);
            }
        } else {
            if (isInlineLike(ctx.lastNormalWidget->getDisplay())) {
                setLeftAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorTop);
            } else {
                setLeftAnchor(self, "parent", Fw::AnchorLeft);
                if (!topCleared) setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorBottom);
            }
        }
    }

    void applyBlock(UIWidget* self, const FlowContext& ctx, bool topCleared) {
        if (ctx.lastNormalWidget && isInlineLike(ctx.lastNormalWidget->getDisplay())) {
            if (auto* tallest = ctx.tallestInlineWidget) {
                setLeftAnchor(self, "parent", Fw::AnchorLeft);
                if (!topCleared)
                    setTopAnchor(self, tallest->getId().c_str(), Fw::AnchorBottom);
                return;
            }
        }

        if (!ctx.lastNormalWidget) {
            if (ctx.hasLeftFloat) {
                setLeftAnchor(self, ctx.lastLeftFloat->getId().c_str(), Fw::AnchorRight);
                setRightAnchor(self, "parent", Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else if (ctx.hasRightFloat) {
                setRightAnchor(self, "parent", Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else {
                anchorToParentTopLeft(self);
            }
        } else {
            setLeftAnchor(self, "parent", Fw::AnchorLeft);
            if (!topCleared) setTopAnchor(self, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorBottom);
        }
    }

    void updateDimension(UIWidget* widget, int width, int height) {
        bool checkChildren = false;
        auto& wHtml = widget->getWidthHtml();
        auto& hHtml = widget->getHeightHtml();

        if (wHtml.needsUpdate(Unit::Percent) || wHtml.needsUpdate(Unit::Auto)) {
            width -= (widget->getMarginLeft() + widget->getMarginRight());

            if (wHtml.version != SIZE_VERSION_COUNTER) {
                if (wHtml.needsUpdate(Unit::Percent))
                    width = std::round(width * (wHtml.value / 100.0));

                widget->setWidth_px(width);
                wHtml.applyUpdate(width, SIZE_VERSION_COUNTER);

                checkChildren = true;
            }
        }

        if (hHtml.needsUpdate(Unit::Percent, SIZE_VERSION_COUNTER)) {
            height = std::round(height * (hHtml.value / 100.0));
            widget->setHeight_px(height);
            hHtml.applyUpdate(height, SIZE_VERSION_COUNTER);
            checkChildren = true;
        }

        if (checkChildren) {
            for (const auto& child : widget->getChildren()) {
                if (child->getWidthHtml().unit == Unit::Auto ||
                    child->getWidthHtml().unit == Unit::Percent ||
                    child->getHeightHtml().unit == Unit::Percent) {
                    updateDimension(child.get(), width, height);
                }
            }
        }
    }
}

void UIWidget::refreshHtml(bool childrenTo) {
    if (!isOnHtml())
        return;

    if (childrenTo) {
        for (const auto& child : m_children) {
            child->scheduleHtmlTask(PropApplyAnchorAlignment);
        }
    }

    auto parent = this;
    while (parent && parent->isOnHtml()) {
        if (parent->m_width.unit != Unit::Em && parent->m_width.unit != Unit::Px)
            parent->applyDimension(true, parent->m_width.unit, parent->m_width.value);
        if (parent->m_height.unit != Unit::Em && parent->m_height.unit != Unit::Px)
            parent->applyDimension(false, parent->m_height.unit, parent->m_height.value);
        parent = parent->m_parent.get();
    }
}

void UIWidget::setLineHeight(std::string valueStr) {
    stdext::trim(valueStr);
    stdext::tolower(valueStr);

    const std::string_view sv = valueStr;
    const Unit unit = detectUnit(sv);
    int16_t num = stdext::to_number(std::string(numericPart(sv)));
    m_lineHeight = { unit, num, num, true };
}

void UIWidget::applyDimension(bool isWidth, std::string valueStr) {
    stdext::trim(valueStr);
    stdext::tolower(valueStr);

    const std::string_view sv = valueStr;
    const Unit unit = detectUnit(sv);
    int16_t num = stdext::to_number(std::string(numericPart(sv)));
    applyDimension(isWidth, unit, num);
    if (m_htmlNode)
        m_htmlNode->getStyles()["styles"][isWidth ? "width" : "height"] = valueStr;
}

void UIWidget::applyDimension(bool isWidth, Unit unit, int16_t value) {
    int16_t valueCalculed = -1;

    bool needUpdate = false;

    switch (unit) {
        case Unit::Auto: {
            if (isWidth && m_displayType == DisplayType::Block) {
                needUpdate = m_parent != nullptr;
            } else {
                unit = Unit::FitContent;
                needUpdate = true;
            }
            break;
        }
        case Unit::FitContent: {
            needUpdate = true;
            break;
        }
        case Unit::Percent: {
            needUpdate = m_displayType != DisplayType::Inline;
            break;
        }

        case Unit::Em:
        case Unit::Px:
        case Unit::Invalid:
        default: {
            if (isOnHtml())
                value += getPaddingLeft() + getPaddingRight();

            valueCalculed = value;

            if (isWidth) setWidth_px(value);
            else         setHeight_px(value);
            break;
        }
    }

    if (!isOnHtml())
        return;

    if (isWidth) {
        m_width = { unit , value, valueCalculed, needUpdate };
    } else {
        m_height = { unit , value, valueCalculed, needUpdate };
    }

    if (needUpdate) {
        scheduleHtmlTask(PropUpdateSize);
    }

    refreshAnchorAlignment(true);
}

void UIWidget::refreshAnchorAlignment(bool onlyChild) {
    if (!onlyChild)
        scheduleHtmlTask(PropApplyAnchorAlignment);

    for (const auto& child : m_children) {
        child->refreshAnchorAlignment();
    }
}

void UIWidget::scheduleHtmlTask(FlagProp prop) {
    bool schedule = false;

    switch (prop) {
        case PropUpdateSize:
        case PropApplyAnchorAlignment:
            schedule = true;
            break;

        default: return;
    }

    if (schedule && !hasProp(PropApplyAnchorAlignment) && !hasProp(PropUpdateSize))
        pendingWidgets.emplace_back(static_self_cast<UIWidget>());

    setProp(prop, true);

    if (pendingFlush)
        return;

    pendingFlush = true;
    g_dispatcher.deferEvent([self = static_self_cast<UIWidget>()] {
        for (const auto& widget : pendingWidgets) {
            if (widget->hasProp(PropUpdateSize)) {
                widget->updateSize();
                widget->setProp(PropUpdateSize, false);
            }

            if (widget->hasProp(PropApplyAnchorAlignment)) {
                widget->applyAnchorAlignment();
                widget->setProp(PropApplyAnchorAlignment, false);
            }
        }

        pendingWidgets.clear();
        pendingFlush = false;
        ++SIZE_VERSION_COUNTER;
    });
}

void UIWidget::setOverflow(OverflowType type) {
    if (m_overflowType == type)
        return;

    m_overflowType = type;

    scheduleHtmlTask(PropApplyAnchorAlignment);

    if (type == OverflowType::Scroll) {
        auto scrollWidget = g_ui.createWidget("VerticalScrollBar", nullptr);
        scrollWidget->setDisplay(m_displayType);
        scrollWidget->setAnchorable(false);
        m_parent->insertChild(getChildIndex() + 1, scrollWidget);
        callLuaField("setVerticalScrollBar", scrollWidget);

        scrollWidget->addAnchor(Fw::AnchorTop, m_id, Fw::AnchorTop);
        scrollWidget->addAnchor(Fw::AnchorRight, m_id, Fw::AnchorRight);
        scrollWidget->addAnchor(Fw::AnchorBottom, m_id, Fw::AnchorBottom);
        scrollWidget->callLuaField("setStep", 48);
        scrollWidget->callLuaField("setPixelsScroll", true);
    }
}

void UIWidget::setPositions(std::string_view type, std::string_view value) {
    const Unit unit = detectUnit(value);
    int16_t v = stdext::to_number(std::string(numericPart(value)));

    if (type == "top") {
        m_positions.top.unit = unit;
        m_positions.top.value = v;
    } else if (type == "bottom") {
        m_positions.bottom.unit = unit;
        m_positions.bottom.value = v;
    } else if (type == "left") {
        m_positions.left.unit = unit;
        m_positions.left.value = v;
    } else if (type == "right") {
        m_positions.right.unit = unit;
        m_positions.right.value = v;
    }
}

void UIWidget::setDisplay(DisplayType type) {
    if (m_displayType == type)
        return;

    auto old = m_displayType;
    m_displayType = type;
    scheduleHtmlTask(PropApplyAnchorAlignment);

    if (type == DisplayType::None) {
        setVisible(false);
    } else if (old == DisplayType::None)
        setVisible(true);
}

void UIWidget::ensureUniqueId() {
    static uint_fast32_t LAST_UNIQUE_ID = 0;
    if (!m_htmlNode)
        return;

    const auto& id = m_htmlNode->getAttr("id");
    if (id.empty())
        return;

    const auto parentNode = m_parent ? m_parent->getHtmlNode() : nullptr;
    if (parentNode && parentNode->getById(id) != m_htmlNode) {
        const std::string newId = "html" + std::to_string(++LAST_UNIQUE_ID);
        setId(newId);

        if (const auto root = g_html.getRoot(m_htmlRootId)) {
            g_logger.warning("[" + root->moduleName + "] Duplicate id '" + id + "' detected. "
                             "Widget id reassigned to '" + newId + "'.");
        }
    } else setId(id);
}

UIWidgetPtr UIWidget::getVirtualParent() const {
    if (m_positionType != PositionType::Absolute)
        return m_parent;

    auto parent = m_parent;
    while (parent->m_positionType == PositionType::Static) {
        parent = parent->m_parent;
    }

    return parent;
}

void UIWidget::updateSize() {
    if (!isAnchorable()) return;

    if (m_positionType == PositionType::Absolute) {
        const bool L = m_positions.left.unit != Unit::Auto;
        const bool R = m_positions.right.unit != Unit::Auto;
        const bool T = m_positions.top.unit != Unit::Auto;
        const bool B = m_positions.bottom.unit != Unit::Auto;

        const auto updateWidth = m_width.needsUpdate(Unit::Auto, SIZE_VERSION_COUNTER) && L && R;
        const auto updateHeigth = m_height.needsUpdate(Unit::FitContent, SIZE_VERSION_COUNTER) && T && B;

        if (updateWidth || updateHeigth) {
            auto parent = getVirtualParent();
            parent->updateSize();

            const int pW = parent->isOnHtml() ? parent->getWidthHtml().valueCalculed : parent->getWidth();
            const int pH = parent->isOnHtml() ? parent->getHeightHtml().valueCalculed : parent->getHeight();

            if (updateWidth) {
                int w = pW
                    - (m_positions.left.unit == Unit::Percent ? (pW * m_positions.left.value) / 100 : m_positions.left.value)
                    - (m_positions.right.unit == Unit::Percent ? (pW * m_positions.right.value) / 100 : m_positions.right.value)
                    - (getPaddingLeft() + getPaddingRight());
                setWidth_px(std::max<int>(0, w));
                m_width.applyUpdate(getWidth(), SIZE_VERSION_COUNTER);
            }

            if (updateHeigth) {
                int h = pH
                    - (m_positions.top.unit == Unit::Percent ? (pH * m_positions.top.value) / 100 : m_positions.top.value)
                    - (m_positions.bottom.unit == Unit::Percent ? (pH * m_positions.bottom.value) / 100 : m_positions.bottom.value)
                    - (getPaddingTop() + getPaddingBottom());
                setHeight_px(std::max<int>(0, h));
                m_height.applyUpdate(getHeight(), SIZE_VERSION_COUNTER);
            }
        }
    }

    const bool widthNeedsUpdate = m_width.needsUpdate(Unit::Auto, SIZE_VERSION_COUNTER) || m_width.needsUpdate(Unit::Percent, SIZE_VERSION_COUNTER);
    const bool heightNeedsUpdate = m_height.needsUpdate(Unit::Percent, SIZE_VERSION_COUNTER);

    if (widthNeedsUpdate || heightNeedsUpdate) {
        auto width = -1;
        auto height = -1;
        auto parent = m_parent;
        while (parent) {
            if (m_positionType == PositionType::Absolute && parent->m_positionType == PositionType::Static) {
                parent = parent->m_parent;
                continue;
            }

            if (widthNeedsUpdate) {
                auto v = (parent->isOnHtml() ? parent->getWidthHtml().valueCalculed : parent->getWidth());
                if (v > -1) width = v - parent->getPaddingLeft() - parent->getPaddingRight();
            }

            if (heightNeedsUpdate) {
                auto v = (parent->isOnHtml() ? parent->getHeightHtml().valueCalculed : parent->getHeight());
                if (v > -1) height = v - parent->getPaddingTop() - parent->getPaddingBottom();
            }

            if (widthNeedsUpdate && heightNeedsUpdate) {
                if (width > -1 && height > -1)
                    break;
            } else if (widthNeedsUpdate) {
                if (width > -1)
                    break;
            } else if (heightNeedsUpdate)
                if (height > -1)
                    break;

            parent = parent->m_parent;
        }

        if (width > -1 || height > -1) {
            updateDimension(this, width, height);
        }
    }

    if (m_children.empty()) {
        m_width.pendingUpdate = false;
        m_height.pendingUpdate = false;
        return;
    }

    if (m_width.needsUpdate(Unit::FitContent, SIZE_VERSION_COUNTER) || m_height.needsUpdate(Unit::FitContent, SIZE_VERSION_COUNTER)) {
        int width = 0;
        int height = 0;
        for (auto& c : getChildren()) {
            if (c->getFloat() == FloatType::None && c->getPositionType() != PositionType::Absolute) {
                const auto textSize = c->getTextSize() + c->getTextOffset().toSize();

                const int c_width = std::max<int>(textSize.width(), std::max<int>(c->getWidth(), c->getWidthHtml().valueCalculed)) + c->getMarginRight() + c->getMarginLeft() + c->getPaddingLeft() + c->getPaddingRight();
                if (breakLine(c->getDisplay())) {
                    if (c_width > width)
                        width = c_width;
                } else  width += c_width;

                const int c_height = std::max<int>(textSize.height(), std::max<int>(c->getHeight(), c->getHeightHtml().valueCalculed)) + c->getMarginBottom() + c->getMarginTop() + c->getPaddingTop() + c->getPaddingBottom();
                if (breakLine(c->getDisplay()) || c->getPrevWidget() && breakLine(c->getPrevWidget()->getDisplay())) {
                    height += c_height;
                } else if (c_height > height)
                    height = c_height;
            }
        }

        if (m_width.needsUpdate(Unit::FitContent, SIZE_VERSION_COUNTER)) {
            setWidth_px(width + getPaddingLeft() + getPaddingRight());
            m_width.applyUpdate(getWidth(), SIZE_VERSION_COUNTER);
        }

        if (m_height.needsUpdate(Unit::FitContent, SIZE_VERSION_COUNTER)) {
            setHeight_px(height + getPaddingTop() + getPaddingBottom());
            m_height.applyUpdate(getHeight(), SIZE_VERSION_COUNTER);
        }
    }
}

void UIWidget::applyAnchorAlignment() {
    if (!isOnHtml() || !isAnchorable())
        return;

    resetAnchors();

    if (m_displayType == DisplayType::None) {
        return;
    }

    if (!hasAnchoredLayout())
        return;

    disableUpdateTemporarily();

    if (m_htmlNode->getAttr("anchor") == "parent") {
        setLeftAnchor(this, "parent", Fw::AnchorLeft);
        setTopAnchor(this, "parent", Fw::AnchorTop);
        return;
    }

    const DisplayType parentDisplay = m_parent ? m_parent->m_displayType : DisplayType::Block;

    FloatType effFloat = mapLogicalFloat(getFloat());
    if (isFlexContainer(parentDisplay) || isGridContainer(parentDisplay) || isTableContainer(parentDisplay) || m_positionType == PositionType::Absolute) {
        effFloat = FloatType::None;
    }

    FlowContext ctx = computeFlowContext(this, parentDisplay, effFloat);

    if (parentDisplay == DisplayType::InlineBlock || parentDisplay == DisplayType::Block || parentDisplay == DisplayType::TableCell) {
        bool anchored = true;

        const auto isInline = isInlineLike(m_displayType);

        if (isInline && m_parent->getTextAlign() == Fw::AlignCenter ||
            !isInline && m_parent->getJustifyItems() == JustifyItemsType::Center) {
            if (ctx.lastNormalWidget)
                setLeftAnchor(this, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorRight);
            else
                addAnchor(Fw::AnchorHorizontalCenter, "parent", Fw::AnchorHorizontalCenter);
        } else if (m_positionType != PositionType::Absolute) {
            if (isInline && m_parent->getTextAlign() == Fw::AlignLeft ||
                !isInline && m_parent->getJustifyItems() == JustifyItemsType::Left) {
                if (ctx.lastNormalWidget)
                    setLeftAnchor(this, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorRight);
                else
                    addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
            } else if (isInline && m_parent->getTextAlign() == Fw::AlignRight ||
                    !isInline && m_parent->getJustifyItems() == JustifyItemsType::Right) {
                if (ctx.lastNormalWidget)
                    setRightAnchor(this, "next", Fw::AnchorLeft);
                else
                    addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
            } else anchored = false;

            if (m_parent->getHtmlNode()->getStyle("align-items") == "center" && m_positionType != PositionType::Absolute) {
                anchored = true;
                addAnchor(Fw::AnchorVerticalCenter, "parent", Fw::AnchorVerticalCenter);
            }
        } else anchored = false;

        if (anchored) {
            if (!ctx.lastNormalWidget) {
                addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            } else {
                if (isInlineLike(m_displayType) && isInlineLike(ctx.lastNormalWidget->getDisplay()))
                    addAnchor(Fw::AnchorTop, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorTop);
                else
                    addAnchor(Fw::AnchorTop, ctx.lastNormalWidget->getId().c_str(), Fw::AnchorBottom);
            }
            return;
        }
    }

    if (m_positionType == PositionType::Absolute) {
        if (getPositions().top.unit == Unit::Auto && getPositions().bottom.unit != Unit::Auto) {
            addAnchor(Fw::AnchorBottom, "parent", Fw::AnchorBottom);
        } else {
            addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        }

        if (getPositions().left.unit == Unit::Auto && getPositions().right.unit != Unit::Auto) {
            addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
        } else {
            addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        }

        return;
    }

    const ClearType effClear = mapLogicalClear(m_clearType);
    const bool topCleared = applyClear(this, ctx, effClear);

    if (effFloat == FloatType::Left || effFloat == FloatType::Right) {
        applyFloat(this, ctx, effFloat, topCleared);
    } else if (isFlexContainer(parentDisplay)) {
        applyFlex(this, ctx, topCleared);
    } else if (isGridContainer(parentDisplay)) {
        applyGridOrTable(this, ctx, topCleared);
    } else if (isTableBox(parentDisplay)) {
        switch (parentDisplay) {
            case DisplayType::Table: {
                if (m_displayType == DisplayType::TableCaption)
                    applyTableCaption(this, ctx, topCleared);
                else if (m_displayType == DisplayType::TableColumnGroup || m_displayType == DisplayType::TableColumn)
                    applyTableColumnLike(this);
                else
                    applyTableChild(this, ctx, topCleared);
                break;
            }
            case DisplayType::TableRowGroup:
            case DisplayType::TableHeaderGroup:
            case DisplayType::TableFooterGroup: {
                applyTableRowGroupChild(this, ctx, topCleared);
                break;
            }
            case DisplayType::TableRow: {
                applyTableRowChild(this, ctx, topCleared);
                break;
            }
            default: {
                applyGridOrTable(this, ctx, topCleared);
                break;
            }
        }
    } else if (isInlineLike(m_displayType)) {
        applyInline(this, ctx, topCleared);
    } else {
        applyBlock(this, ctx, topCleared);
    }
}