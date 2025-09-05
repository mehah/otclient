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
    } else {
        auto isInlineLike = [](DisplayType d) {
            switch (d) {
                case DisplayType::Inline:
                case DisplayType::InlineBlock:
                case DisplayType::InlineFlex:
                case DisplayType::InlineGrid: return true;
                default: return false;
            }
        };
        auto isFlexContainer = [](DisplayType d) {
            return d == DisplayType::Flex || d == DisplayType::InlineFlex;
        };
        auto isGridContainer = [](DisplayType d) {
            return d == DisplayType::Grid || d == DisplayType::InlineGrid;
        };
        auto isTableContext = [](DisplayType d) {
            return d == DisplayType::Table || d == DisplayType::TableRow || d == DisplayType::TableCell;
        };
        auto anchorToParentTL = [this]() {
            addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
            addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
        };
        auto mapLogicalFloat = [](FloatType f) {
            if (f == FloatType::InlineStart) return FloatType::Left;
            if (f == FloatType::InlineEnd)   return FloatType::Right;
            return f;
        };
        auto mapLogicalClear = [](ClearType c) {
            if (c == ClearType::InlineStart) return ClearType::Left;
            if (c == ClearType::InlineEnd)   return ClearType::Right;
            return c;
        };

        const DisplayType parentDisplay = m_parent ? m_parent->m_displayType : DisplayType::Block;

        FloatType effFloat = mapLogicalFloat(m_floatType);
        if (isFlexContainer(parentDisplay) || isGridContainer(parentDisplay) || isTableContext(parentDisplay))
            effFloat = FloatType::None;

        UIWidget* prevNonFloat = nullptr;
        UIWidget* lastLeftFloat = nullptr;
        UIWidget* lastRightFloat = nullptr;
        UIWidget* lastFloatSameSide = nullptr;
        int prevNonFloatIdx = -1, lastLeftIdx = -1, lastRightIdx = -1, i = 0;

        if (m_parent) {
            for (const auto& c : m_parent->m_children) {
                if (c.get() == this) break;
                const FloatType cf = mapLogicalFloat(c->m_floatType);
                if (cf == FloatType::None) { prevNonFloat = c.get(); prevNonFloatIdx = i; } else if (cf == FloatType::Left) { lastLeftFloat = c.get();  lastLeftIdx = i; } else if (cf == FloatType::Right) { lastRightFloat = c.get(); lastRightIdx = i; }
                if (cf == effFloat) lastFloatSameSide = c.get();
                ++i;
            }
        }

        const bool isInline = isInlineLike(m_displayType);
        const bool hasLeft = lastLeftFloat != nullptr;
        const bool hasRight = lastRightFloat != nullptr;

        bool topCleared = false;
        const ClearType effClear = mapLogicalClear(m_clearType);
        auto pickLower = [&](UIWidget* a, UIWidget* b) -> UIWidget* {
            if (!a) return b;
            if (!b) return a;
            const auto ay = a->m_rect.bottomLeft().y;
            const auto by = b->m_rect.bottomLeft().y;
            return by > ay ? b : a;
        };
        UIWidget* clearTarget = nullptr;
        if (effClear == ClearType::Both) clearTarget = pickLower(lastLeftFloat, lastRightFloat);
        else if (effClear == ClearType::Left)  clearTarget = lastLeftFloat;
        else if (effClear == ClearType::Right) clearTarget = lastRightFloat;

        if (clearTarget) {
            addAnchor(Fw::AnchorTop, clearTarget->getId(), Fw::AnchorBottom);
            topCleared = true;
        } else if (effClear != ClearType::None) {
            addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            topCleared = true;
        }

        if (effFloat == FloatType::Left || effFloat == FloatType::Right) {
            const bool isLeftF = (effFloat == FloatType::Left);
            const bool blockAfterLeftSameLine =
                (!isLeftF) && prevNonFloat && (prevNonFloatIdx > lastLeftIdx) && (lastLeftIdx >= 0) && !isInlineLike(prevNonFloat->m_displayType);

            if (lastFloatSameSide) {
                addAnchor(isLeftF ? Fw::AnchorLeft : Fw::AnchorRight,
                          lastFloatSameSide->getId(),
                          isLeftF ? Fw::AnchorRight : Fw::AnchorLeft);
                if (!topCleared)
                    addAnchor(Fw::AnchorTop, lastFloatSameSide->getId(), Fw::AnchorTop);
            } else if (!isLeftF && blockAfterLeftSameLine) {
                addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
                if (!topCleared)
                    addAnchor(Fw::AnchorTop, prevNonFloat->getId(), Fw::AnchorTop);
                if (prevNonFloat) {
                    prevNonFloat->removeAnchor(Fw::AnchorRight);
                    prevNonFloat->addAnchor(Fw::AnchorRight, getId(), Fw::AnchorLeft);
                }
            } else {
                addAnchor(isLeftF ? Fw::AnchorLeft : Fw::AnchorRight, "parent", isLeftF ? Fw::AnchorLeft : Fw::AnchorRight);
                if (!topCleared)
                    addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            }
        } else if (isFlexContainer(parentDisplay)) {
            if (!prevNonFloat) {
                addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
                if (!topCleared) addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
            } else {
                addAnchor(Fw::AnchorLeft, prevNonFloat->getId(), Fw::AnchorRight);
                if (!topCleared) addAnchor(Fw::AnchorTop, prevNonFloat->getId(), Fw::AnchorTop);
            }
        } else if (isGridContainer(parentDisplay) || isTableContext(parentDisplay)) {
            if (!prevNonFloat) {
                anchorToParentTL();
            } else {
                addAnchor(Fw::AnchorLeft, prevNonFloat->getId(), Fw::AnchorRight);
                if (!topCleared) addAnchor(Fw::AnchorTop, prevNonFloat->getId(), Fw::AnchorTop);
            }
        } else if (isInline) {
            if (!prevNonFloat) {
                if (hasLeft) {
                    addAnchor(Fw::AnchorLeft, lastLeftFloat->getId(), Fw::AnchorRight);
                    if (!topCleared) addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
                } else if (hasRight) {
                    addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
                    if (!topCleared) addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
                } else {
                    anchorToParentTL();
                }
            } else {
                if (isInlineLike(prevNonFloat->m_displayType)) {
                    addAnchor(Fw::AnchorLeft, "prev", Fw::AnchorRight);
                    if (!topCleared) addAnchor(Fw::AnchorTop, "prev", Fw::AnchorTop);
                } else {
                    addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
                    if (!topCleared) addAnchor(Fw::AnchorTop, "prev", Fw::AnchorBottom);
                }
            }
        } else {
            if (!prevNonFloat) {
                if (hasLeft) {
                    addAnchor(Fw::AnchorLeft, lastLeftFloat->getId(), Fw::AnchorRight);
                    addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
                    if (!topCleared) addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
                } else if (hasRight) {
                    addAnchor(Fw::AnchorRight, "parent", Fw::AnchorRight);
                    if (!topCleared) addAnchor(Fw::AnchorTop, "parent", Fw::AnchorTop);
                } else {
                    anchorToParentTL();
                }
            } else {
                addAnchor(Fw::AnchorLeft, "parent", Fw::AnchorLeft);
                if (!topCleared) addAnchor(Fw::AnchorTop, "prev", Fw::AnchorBottom);
            }
        }
    }

    if (getChildren().empty() || (!hasProp(PropFitWidth) && !hasProp(PropFitHeight)))
        return;

    g_dispatcher.deferEvent([this, self = static_self_cast<UIWidget>()] {
        if (hasProp(PropFitWidth)) {
            auto start = m_rect.topLeft().x - getMarginLeft();
            auto end = m_rect.topRight().x + getMarginRight();
            for (const auto& c : getChildren()) {
                if (c->m_rect.topLeft().x < start || start == 0) start = c->m_rect.topLeft().x - c->getMarginLeft();
                if (c->m_rect.topRight().x > end)                end = c->m_rect.topRight().x + c->getMarginRight();
            }
            setWidth_px(end - start);
            setProp(PropFitWidth, false);
        }
        if (hasProp(PropFitHeight)) {
            auto start = m_rect.topLeft().y - getMarginTop();
            auto end = m_rect.bottomLeft().y + getMarginBottom();
            for (const auto& c : getChildren()) {
                if (c->m_rect.topLeft().y < start || start == 0) start = c->m_rect.topLeft().y - c->getMarginTop();
                if (c->m_rect.bottomLeft().y > end)               end = c->m_rect.bottomLeft().y + c->getMarginBottom();
            }
            setHeight_px(end - start);
            setProp(PropFitHeight, false);
        }
    });
}