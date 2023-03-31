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

#ifdef ANDROID

#include "androidwindow.h"
#include "androidmanager.h"
#include <game-activity/native_app_glue/android_native_app_glue.h>
#include <framework/core/eventdispatcher.h>

AndroidWindow& g_androidWindow = (AndroidWindow&) g_window;

AndroidWindow::AndroidWindow() {
    m_minimumSize = Size(600, 480);
    m_size = Size(600, 480);

    m_keyMap[AndroidWindow::KEY_ENTER] = Fw::KeyEnter;
    m_keyMap[AndroidWindow::KEY_BACKSPACE] = Fw::KeyBackspace;
}

AndroidWindow::~AndroidWindow() {
    internalDestroyGLContext();
}

AndroidWindow::KeyCode AndroidWindow::NativeEvent::getKeyCodeFromInt(int keyCode) {
    switch (keyCode) {
        case 66:
            return KEY_ENTER;
        case 67:
            return KEY_BACKSPACE;
        default:
            return KEY_UNDEFINED;
    }
}

AndroidWindow::EventType AndroidWindow::NativeEvent::getEventTypeFromInt(int actionType) {
    switch (actionType) {
        case 0:
            return TOUCH_DOWN;
        case 1:
            return TOUCH_UP;
        case 2:
            return TOUCH_MOTION;
        case 3:
            return TOUCH_LONGPRESS;
        default:
            return EVENT_UNDEFINED;
    }
}

void AndroidWindow::internalInitGL() {
    internalCheckGL();
    internalChooseGL();
    internalCreateGLSurface();
    internalCreateGLContext();
}

void AndroidWindow::internalCheckGL() {
    if (m_eglDisplay != EGL_NO_DISPLAY) {
        return;
    }

    m_eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if(m_eglDisplay == EGL_NO_DISPLAY)
        g_logger.fatal("EGL not supported");

    if(!eglInitialize(m_eglDisplay, NULL, NULL))
        g_logger.fatal("Unable to initialize EGL");
}

void AndroidWindow::internalChooseGL() {
    static int attrList[] = {
#if OPENGL_ES==2
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
#else
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES_BIT,
#endif
        EGL_RED_SIZE, 4,
        EGL_GREEN_SIZE, 4,
        EGL_BLUE_SIZE, 4,
        EGL_ALPHA_SIZE, 4,
        EGL_NONE
    };

    EGLint numConfig;

    if(!eglChooseConfig(m_eglDisplay, attrList, &m_eglConfig, 1, &numConfig))
        g_logger.fatal("Failed to choose EGL config");

    if(numConfig != 1)
        g_logger.warning("Didn't got the exact EGL config");

    EGLint vid;
    if(!eglGetConfigAttrib(m_eglDisplay, m_eglConfig, EGL_NATIVE_VISUAL_ID, &vid))
        g_logger.fatal("Unable to get visual EGL visual id");
}

void AndroidWindow::internalCreateGLContext() {
    if (m_eglContext != EGL_NO_CONTEXT) {
        return;
    }

    EGLint attrList[] = {
#if OPENGL_ES==2
        EGL_CONTEXT_CLIENT_VERSION, 2,
#else
        EGL_CONTEXT_CLIENT_VERSION, 1,
#endif
        EGL_NONE
    };

    m_eglContext = eglCreateContext(m_eglDisplay, m_eglConfig, EGL_NO_CONTEXT, attrList);
    if(m_eglContext == EGL_NO_CONTEXT )
        g_logger.fatal(stdext::format("Unable to create EGL context: %s", eglGetError()));

    internalConnectSurface();
}

void AndroidWindow::internalConnectSurface() {
    if (!eglMakeCurrent(m_eglDisplay, m_eglSurface, m_eglSurface, m_eglContext))
        g_logger.fatal("Unable to connect EGL context into Android native window");
}

void AndroidWindow::internalDestroyGLContext() {
    if(m_eglDisplay) {
        eglMakeCurrent(m_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

        internalDestroySurface();

        if(m_eglContext) {
            eglDestroyContext(m_eglDisplay, m_eglContext);
            m_eglContext = EGL_NO_CONTEXT;
        }

        eglTerminate(m_eglDisplay);
        m_eglDisplay = EGL_NO_DISPLAY;
    }
}

void AndroidWindow::internalDestroySurface() {
    if (m_eglSurface) {
        eglDestroySurface(m_eglDisplay, m_eglSurface);
        m_eglSurface = EGL_NO_SURFACE;
    }
}

void AndroidWindow::internalCreateGLSurface() {
    if (m_eglSurface != EGL_NO_SURFACE) {
        return;
    }

    m_eglSurface = eglCreateWindowSurface(m_eglDisplay, m_eglConfig, m_app->window, NULL);
    if(m_eglSurface == EGL_NO_SURFACE)
        g_logger.fatal(stdext::format("Unable to create EGL surface: %s", eglGetError()));
}

void AndroidWindow::queryGlSize() {
    int width, height;
    if (EGL_FALSE == eglQuerySurface(m_eglDisplay, m_eglSurface, EGL_WIDTH, &width) ||
        EGL_FALSE ==  eglQuerySurface(m_eglDisplay, m_eglSurface, EGL_HEIGHT, &height)) {
        g_logger.fatal("Unable to query surface to get width and height");
    }
    m_size = Size(width, height);
}

void AndroidWindow::terminate() {
    m_visible = false;
    internalDestroyGLContext();
}

void AndroidWindow::poll() {
    handleNativeEvents();

    while( !m_events.empty() ) {
        m_currentEvent = m_events.front();

        switch( m_currentEvent.type ) {
            case TEXTINPUT:
                processTextInput();
                break;
            case TOUCH_DOWN:
            case TOUCH_LONGPRESS:
            case TOUCH_UP:
                processFingerDownAndUp();
                break;
            case TOUCH_MOTION:
                processFingerMotion();
            case KEY_DOWN:
            case KEY_UP:
            case EVENT_UNDEFINED:
                processKeyDownOrUp();
                break;
        }

        m_events.pop();
    }

    fireKeysPress();
}

void AndroidWindow::processKeyDownOrUp() {
    if(m_currentEvent.type == KEY_DOWN || m_currentEvent.type == KEY_UP) {
        Fw::Key keyCode = Fw::KeyUnknown;
        KeyCode key = m_currentEvent.keyCode;

        if(m_keyMap.find(key) != m_keyMap.end())
            keyCode = m_keyMap[key];

        if(m_currentEvent.type == KEY_DOWN)
            processKeyDown(keyCode);
        else if(m_currentEvent.type == KEY_UP)
            processKeyUp(keyCode);
    }
}

void AndroidWindow::processTextInput() {
    std::string text = m_currentEvent.text;
    KeyCode keyCode = m_currentEvent.keyCode;

    if(text.length() == 0 || keyCode == KEY_ENTER || keyCode == KEY_BACKSPACE)
        return;

    if(m_onInputEvent) {
        m_inputEvent.reset(Fw::KeyTextInputEvent);
        m_inputEvent.keyText = text;
        m_onInputEvent(m_inputEvent);
    }
}

void AndroidWindow::processFingerDownAndUp() {
    bool isTouchdown = m_currentEvent.type == TOUCH_DOWN;
    Fw::MouseButton mouseButton = (m_currentEvent.type == TOUCH_LONGPRESS) ?
        Fw::MouseRightButton : Fw::MouseLeftButton;

    m_inputEvent.reset();
    m_inputEvent.type = (isTouchdown) ? Fw::MousePressInputEvent : Fw::MouseReleaseInputEvent;
    m_inputEvent.mouseButton = mouseButton;
	if(isTouchdown) {
		m_mouseButtonStates |= 1 << mouseButton;
	} else {
		g_dispatcher.addEvent([this, mouseButton] { m_mouseButtonStates &= ~(1 << mouseButton); });
	}

    handleInputEvent();
}

void AndroidWindow::processFingerMotion() {
    m_inputEvent.reset();
    m_inputEvent.type = Fw::MouseMoveInputEvent;

    handleInputEvent();
}

void AndroidWindow::handleInputEvent() {
    Point newMousePos(m_currentEvent.x / m_displayDensity, m_currentEvent.y / m_displayDensity);
    m_inputEvent.mouseMoved = newMousePos - m_inputEvent.mousePos;
    m_inputEvent.mousePos = newMousePos;

    if (m_onInputEvent)
        m_onInputEvent(m_inputEvent);
}

void AndroidWindow::swapBuffers() {
    eglSwapBuffers(m_eglDisplay, m_eglSurface);
}

void AndroidWindow::setVerticalSync(bool enable) {
    eglSwapInterval(m_eglDisplay, enable ? 1 : 0);
}

std::string AndroidWindow::getClipboardText() {
    // TODO
    return "";
}

void AndroidWindow::setClipboardText(const std::string_view text) {
    // TODO
}

Size AndroidWindow::getDisplaySize() {
    return m_size;
}

std::string AndroidWindow::getPlatformType() {
    return "ANDROID-EGL";
}

/* Does not apply to Android */
void AndroidWindow::init() {}

void AndroidWindow::show() {}

void AndroidWindow::hide() {}

void AndroidWindow::maximize() {}

void AndroidWindow::move(const Point& pos) {}

void AndroidWindow::resize(const Size& size) {}

void AndroidWindow::showMouse() {}

void AndroidWindow::hideMouse() {}

int AndroidWindow::internalLoadMouseCursor(const ImagePtr& image, const Point& hotSpot) { return 0; }

void AndroidWindow::setMouseCursor(int cursorId) {}

void AndroidWindow::restoreMouseCursor() {}

void AndroidWindow::setTitle(const std::string_view title) {}

void AndroidWindow::setMinimumSize(const Size& minimumSize) {}

void AndroidWindow::setFullscreen(bool fullscreen) {}

void AndroidWindow::setIcon(const std::string& iconFile) {}

/* Android specific thngs */
void AndroidWindow::initializeAndroidApp(android_app* app) {
    m_app = app;
    m_app->userData = this;
    m_app->onAppCmd = [](struct android_app * app, int32_t cmd) {
        auto *engine = (AndroidWindow*) app->userData;
        engine->handleCmd(cmd);
    };

    android_app_set_key_event_filter(m_app, NULL);
    android_app_set_motion_event_filter(m_app, NULL);
}

void AndroidWindow::onNativeTouch(int actionType,
                                  uint32_t pointerIndex,
                                  GameActivityMotionEvent* motionEvent) {
    float x = GameActivityPointerAxes_getX(&motionEvent->pointers[pointerIndex]);
    float y = GameActivityPointerAxes_getY(&motionEvent->pointers[pointerIndex]);

    EventType type = NativeEvent::getEventTypeFromInt(actionType);

    m_events.push(NativeEvent(type, x, y));
}

void AndroidWindow::onNativeKeyDown( int keyCode ) {
    KeyCode key = NativeEvent::getKeyCodeFromInt(keyCode);

    m_events.push(NativeEvent(KEY_DOWN, key));
}

void AndroidWindow::onNativeKeyUp( int keyCode ) {
    KeyCode key = NativeEvent::getKeyCodeFromInt(keyCode);

    m_events.push(NativeEvent(KEY_UP, key));
}

void AndroidWindow::nativeCommitText(jstring jString) {
    std::string text = g_androidManager.getStringFromJString(jString);
    m_events.push(NativeEvent(TEXTINPUT, text));
}

void AndroidWindow::handleNativeEvents() {
    int events;
    struct android_poll_source* source;

    // If not visible, block until we get an event; if visible, don't block.
    while ((ALooper_pollAll(m_visible ? 0 : -1, NULL, &events, (void **) &source)) >= 0) {
        if (source != NULL) {
            source->process(m_app, source);
        }

        if (m_app->destroyRequested) {
            internalDestroySurface();
            return;
        }
    }

    processNativeInputEvents();
}

void AndroidWindow::handleCmd(int32_t cmd) {
    switch (cmd) {
        case APP_CMD_INIT_WINDOW:
            if (m_app->window != nullptr) {
                if (m_eglContext) {
                    internalCreateGLSurface();
                    internalConnectSurface();
                } else {
                    internalInitGL();
                }
                m_displayDensity = g_androidManager.getScreenDensity();
                m_visible = true;
            } else {
                m_visible = false;
            }
            break;
        case APP_CMD_LOW_MEMORY:
        case APP_CMD_TERM_WINDOW:
            m_visible = false;
            internalDestroySurface();
            break;
        case APP_CMD_WINDOW_RESIZED:
        case APP_CMD_CONFIG_CHANGED:
            queryGlSize();
            break;
        default:
            break;
    }
}

void AndroidWindow::processNativeInputEvents() {
    android_input_buffer* inputBuffer = android_app_swap_input_buffers(m_app);

    if (inputBuffer == nullptr) return;

    if (inputBuffer->motionEventsCount != 0) {
        for (uint64_t i = 0; i < inputBuffer->motionEventsCount; ++i) {
            auto* motionEvent = &inputBuffer->motionEvents[i];
            const int action = motionEvent->action;
            const int actionMasked = action & AMOTION_EVENT_ACTION_MASK;
            uint32_t pointerIndex = GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT;

            switch (actionMasked) {
                case AMOTION_EVENT_ACTION_UP:
                case AMOTION_EVENT_ACTION_DOWN:
                    pointerIndex = 0;
                    break;
                case AMOTION_EVENT_ACTION_POINTER_UP:
                case AMOTION_EVENT_ACTION_POINTER_DOWN:
                    pointerIndex = ((action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK)
                            >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT);
                    break;
                case AMOTION_EVENT_ACTION_MOVE: {
                    for (uint32_t innerPointerIndex = 0; innerPointerIndex < motionEvent->pointerCount; innerPointerIndex++) {
                        onNativeTouch(actionMasked, innerPointerIndex, motionEvent);
                    }
                    break;
                }
                default:
                    break;
            }

            if (pointerIndex != GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT) {
                onNativeTouch(actionMasked, pointerIndex, motionEvent);
            }
        }
        android_app_clear_motion_events(inputBuffer);
    }
}

extern "C" {
void Java_com_otclient_NativeInputConnection_nativeCommitText(
        JNIEnv* env, jobject obj, jstring text) {
    ((AndroidWindow&) g_window).nativeCommitText(text);
}

void Java_com_otclient_FakeEditText_onNativeKeyDown(
        JNIEnv* env, jobject obj, jint keyCode ) {
    ((AndroidWindow&) g_window).onNativeKeyDown(keyCode);
}

void Java_com_otclient_FakeEditText_onNativeKeyUp(
        JNIEnv* env, jobject obj, jint keyCode ) {
    ((AndroidWindow&) g_window).onNativeKeyUp(keyCode);
}
}

#endif // ANDROID
