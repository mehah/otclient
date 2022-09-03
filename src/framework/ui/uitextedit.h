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

#pragma once

#include "uiwidget.h"

 // @bindclass
class UITextEdit : public UIWidget
{
public:
    UITextEdit();

    void drawSelf(Fw::DrawPane drawPane) override;

private:
    void update(bool focusCursor = false);

public:
    void setCursorPos(int pos);
    void setSelection(int start, int end);
    void setCursorVisible(bool enable) { m_cursorVisible = enable; }
    void setChangeCursorImage(bool enable) { m_changeCursorImage = enable; }
    void setTextHidden(bool hidden);
    void setValidCharacters(const std::string_view validCharacters) { m_validCharacters = validCharacters; }
    void setShiftNavigation(bool enable) { m_shiftNavigation = enable; }
    void setMultiline(bool enable) { m_multiline = enable; }
    void setMaxLength(uint32_t maxLength) { m_maxLength = maxLength; }
    void setTextVirtualOffset(const Point& offset);
    void setEditable(bool editable) { m_editable = editable; }
    void setSelectable(bool selectable) { m_selectable = selectable; }
    void setSelectionColor(const Color& color) { m_selectionColor = color; }
    void setSelectionBackgroundColor(const Color& color) { m_selectionBackgroundColor = color; }
    void setAutoScroll(bool autoScroll) { m_autoScroll = autoScroll; }

    void moveCursorHorizontally(bool right);
    void moveCursorVertically(bool up);
    void appendText(const std::string_view text);
    void appendCharacter(char c);
    void removeCharacter(bool right);
    void blinkCursor();

    void del(bool right = false);
    void paste(const std::string_view text);
    std::string copy();
    std::string cut();
    void selectAll() { setSelection(0, m_text.length()); }
    void clearSelection() { setSelection(0, 0); }

    void wrapText();
    std::string getDisplayedText() { return m_displayedText; }
    std::string getSelection();
    int getTextPos(const Point& pos);
    int getCursorPos() { return m_cursorPos; }
    Point getTextVirtualOffset() { return m_textVirtualOffset; }
    Size getTextVirtualSize() { return m_textVirtualSize; }
    Size getTextTotalSize() { return m_textTotalSize; }
    uint32_t getMaxLength() { return m_maxLength; }
    int getSelectionStart() { return m_selectionStart; }
    int getSelectionEnd() { return m_selectionEnd; }
    Color getSelectionColor() { return m_selectionColor; }
    Color getSelectionBackgroundColor() { return m_selectionBackgroundColor; }
    bool hasSelection() { return m_selectionEnd - m_selectionStart > 0; }
    bool isCursorVisible() { return m_cursorVisible; }
    bool isChangingCursorImage() { return m_changeCursorImage; }
    bool isTextHidden() { return m_textHidden; }
    bool isShiftNavigation() { return m_shiftNavigation; }
    bool isMultiline() { return m_multiline; }
    bool isEditable() { return m_editable; }
    bool isSelectable() { return m_selectable; }
    bool isAutoScrolling() { return m_autoScroll; }

protected:
    void updateText() override;

    void onHoverChange(bool hovered) override;
    void onStyleApply(const std::string_view styleName, const OTMLNodePtr& styleNode) override;
    void onGeometryChange(const Rect& oldRect, const Rect& newRect) override;
    void onFocusChange(bool focused, Fw::FocusReason reason) override;
    bool onKeyText(const std::string_view keyText) override;
    bool onKeyPress(uint8_t keyCode, int keyboardModifiers, int autoRepeatTicks) override;
    bool onMousePress(const Point& mousePos, Fw::MouseButton button) override;
    bool onMouseRelease(const Point& mousePos, Fw::MouseButton button) override;
    bool onMouseMove(const Point& mousePos, const Point& mouseMoved) override;
    bool onDoubleClick(const Point& mousePos) override;
    virtual void onTextAreaUpdate(const Point& vitualOffset, const Size& visibleSize, const Size& totalSize);

private:
    void updateDisplayedText();
    void disableUpdates() { m_updatesEnabled = false; }
    void enableUpdates() { m_updatesEnabled = true; }
    void recacheGlyphs() { m_glyphsMustRecache = true; }

    std::string m_validCharacters;
    uint32_t m_maxLength;

    Rect m_drawArea;
    Point m_textVirtualOffset;
    Size m_textVirtualSize;
    Size m_textTotalSize;
    ticks_t m_cursorTicks;

    bool m_textHidden;
    bool m_shiftNavigation;
    bool m_multiline;
    bool m_cursorInRange;
    bool m_cursorVisible;
    bool m_editable;
    bool m_changeCursorImage;
    bool m_updatesEnabled;
    bool m_autoScroll;

    bool m_selectable;

    int m_selectionReference;
    int m_selectionStart;
    int m_selectionEnd;
    int m_cursorPos{ 0 };

    Color m_selectionColor;
    Color m_selectionBackgroundColor;

    std::vector<Rect> m_glyphsCoords;
    std::vector<Rect> m_glyphsTexCoords;

    std::vector<std::pair<Rect, Rect>> m_glyphsTextRectCache;
    std::vector<std::pair<Rect, Rect>> m_glyphsSelectRectCache;

    std::string m_displayedText;

    bool m_glyphsMustRecache;
};
