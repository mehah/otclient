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

#include "uitextedit.h"
#include <framework/core/application.h>
#include <framework/core/clock.h>
#include <framework/graphics/bitmapfont.h>
#include <framework/graphics/graphics.h>
#include <framework/input/mouse.h>
#include <framework/otml/otmlnode.h>
#include <framework/platform/platformwindow.h>

#include "framework/graphics/drawpoolmanager.h"

UITextEdit::UITextEdit()
{
    setProp(Props::PropCursorInRange, true);
    setProp(Props::PropCursorVisible, true);
    setProp(Props::PropEditable, true);
    setProp(Props::PropChangeCursorImage, true);
    setProp(Props::PropUpdatesEnabled, true);
    setProp(Props::PropAutoScroll, true);
    setProp(Props::PropSelectable, true);
    setProp(Props::PropGlyphsMustRecache, true);

    m_textAlign = Fw::AlignTopLeft;
    blinkCursor();
}

void UITextEdit::drawSelf(DrawPoolType drawPane)
{
    if (drawPane != DrawPoolType::FOREGROUND)
        return;

    drawBackground(m_rect);
    drawBorder(m_rect);
    drawImage(m_rect);
    drawIcon(m_rect);

    const auto& texture = m_font->getTexture();
    if (!texture)
        return;

    const bool glyphsMustRecache = getProp(PropGlyphsMustRecache);
    if (glyphsMustRecache)
        setProp(PropGlyphsMustRecache, false);

    const int textLength = std::min<int>(m_glyphsCoords.size(), m_text.length());
    if (m_color != Color::alpha) {
        if (glyphsMustRecache) {
            m_glyphsTextRectCache.clear();
            for (int i = -1; ++i < textLength;)
                m_glyphsTextRectCache.emplace_back(m_glyphsCoords[i].first, m_glyphsCoords[i].second);
        }
        for (const auto& [dest, src] : m_glyphsTextRectCache)
            g_drawPool.addTexturedRect(dest, texture, src, m_color);
    }

    if (hasSelection()) {
        if (glyphsMustRecache) {
            m_glyphsSelectRectCache.clear();
            for (int i = m_selectionStart; i < m_selectionEnd; ++i)
                m_glyphsSelectRectCache.emplace_back(m_glyphsCoords[i].first, m_glyphsCoords[i].second);
        }
        for (const auto& [dest, src] : m_glyphsSelectRectCache)
            g_drawPool.addFilledRect(dest, m_selectionBackgroundColor);

        for (const auto& [dest, src] : m_glyphsSelectRectCache)
            g_drawPool.addTexturedRect(dest, texture, src, m_selectionColor);
    }

    // render cursor
    if (isExplicitlyEnabled() && getProp(PropCursorVisible) && getProp(PropCursorInRange) && isActive() && m_cursorPos >= 0) {
        assert(m_cursorPos <= textLength);
        // draw every 333ms
        constexpr int delay = 333;
        const ticks_t elapsed = g_clock.millis() - m_cursorTicks;
        if (elapsed <= delay) {
            const auto& cursorRect = m_cursorPos > 0 ?
                Rect(m_glyphsCoords[m_cursorPos - 1].first.right(), m_glyphsCoords[m_cursorPos - 1].first.top(), 1, m_font->getGlyphHeight())
                :
                Rect(m_rect.left() + m_padding.left, m_rect.top() + m_padding.top, 1, m_font->getGlyphHeight());

            const bool useSelectionColor = hasSelection() && m_cursorPos >= m_selectionStart && m_cursorPos <= m_selectionEnd;
            const auto& color = useSelectionColor ? m_selectionColor : m_color;
            g_drawPool.addFilledRect(cursorRect, color);
        } else if (elapsed >= 2 * delay) {
            m_cursorTicks = g_clock.millis();
        }
    }
}

void UITextEdit::update(bool focusCursor)
{
    if (!getProp(PropUpdatesEnabled))
        return;

    std::string text = getDisplayedText();
    if (m_text.ends_with(" "))
        text += " ";

    m_drawText = text;
    const int textLength = text.length();

    // prevent glitches
    if (m_rect.isEmpty())
        return;

    // recache coords buffers
    recacheGlyphs();

    // map glyphs positions
    Size textBoxSize;
    const auto& glyphsPositions = m_font->calculateGlyphsPositions(text, m_textAlign, &textBoxSize);
    const Rect* glyphsTextureCoords = m_font->getGlyphsTextureCoords();
    const Size* glyphsSize = m_font->getGlyphsSize();
    int glyph;

    // update rect size
    if (!m_rect.isValid() || hasProp(PropTextHorizontalAutoResize) || hasProp(PropTextVerticalAutoResize)) {
        textBoxSize += Size(m_padding.left + m_padding.right, m_padding.top + m_padding.bottom) + m_textOffset.toSize();
        Size size = getSize();
        if (size.width() <= 0 || (hasProp(PropTextHorizontalAutoResize) && !isTextWrap()))
            size.setWidth(textBoxSize.width());
        if (size.height() <= 0 || hasProp(PropTextVerticalAutoResize))
            size.setHeight(textBoxSize.height());
        setSize(size);
    }

    // resize just on demand
    if (textLength > static_cast<int>(m_glyphsCoords.size())) {
        m_glyphsCoords.resize(textLength);
    }

    const Point oldTextAreaOffset = m_textVirtualOffset;

    if (textBoxSize.width() <= getPaddingRect().width())
        m_textVirtualOffset.x = 0;
    if (textBoxSize.height() <= getPaddingRect().height())
        m_textVirtualOffset.y = 0;

    // readjust start view area based on cursor position
    setProp(PropCursorInRange, false);
    if (focusCursor && getProp(PropAutoScroll)) {
        if (m_cursorPos > 0 && textLength > 0) {
            assert(m_cursorPos <= textLength);
            const Rect virtualRect(m_textVirtualOffset, m_rect.size() - Size(m_padding.left + m_padding.right, 0)); // previous rendered virtual rect
            int pos = m_cursorPos - 1; // element before cursor
            glyph = static_cast<uint8_t>(text[pos]); // glyph of the element before cursor
            Rect glyphRect(glyphsPositions[pos], glyphsSize[glyph]);

            // if the cursor is not on the previous rendered virtual rect we need to update it
            if (!virtualRect.contains(glyphRect.topLeft()) || !virtualRect.contains(glyphRect.bottomRight())) {
                // calculate where is the first glyph visible
                Point startGlyphPos;
                startGlyphPos.y = std::max<int>(glyphRect.bottom() - virtualRect.height(), 0);
                startGlyphPos.x = std::max<int>(glyphRect.right() - virtualRect.width(), 0);

                // find that glyph
                for (pos = 0; pos < textLength; ++pos) {
                    glyph = static_cast<uint8_t>(text[pos]);
                    glyphRect = Rect(glyphsPositions[pos], glyphsSize[glyph]);
                    glyphRect.setTop(std::max<int>(glyphRect.top() - m_font->getYOffset() - m_font->getGlyphSpacing().height(), 0));
                    glyphRect.setLeft(std::max<int>(glyphRect.left() - m_font->getGlyphSpacing().width(), 0));

                    // first glyph entirely visible found
                    if (glyphRect.topLeft() >= startGlyphPos) {
                        m_textVirtualOffset.x = glyphsPositions[pos].x;
                        m_textVirtualOffset.y = glyphsPositions[pos].y - m_font->getYOffset();
                        break;
                    }
                }
            }
        } else {
            m_textVirtualOffset = {};
        }
        setProp(PropCursorInRange, true);
    } else {
        if (m_cursorPos > 0 && textLength > 0) {
            const Rect virtualRect(m_textVirtualOffset, m_rect.size() - Size(2 * m_padding.left + m_padding.right, 0)); // previous rendered virtual rect
            const int pos = m_cursorPos - 1; // element before cursor
            glyph = static_cast<uint8_t>(text[pos]); // glyph of the element before cursor
            const Rect glyphRect(glyphsPositions[pos], glyphsSize[glyph]);
            if (virtualRect.contains(glyphRect.topLeft()) && virtualRect.contains(glyphRect.bottomRight()))
                setProp(PropCursorInRange, true);
        } else {
            setProp(PropCursorInRange, true);
        }
    }

    bool fireAreaUpdate = false;
    if (oldTextAreaOffset != m_textVirtualOffset)
        fireAreaUpdate = true;

    Rect textScreenCoords = m_rect;
    textScreenCoords.expandLeft(-m_padding.left);
    textScreenCoords.expandRight(-m_padding.right);
    textScreenCoords.expandBottom(-m_padding.bottom);
    textScreenCoords.expandTop(-m_padding.top);
    m_drawArea = textScreenCoords;

    if (textScreenCoords.size() != m_textVirtualSize) {
        m_textVirtualSize = textScreenCoords.size();
        fireAreaUpdate = true;
    }

    Size totalSize = textBoxSize;
    if (totalSize.width() < m_textVirtualSize.width())
        totalSize.setWidth(m_textVirtualSize.height());
    if (totalSize.height() < m_textVirtualSize.height())
        totalSize.setHeight(m_textVirtualSize.height());
    if (m_textTotalSize != totalSize) {
        m_textTotalSize = totalSize;
        fireAreaUpdate = true;
    }

    if (m_textAlign & Fw::AlignBottom) {
        m_drawArea.translate(0, textScreenCoords.height() - textBoxSize.height());
    } else if (m_textAlign & Fw::AlignVerticalCenter) {
        m_drawArea.translate(0, (textScreenCoords.height() - textBoxSize.height()) / 2);
    } else { // AlignTop
    }

    if (m_textAlign & Fw::AlignRight) {
        m_drawArea.translate(textScreenCoords.width() - textBoxSize.width(), 0);
    } else if (m_textAlign & Fw::AlignHorizontalCenter) {
        m_drawArea.translate((textScreenCoords.width() - textBoxSize.width()) / 2, 0);
    } else { // AlignLeft
    }

    for (int i = 0; i < textLength; ++i) {
        glyph = static_cast<uint8_t>(text[i]);
        m_glyphsCoords[i].first.clear();

        // skip invalid glyphs
        if (glyph < 32 && glyph != static_cast<uint8_t>('\n'))
            continue;

        // calculate initial glyph rect and texture coords
        Rect glyphScreenCoords(glyphsPositions[i], glyphsSize[glyph]);
        Rect glyphTextureCoords = glyphsTextureCoords[glyph];

        // first translate to align position
        if (m_textAlign & Fw::AlignBottom) {
            glyphScreenCoords.translate(0, textScreenCoords.height() - textBoxSize.height());
        } else if (m_textAlign & Fw::AlignVerticalCenter) {
            glyphScreenCoords.translate(0, (textScreenCoords.height() - textBoxSize.height()) / 2);
        } else { // AlignTop
            // nothing to do
        }

        if (m_textAlign & Fw::AlignRight) {
            glyphScreenCoords.translate(textScreenCoords.width() - textBoxSize.width(), 0);
        } else if (m_textAlign & Fw::AlignHorizontalCenter) {
            glyphScreenCoords.translate((textScreenCoords.width() - textBoxSize.width()) / 2, 0);
        } else { // AlignLeft
            // nothing to do
        }

        // only render glyphs that are after startRenderPosition
        if (glyphScreenCoords.bottom() < m_textVirtualOffset.y || glyphScreenCoords.right() < m_textVirtualOffset.x)
            continue;

        // bound glyph topLeft to startRenderPosition
        if (glyphScreenCoords.top() < m_textVirtualOffset.y) {
            glyphTextureCoords.setTop(glyphTextureCoords.top() + (m_textVirtualOffset.y - glyphScreenCoords.top()));
            glyphScreenCoords.setTop(m_textVirtualOffset.y);
        }
        if (glyphScreenCoords.left() < m_textVirtualOffset.x) {
            glyphTextureCoords.setLeft(glyphTextureCoords.left() + (m_textVirtualOffset.x - glyphScreenCoords.left()));
            glyphScreenCoords.setLeft(m_textVirtualOffset.x);
        }

        // subtract startInternalPos
        glyphScreenCoords.translate(-m_textVirtualOffset);

        // translate rect to screen coords
        glyphScreenCoords.translate(textScreenCoords.topLeft());

        // only render if glyph rect is visible on screenCoords
        if (!textScreenCoords.intersects(glyphScreenCoords))
            continue;

        // bound glyph bottomRight to screenCoords bottomRight
        if (glyphScreenCoords.bottom() > textScreenCoords.bottom()) {
            glyphTextureCoords.setBottom(glyphTextureCoords.bottom() + (textScreenCoords.bottom() - glyphScreenCoords.bottom()));
            glyphScreenCoords.setBottom(textScreenCoords.bottom());
        }
        if (glyphScreenCoords.right() > textScreenCoords.right()) {
            glyphTextureCoords.setRight(glyphTextureCoords.right() + (textScreenCoords.right() - glyphScreenCoords.right()));
            glyphScreenCoords.setRight(textScreenCoords.right());
        }

        // render glyph
        m_glyphsCoords[i].first = glyphScreenCoords;
        m_glyphsCoords[i].second = glyphTextureCoords;
    }

    if (fireAreaUpdate)
        onTextAreaUpdate(m_textVirtualOffset, m_textVirtualSize, m_textTotalSize);

    g_app.repaint();
}

void UITextEdit::setCursorPos(int pos)
{
    if (pos < 0)
        pos = m_text.length();

    if (pos == m_cursorPos)
        return;

    if (pos < 0)
        m_cursorPos = 0;
    else if (static_cast<size_t>(pos) >= m_text.length())
        m_cursorPos = m_text.length();
    else
        m_cursorPos = pos;

    update(true);
}

void UITextEdit::setSelection(int start, int end)
{
    if (start == m_selectionStart && end == m_selectionEnd)
        return;

    if (start > end)
        std::swap(start, end);

    if (end == -1)
        end = m_text.length();

    m_selectionStart = std::clamp<int>(start, 0, static_cast<int>(m_text.length()));
    m_selectionEnd = std::clamp<int>(end, 0, static_cast<int>(m_text.length()));
    recacheGlyphs();

    g_app.repaint();
}

void UITextEdit::setTextHidden(bool hidden)
{
    setProp(PropTextHidden, hidden);
    update(true);
}

void UITextEdit::setTextVirtualOffset(const Point& offset)
{
    m_textVirtualOffset = offset;
    update();
}

void UITextEdit::appendText(const std::string_view txt)
{
    std::string text{ txt.data() };

    if (hasSelection())
        del();

    if (m_cursorPos >= 0) {
        // replace characters that are now allowed
        if (!getProp(PropMultiline))
            stdext::replace_all(text, "\n", " ");
        stdext::replace_all(text, "\r", "");
        stdext::replace_all(text, "\t", "    ");

        if (text.length() > 0) {
            // only add text if textedit can add it
            if (m_maxLength > 0 && m_text.length() + text.length() > m_maxLength)
                return;

            // only ignore text append if it contains invalid characters
            if (!m_validCharacters.empty()) {
                for (const char i : text) {
                    if (m_validCharacters.find(i) == std::string::npos)
                        return;
                }
            }

            std::string tmp = m_text;
            tmp.insert(m_cursorPos, text);
            m_cursorPos += text.length();
            setText(tmp);
        }
    }
}

void UITextEdit::appendCharacter(char c)
{
    if ((c == '\n' && !getProp(PropMultiline)) || c == '\r')
        return;

    if (hasSelection())
        del();

    if (m_cursorPos == 0)
        return;

    if (m_maxLength > 0 && m_text.length() + 1 > m_maxLength)
        return;

    if (!m_validCharacters.empty() && m_validCharacters.find(c) == std::string::npos)
        return;

    std::string tmp;
    tmp = c;
    std::string tmp2 = m_text;
    tmp2.insert(m_cursorPos, tmp);
    ++m_cursorPos;
    setText(tmp2);
}

void UITextEdit::removeCharacter(bool right)
{
    std::string tmp = m_text;
    if (static_cast<size_t>(m_cursorPos) >= 0 && tmp.length() > 0) {
        if (static_cast<size_t>(m_cursorPos) >= tmp.length()) {
            tmp.erase(tmp.begin() + (--m_cursorPos));
        } else if (right)
            tmp.erase(tmp.begin() + m_cursorPos);
        else if (m_cursorPos > 0)
            tmp.erase(tmp.begin() + --m_cursorPos);
        setText(tmp);
    }
}

void UITextEdit::blinkCursor()
{
    m_cursorTicks = g_clock.millis();
    g_app.repaint();
}

void UITextEdit::del(bool right)
{
    if (hasSelection()) {
        std::string tmp = m_text;
        tmp.erase(m_selectionStart, m_selectionEnd - m_selectionStart);

        setCursorPos(m_selectionStart);
        clearSelection();
        setText(tmp);
    } else
        removeCharacter(right);
}

void UITextEdit::paste(const std::string_view text)
{
    if (hasSelection())
        del();

    appendText(text);
}

std::string UITextEdit::copy()
{
    std::string text;
    if (hasSelection()) {
        text = getSelection();
        g_window.setClipboardText(text);
    }
    return text;
}

std::string UITextEdit::cut()
{
    std::string text = copy();
    del();
    return text;
}

void UITextEdit::wrapText()
{
    setText(m_font->wrapText(m_text, getPaddingRect().width() - m_textOffset.x));
}

void UITextEdit::moveCursorHorizontally(bool right)
{
    if (right) {
        if (static_cast<size_t>(m_cursorPos) + 1 <= m_text.length())
            ++m_cursorPos;
        else
            m_cursorPos = 0;
    } else if (m_cursorPos - 1 >= 0)
        --m_cursorPos;
    else
        m_cursorPos = m_text.length();

    blinkCursor();
    update(true);
}

void UITextEdit::moveCursorVertically(bool)
{
    //TODO
}

int UITextEdit::getTextPos(const Point& pos)
{
    const int textLength = m_text.length();

    // find any glyph that is actually on the
    int candidatePos = -1;
    Rect firstGlyphRect, lastGlyphRect;
    for (int i = 0; i < textLength; ++i) {
        Rect clickGlyphRect = m_glyphsCoords[i].first;
        if (!clickGlyphRect.isValid())
            continue;
        if (!firstGlyphRect.isValid())
            firstGlyphRect = clickGlyphRect;
        lastGlyphRect = clickGlyphRect;
        clickGlyphRect.expandTop(m_font->getYOffset() + m_font->getGlyphSpacing().height());
        clickGlyphRect.expandLeft(m_font->getGlyphSpacing().width() + 1);
        if (clickGlyphRect.contains(pos)) {
            candidatePos = i;
            break;
        }
        if (pos.y >= clickGlyphRect.top() && pos.y <= clickGlyphRect.bottom()) {
            if (pos.x <= clickGlyphRect.left()) {
                candidatePos = i;
                break;
            }
            if (pos.x >= clickGlyphRect.right())
                candidatePos = i + 1;
        }
    }

    if (textLength > 0) {
        if (pos.y < firstGlyphRect.top())
            return 0;
        if (pos.y > lastGlyphRect.bottom())
            return textLength;
    }

    return candidatePos;
}

void UITextEdit::updateDisplayedText()
{
    std::string text;
    if (getProp(PropTextHidden))
        text = std::string(m_text.length(), '*');
    else
        text = m_text;

    if (isTextWrap() && m_rect.isValid())
        text = m_font->wrapText(text, getPaddingRect().width() - m_textOffset.x);

    m_displayedText = text;
}

std::string UITextEdit::getSelection()
{
    if (!hasSelection())
        return {};
    return m_text.substr(m_selectionStart, m_selectionEnd - m_selectionStart);
}

void UITextEdit::updateText()
{
    if (m_cursorPos > static_cast<int>(m_text.length()))
        m_cursorPos = m_text.length();

    // any text changes reset the selection
    if (getProp(PropSelectable)) {
        m_selectionEnd = 0;
        m_selectionStart = 0;
    }

    blinkCursor();

    updateDisplayedText();
    update(true);
}

void UITextEdit::onHoverChange(bool hovered)
{
    if (getProp(PropChangeCursorImage)) {
        if (hovered && !g_mouse.isCursorChanged())
            g_mouse.pushCursor("text");
        else
            g_mouse.popCursor("text");
    }
}

void UITextEdit::onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode)
{
    UIWidget::onStyleApply(styleName, styleNode);

    for (const auto& node : styleNode->children()) {
        if (node->tag() == "text") {
            setText(node->value());
            setCursorPos(m_text.length());
        } else if (node->tag() == "text-hidden")
            setTextHidden(node->value<bool>());
        else if (node->tag() == "shift-navigation")
            setShiftNavigation(node->value<bool>());
        else if (node->tag() == "multiline")
            setMultiline(node->value<bool>());
        else if (node->tag() == "max-length")
            setMaxLength(node->value<int>());
        else if (node->tag() == "editable")
            setEditable(node->value<bool>());
        else if (node->tag() == "selectable")
            setSelectable(node->value<bool>());
        else if (node->tag() == "selection-color")
            setSelectionColor(node->value<Color>());
        else if (node->tag() == "selection-background-color")
            setSelectionBackgroundColor(node->value<Color>());
        else if (node->tag() == "selection") {
            const auto& selectionRange = node->value<Point>();
            setSelection(selectionRange.x, selectionRange.y);
        } else if (node->tag() == "cursor-visible")
            setCursorVisible(node->value<bool>());
        else if (node->tag() == "change-cursor-image")
            setChangeCursorImage(node->value<bool>());
        else if (node->tag() == "auto-scroll")
            setAutoScroll(node->value<bool>());
    }
}

void UITextEdit::onGeometryChange(const Rect& oldRect, const Rect& newRect)
{
    update(true);
    UIWidget::onGeometryChange(oldRect, newRect);
}

void UITextEdit::onFocusChange(bool focused, Fw::FocusReason reason)
{
    if (focused) {
        if (reason == Fw::KeyboardFocusReason)
            setCursorPos(m_text.length());
        else
            blinkCursor();
        update(true);
#ifdef ANDROID
        g_androidManager.showKeyboardSoft();
#endif
    } else if (getProp(PropSelectable))
        clearSelection();
    UIWidget::onFocusChange(focused, reason);
}

bool UITextEdit::onKeyPress(uint8_t keyCode, int keyboardModifiers, int autoRepeatTicks)
{
    if (UIWidget::onKeyPress(keyCode, keyboardModifiers, autoRepeatTicks))
        return true;

    if (keyboardModifiers == Fw::KeyboardNoModifier) {
        if (keyCode == Fw::KeyDelete && getProp(PropEditable)) { // erase right character
            if (hasSelection() || !m_text.empty()) {
                del(true);
                return true;
            }
        } else if (keyCode == Fw::KeyBackspace && getProp(PropEditable)) { // erase left character
            if (hasSelection() || !m_text.empty()) {
                del(false);
                return true;
            }
        } else if (keyCode == Fw::KeyRight && !getProp(PropShiftNavigation)) { // move cursor right
            clearSelection();
            moveCursorHorizontally(true);
            return true;
        } else if (keyCode == Fw::KeyLeft && !getProp(PropShiftNavigation)) { // move cursor left
            clearSelection();
            moveCursorHorizontally(false);
            return true;
        } else if (keyCode == Fw::KeyHome) { // move cursor to first character
            if (m_cursorPos != 0) {
                clearSelection();
                setCursorPos(0);
                return true;
            }
        } else if (keyCode == Fw::KeyEnd) { // move cursor to last character
            if (m_cursorPos != static_cast<int>(m_text.length())) {
                clearSelection();
                setCursorPos(m_text.length());
                return true;
            }
        } else if (keyCode == Fw::KeyTab && !getProp(PropShiftNavigation)) {
            clearSelection();
            if (const auto& parent = getParent())
                parent->focusNextChild(Fw::KeyboardFocusReason, true);
            return true;
        } else if (keyCode == Fw::KeyEnter && getProp(PropMultiline) && getProp(PropEditable)) {
            appendCharacter('\n');
            return true;
        } else if (keyCode == Fw::KeyUp && !getProp(PropShiftNavigation) && getProp(PropMultiline)) {
            moveCursorVertically(true);
            return true;
        } else if (keyCode == Fw::KeyDown && !getProp(PropShiftNavigation) && getProp(PropMultiline)) {
            moveCursorVertically(false);
            return true;
        }
    } else if (keyboardModifiers == Fw::KeyboardCtrlModifier) {
        if (keyCode == Fw::KeyV && getProp(PropEditable)) {
            paste(g_window.getClipboardText());
            return true;
        }
        if (keyCode == Fw::KeyX && getProp(PropEditable) && getProp(PropSelectable)) {
            if (hasSelection()) {
                cut();
                return true;
            }
        } else if (keyCode == Fw::KeyC && getProp(PropSelectable)) {
            if (hasSelection()) {
                copy();
                return true;
            }
        } else if (keyCode == Fw::KeyA && getProp(PropSelectable)) {
            if (m_text.length() > 0) {
                selectAll();
                return true;
            }
        }
    } else if (keyboardModifiers == Fw::KeyboardShiftModifier) {
        if (keyCode == Fw::KeyTab && !getProp(PropShiftNavigation)) {
            if (const auto& parent = getParent())
                parent->focusPreviousChild(Fw::KeyboardFocusReason, true);
            return true;
        }
        if (keyCode == Fw::KeyRight || keyCode == Fw::KeyLeft) {
            const size_t oldCursorPos = m_cursorPos;

            if (keyCode == Fw::KeyRight) // move cursor right
                moveCursorHorizontally(true);
            else if (keyCode == Fw::KeyLeft) // move cursor left
                moveCursorHorizontally(false);

            if (getProp(PropShiftNavigation))
                clearSelection();
            else {
                if (!hasSelection())
                    m_selectionReference = oldCursorPos;
                setSelection(m_selectionReference, m_cursorPos);
            }
            return true;
        }
        if (keyCode == Fw::KeyHome) { // move cursor to first character
            if (m_cursorPos != 0) {
                setSelection(m_cursorPos, 0);
                setCursorPos(0);
                return true;
            }
        } else if (keyCode == Fw::KeyEnd) { // move cursor to last character
            if (m_cursorPos != static_cast<int>(m_text.length())) {
                setSelection(m_cursorPos, m_text.length());
                setCursorPos(m_text.length());
                return true;
            }
        }
    }

    return false;
}

bool UITextEdit::onKeyText(const std::string_view keyText)
{
    if (getProp(PropEditable)) {
        appendText(keyText.data());
        return true;
    }
    return false;
}

bool UITextEdit::onMousePress(const Point& mousePos, Fw::MouseButton button)
{
    if (UIWidget::onMousePress(mousePos, button))
        return true;

    if (button == Fw::MouseLeftButton) {
        const int pos = getTextPos(mousePos);
        if (pos >= 0) {
            setCursorPos(pos);

            if (getProp(PropSelectable)) {
                m_selectionReference = pos;
                setSelection(pos, pos);
            }
        }
        return true;
    }
    return false;
}

bool UITextEdit::onMouseRelease(const Point& mousePos, Fw::MouseButton button)
{
    return UIWidget::onMouseRelease(mousePos, button);
}

bool UITextEdit::onMouseMove(const Point& mousePos, const Point& mouseMoved)
{
    if (UIWidget::onMouseMove(mousePos, mouseMoved))
        return true;

    if (getProp(PropSelectable) && isPressed()) {
        const int pos = getTextPos(mousePos);
        if (pos >= 0) {
            setSelection(m_selectionReference, pos);
            setCursorPos(pos);
        }
        return true;
    }
    return false;
}

bool UITextEdit::onDoubleClick(const Point& mousePos)
{
    if (UIWidget::onDoubleClick(mousePos))
        return true;
    if (getProp(PropSelectable) && m_text.length() > 0) {
        selectAll();
        return true;
    }
    return false;
}

void UITextEdit::onTextAreaUpdate(const Point& offset, const Size& visibleSize, const Size& totalSize)
{
    callLuaField("onTextAreaUpdate", offset, visibleSize, totalSize);
}