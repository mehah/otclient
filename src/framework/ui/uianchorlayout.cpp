/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
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

#include "uianchorlayout.h"
#include "uiwidget.h"

UIWidgetPtr UIAnchor::getHookedWidget(const UIWidgetPtr& widget, const UIWidgetPtr& parentWidget)
{
    if (!parentWidget)
        return nullptr;

    // determine hooked widget
    if (m_hookedWidgetId == "parent")
        return parentWidget;

    if (m_hookedWidgetId == "next")
        return parentWidget->getChildAfter(widget);

    if (m_hookedWidgetId == "prev")
        return parentWidget->getChildBefore(widget);

    return parentWidget->getChildById(m_hookedWidgetId);
}

int UIAnchor::getHookedPoint(const UIWidgetPtr& hookedWidget, const UIWidgetPtr& parentWidget)
{
    // determine hooked widget edge point
    const auto& hookedWidgetRect = hookedWidget == parentWidget ?
        parentWidget->getPaddingRect() : hookedWidget->getRect();

    int point = 0;
    switch (m_hookedEdge) {
        case Fw::AnchorLeft:
            point = hookedWidgetRect.left();
            break;
        case Fw::AnchorRight:
            point = hookedWidgetRect.right();
            break;
        case Fw::AnchorTop:
            point = hookedWidgetRect.top();
            break;
        case Fw::AnchorBottom:
            point = hookedWidgetRect.bottom();
            break;
        case Fw::AnchorHorizontalCenter:
            point = hookedWidgetRect.horizontalCenter();
            break;
        case Fw::AnchorVerticalCenter:
            point = hookedWidgetRect.verticalCenter();
            break;
        default:
            // must never happens
            assert(false);
            break;
    }

    if (hookedWidget == parentWidget) {
        switch (m_hookedEdge) {
            case Fw::AnchorLeft:
            case Fw::AnchorRight:
            case Fw::AnchorHorizontalCenter:
                point -= parentWidget->getVirtualOffset().x;
                break;
            case Fw::AnchorBottom:
            case Fw::AnchorTop:
            case Fw::AnchorVerticalCenter:
                point -= parentWidget->getVirtualOffset().y;
                break;
            default:
                break;
        }
    }

    return point;
}

void UIAnchorGroup::addAnchor(const UIAnchorPtr& anchor)
{
    // duplicated anchors must be replaced
    for (auto& other : m_anchors) {
        if (other->getAnchoredEdge() == anchor->getAnchoredEdge()) {
            other = anchor;
            return;
        }
    }
    m_anchors.emplace_back(anchor);
}

void UIAnchorLayout::addAnchor(const UIWidgetPtr& anchoredWidget, Fw::AnchorEdge anchoredEdge,
                               const std::string_view hookedWidgetId, Fw::AnchorEdge hookedEdge)
{
    if (!anchoredWidget)
        return;

    assert(anchoredWidget != getParentWidget());

    auto& anchorGroup = m_anchorsGroups[anchoredWidget];
    if (!anchorGroup)
        anchorGroup = std::make_shared<UIAnchorGroup>();

    anchorGroup->addAnchor(std::make_shared<UIAnchor>(anchoredEdge, hookedWidgetId, hookedEdge));

    // layout must be updated because a new anchor got in
    update();
}

void UIAnchorLayout::removeAnchors(const UIWidgetPtr& anchoredWidget)
{
    m_anchorsGroups.erase(anchoredWidget);
    update();
}

bool UIAnchorLayout::hasAnchors(const UIWidgetPtr& anchoredWidget) const
{
    return m_anchorsGroups.contains(anchoredWidget);
}

void UIAnchorLayout::centerIn(const UIWidgetPtr& anchoredWidget, const std::string_view hookedWidgetId)
{
    addAnchor(anchoredWidget, Fw::AnchorHorizontalCenter, hookedWidgetId, Fw::AnchorHorizontalCenter);
    addAnchor(anchoredWidget, Fw::AnchorVerticalCenter, hookedWidgetId, Fw::AnchorVerticalCenter);
}

void UIAnchorLayout::fill(const UIWidgetPtr& anchoredWidget, const std::string_view hookedWidgetId)
{
    addAnchor(anchoredWidget, Fw::AnchorLeft, hookedWidgetId, Fw::AnchorLeft);
    addAnchor(anchoredWidget, Fw::AnchorRight, hookedWidgetId, Fw::AnchorRight);
    addAnchor(anchoredWidget, Fw::AnchorTop, hookedWidgetId, Fw::AnchorTop);
    addAnchor(anchoredWidget, Fw::AnchorBottom, hookedWidgetId, Fw::AnchorBottom);
}

void UIAnchorLayout::addWidget(const UIWidgetPtr&)
{
    update();
}

void UIAnchorLayout::removeWidget(const UIWidgetPtr& widget)
{
    removeAnchors(widget);
}

bool UIAnchorLayout::updateWidget(const UIWidgetPtr& widget, const UIAnchorGroupPtr& anchorGroup, UIWidgetPtr first)
{
    const auto& parentWidget = getParentWidget();
    if (!parentWidget)
        return false;

    if (first == widget) {
        g_logger.error(stdext::format("child '%s' of parent widget '%s' is recursively anchored to itself, please fix this", widget->getId(), parentWidget->getId()));
        return false;
    }

    if (!first)
        first = widget;

    Rect newRect = widget->getRect();
    bool verticalMoved = false;
    bool horizontalMoved = false;

    // calculates new rect based on anchors
    for (const auto& anchor : anchorGroup->getAnchors()) {
        // skip invalid anchors
        if (anchor->getHookedEdge() == Fw::AnchorNone)
            continue;

        // determine hooked widget
        const auto& hookedWidget = anchor->getHookedWidget(widget, parentWidget);

        // skip invalid anchors
        if (!hookedWidget)
            continue;

        if (hookedWidget != getParentWidget()) {
            // update this hooked widget anchors
            auto it = m_anchorsGroups.find(hookedWidget);
            if (it != m_anchorsGroups.end()) {
                const auto& hookedAnchorGroup = it->second;
                if (!hookedAnchorGroup->isUpdated())
                    updateWidget(hookedWidget, hookedAnchorGroup, first);
            }
        }

        const int point = anchor->getHookedPoint(hookedWidget, parentWidget);
        switch (anchor->getAnchoredEdge()) {
            case Fw::AnchorHorizontalCenter:
                newRect.moveHorizontalCenter(point + widget->getMarginLeft() - widget->getMarginRight());
                horizontalMoved = true;
                break;
            case Fw::AnchorLeft:
                if (!horizontalMoved) {
                    newRect.moveLeft(point + widget->getMarginLeft());
                    horizontalMoved = true;
                } else
                    newRect.setLeft(point + widget->getMarginLeft());
                break;
            case Fw::AnchorRight:
                if (!horizontalMoved) {
                    newRect.moveRight(point - widget->getMarginRight());
                    horizontalMoved = true;
                } else
                    newRect.setRight(point - widget->getMarginRight());
                break;
            case Fw::AnchorVerticalCenter:
                newRect.moveVerticalCenter(point + widget->getMarginTop() - widget->getMarginBottom());
                verticalMoved = true;
                break;
            case Fw::AnchorTop:
                if (!verticalMoved) {
                    newRect.moveTop(point + widget->getMarginTop());
                    verticalMoved = true;
                } else
                    newRect.setTop(point + widget->getMarginTop());
                break;
            case Fw::AnchorBottom:
                if (!verticalMoved) {
                    newRect.moveBottom(point - widget->getMarginBottom());
                    verticalMoved = true;
                } else
                    newRect.setBottom(point - widget->getMarginBottom());
                break;
            default:
                break;
        }
    }

    anchorGroup->setUpdated(true);
    return widget->setRect(newRect);
}

bool UIAnchorLayout::internalUpdate()
{
    // reset all anchors groups update state
    for (auto& it : m_anchorsGroups)
        it.second->setUpdated(false);

    bool changed = false;

    // update all anchors
    for (const auto& [widget, anchorGroup] : m_anchorsGroups) {
        if (anchorGroup->isUpdated())
            continue;

        if (updateWidget(widget, anchorGroup))
            changed = true;
    }

    return changed;
}