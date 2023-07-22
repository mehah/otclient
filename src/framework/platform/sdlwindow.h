#ifndef ANDROID_WINDOW_H
#define ANDROID_WINDOW_H

#include "platformwindow.h"

class SDLWindow : public PlatformWindow {
    enum EventType {
        TOUCH_DOWN,
        TOUCH_UP,
        TOUCH_MOTION,
        TOUCH_LONGPRESS,
        KEY_DOWN,
        KEY_UP,
        TEXTINPUT,
        EVENT_UNDEFINED
    };

    enum NativeMessage {
        RECREATE_CONTEXT,
        APP_TERMINATE
    };

    void internalInitGL();
    void internalDestroyGL();

    void internalCheckGL();
    void internalChooseGL();
    void internalCreateGLContext();
    void internalDestroyGLContext();
    void internalConnectGLContext();


public:
    SDLWindow();
    ~SDLWindow();

    void init();
    void terminate();
    void move(const Point& pos);
    void resize(const Size& size);
    void show();
    void hide();
    void minimize();
    void maximize();
    void poll();
    void swapBuffers();
    void showMouse();
    void hideMouse();

    void setMouseCursor(int cursorId);
    void restoreMouseCursor();

    void setTitle(const std::string& title);
    void setMinimumSize(const Size& minimumSize);
    void setFullscreen(bool fullscreen);
    void setVerticalSync(bool enable);
    void setIcon(const std::string& iconFile);
    void setClipboardText(const std::string& text);

    Size getDisplaySize();
    std::string getClipboardText();
    std::string getPlatformType();

    void displayFatalError(const std::string& message) override;
    void showTextEditor(const std::string& title, const std::string& description, const std::string& text, int flags) override;

    void updateSize();
    void handleTextInput(std::string text);
    void openUrl(std::string url);

protected:
    int internalLoadMouseCursor(const ImagePtr& image, const Point& hotSpot) override { return -1; };

private:
    EGLConfig m_eglConfig;
    EGLContext m_eglContext;
    EGLDisplay m_eglDisplay;
    EGLSurface m_eglSurface;
    InputEvent m_multiInputEvent[3];
};

#endif