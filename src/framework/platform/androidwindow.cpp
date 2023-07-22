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

#include <framework/core/eventdispatcher.h>
#include "androidwindow.h"

AndroidWindow g_androidWindow;

AndroidWindow::AndroidWindow()
{
    m_minimumSize = Size(640, 360);
    m_size = Size(640, 360);
    m_eglDisplay = EGL_NO_DISPLAY;
    m_eglContext = EGL_NO_CONTEXT;
    m_eglSurface = EGL_NO_SURFACE;

    m_keyMap[AKEYCODE_BACK] = Fw::KeyEscape;
    m_keyMap[AKEYCODE_VOLUME_UP] = Fw::KeyF1;
    m_keyMap[AKEYCODE_VOLUME_DOWN] = Fw::KeyF2;
    m_keyMap[AKEYCODE_CAMERA] = Fw::KeyF3;

    m_keyMap[AKEYCODE_ESCAPE] = Fw::KeyEscape;
    m_keyMap[AKEYCODE_TAB] = Fw::KeyTab;
    m_keyMap[AKEYCODE_ENTER] = Fw::KeyEnter;
    m_keyMap[AKEYCODE_DEL] = Fw::KeyBackspace;
    m_keyMap[AKEYCODE_SPACE] = Fw::KeySpace;

    m_keyMap[AKEYCODE_PAGE_UP] = Fw::KeyPageUp;
    m_keyMap[AKEYCODE_PAGE_DOWN] = Fw::KeyPageDown;
    m_keyMap[AKEYCODE_MOVE_HOME] = Fw::KeyHome;
    m_keyMap[AKEYCODE_MOVE_END] = Fw::KeyEnd;
    m_keyMap[AKEYCODE_INSERT] = Fw::KeyInsert;
    m_keyMap[AKEYCODE_FORWARD_DEL] = Fw::KeyDelete;

    m_keyMap[AKEYCODE_DPAD_UP] = Fw::KeyUp;
    m_keyMap[AKEYCODE_DPAD_DOWN] = Fw::KeyDown;
    m_keyMap[AKEYCODE_DPAD_LEFT] = Fw::KeyLeft;
    m_keyMap[AKEYCODE_DPAD_RIGHT] = Fw::KeyRight;

    m_keyMap[AKEYCODE_NUM_LOCK] = Fw::KeyNumLock;
    m_keyMap[AKEYCODE_SCROLL_LOCK] = Fw::KeyScrollLock;
    m_keyMap[AKEYCODE_CAPS_LOCK] = Fw::KeyCapsLock;

    m_keyMap[AKEYCODE_CTRL_LEFT] = Fw::KeyCtrl;
    m_keyMap[AKEYCODE_CTRL_RIGHT] = Fw::KeyCtrl;
    m_keyMap[AKEYCODE_SHIFT_LEFT] = Fw::KeyShift;
    m_keyMap[AKEYCODE_SHIFT_RIGHT] = Fw::KeyShift;
    m_keyMap[AKEYCODE_ALT_LEFT] = Fw::KeyAlt;
    m_keyMap[AKEYCODE_ALT_RIGHT] = Fw::KeyAlt;

    m_keyMap[AKEYCODE_0] = Fw::Key0;
    m_keyMap[AKEYCODE_1] = Fw::Key1;
    m_keyMap[AKEYCODE_2] = Fw::Key2;
    m_keyMap[AKEYCODE_3] = Fw::Key3;
    m_keyMap[AKEYCODE_4] = Fw::Key4;
    m_keyMap[AKEYCODE_5] = Fw::Key5;
    m_keyMap[AKEYCODE_6] = Fw::Key6;
    m_keyMap[AKEYCODE_7] = Fw::Key7;
    m_keyMap[AKEYCODE_8] = Fw::Key8;
    m_keyMap[AKEYCODE_9] = Fw::Key9;

    m_keyMap[AKEYCODE_A] = Fw::KeyA;
    m_keyMap[AKEYCODE_B] = Fw::KeyB;
    m_keyMap[AKEYCODE_C] = Fw::KeyC;
    m_keyMap[AKEYCODE_D] = Fw::KeyD;
    m_keyMap[AKEYCODE_E] = Fw::KeyE;
    m_keyMap[AKEYCODE_F] = Fw::KeyF;
    m_keyMap[AKEYCODE_G] = Fw::KeyG;
    m_keyMap[AKEYCODE_H] = Fw::KeyH;
    m_keyMap[AKEYCODE_I] = Fw::KeyI;
    m_keyMap[AKEYCODE_J] = Fw::KeyJ;
    m_keyMap[AKEYCODE_K] = Fw::KeyK;
    m_keyMap[AKEYCODE_L] = Fw::KeyL;
    m_keyMap[AKEYCODE_M] = Fw::KeyM;
    m_keyMap[AKEYCODE_N] = Fw::KeyN;
    m_keyMap[AKEYCODE_O] = Fw::KeyO;
    m_keyMap[AKEYCODE_P] = Fw::KeyP;
    m_keyMap[AKEYCODE_Q] = Fw::KeyQ;
    m_keyMap[AKEYCODE_R] = Fw::KeyR;
    m_keyMap[AKEYCODE_S] = Fw::KeyS;
    m_keyMap[AKEYCODE_T] = Fw::KeyT;
    m_keyMap[AKEYCODE_U] = Fw::KeyU;
    m_keyMap[AKEYCODE_V] = Fw::KeyV;
    m_keyMap[AKEYCODE_W] = Fw::KeyW;
    m_keyMap[AKEYCODE_X] = Fw::KeyX;
    m_keyMap[AKEYCODE_Y] = Fw::KeyY;
    m_keyMap[AKEYCODE_Z] = Fw::KeyZ;

    m_keyMap[AKEYCODE_SEMICOLON] = Fw::KeySemicolon;
    m_keyMap[AKEYCODE_SLASH] = Fw::KeySlash;
    m_keyMap[AKEYCODE_GRAVE] = Fw::KeyGrave;
    m_keyMap[AKEYCODE_LEFT_BRACKET] = Fw::KeyLeftBracket;
    m_keyMap[AKEYCODE_BACKSLASH] = Fw::KeyBackslash;
    m_keyMap[AKEYCODE_RIGHT_BRACKET] = Fw::KeyRightBracket;
    m_keyMap[AKEYCODE_APOSTROPHE] = Fw::KeyApostrophe;
    m_keyMap[AKEYCODE_MINUS] = Fw::KeyMinus;
    m_keyMap[AKEYCODE_EQUALS] = Fw::KeyEqual;
    m_keyMap[AKEYCODE_COMMA] = Fw::KeyComma;
    m_keyMap[AKEYCODE_PERIOD] = Fw::KeyPeriod;

    m_keyMap[AKEYCODE_F1] = Fw::KeyF1;
    m_keyMap[AKEYCODE_F2] = Fw::KeyF2;
    m_keyMap[AKEYCODE_F3] = Fw::KeyF3;
    m_keyMap[AKEYCODE_F4] = Fw::KeyF4;
    m_keyMap[AKEYCODE_F5] = Fw::KeyF5;
    m_keyMap[AKEYCODE_F6] = Fw::KeyF6;
    m_keyMap[AKEYCODE_F7] = Fw::KeyF7;
    m_keyMap[AKEYCODE_F8] = Fw::KeyF8;
    m_keyMap[AKEYCODE_F9] = Fw::KeyF9;
    m_keyMap[AKEYCODE_F10] = Fw::KeyF10;
    m_keyMap[AKEYCODE_F11] = Fw::KeyF11;
    m_keyMap[AKEYCODE_F12] = Fw::KeyF12;
}

AndroidWindow::~AndroidWindow()
{
    internalDestroyGL();
}


void AndroidWindow::internalInitGL()
{
    const EGLint attribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_BLUE_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_RED_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_NONE
    };
    const EGLint context_attrib_list[] = {
        // request a context using Open GL ES 2.0
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE
    };
    EGLint format;
    EGLint numConfigs;

    bool initDisplay = m_eglDisplay == EGL_NO_DISPLAY;
    if (initDisplay)
        m_eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (m_eglDisplay == EGL_NO_DISPLAY)
        g_logger.fatal("EGL not supported");

    if (initDisplay) {
        if (!eglInitialize(m_eglDisplay, 0, 0))
            g_logger.fatal("Unable to initialize EGL");

        eglChooseConfig(m_eglDisplay, attribs, &m_eglConfig, 1, &numConfigs);
        eglGetConfigAttrib(m_eglDisplay, m_eglConfig, EGL_NATIVE_VISUAL_ID, &format);
        ANativeWindow_setBuffersGeometry(g_androidState->window, 0, 0, format);
    }

    m_eglSurface = eglCreateWindowSurface(m_eglDisplay, m_eglConfig, g_androidState->window, NULL);
    if (m_eglContext == EGL_NO_CONTEXT)
        m_eglContext = eglCreateContext(m_eglDisplay, m_eglConfig, NULL, context_attrib_list);
    if (m_eglContext == EGL_NO_CONTEXT)
        g_logger.fatal(stdext::format("Unable to create EGL context: %i", eglGetError()));
    if (eglMakeCurrent(m_eglDisplay, m_eglSurface, m_eglSurface, m_eglContext) == EGL_FALSE)
        g_logger.fatal(stdext::format("Unable to eglMakeCurrent: %i", eglGetError()));

    updateSize();
}

void AndroidWindow::internalDestroyGL()
{
    if (m_eglDisplay != EGL_NO_DISPLAY) {
        eglMakeCurrent(m_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        //if (m_eglContext != EGL_NO_CONTEXT) {
        //    eglDestroyContext(m_eglDisplay, m_eglContext);
        //}
        if (m_eglSurface != EGL_NO_SURFACE) {
            eglDestroySurface(m_eglDisplay, m_eglSurface);
        }
        //eglTerminate(m_eglDisplay);
    }
    //m_eglDisplay = EGL_NO_DISPLAY;
    //m_eglContext = EGL_NO_CONTEXT;
    m_eglSurface = EGL_NO_SURFACE;
}

void AndroidWindow::internalCheckGL()
{
    m_eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (m_eglDisplay == EGL_NO_DISPLAY)
        g_logger.fatal("EGL not supported");

    if (!eglInitialize(m_eglDisplay, NULL, NULL))
        g_logger.fatal("Unable to initialize EGL");
}

void AndroidWindow::internalChooseGL()
{

}

void AndroidWindow::internalCreateGLContext()
{
    EGLint attrList[] = {
#if OPENGL_ES==2
        EGL_CONTEXT_CLIENT_VERSION, 2,
#else
        EGL_CONTEXT_CLIENT_VERSION, 1,
#endif
        EGL_NONE
    };

    m_eglContext = eglCreateContext(m_eglDisplay, m_eglConfig, EGL_NO_CONTEXT, attrList);
    if (m_eglContext == EGL_NO_CONTEXT)
        g_logger.fatal(stdext::format("Unable to create EGL context: %s", eglGetError()));

    if (!eglMakeCurrent(m_eglDisplay, m_eglSurface, m_eglSurface, m_eglContext))
        g_logger.fatal("Unable to connect EGL context into Android native window");
}

void AndroidWindow::internalDestroyGLContext()
{
    /*
    if (m_window == NULL)
        return;

    if(m_eglDisplay) {
        eglMakeCurrent(m_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

        if (m_eglSurface) {
            eglDestroySurface(m_eglDisplay, m_eglSurface);
            m_eglSurface = EGL_NO_SURFACE;
        }

        if(m_eglContext) {
            eglDestroyContext(m_eglDisplay, m_eglContext);
            m_eglContext = EGL_NO_CONTEXT;
        }

        eglTerminate(m_eglDisplay);
        m_eglDisplay = EGL_NO_DISPLAY;
    } */
}

void AndroidWindow::internalConnectGLContext()
{
    /*
    m_eglSurface = eglCreateWindowSurface(m_eglDisplay, m_eglConfig, m_window, NULL);
    if(m_eglSurface == EGL_NO_SURFACE)
        g_logger.fatal(stdext::format("Unable to create EGL surface: %s", eglGetError())); */
}

void AndroidWindow::terminate()
{
    //nativePause();
}

void AndroidWindow::poll()
{
    int ident;
    int events;
    struct android_poll_source* source;

    // If not animating, we will block forever waiting for events.
    // If animating, we loop until all events are read, then continue
    // to draw the next frame of animation.
    while ((ident = ALooper_pollAll(0, NULL, &events, (void**)&source)) >= 0) {
        // Process this event.
        if (source != NULL) {
            source->process(g_androidState, source);
        }
    }

    g_dispatcher.addEvent(std::bind(&AndroidWindow::fireKeysPress, this));
}

void AndroidWindow::swapBuffers()
{
    eglSwapBuffers(m_eglDisplay, m_eglSurface);
}

void AndroidWindow::setVerticalSync(bool enable)
{
    //eglSwapInterval(m_eglDisplay, enable ? 1 : 0);
}

std::string AndroidWindow::getClipboardText()
{
    // TODO
    return "";
}

void AndroidWindow::setClipboardText(const std::string_view text)
{
    // TODO
}

Size AndroidWindow::getDisplaySize()
{
    return m_size;
}

std::string AndroidWindow::getPlatformType()
{
    return "ANDROID-EGL";
}

void AndroidWindow::init() {}

void AndroidWindow::init(struct android_app* app)
{
    g_androidState = app;
    g_androidState->userData = (void*)this;
    g_androidState->onAppCmd = static_cast<void(*)(android_app*, int32_t)>(+[](android_app* app, int32_t cmd) -> void {
        AndroidWindow* window = (AndroidWindow*)app->userData;
        if (window)
            return window->handleCmd(cmd);
    });
    g_androidState->onInputEvent = static_cast<int32_t(*)(android_app*, AInputEvent*)>(+[](android_app* app, AInputEvent* event) -> int32_t {
        AndroidWindow* window = (AndroidWindow*)app->userData;
        if (window)
            return window->handleInput(event);
        return 0;
    });
}

void AndroidWindow::show() {}

void AndroidWindow::hide() {}

void AndroidWindow::minimize() {}

void AndroidWindow::maximize() {}

void AndroidWindow::move(const Point& pos) {}

void AndroidWindow::resize(const Size& size) {}

void AndroidWindow::showMouse() {}

void AndroidWindow::hideMouse() {}

void AndroidWindow::setMouseCursor(int cursorId) {}

void AndroidWindow::restoreMouseCursor() {}

void AndroidWindow::setTitle(const std::string_view title) {}

void AndroidWindow::setMinimumSize(const Size& minimumSize) {}

void AndroidWindow::setFullscreen(bool fullscreen) {}

void AndroidWindow::setIcon(const std::string& iconFile) {}


void AndroidWindow::handleCmd(int32_t cmd)
{
    switch (cmd) {
    case APP_CMD_SAVE_STATE:
        break;
    case APP_CMD_INIT_WINDOW:
        if (g_androidState->window != NULL) {
            internalInitGL();
        }
        releaseAllKeys();
        break;
    case APP_CMD_TERM_WINDOW:
        m_visible = false;
        internalDestroyGL();
        releaseAllKeys();
        break;
    case APP_CMD_GAINED_FOCUS:
        m_visible = (m_eglContext != EGL_NO_CONTEXT);
        releaseAllKeys();
        break;
    case APP_CMD_LOST_FOCUS:
        //m_visible = false;
        releaseAllKeys();
        break;
    case APP_CMD_PAUSE:
    case APP_CMD_STOP:
        m_visible = false;
        releaseAllKeys();
        break;
    case APP_CMD_DESTROY:
        if (m_onClose)
            m_onClose();
        break;
    }
    updateSize();
}

int AndroidWindow::handleInput(AInputEvent* event)
{
    int32_t eventType = AInputEvent_getType(event);
    int32_t action = AKeyEvent_getAction(event);
    int32_t key_val = eventType == AINPUT_EVENT_TYPE_KEY ? AKeyEvent_getKeyCode(event) : 0;
    int pointerId = 0;
    Point mousePos;
    if (eventType == AINPUT_EVENT_TYPE_MOTION) {
        pointerId = (action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
        mousePos = Point(AMotionEvent_getX(event, pointerId), AMotionEvent_getY(event, pointerId));
    }

    Fw::Key key = Fw::KeyUnknown;
    static Point touchStartPos(0, 0);
    int dist = std::max<int>(std::abs(touchStartPos.x - mousePos.x), std::abs(touchStartPos.y - mousePos.y));
    g_dispatcher.addEvent([&, eventType, action, key_val, pointerId, mousePos] {
        if (!m_onInputEvent) return;
        static ticks_t lastPress = 0;
        static bool pressed = false;
        if (eventType == AINPUT_EVENT_TYPE_MOTION) {
            static int actionType = action & AMOTION_EVENT_ACTION_MASK;
            if (pointerId == 1 || pointerId == 2) { // multitouch
                if (actionType == AMOTION_EVENT_ACTION_POINTER_DOWN) {
                    m_multiInputEvent[pointerId].reset(Fw::MousePressInputEvent);
                    m_multiInputEvent[pointerId].mousePos = mousePos;
                    m_multiInputEvent[pointerId].mouseButton = pointerId == 1 ? Fw::MouseTouch2 : Fw::MouseTouch3;
                    m_mouseButtonStates = m_multiInputEvent[pointerId].mouseButton;
                    m_onInputEvent(m_multiInputEvent[pointerId]);
                } else if (actionType == AMOTION_EVENT_ACTION_POINTER_UP) {
                    m_multiInputEvent[pointerId].reset(Fw::MouseReleaseInputEvent);
                    m_multiInputEvent[pointerId].mousePos = mousePos;
                    m_multiInputEvent[pointerId].mouseButton = pointerId == 1 ? Fw::MouseTouch2 : Fw::MouseTouch3;
                    m_mouseButtonStates = 0;
                    m_onInputEvent(m_multiInputEvent[pointerId]);
                }
                return;
            }

            m_inputEvent.reset(Fw::MouseMoveInputEvent);
            m_inputEvent.mouseMoved = mousePos - m_inputEvent.mousePos;
            m_inputEvent.mousePos = mousePos;
            m_onInputEvent(m_inputEvent);

            if (actionType == AMOTION_EVENT_ACTION_DOWN) {
                lastPress = g_clock.millis();
                m_inputEvent.reset(Fw::MousePressInputEvent);
                m_inputEvent.mouseButton = Fw::MouseTouch;
                m_mouseButtonStates = m_multiInputEvent[pointerId].mouseButton;
                m_onInputEvent(m_inputEvent);
                touchStartPos = mousePos;
            } else if (actionType == AMOTION_EVENT_ACTION_UP || actionType == AMOTION_EVENT_ACTION_POINTER_UP) {
                m_inputEvent.reset(Fw::MouseReleaseInputEvent);
                m_inputEvent.mouseButton = Fw::MouseTouch;
                m_mouseButtonStates = 0;
                m_onInputEvent(m_inputEvent);
                if (pointerId == 0) {
                    if (!pressed) {
                        if (lastPress + 500 < stdext::millis()) {
                            m_inputEvent.reset(Fw::MousePressInputEvent);
                            m_inputEvent.mouseButton = Fw::MouseRightButton;
                            m_onInputEvent(m_inputEvent);

                            m_inputEvent.reset(Fw::MouseReleaseInputEvent);
                            m_inputEvent.mouseButton = Fw::MouseRightButton;
                            m_onInputEvent(m_inputEvent);
                        } else {
                            lastPress = stdext::millis();
                            m_inputEvent.reset(Fw::MousePressInputEvent);
                            m_inputEvent.mouseButton = Fw::MouseLeftButton;
                            m_onInputEvent(m_inputEvent);

                            m_inputEvent.reset(Fw::MouseReleaseInputEvent);
                            m_inputEvent.mouseButton = Fw::MouseLeftButton;
                            m_onInputEvent(m_inputEvent);
                        }
                    } else {
                        pressed = false;
                        m_inputEvent.reset(Fw::MouseReleaseInputEvent);
                        m_inputEvent.mouseButton = Fw::MouseLeftButton;
                        m_mouseButtonStates = 0;
                        m_onInputEvent(m_inputEvent);
                    }
                }
            } else if (actionType == AMOTION_EVENT_ACTION_MOVE) {
                if (!pressed && dist > 8) {
                    pressed = true;
                    m_inputEvent.reset(Fw::MouseMoveInputEvent);
                    m_inputEvent.mouseMoved = touchStartPos - m_inputEvent.mousePos;
                    m_inputEvent.mousePos = touchStartPos;
                    m_onInputEvent(m_inputEvent);

                    m_inputEvent.reset(Fw::MousePressInputEvent);
                    m_inputEvent.mouseButton = Fw::MouseLeftButton;
                    m_mouseButtonStates = 0;
                    m_onInputEvent(m_inputEvent);
                }
            }
        } else if (eventType == AINPUT_EVENT_TYPE_KEY) {
            if (m_keyMap.find(key_val) != m_keyMap.end())
                key = m_keyMap[key_val];
            if (action == AKEY_EVENT_ACTION_DOWN) {
                processKeyDown(key);
            } else if (action == AKEY_EVENT_ACTION_UP) {
                processKeyUp(key);
            }
        }
    });
    if (eventType == AINPUT_EVENT_TYPE_MOTION) {
        return 1;
    } else if (eventType == AINPUT_EVENT_TYPE_KEY) {
        Fw::Key key = Fw::KeyUnknown;
        if (m_keyMap.find(key_val) != m_keyMap.end())
            key = m_keyMap[key_val];
        return key != Fw::KeyUnknown ? 1 : 0;
    }
    return 0;
}

void AndroidWindow::updateSize()
{
    if (m_eglDisplay == EGL_NO_DISPLAY || m_eglSurface == EGL_NO_SURFACE) return;
    EGLint w, h;
    eglQuerySurface(m_eglDisplay, m_eglSurface, EGL_WIDTH, &w);
    eglQuerySurface(m_eglDisplay, m_eglSurface, EGL_HEIGHT, &h);
    Size new_size(w, h);
    if (new_size == m_size) return;
    m_size = new_size;
    if (m_onResize)
        m_onResize(new_size);
}


void AndroidWindow::handleTextInput(std::string text)
{
    if (!m_onInputEvent) return;
    g_dispatcher.addEvent([&, text] {
        if (!m_onInputEvent) return;
        m_inputEvent.reset(Fw::KeyTextInputEvent);
        m_inputEvent.keyText = text;
        m_onInputEvent(m_inputEvent);
    });
}

void AndroidWindow::showTextEditor(const std::string& title, const std::string& description, const std::string& text, int flags)
{
    g_dispatcher.addEvent([&, title, description, text, flags] {
        JNIEnv* env = getJNIEnv();
        JavaVMAttachArgs javaVMAttachArgs;
        javaVMAttachArgs.version = JNI_VERSION_1_6;
        javaVMAttachArgs.name = "NativeThread";
        javaVMAttachArgs.group = NULL;

        jint nResult = g_androidState->activity->vm->AttachCurrentThread(&env, &javaVMAttachArgs);
        if (nResult != JNI_ERR) {
            jmethodID MethodShowKeyboard = env->GetMethodID(env->GetObjectClass(g_androidState->activity->clazz), "showTextEdit", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)V");
            env->CallVoidMethod(g_androidState->activity->clazz, MethodShowKeyboard, env->NewStringUTF(title.c_str()), env->NewStringUTF(description.c_str()), env->NewStringUTF(text.c_str()), flags);
            g_androidState->activity->vm->DetachCurrentThread();
        }
    });
}

void AndroidWindow::displayFatalError(const std::string_view message)
{
    JNIEnv* env = getJNIEnv();
    JavaVM* vm = getJavaVM();
    jint nResult = vm->AttachCurrentThread(&env, NULL);
    if (nResult != JNI_ERR) {
        jclass clazz = env->GetObjectClass(getClazz());
        jmethodID methodID = env->GetMethodID(clazz, "displayFatalError", "(Ljava/lang/String;)V");
        jstring jmessage = env->NewStringUTF(message.data());
        env->CallVoidMethod(getClazz(), methodID, jmessage);
        env->DeleteLocalRef(jmessage);
        vm->DetachCurrentThread();
    }
}

void AndroidWindow::openUrl(std::string url)
{
    JNIEnv* env = getJNIEnv();
    JavaVM* vm = getJavaVM();
    jint nResult = vm->AttachCurrentThread(&env, NULL);
    if (nResult != JNI_ERR) {
        jclass clazz = env->GetObjectClass(getClazz());
        jmethodID methodID = env->GetMethodID(clazz, "openUrl", "(Ljava/lang/String;)V");
        jstring jmessage = env->NewStringUTF(url.c_str());
        env->CallVoidMethod(getClazz(), methodID, jmessage);
        env->DeleteLocalRef(jmessage);
        vm->DetachCurrentThread();
    }
}

extern "C"
{
    JNIEXPORT void JNICALL Java_com_otclientv8_OTClientV8_commitText(
        JNIEnv* env, jobject obj, jstring text)
    {
        const char* newChar = env->GetStringUTFChars(text, NULL);
        std::string newText = newChar;
        env->ReleaseStringUTFChars(text, newChar);
        g_dispatcher.addEvent([newText] {
            g_window.handleTextInput(newText);
        });
    }
}

