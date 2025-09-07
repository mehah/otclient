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

namespace {
    inline bool isInlineLike(DisplayType d) {
        switch (d) {
            case DisplayType::Inline:
            case DisplayType::InlineBlock:
            case DisplayType::InlineFlex:
            case DisplayType::InlineGrid: return true;
            default: return false;
        }
    }
    inline bool isFlexContainer(DisplayType d) {
        return d == DisplayType::Flex || d == DisplayType::InlineFlex;
    }
    inline bool isGridContainer(DisplayType d) {
        return d == DisplayType::Grid || d == DisplayType::InlineGrid;
    }

    inline bool isTableBox(DisplayType d) {
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

    inline bool breakLine(DisplayType d) {
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

    inline bool isTableContainer(DisplayType d) {
        return d == DisplayType::Table
            || d == DisplayType::TableRowGroup
            || d == DisplayType::TableHeaderGroup
            || d == DisplayType::TableFooterGroup
            || d == DisplayType::TableRow;
    }

    inline FloatType mapLogicalFloat(FloatType f) {
        if (f == FloatType::InlineStart) return FloatType::Left;
        if (f == FloatType::InlineEnd)   return FloatType::Right;
        return f;
    }
    inline ClearType mapLogicalClear(ClearType c) {
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

    inline void anchorToParentTL(UIWidget* self) {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorTop);
        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
    }

    void applyTableChild(UIWidget* self, const FlowCtx& ctx, bool topCleared)
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

    void applyTableRowGroupChild(UIWidget* self, const FlowCtx& ctx, bool topCleared)
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

    void applyTableRowChild(UIWidget* self, const FlowCtx& ctx, bool topCleared)
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

    void applyTableCaption(UIWidget* self, const FlowCtx& /*ctx*/, bool /*topCleared*/)
    {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorRight);
        self->removeAnchor(Fw::AnchorTop);

        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
        self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
    }

    void applyTableColumnLike(UIWidget* self)
    {
        self->removeAnchor(Fw::AnchorLeft);
        self->removeAnchor(Fw::AnchorTop);
        self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
    }

    inline UIWidget* pickLower(UIWidget* a, UIWidget* b) {
        if (!a) return b;
        if (!b) return a;
        const auto ay = a->getRect().bottomLeft().y;
        const auto by = b->getRect().bottomLeft().y;
        return (by > ay) ? b : a;
    }

    inline void setLeftAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->removeAnchor(Fw::AnchorLeft);
        w->addAnchor(Fw::AnchorLeft, std::string(toId), edge);
    }
    inline void setRightAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->removeAnchor(Fw::AnchorRight);
        w->addAnchor(Fw::AnchorRight, std::string(toId), edge);
    }
    inline void setTopAnchor(UIWidget* w, std::string_view toId, Fw::AnchorEdge edge) {
        w->removeAnchor(Fw::AnchorTop);
        w->addAnchor(Fw::AnchorTop, std::string(toId), edge);
    }

    FlowCtx computeFlowContext(UIWidget* self, DisplayType /*parentDisplay*/, FloatType effFloat) {
        FlowCtx ctx;
        if (!self->getParent()) return ctx;

        int i = 0;
        for (const auto& c : self->getParent()->getChildren()) {
            if (c.get() == self) break;

            if (c->getDisplay() == DisplayType::None) { ++i; continue; }

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

    void applyFloat(UIWidget* self, const FlowCtx& ctx, FloatType effFloat, bool topCleared) {
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

    void applyFlex(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            setLeftAnchor(self, "parent", Fw::AnchorLeft);
            if (!topCleared) setTopAnchor(self, "parent", Fw::AnchorTop);
        } else {
            setLeftAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorTop);
        }
    }

    void applyGridOrTable(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            anchorToParentTL(self);
        } else {
            setLeftAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorRight);
            if (!topCleared) setTopAnchor(self, ctx.prevNonFloat->getId(), Fw::AnchorTop);
        }
    }

    void applyInline(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
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
}

void UIWidget::applyDimension(bool isWidth, std::string valueStr) {
    stdext::trim(valueStr);
    stdext::tolower(valueStr);

    const std::string_view sv = valueStr;
    const Unit unit = detectUnit(sv);
    const auto num = stdext::to_number(std::string(numericPart(sv)));

    auto setFitProp = [&](bool on) {
        if (isWidth) setProp(PropFitWidth, on);
        else         setProp(PropFitHeight, on);
    };
    auto setPx = [&](int px) {
        if (isWidth) setWidth_px(px);
        else         setHeight_px(px);
    };

    setFitProp(false);
    setProp(PropAutoWidth, false);

    switch (unit) {
        case Unit::Auto: {
            if (isWidth) {
                if (m_displayType == DisplayType::Block) {
                    if (m_parent) setProp(PropAutoWidth, true);
                } else {
                    setFitProp(true);
                }
            } else {
                setFitProp(true);
            }
            break;
        }
        case Unit::FitContent: {
            setFitProp(true);
            break;
        }
        case Unit::Percent: {
            if (m_parent) {
                const int base = isWidth ? m_parent->getWidth() : m_parent->getHeight();
                setPx(static_cast<int>(std::round(base * (num / 100.0))));
            } else {
                setPx(0);
            }
            break;
        }
        case Unit::Em:
        case Unit::Px:
        case Unit::Invalid:
        default: {
            setPx(static_cast<int>(std::round(num)));
            return;
        }
    }

    scheduleUpdateSize();
}

namespace {
    static uint32_t UPDATE_EPOCH = 1;
    static bool FLUSH_PENDING = false;
    std::vector<UIWidgetPtr> WIDGET_QUEUE;
}

void UIWidget::scheduleUpdateSize() {
    WIDGET_QUEUE.emplace_back(static_self_cast<UIWidget>());
    if (FLUSH_PENDING)
        return;

    FLUSH_PENDING = true;
    g_dispatcher.deferEvent([self = static_self_cast<UIWidget>()] {
        for (const auto& widget : WIDGET_QUEUE)
            widget->updateSize();

        WIDGET_QUEUE.clear();
        FLUSH_PENDING = false;
        ++UPDATE_EPOCH;
    });
}

void UIWidget::setDisplay(DisplayType type) {
    m_displayType = type;
    const bool show = m_displayType != DisplayType::None;
    setVisible(show);
    if (show)scheduleAnchorAlignment();
}

void UIWidget::updateSize() {
    if (m_updateId == UPDATE_EPOCH)
        return;

    static auto updateRect = [](UIWidget* c, int& width, int& height, auto&& updateRect)->void {
        if (c->m_updateId != UPDATE_EPOCH && !c->m_children.empty() && (c->hasProp(PropFitWidth) || c->hasProp(PropFitHeight))) {
            for (auto& w : c->m_children) {
                updateRect(w.get(), width, height, updateRect);
            }

            if (c->hasProp(PropFitWidth)) {
                c->setWidth_px(width + c->getPaddingLeft() + c->getPaddingRight());
                c->setProp(PropFitWidth, false);
            }

            if (c->hasProp(PropFitHeight)) {
                c->setHeight_px(height + (c->m_children.size() + 1) + c->getMarginBottom() + c->getPaddingTop() + c->getPaddingBottom());
                c->setProp(PropFitHeight, false);
            }

            c->m_updateId = UPDATE_EPOCH;
        } else {
            const auto textSize = c->getTextSize() + c->getTextOffset().toSize();

            const int c_width = std::max<int>(textSize.width(), c->getWidth()) + c->getMarginRight() + c->getMarginRight() + c->getPaddingLeft() + c->getPaddingRight();
            if (breakLine(c->getDisplay())) {
                if (c_width > width)
                    width = c_width;
            } else
                width += c_width;

            const int c_height = std::max<int>(textSize.height(), c->getHeight()) + c->getMarginBottom() + c->getMarginTop() + c->getPaddingTop() + c->getPaddingBottom();

            if (breakLine(c->getDisplay())) {
                height += c_height;
            } else
                if (c_height > height)
                    height = c_height;
        }
    };

    if (hasProp(PropAutoWidth)) {
        auto width = 0;
        auto parent = m_parent;
        while (parent) {
            if (parent->getWidth() > 0) {
                width = parent->getWidth();
                break;
            }

            parent = parent->m_parent;
        }
        if (width > 0)
            setWidth_px(width - getMarginLeft());
    }

    if (m_children.empty()) {
        setProp(PropFitWidth, false);
        setProp(PropFitHeight, false);
        return;
    }

    int width = 0;
    int height = 0;
    updateRect(this, width, height, updateRect);
}

void UIWidget::scheduleAnchorAlignment() {
    if (hasProp(PropApplyAnchorAlignment))
        return;

    setProp(PropApplyAnchorAlignment, true);
    g_dispatcher.deferEvent([self = static_self_cast<UIWidget>()] {
        self->applyAnchorAlignment();
        self->setProp(PropApplyAnchorAlignment, false);
    });
}

void UIWidget::applyAnchorAlignment() {
    if (!isOnHtml())
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

    FloatType effFloat = mapLogicalFloat(m_floatType);
    if (isFlexContainer(parentDisplay) || isGridContainer(parentDisplay) || isTableContainer(parentDisplay)) {
        effFloat = FloatType::None;
    }

    FlowCtx ctx = computeFlowContext(this, parentDisplay, effFloat);

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