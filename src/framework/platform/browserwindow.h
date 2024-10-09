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
#include <queue>

class BrowserWindow : public PlatformWindow
{
    void internalInitGL();


public:
    BrowserWindow();

    void init();
    void terminate();

    void move(const Point& pos);
    void resize(const Size& size);
    void show();
    void hide();
    void maximize();
    void poll();
    void swapBuffers();
    void showMouse();
    void hideMouse();

    void setMouseCursor(int cursorId);
    void restoreMouseCursor();
    int loadMouseCursor(const std::string& file, const Point& hotSpot) override;

    void setTitle(const std::string_view title);
    void setMinimumSize(const Size& minimumSize);
    void setFullscreen(bool fullscreen);
    void setVerticalSync(bool enable);
    void setIcon(const std::string& iconFile);
    void setClipboardText(const std::string_view text);
    void setRunning(bool running) { m_running = running; }

    void handleResizeCallback(const EmscriptenUiEvent* event);
    void handleMouseCallback(int eventType, const EmscriptenMouseEvent* event);
    void handleMouseWheelCallback(const EmscriptenWheelEvent* event);
    void handleMouseMotionCallback(const EmscriptenMouseEvent* event);
    void handleKeyboardCallback(int eventType, const EmscriptenKeyboardEvent* event);
    void handleFocusCallback(int eventType, const EmscriptenFocusEvent* event);

    Size getDisplaySize();
    std::string getClipboardText();
    std::string getPlatformType();

protected:
    int internalLoadMouseCursor(const ImagePtr& image, const Point& hotSpot);
private:
    bool m_running;
    std::vector<std::pair<char const*, Fw::Key>> web_keymap;
    std::string m_clipboardText;
    std::vector<std::string> m_cursors;
};

extern BrowserWindow& g_browserWindow;

#endif
