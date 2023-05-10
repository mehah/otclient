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

#include "uiprogressrect.h"
#include <framework/graphics/fontmanager.h>

#include "framework/graphics/drawpool.h"
#include "framework/graphics/drawpoolmanager.h"

void UIProgressRect::drawSelf(DrawPoolType drawPane)
{
    if (drawPane != DrawPoolType::FOREGROUND)
        return;

    // todo: check +1 to right/bottom
    // todo: add smooth
    const auto& drawRect = getPaddingRect();

    // 0% - 12.5% (12.5)
    // triangle from top center, to top right (var x)
    if (m_percent < 12.5) {
        const auto& var = Point(std::max<int>(m_percent - 0.0, 0.0) * (drawRect.right() - drawRect.horizontalCenter()) / 12.5, 0);
        g_drawPool.addFilledTriangle(drawRect.center(), drawRect.topRight() + Point(1, 0), drawRect.topCenter() + var, m_backgroundColor);
    }

    // 12.5% - 37.5% (25)
    // triangle from top right to bottom right (var y)
    if (m_percent < 37.5) {
        const auto& var = Point(0, std::max<int>(m_percent - 12.5, 0.0) * (drawRect.bottom() - drawRect.top()) / 25.0);
        g_drawPool.addFilledTriangle(drawRect.center(), drawRect.bottomRight() + Point(1), drawRect.topRight() + var + Point(1, 0), m_backgroundColor);
    }

    // 37.5% - 62.5% (25)
    // triangle from bottom right to bottom left (var x)
    if (m_percent < 62.5) {
        const auto& var = Point(std::max<int>(m_percent - 37.5, 0.0) * (drawRect.right() - drawRect.left()) / 25.0, 0);
        g_drawPool.addFilledTriangle(drawRect.center(), drawRect.bottomLeft() + Point(0, 1), drawRect.bottomRight() - var + Point(1), m_backgroundColor);
    }

    // 62.5% - 87.5% (25)
    // triangle from bottom left to top left
    if (m_percent < 87.5) {
        const auto& var = Point(0, std::max<int>(m_percent - 62.5, 0.0) * (drawRect.bottom() - drawRect.top()) / 25.0);
        g_drawPool.addFilledTriangle(drawRect.center(), drawRect.topLeft(), drawRect.bottomLeft() - var + Point(0, 1), m_backgroundColor);
    }

    // 87.5% - 100% (12.5)
    // triangle from top left to top center
    if (m_percent < 100) {
        const auto& var = Point(std::max<int>(m_percent - 87.5, 0.0) * (drawRect.horizontalCenter() - drawRect.left()) / 12.5, 0);
        g_drawPool.addFilledTriangle(drawRect.center(), drawRect.topCenter(), drawRect.topLeft() + var, m_backgroundColor);
    }

    drawImage(m_rect);
    drawBorder(m_rect);
    drawIcon(m_rect);
    drawText(m_rect);
}

void UIProgressRect::setPercent(float percent)
{
    m_percent = std::clamp<float>(percent, 0.0, 100.0);
}

void UIProgressRect::onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode)
{
    UIWidget::onStyleApply(styleName, styleNode);

    for (const auto& node : styleNode->children()) {
        if (node->tag() == "percent")
            setPercent(node->value<float>());
    }
}