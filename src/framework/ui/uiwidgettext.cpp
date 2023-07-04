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

#include <framework/core/graphicalapplication.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/fontmanager.h>
#include <client/gameconfig.h>
#include "uitranslator.h"
#include "uiwidget.h"

void UIWidget::initText()
{
    m_font = g_gameConfig.getWidgetTextFont();
    m_textAlign = Fw::AlignCenter;
    m_coordsBuffer = std::make_shared<CoordsBuffer>();
}

void UIWidget::updateText()
{
    if (isTextWrap() && m_rect.isValid())
        m_drawText = m_font->wrapText(m_text, getWidth() - m_textOffset.x);
    else
        m_drawText = m_text;

    if (m_font)
        m_glyphsPositionsCache = m_font->calculateGlyphsPositions(m_drawText, m_textAlign, &m_textSize);

    // update rect size
    if (!m_rect.isValid() || hasProp(PropTextHorizontalAutoResize) || hasProp(PropTextVerticalAutoResize)) {
        Size textBoxSize = m_textSize;
        textBoxSize += Size(m_padding.left + m_padding.right, m_padding.top + m_padding.bottom) + m_textOffset.toSize();
        textBoxSize *= m_fontScale;

        Size size = getSize();
        if (size.width() <= 0 || (hasProp(PropTextHorizontalAutoResize) && !isTextWrap()))
            size.setWidth(textBoxSize.width());
        if (size.height() <= 0 || hasProp(PropTextVerticalAutoResize))
            size.setHeight(textBoxSize.height());

        setSize(size);
    }

    m_textCachedScreenCoords = {};
    g_app.repaint();
}

void UIWidget::resizeToText()
{
    auto textSize = getTextSize();
    textSize += Size(m_padding.left + m_padding.right, m_padding.top + m_padding.bottom);
    textSize += m_textOffset.toSize();
    setSize(textSize * m_fontScale);
}

void UIWidget::parseTextStyle(const OTMLNodePtr& styleNode)
{
    for (const auto& node : styleNode->children()) {
        if (node->tag() == "text")
            setText(node->value());
        else if (node->tag() == "text-align")
            setTextAlign(Fw::translateAlignment(node->value()));
        else if (node->tag() == "text-offset")
            setTextOffset(node->value<Point>());
        else if (node->tag() == "text-wrap")
            setTextWrap(node->value<bool>());
        else if (node->tag() == "text-auto-resize")
            setTextAutoResize(node->value<bool>());
        else if (node->tag() == "text-horizontal-auto-resize")
            setTextHorizontalAutoResize(node->value<bool>());
        else if (node->tag() == "text-vertical-auto-resize")
            setTextVerticalAutoResize(node->value<bool>());
        else if (node->tag() == "text-only-upper-case")
            setTextOnlyUpperCase(node->value<bool>());
        else if (node->tag() == "font")
            setFont(node->value());
        else if (node->tag() == "font-scale")
            setFontScale(node->value<float>());
    }
}

void UIWidget::drawText(const Rect& screenCoords)
{
    if (m_drawText.empty() || m_color.aF() == 0.f)
        return;

    if (screenCoords != m_textCachedScreenCoords) {
        m_textCachedScreenCoords = screenCoords;

        auto textOffset = m_textOffset;
        textOffset.scale(m_fontScale);

        auto coords = Rect(screenCoords.topLeft().scale(m_fontScale), screenCoords.bottomRight().scale(m_fontScale));
        coords.translate(textOffset);

        m_font->fillTextCoords(m_coordsBuffer, m_text, m_textSize, m_textAlign, coords, m_glyphsPositionsCache);
    }

    g_drawPool.scale(m_fontScale);
    g_drawPool.addTexturedCoordsBuffer(m_font->getTexture(), m_coordsBuffer, m_color);
    g_drawPool.scale(1.f); // reset scale
}

void UIWidget::onTextChange(const std::string_view text, const std::string_view oldText)
{
    callLuaField("onTextChange", text, oldText);
}

void UIWidget::onFontChange(const std::string_view font) { callLuaField("onFontChange", font); }

void UIWidget::setText(const std::string_view text, bool dontFireLuaCall)
{
    std::string _text{ text.data() };
    if (hasProp(PropTextOnlyUpperCase))
        stdext::toupper(_text);

    if (m_text == _text)
        return;

    const std::string oldText = m_text;
    m_text = _text;
    updateText();

    if (!dontFireLuaCall) {
        onTextChange(_text, oldText);
    }
}

void UIWidget::setFont(const std::string_view fontName)
{
    m_font = g_fonts.getFont(fontName);
    updateText();
    onFontChange(fontName);
}