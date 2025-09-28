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
    static uint32_t VERSION_EPOCH = 1;
    static bool FLUSH_PENDING = false;
    static std::vector<UIWidgetPtr> WIDGET_QUEUE;

    static bool isInlineLike(DisplayType d) {
        switch (d) {
            case DisplayType::Inline:
            case DisplayType::InlineBlock:
            case DisplayType::InlineFlex:
            case DisplayType::InlineGrid: return true;
            default: return false;
        }
    }
    static bool isFlexContainer(DisplayType d) {
        return d == DisplayType::Flex || d == DisplayType::InlineFlex;
    }
    static bool isGridContainer(DisplayType d) {
        return d == DisplayType::Grid || d == DisplayType::InlineGrid;
    }

    static bool isTableBox(DisplayType d) {
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

    static bool breakLine(DisplayType d) {
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

    static bool isTableContainer(DisplayType d) {
        return d == DisplayType::Table
            || d == DisplayType::TableRowGroup
            || d == DisplayType::TableHeaderGroup
            || d == DisplayType::TableFooterGroup
            || d == DisplayType::TableRow;
    }

    static FloatType mapLogicalFloat(FloatType f) {
        if (f == FloatType::InlineStart) return FloatType::Left;
        if (f == FloatType::InlineEnd)   return FloatType::Right;
        return f;
    }
    static ClearType mapLogicalClear(ClearType c) {
        if (c == ClearType::InlineStart) return ClearType::Left;
        if (c == ClearType::InlineEnd)   return ClearType::Right;
        return c;
    }

    struct FlowCtx
    {
        UIWidget* prevNonFloat = nullptr;
        UIWidget* lastLeftFloat = nullptr;
        UIWidget* lastRightFloat = nullptr;
        UIWidget* lastFloatSameSide = nullptr;

        int prevNonFloatIdx = -1;
        int lastLeftIdx = -1;
        int lastRightIdx = -1;
        bool hasLeft = false;
        bool hasRight = false;
    };

    static void anchorToParentTL(UIWidget* self) {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorTop);
        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
    }

    static void applyTableChild(UIWidget* self, const FlowCtx& ctx, bool topCleared)
    {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorRight);
        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);

        if (!ctx.prevNonFloat) {
            self->removeAnchor(Fw::AnchorTop);
            self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        } else {
            if (!topCleared) {
                self->removeAnchor(Fw::AnchorTop);
                self->addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorBottom);
            }
        }
    }

    static void applyTableRowGroupChild(UIWidget* self, const FlowCtx& ctx, bool topCleared)
    {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorRight);
        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);

        if (!ctx.prevNonFloat) {
            self->removeAnchor(Fw::AnchorTop);
            self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        } else if (!topCleared) {
            self->removeAnchor(Fw::AnchorTop);
            self->addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorBottom);
        }
    }

    static void applyTableRowChild(UIWidget* self, const FlowCtx& ctx, bool topCleared)
    {
        self->removeAnchor(Fw::AnchorTop);
        self->removeAnchor(Fw::AnchorBottom);
        self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        self->addAnchor(Fw::AnchorBottom, "parent", Fw::AnchorBottom);

        if (!ctx.prevNonFloat) {
            self->removeAnchor(Fw::AnchorLeft);
            self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        } else {
            self->removeAnchor(Fw::AnchorLeft);
            self->addAnchor(Fw::AnchorLeft, ctx.prevNonFloat->getId(), Fw::AnchorRight);
        }
    }

    static void applyTableCaption(UIWidget* self, const FlowCtx& /*ctx*/, bool /*topCleared*/)
    {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorRight);
        self->removeAnchor(Fw::AnchorTop);

        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
        self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
    }

    static void applyTableColumnLike(UIWidget* self)
    {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorTop);
        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
    }

    static UIWidget* pickLower(UIWidget* a, UIWidget* b) {
        if (!a) return b;
        if (!b) return a;
        const auto ay = a->getRect().bottomLeft().y;
        const auto by = b->getRect().bottomLeft().y;
        return (by > ay) ? b : a;
    }

    static void setLeftAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->removeAnchor(Fw::AnchorLeft);
        w->addAnchor(Fw::AnchorLeft, std::string(toId), edge);
    }
    static void setRightAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->removeAnchor(Fw::AnchorRight);
        w->addAnchor(Fw::AnchorRight, std::string(toId), edge);
    }
    static void setTopAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->removeAnchor(Fw::AnchorTop);
        w->addAnchor(Fw::AnchorTop, std::string(toId), edge);
    }

    static FlowCtx computeFlowContext(UIWidget* self, DisplayType /*parentDisplay*/, FloatType effFloat) {
        FlowCtx ctx;

        if (self->getPositionType() == PositionType::Absolute)
            return ctx;

        int i = 0;
        for (const auto& c : self->getParent()->getChildren()) {
            if (c.get() == self) break;

            if (c->getDisplay() == DisplayType::None) { ++i; continue; }
            if (!c->isAnchorable() || c->getPositionType() == PositionType::Absolute) { ++i; continue; }

            const FloatType cf = mapLogicalFloat(c->getFloat());
            if (cf == FloatType::None) {
                ctx.prevNonFloat = c.get(); ctx.prevNonFloatIdx = i;
            } else if (cf == FloatType::Left) {
                ctx.lastLeftFloat = c.get();  ctx.lastLeftIdx = i;
            } else if (cf == FloatType::Right) {
                ctx.lastRightFloat = c.get(); ctx.lastRightIdx = i;
            }
            if (cf == effFloat) ctx.lastFloatSameSide = c.get();
            ++i;
        }
        ctx.hasLeft = (ctx.lastLeftFloat != nullptr);
        ctx.hasRight = (ctx.lastRightFloat != nullptr);
        return ctx;
    }

    bool applyClear(UIWidget* self, const FlowCtx& ctx, ClearType effClear) {
        if (effClear == ClearType::None) return false;

        UIWidget* target = nullptr;
        if (effClear == ClearType::Both)      target = pickLower(ctx.lastLeftFloat, ctx.lastRightFloat);
        else if (effClear == ClearType::Left) target = ctx.lastLeftFloat;
        else /* Right */                      target = ctx.lastRightFloat;

        if (target) {
            setTopAnchor(self, target->getId(), Fw::AnchorBottom);
            return true;
        }
        return false;
    }

    static void applyFloat(UIWidget* self, const FlowCtx& ctx, FloatType effFloat, bool topCleared) {
        const bool isLeftF = (effFloat == FloatType::Left);

        const bool blockAfterLeftSameLine =
            (!isLeftF)
            && ctx.prevNonFloat
            && (ctx.prevNonFloatIdx > ctx.lastLeftIdx)
            && (ctx.lastLeftIdx >= 0)
            && !isInlineLike(ctx.prevNonFloat->getDisplay());

        if (ctx.lastFloatSameSide) {
            if (isLeftF) setLeftAnchor(self, ctx.lastFloatSameSide->getId(), Fw::AnchorRight);
            else         setRightAnchor(self, ctx.lastFloatSameSide->getId(), Fw::AnchorLeft);
            if (!topCleared) setTopAnchor(self, ctx.lastFloatSameSide->getId(), Fw::AnchorTop);
        } else if (!isLeftF && blockAfterLeftSameLine) {
            setRightAnchor(self, "parent", Fw::AnchorRight);
            if (!topCleared && ctx.prevNonFloat)
                setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorTop);
        } else {
            if (isLeftF) setLeftAnchor(self, "parent", Fw::AnchorLeft);
            else         setRightAnchor(self, "parent", Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
        }
    }

    static void applyFlex(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            setLeftAnchor(self, "parent", Fw::AnchorLeft);
            if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
        } else {
            setLeftAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorTop);
        }
    }

    static void applyGridOrTable(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            anchorToParentTL(self);
        } else {
            setLeftAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorTop);
        }
    }

    static int calcOuterWidth(UIWidget* w) {
        const auto textSz = w->getTextSize() + w->getTextOffset().toSize();
        const int contentW = std::max<int>(textSz.width(),
                              std::max<int>(w->getWidth(),
                                           w->isOnHtml() ? w->getWidthHtml().valueCalculed : -1));
        return contentW
            + w->getMarginLeft() + w->getMarginRight()
            + w->getPaddingLeft() + w->getPaddingRight();
    }

    static int calcOuterHeight(UIWidget* w) {
        const auto textSz = w->getTextSize() + w->getTextOffset().toSize();
        const int contentH = std::max<int>(textSz.height(),
                              std::max<int>(w->getHeight(),
                                           w->isOnHtml() ? w->getHeightHtml().valueCalculed : -1));
        return contentH
            + w->getMarginTop() + w->getMarginBottom()
            + w->getPaddingTop() + w->getPaddingBottom();
    }

    static int parentInnerWidth(UIWidget* p) {
        const int pw = p->isOnHtml() ? p->getWidthHtml().valueCalculed : p->getWidth();
        return std::max<int>(0, pw - p->getPaddingLeft() - p->getPaddingRight());
    }

    static int currentInlineRunWidth(UIWidget* self) {
        auto* parent = self->getParent().get();
        if (!parent) return 0;

        int run = 0;
        int lastTop = INT_MIN;

        for (const auto& c : parent->getChildren()) {
            if (c.get() == self) break;
            if (c->getDisplay() == DisplayType::None) continue;
            if (!c->isAnchorable() || c->getPositionType() == PositionType::Absolute) continue;

            const auto cf = mapLogicalFloat(c->getFloat());
            if (cf != FloatType::None) continue;

            if (breakLine(c->getDisplay())) { run = 0; lastTop = INT_MIN; continue; }

            if (isInlineLike(c->getDisplay())) {
                const int ct = c->getRect().topLeft().y;
                if (lastTop == INT_MIN) lastTop = ct;
                if (ct > lastTop) { run = 0; lastTop = ct; }
                run += calcOuterWidth(c.get());
            } else {
                run = 0;
                lastTop = INT_MIN;
            }
        }
        return run;
    }

    void applyInline(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (auto* parent = self->getParent().get()) {
            const int innerW = parentInnerWidth(parent);
            if (innerW > 0) {
                const int runBefore = currentInlineRunWidth(self);
                const int nextRun = runBefore + calcOuterWidth(self);
                if (nextRun > innerW) {
                    setLeftAnchor(self, "parent", Fw::AnchorLeft);
                    if (!topCleared) {
                        if (ctx.prevNonFloat) setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorBottom);
                        else                  setTopAnchor(self, "parent", Fw::AnchorTop);
                    }
                    return;
                }
            }
        }

        if (!ctx.prevNonFloat) {
            if (ctx.hasLeft) {
                setLeftAnchor(self, ctx.lastLeftFloat->getId(), Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else if (ctx.hasRight) {
                setRightAnchor(self, "parent", Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else {
                anchorToParentTL(self);
            }
        } else {
            if (isInlineLike(ctx.prevNonFloat->getDisplay())) {
                self->removeAnchor(Fw::AnchorLeft);
                self->addAnchor(Fw::AnchorLeft, ctx.prevNonFloat->getId(), Fw::AnchorRight);
                if (!topCleared) {
                    self->removeAnchor(Fw::AnchorTop);
                    self->addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorTop);
                }
            } else {
                setLeftAnchor(self, "parent", Fw::AnchorLeft);
                if (!topCleared) setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorBottom);
            }
        }
    }

    void applyBlock(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            if (ctx.hasLeft) {
                setLeftAnchor(self, ctx.lastLeftFloat->getId(), Fw::AnchorRight);
                setRightAnchor(self, "parent", Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else if (ctx.hasRight) {
                setRightAnchor(self, "parent", Fw::AnchorRight);
                if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
            } else {
                anchorToParentTL(self);
            }
        } else {
            setLeftAnchor(self, "parent", Fw::AnchorLeft);
            if (!topCleared) setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorBottom);
        }
    }

    static Unit detectUnit(std::string_view s) {
        if (s == "auto") return Unit::Auto;
        if (s == "fit-content") return Unit::FitContent;
        if (s.ends_with("px")) return Unit::Px;
        if (s.ends_with("em")) return Unit::Em;
        if (s.ends_with("%"))  return Unit::Percent;
        return Unit::Px;
    }

    static std::string_view numericPart(std::string_view s) {
        if (s.ends_with("px") || s.ends_with("em")) return s.substr(0, s.size() - 2);
        if (s.ends_with("%")) return s.substr(0, s.size() - 1);
        return s;
    }

    void updateDimension(UIWidget* widget, int width, int height) {
        bool checkChildren = false;

        if (widget->getWidthHtml().needsUpdate(Unit::Percent) || widget->getWidthHtml().needsUpdate(Unit::Auto)) {
            width -= (widget->getMarginLeft() + widget->getMarginRight());

            if (widget->getWidthHtml().version != VERSION_EPOCH) {
                if (widget->getWidthHtml().needsUpdate(Unit::Percent))
                    width = std::round(width * (widget->getWidthHtml().value / 100.0));

                widget->setWidth_px(width);
                widget->getWidthHtml().applyUpdate(width, VERSION_EPOCH);

                checkChildren = true;
            }
        }

        if (widget->getHeightHtml().needsUpdate(Unit::Percent, VERSION_EPOCH)) {
            height = std::round(height * (widget->getHeightHtml().value / 100.0));
            widget->setHeight_px(height);
            widget->getHeightHtml().applyUpdate(height, VERSION_EPOCH);
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
        WIDGET_QUEUE.emplace_back(static_self_cast<UIWidget>());

    setProp(prop, true);

    if (FLUSH_PENDING)
        return;

    FLUSH_PENDING = true;
    g_dispatcher.deferEvent([self = static_self_cast<UIWidget>()] {
        for (const auto& widget : WIDGET_QUEUE) {
            if (widget->hasProp(PropUpdateSize)) {
                widget->updateSize();
                widget->setProp(PropUpdateSize, false);
            }

            if (widget->hasProp(PropApplyAnchorAlignment)) {
                widget->applyAnchorAlignment();
                widget->setProp(PropApplyAnchorAlignment, false);
            }
        }

        WIDGET_QUEUE.clear();
        FLUSH_PENDING = false;
        ++VERSION_EPOCH;
    });
}

void UIWidget::setOverflow(OverflowType type) {
    if (m_overflowType == type)
        return;

    m_overflowType = type;

    scheduleHtmlTask(PropApplyAnchorAlignment);

    // Only Vertical
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
    const Unit unit = detectUnit(type);
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

// needs to be cached
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

        const auto updateWidth = m_width.needsUpdate(Unit::Auto, VERSION_EPOCH) && L && R;
        const auto updateHeigth = m_height.needsUpdate(Unit::FitContent, VERSION_EPOCH) && T && B;

        if (updateWidth || updateHeigth) {
            static auto pxW = [](const SizeUnit& u, int pW) { return u.unit == Unit::Percent ? (pW * int(u.value)) / 100 : int(u.value); };
            static auto pxH = [](const SizeUnit& u, int pH) { return u.unit == Unit::Percent ? (pH * int(u.value)) / 100 : int(u.value); };

            auto parent = getVirtualParent();
            parent->updateSize();

            auto pW = parent->isOnHtml() ? parent->getWidthHtml().valueCalculed : parent->getWidth();
            auto pH = parent->isOnHtml() ? parent->getHeightHtml().valueCalculed : parent->getHeight();

            if (updateWidth) {
                int w = pW
                    - (m_positions.left.unit == Unit::Percent ? (pW * m_positions.left.value) / 100 : m_positions.left.value)
                    - (m_positions.right.unit == Unit::Percent ? (pW * m_positions.right.value) / 100 : m_positions.right.value)
                    - (getPaddingLeft() + getPaddingRight());
                setWidth_px(std::max<int>(0, w));
                m_width.applyUpdate(getWidth(), VERSION_EPOCH);
            }

            if (updateHeigth) {
                int h = pH
                    - (m_positions.top.unit == Unit::Percent ? (pH * m_positions.top.value) / 100 : m_positions.top.value)
                    - (m_positions.bottom.unit == Unit::Percent ? (pH * m_positions.bottom.value) / 100 : m_positions.bottom.value)
                    - (getPaddingTop() + getPaddingBottom());
                setHeight_px(std::max<int>(0, h));
                m_height.applyUpdate(getHeight(), VERSION_EPOCH);
            }
        }
    }

    const bool widthNeedsUpdate = m_width.needsUpdate(Unit::Auto, VERSION_EPOCH) || m_width.needsUpdate(Unit::Percent, VERSION_EPOCH);
    const bool heightNeedsUpdate = m_height.needsUpdate(Unit::Percent, VERSION_EPOCH);

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

    if (m_width.needsUpdate(Unit::FitContent, VERSION_EPOCH) || m_height.needsUpdate(Unit::FitContent, VERSION_EPOCH)) {
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

        if (m_width.needsUpdate(Unit::FitContent, VERSION_EPOCH)) {
            setWidth_px(width + getPaddingLeft() + getPaddingRight());
            m_width.applyUpdate(getWidth(), VERSION_EPOCH);
        }

        if (m_height.needsUpdate(Unit::FitContent, VERSION_EPOCH)) {
            setHeight_px(height + getPaddingTop() + getPaddingBottom());
            m_height.applyUpdate(getHeight(), VERSION_EPOCH);
        }
    }
}

void UIWidget::applyAnchorAlignment() {
    if (!isOnHtml() || !isAnchorable())
        return;

    breakAnchors();

    if (m_displayType == DisplayType::None) {
        return;
    }

    if (!hasAnchoredLayout())
        return;

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

    FlowCtx ctx = computeFlowContext(this, parentDisplay, effFloat);

    if (parentDisplay == DisplayType::InlineBlock || parentDisplay == DisplayType::Block || parentDisplay == DisplayType::TableCell) {
        bool anchored = true;

        const auto isInline = isInlineLike(m_displayType);

        if (isInline && m_parent->getTextAlign() == Fw::AlignCenter ||
            !isInline && m_parent->getJustifyItems() == JustifyItemsType::Center) {
            if (ctx.prevNonFloat)
                setLeftAnchor(this, ctx.prevNonFloat->getId(), Fw::AnchorRight);
            else
                addAnchor(Fw::AnchorHorizontalCenter, "parent", Fw::AnchorHorizontalCenter);
        } else if (m_positionType != PositionType::Absolute) {
            if (isInline && m_parent->getTextAlign() == Fw::AlignLeft ||
                !isInline && m_parent->getJustifyItems() == JustifyItemsType::Left) {
                if (ctx.prevNonFloat)
                    setLeftAnchor(this, ctx.prevNonFloat->getId(), Fw::AnchorRight);
                else
                    addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
            } else if (isInline && m_parent->getTextAlign() == Fw::AlignRight ||
                    !isInline && m_parent->getJustifyItems() == JustifyItemsType::Right) {
                if (ctx.prevNonFloat)
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
            if (!ctx.prevNonFloat) {
                addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            } else {
                if (isInlineLike(m_displayType) && isInlineLike(ctx.prevNonFloat->getDisplay()))
                    addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorTop);
                else
                    addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorBottom);
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