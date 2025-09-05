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
    inline bool isTableContext(DisplayType d) {
        return d == DisplayType::Table || d == DisplayType::TableRow || d == DisplayType::TableCell;
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

    FlowCtx computeFlowContext(UIWidget* self, DisplayType parentDisplay, FloatType effFloat) {
        FlowCtx ctx;
        if (!self->getParent()) return ctx;

        int i = 0;
        for (const auto& c : self->getParent()->getChildren()) {
            if (c.get() == self) break;
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

    inline void anchorToParentTL(UIWidget* self) {
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

    bool applyClear(UIWidget* self, const FlowCtx& ctx, ClearType effClear) {
        bool topCleared = false;
        UIWidget* clearTarget = nullptr;

        if (effClear == ClearType::Both) {
            clearTarget = pickLower(ctx.lastLeftFloat, ctx.lastRightFloat);
        } else if (effClear == ClearType::Left) {
            clearTarget = ctx.lastLeftFloat;
        } else if (effClear == ClearType::Right) {
            clearTarget = ctx.lastRightFloat;
        }

        if (clearTarget) {
            self->addAnchor(Fw::AnchorTop, clearTarget->getId(), Fw::AnchorBottom);
            topCleared = true;
        } else if (effClear != ClearType::None) {
            self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            topCleared = true;
        }
        return topCleared;
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
            self->addAnchor(isLeftF ? Fw::AnchorLeft : Fw::AnchorRight,
                            ctx.lastFloatSameSide->getId(),
                            isLeftF ? Fw::AnchorRight : Fw::AnchorLeft);
            if (!topCleared)
                self->addAnchor(Fw::AnchorTop, ctx.lastFloatSameSide->getId(), Fw::AnchorTop);
        } else if (!isLeftF && blockAfterLeftSameLine) {
            self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
            if (!topCleared)
                self->addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorTop);

            if (ctx.prevNonFloat) {
                ctx.prevNonFloat->removeAnchor(Fw::AnchorRight);
                ctx.prevNonFloat->addAnchor(Fw::AnchorRight, self->getId(), Fw::AnchorLeft);
            }
        } else {
            self->addAnchor(isLeftF ? Fw::AnchorLeft : Fw::AnchorRight,
                            "parent",
                            isLeftF ? Fw::AnchorLeft : Fw::AnchorRight);
            if (!topCleared)
                self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        }
    }

    void applyFlex(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
            if (!topCleared) self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        } else {
            self->addAnchor(Fw::AnchorLeft, ctx.prevNonFloat->getId(), Fw::AnchorRight);
            if (!topCleared) self->addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorTop);
        }
    }

    void applyGridOrTable(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            anchorToParentTL(self);
        } else {
            self->addAnchor(Fw::AnchorLeft, ctx.prevNonFloat->getId(), Fw::AnchorRight);
            if (!topCleared) self->addAnchor(Fw::AnchorTop, ctx.prevNonFloat->getId(), Fw::AnchorTop);
        }
    }

    void applyInline(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            if (ctx.hasLeft) {
                self->addAnchor(Fw::AnchorLeft, ctx.lastLeftFloat->getId(), Fw::AnchorRight);
                if (!topCleared) self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            } else if (ctx.hasRight) {
                self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
                if (!topCleared) self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            } else {
                anchorToParentTL(self);
            }
        } else {
            if (isInlineLike(ctx.prevNonFloat->getDisplay())) {
                self->addAnchor(Fw::AnchorLeft, "prev", Fw::AnchorRight);
                if (!topCleared) self->addAnchor(Fw::AnchorTop, "prev", Fw::AnchorTop);
            } else {
                self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
                if (!topCleared) self->addAnchor(Fw::AnchorTop, "prev", Fw::AnchorBottom);
            }
        }
    }

    void applyBlock(UIWidget* self, const FlowCtx& ctx, bool topCleared) {
        if (!ctx.prevNonFloat) {
            if (ctx.hasLeft) {
                self->addAnchor(Fw::AnchorLeft, ctx.lastLeftFloat->getId(), Fw::AnchorRight);
                self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
                if (!topCleared) self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            } else if (ctx.hasRight) {
                self->addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
                if (!topCleared) self->addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            } else {
                anchorToParentTL(self);
            }
        } else {
            self->addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
            if (!topCleared) self->addAnchor(Fw::AnchorTop, "prev", Fw::AnchorBottom);
        }
    }

    void applyFitContentIfNeeded(UIWidget* self) {
        if (self->getChildren().empty() || (!self->hasProp(PropFitWidth) && !self->hasProp(PropFitHeight)))
            return;

        g_dispatcher.deferEvent([self_w = self->static_self_cast<UIWidget>()] {
            UIWidget* self = self_w.get();

            if (self->hasProp(PropFitWidth)) {
                auto start = self->getRect().topLeft().x - self->getMarginLeft();
                auto end = self->getRect().topRight().x + self->getMarginRight();
                for (const auto& c : self->getChildren()) {
                    if (c->getRect().topLeft().x < start || start == 0)
                        start = c->getRect().topLeft().x - c->getMarginLeft();
                    if (c->getRect().topRight().x > end)
                        end = c->getRect().topRight().x + c->getMarginRight();
                }
                self->setWidth_px(end - start);
                self->setProp(PropFitWidth, false);
            }

            if (self->hasProp(PropFitHeight)) {
                auto start = self->getRect().topLeft().y - self->getMarginTop();
                auto end = self->getRect().bottomLeft().y + self->getMarginBottom();
                for (const auto& c : self->getChildren()) {
                    if (c->getRect().topLeft().y < start || start == 0)
                        start = c->getRect().topLeft().y - c->getMarginTop();
                    if (c->getRect().bottomLeft().y > end)
                        end = c->getRect().bottomLeft().y + c->getMarginBottom();
                }
                self->setHeight_px(end - start);
                self->setProp(PropFitHeight, false);
            }
        });
    }
}

void UIWidget::setHeight(std::string heightStr) {
    stdext::trim(heightStr);
    stdext::tolower(heightStr);

    auto height = stdext::to_number(heightStr);

    if (heightStr == "auto" || heightStr == "fit-content") {
        setProp(PropFitHeight, true);
        scheduleHtmlStyleUpdate();
    } else if (heightStr.ends_with("em")) {
    } else if (heightStr.ends_with("%")) {
    } else /*px*/ {
        setProp(PropFitHeight, false);
        setHeight_px(height);
    }
}

void UIWidget::setWidth(std::string widthStr) {
    stdext::trim(widthStr);
    stdext::tolower(widthStr);

    auto width = stdext::to_number(widthStr);

    if (widthStr == "auto") {
        if (m_displayType == DisplayType::Block) {
            if (m_parent) setWidth_px(m_parent->getWidth());
        } else {
            setProp(PropFitWidth, true);
            scheduleHtmlStyleUpdate();
        }
    } else if (widthStr == "fit-content") {
        setProp(PropFitWidth, true);
        scheduleHtmlStyleUpdate();
    } else if (widthStr.ends_with("em")) {
    } else if (widthStr.ends_with("%")) {
    } else /*px*/ {
        setProp(PropFitWidth, false);
        setWidth_px(width);
    }
}

void UIWidget::scheduleHtmlStyleUpdate() {
    if (hasProp(PropUpdateStyleHtml))
        return;

    setProp(PropUpdateStyleHtml, true);
    g_dispatcher.deferEvent([self = static_self_cast<UIWidget>()] {
        self->updateStyleHtml();
        self->setProp(PropUpdateStyleHtml, false);
    });
}

void UIWidget::updateStyleHtml() {
    if (!isOnHtml())
        return;

    breakAnchors();

    if (m_displayType == DisplayType::None) {
        setVisible(false);
        return;
    }
    setVisible(true);

    if (!hasAnchoredLayout())
        return;

    if (m_htmlNode->getAttr("anchor") == "parent") {
        addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
        addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        applyFitContentIfNeeded(this);
        return;
    }

    const DisplayType parentDisplay = m_parent ? m_parent->m_displayType : DisplayType::Block;

    FloatType effFloat = mapLogicalFloat(m_floatType);
    if (isFlexContainer(parentDisplay) || isGridContainer(parentDisplay) || isTableContext(parentDisplay)) {
        effFloat = FloatType::None;
    }

    FlowCtx ctx = computeFlowContext(this, parentDisplay, effFloat);

    const ClearType effClear = mapLogicalClear(m_clearType);
    const bool topCleared = applyClear(this, ctx, effClear);

    if (effFloat == FloatType::Left || effFloat == FloatType::Right) {
        applyFloat(this, ctx, effFloat, topCleared);
    } else if (isFlexContainer(parentDisplay)) {
        applyFlex(this, ctx, topCleared);
    } else if (isGridContainer(parentDisplay) || isTableContext(parentDisplay)) {
        applyGridOrTable(this, ctx, topCleared);
    } else if (isInlineLike(m_displayType)) {
        applyInline(this, ctx, topCleared);
    } else {
        applyBlock(this, ctx, topCleared);
    }

    applyFitContentIfNeeded(this);
}