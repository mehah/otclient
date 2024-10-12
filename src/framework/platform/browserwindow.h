/*
 * Copyright (c) 2010-2014 OTClient <https://github.com/edubart/otclient>
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

#ifdef __EMSCRIPTEN__

#include "platformwindow.h"
#include <emscripten/emscripten.h>
#include <emscripten/html5.h>
#include <emscripten/websocket.h>

class BrowserWindow : public PlatformWindow
{
    void internalInitGL();


public:
    BrowserWindow();

    void init() override;
    void terminate() override;

    void move(const Point& pos) override;
    void resize(const Size& size) override;
    void show() override;
    void hide() override;
    void maximize() override;
    void poll() override;
    void swapBuffers() override;
    void showMouse() override;
    void hideMouse() override;

    void setMouseCursor(int cursorId) override;
    void restoreMouseCursor() override;
    int loadMouseCursor(const std::string& file, const Point& hotSpot) override;

    void setTitle(const std::string_view title) override;
    void setMinimumSize(const Size& minimumSize) override;
    void setFullscreen(bool fullscreen) override;
    void setVerticalSync(bool enable) override;
    void setIcon(const std::string& iconFile) override;
    void setClipboardText(const std::string_view text) override;
    void setRunning(bool running) { m_running = running; }

    void handleResizeCallback(const EmscriptenUiEvent* event);
    void handleMouseCallback(int eventType, const EmscriptenMouseEvent* event);
    void handleMouseWheelCallback(const EmscriptenWheelEvent* event);
    void handleMouseMotionCallback(const EmscriptenMouseEvent* event);
    void handleKeyboardCallback(int eventType, const EmscriptenKeyboardEvent* event);
    void handleFocusCallback(int eventType, const EmscriptenFocusEvent* event);
    void handleTouchCallback(int eventType, const EmscriptenTouchEvent* event);
    void updateTouchPosition(const EmscriptenTouchEvent* event);
    void processLongTouch(const EmscriptenTouchEvent* event);

    Size getDisplaySize() override;
    std::string getClipboardText() override;
    std::string getPlatformType() override;

protected:
    int internalLoadMouseCursor(const ImagePtr& image, const Point& hotSpot) override;
private:
    bool m_running;
    Timer m_clickTimer;
    bool m_usingTouch = false;
    std::vector<std::pair<char const*, Fw::Key>> web_keymap;
    std::string m_clipboardText;
    std::vector<std::string> m_cursors;
};

extern BrowserWindow& g_browserWindow;

#endif
