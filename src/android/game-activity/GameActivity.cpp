/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "GameActivity.h"

#include <android/api-level.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android/log.h>
#include <android/looper.h>
#include <android/native_window.h>
#include <android/native_window_jni.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <jni.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/system_properties.h>
#include <sys/types.h>
#include <unistd.h>

#include <memory>
#include <mutex>
#include <string>

#include "GameActivityLog.h"

namespace {

struct OwnedGameTextInputState {
    OwnedGameTextInputState &operator=(const GameTextInputState &rhs) {
        inner = rhs;
        owned_string = std::string(rhs.text_UTF8, rhs.text_length);
        inner.text_UTF8 = owned_string.data();
        return *this;
    }
    GameTextInputState inner;
    std::string owned_string;
};

}  // anonymous namespace

#ifndef NELEM
#define NELEM(x) ((int)(sizeof(x) / sizeof((x)[0])))
#endif

/*
 * JNI methods of the GameActivity Java class.
 */
static struct {
    jmethodID finish;
    jmethodID setWindowFlags;
    jmethodID getWindowInsets;
    jmethodID getWaterfallInsets;
    jmethodID setImeEditorInfoFields;
} gGameActivityClassInfo;

/*
 * JNI fields of the androidx.core.graphics.Insets Java class.
 */
static struct {
    jfieldID left;
    jfieldID right;
    jfieldID top;
    jfieldID bottom;
} gInsetsClassInfo;

/*
 * JNI fields of the Configuration Java class.
 */
static struct ConfigurationClassInfo {
    jfieldID colorMode;
    jfieldID densityDpi;
    jfieldID fontScale;
    jfieldID fontWeightAdjustment;
    jfieldID hardKeyboardHidden;
    jfieldID keyboard;
    jfieldID keyboardHidden;
    jfieldID mcc;
    jfieldID mnc;
    jfieldID navigation;
    jfieldID navigationHidden;
    jfieldID orientation;
    jfieldID screenHeightDp;
    jfieldID screenLayout;
    jfieldID screenWidthDp;
    jfieldID smallestScreenWidthDp;
    jfieldID touchscreen;
    jfieldID uiMode;
} gConfigurationClassInfo;

/*
 * JNI methods of the WindowInsetsCompat.Type Java class.
 */
static struct {
    jmethodID methods[GAMECOMMON_INSETS_TYPE_COUNT];
    jclass clazz;
} gWindowInsetsCompatTypeClassInfo;

/*
 * Contains a command to be executed by the GameActivity
 * on the application main thread.
 */
struct ActivityWork {
    int32_t cmd;
    int64_t arg1;
    int64_t arg2;
    int64_t arg3;
};

/*
 * The type of commands that can be passed to the GameActivity and that
 * are executed on the application main thread.
 */
enum {
    CMD_FINISH = 1,
    CMD_SET_WINDOW_FORMAT,
    CMD_SET_WINDOW_FLAGS,
    CMD_SHOW_SOFT_INPUT,
    CMD_HIDE_SOFT_INPUT,
    CMD_SET_SOFT_INPUT_STATE,
    CMD_SET_IME_EDITOR_INFO
};

/*
 * Last known Configuration values. They may be accessed from the different
 * thread, this is why they are made atomic.
 */
static struct Configuration {
    std::atomic_int colorMode;
    std::atomic_int densityDpi;
    std::atomic<float> fontScale;
    std::atomic_int fontWeightAdjustment;
    std::atomic_int hardKeyboardHidden;
    std::atomic_int keyboard;
    std::atomic_int keyboardHidden;
    std::atomic_int mcc;
    std::atomic_int mnc;
    std::atomic_int navigation;
    std::atomic_int navigationHidden;
    std::atomic_int orientation;
    std::atomic_int screenHeightDp;
    std::atomic_int screenLayout;
    std::atomic_int screenWidthDp;
    std::atomic_int smallestScreenWidthDp;
    std::atomic_int touchscreen;
    std::atomic_int uiMode;
} gConfiguration;

/*
 * Write a command to be executed by the GameActivity on the application main
 * thread.
 */
static void write_work(int fd, int32_t cmd, int64_t arg1 = 0, int64_t arg2 = 0,
                       int64_t arg3 = 0) {
    ActivityWork work;
    work.cmd = cmd;
    work.arg1 = arg1;
    work.arg2 = arg2;
    work.arg3 = arg3;

    LOG_TRACE("write_work: cmd=%d", cmd);
restart:
    int res = write(fd, &work, sizeof(work));
    if (res < 0 && errno == EINTR) {
        goto restart;
    }

    if (res == sizeof(work)) return;

    if (res < 0) {
        ALOGW("Failed writing to work fd: %s", strerror(errno));
    } else {
        ALOGW("Truncated writing to work fd: %d", res);
    }
}

/*
 * Read commands to be executed by the GameActivity on the application main
 * thread.
 */
static bool read_work(int fd, ActivityWork *outWork) {
    int res = read(fd, outWork, sizeof(ActivityWork));
    // no need to worry about EINTR, poll loop will just come back again.
    if (res == sizeof(ActivityWork)) return true;

    if (res < 0) {
        ALOGW("Failed reading work fd: %s", strerror(errno));
    } else {
        ALOGW("Truncated reading work fd: %d", res);
    }
    return false;
}

/*
 * Native state for interacting with the GameActivity class.
 */
struct NativeCode : public GameActivity {
    NativeCode() {
        memset((GameActivity *)this, 0, sizeof(GameActivity));
        memset(&callbacks, 0, sizeof(callbacks));
        memset(&insetsState, 0, sizeof(insetsState));
        nativeWindow = NULL;
        mainWorkRead = mainWorkWrite = -1;
        gameTextInput = NULL;
    }

    ~NativeCode() {
        if (callbacks.onDestroy != NULL) {
            callbacks.onDestroy(this);
        }
        if (env != NULL) {
            if (javaGameActivity != NULL) {
                env->DeleteGlobalRef(javaGameActivity);
            }
            if (javaAssetManager != NULL) {
                env->DeleteGlobalRef(javaAssetManager);
            }
        }
        GameTextInput_destroy(gameTextInput);
        if (looper != NULL && mainWorkRead >= 0) {
            ALooper_removeFd(looper, mainWorkRead);
        }
        ALooper_release(looper);
        looper = NULL;

        setSurface(NULL);
        if (mainWorkRead >= 0) close(mainWorkRead);
        if (mainWorkWrite >= 0) close(mainWorkWrite);
    }

    void setSurface(jobject _surface) {
        if (nativeWindow != NULL) {
            ANativeWindow_release(nativeWindow);
        }
        if (_surface != NULL) {
            nativeWindow = ANativeWindow_fromSurface(env, _surface);
        } else {
            nativeWindow = NULL;
        }
    }

    GameActivityCallbacks callbacks;

    std::string internalDataPathObj;
    std::string externalDataPathObj;
    std::string obbPathObj;

    ANativeWindow *nativeWindow;
    int32_t lastWindowWidth;
    int32_t lastWindowHeight;

    // These are used to wake up the main thread to process work.
    int mainWorkRead;
    int mainWorkWrite;
    ALooper *looper;

    // Need to hold on to a reference here in case the upper layers destroy our
    // AssetManager.
    jobject javaAssetManager;

    GameTextInput *gameTextInput;
    // Set by users in GameActivity_setTextInputState, then passed to
    // GameTextInput.
    OwnedGameTextInputState gameTextInputState;
    std::mutex gameTextInputStateMutex;

    ARect insetsState[GAMECOMMON_INSETS_TYPE_COUNT];
};

static void readConfigurationValues(NativeCode *code, jobject javaConfig);

extern "C" void GameActivity_finish(GameActivity *activity) {
    NativeCode *code = static_cast<NativeCode *>(activity);
    write_work(code->mainWorkWrite, CMD_FINISH, 0);
}

extern "C" void GameActivity_setWindowFlags(GameActivity *activity,
                                            uint32_t values, uint32_t mask) {
    NativeCode *code = static_cast<NativeCode *>(activity);
    write_work(code->mainWorkWrite, CMD_SET_WINDOW_FLAGS, values, mask);
}

extern "C" void GameActivity_showSoftInput(GameActivity *activity,
                                           uint32_t flags) {
    NativeCode *code = static_cast<NativeCode *>(activity);
    write_work(code->mainWorkWrite, CMD_SHOW_SOFT_INPUT, flags);
}

extern "C" void GameActivity_setTextInputState(
    GameActivity *activity, const GameTextInputState *state) {
    NativeCode *code = static_cast<NativeCode *>(activity);
    std::lock_guard<std::mutex> lock(code->gameTextInputStateMutex);
    code->gameTextInputState = *state;
    write_work(code->mainWorkWrite, CMD_SET_SOFT_INPUT_STATE);
}

extern "C" void GameActivity_getTextInputState(
    GameActivity *activity, GameTextInputGetStateCallback callback,
    void *context) {
    NativeCode *code = static_cast<NativeCode *>(activity);
    return GameTextInput_getState(code->gameTextInput, callback, context);
}

extern "C" void GameActivity_hideSoftInput(GameActivity *activity,
                                           uint32_t flags) {
    NativeCode *code = static_cast<NativeCode *>(activity);
    write_work(code->mainWorkWrite, CMD_HIDE_SOFT_INPUT, flags);
}

extern "C" void GameActivity_getWindowInsets(GameActivity *activity,
                                             GameCommonInsetsType type,
                                             ARect *insets) {
    if (type < 0 || type >= GAMECOMMON_INSETS_TYPE_COUNT) return;
    NativeCode *code = static_cast<NativeCode *>(activity);
    *insets = code->insetsState[type];
}

extern "C" GameTextInput *GameActivity_getTextInput(
    const GameActivity *activity) {
    const NativeCode *code = static_cast<const NativeCode *>(activity);
    return code->gameTextInput;
}

/*
 * Log the JNI exception, if any.
 */
static void checkAndClearException(JNIEnv *env, const char *methodName) {
    if (env->ExceptionCheck()) {
        ALOGE("Exception while running %s", methodName);
        env->ExceptionDescribe();
        env->ExceptionClear();
    }
}

/*
 * Callback for handling native events on the application's main thread.
 */
static int mainWorkCallback(int fd, int events, void *data) {
    ALOGD("************** mainWorkCallback *********");
    NativeCode *code = (NativeCode *)data;
    if ((events & POLLIN) == 0) {
        return 1;
    }

    ActivityWork work;
    if (!read_work(code->mainWorkRead, &work)) {
        return 1;
    }
    LOG_TRACE("mainWorkCallback: cmd=%d", work.cmd);
    switch (work.cmd) {
        case CMD_FINISH: {
            code->env->CallVoidMethod(code->javaGameActivity,
                                      gGameActivityClassInfo.finish);
            checkAndClearException(code->env, "finish");
        } break;
        case CMD_SET_WINDOW_FLAGS: {
            code->env->CallVoidMethod(code->javaGameActivity,
                                      gGameActivityClassInfo.setWindowFlags,
                                      work.arg1, work.arg2);
            checkAndClearException(code->env, "setWindowFlags");
        } break;
        case CMD_SHOW_SOFT_INPUT: {
            GameTextInput_showIme(code->gameTextInput, work.arg1);
        } break;
        case CMD_SET_SOFT_INPUT_STATE: {
            std::lock_guard<std::mutex> lock(code->gameTextInputStateMutex);
            GameTextInput_setState(code->gameTextInput,
                                   &code->gameTextInputState.inner);
            checkAndClearException(code->env, "setTextInputState");
        } break;
        case CMD_HIDE_SOFT_INPUT: {
            GameTextInput_hideIme(code->gameTextInput, work.arg1);
        } break;
        case CMD_SET_IME_EDITOR_INFO: {
            code->env->CallVoidMethod(
                code->javaGameActivity,
                gGameActivityClassInfo.setImeEditorInfoFields, work.arg1,
                work.arg2, work.arg3);
            checkAndClearException(code->env, "setImeEditorInfo");
        } break;
        default:
            ALOGW("Unknown work command: %d", work.cmd);
            break;
    }

    return 1;
}

// ------------------------------------------------------------------------
static thread_local std::string g_error_msg;

static jlong initializeNativeCode_native(
    JNIEnv *env, jobject javaGameActivity, jstring internalDataDir,
    jstring obbDir, jstring externalDataDir, jobject jAssetMgr,
    jbyteArray savedState, jobject javaConfig) {
    LOG_TRACE("initializeNativeCode_native");
    NativeCode *code = NULL;

    code = new NativeCode();

    code->looper = ALooper_forThread();
    if (code->looper == nullptr) {
        g_error_msg = "Unable to retrieve native ALooper";
        ALOGW("%s", g_error_msg.c_str());
        delete code;
        return 0;
    }
    ALooper_acquire(code->looper);

    int msgpipe[2];
    if (pipe(msgpipe)) {
        g_error_msg = "could not create pipe: ";
        g_error_msg += strerror(errno);

        ALOGW("%s", g_error_msg.c_str());
        delete code;
        return 0;
    }
    code->mainWorkRead = msgpipe[0];
    code->mainWorkWrite = msgpipe[1];
    int result = fcntl(code->mainWorkRead, F_SETFL, O_NONBLOCK);
    SLOGW_IF(result != 0,
             "Could not make main work read pipe "
             "non-blocking: %s",
             strerror(errno));
    result = fcntl(code->mainWorkWrite, F_SETFL, O_NONBLOCK);
    SLOGW_IF(result != 0,
             "Could not make main work write pipe "
             "non-blocking: %s",
             strerror(errno));
    ALooper_addFd(code->looper, code->mainWorkRead, 0, ALOOPER_EVENT_INPUT,
                  mainWorkCallback, code);

    code->GameActivity::callbacks = &code->callbacks;
    if (env->GetJavaVM(&code->vm) < 0) {
        ALOGW("GameActivity GetJavaVM failed");
        delete code;
        return 0;
    }
    code->env = env;
    code->javaGameActivity = env->NewGlobalRef(javaGameActivity);

    const char *dirStr =
        internalDataDir ? env->GetStringUTFChars(internalDataDir, NULL) : "";
    code->internalDataPathObj = dirStr;
    code->internalDataPath = code->internalDataPathObj.c_str();
    if (internalDataDir) env->ReleaseStringUTFChars(internalDataDir, dirStr);

    dirStr =
        externalDataDir ? env->GetStringUTFChars(externalDataDir, NULL) : "";
    code->externalDataPathObj = dirStr;
    code->externalDataPath = code->externalDataPathObj.c_str();
    if (externalDataDir) env->ReleaseStringUTFChars(externalDataDir, dirStr);

    code->javaAssetManager = env->NewGlobalRef(jAssetMgr);
    code->assetManager = AAssetManager_fromJava(env, jAssetMgr);

    dirStr = obbDir ? env->GetStringUTFChars(obbDir, NULL) : "";
    code->obbPathObj = dirStr;
    code->obbPath = code->obbPathObj.c_str();
    if (obbDir) env->ReleaseStringUTFChars(obbDir, dirStr);

    jbyte *rawSavedState = NULL;
    jsize rawSavedSize = 0;
    if (savedState != NULL) {
        rawSavedState = env->GetByteArrayElements(savedState, NULL);
        rawSavedSize = env->GetArrayLength(savedState);
    }

    readConfigurationValues(code, javaConfig);

    GameActivity_onCreate(code, rawSavedState, rawSavedSize);

    code->gameTextInput = GameTextInput_init(env, 0);
    GameTextInput_setEventCallback(code->gameTextInput,
                                   reinterpret_cast<GameTextInputEventCallback>(
                                       code->callbacks.onTextInputEvent),
                                   code);

    if (rawSavedState != NULL) {
        env->ReleaseByteArrayElements(savedState, rawSavedState, 0);
    }

    return reinterpret_cast<jlong>(code);
}

static jstring getDlError_native(JNIEnv *env, jobject javaGameActivity) {
    jstring result = env->NewStringUTF(g_error_msg.c_str());
    g_error_msg.clear();
    return result;
}

static void terminateNativeCode_native(JNIEnv *env, jobject javaGameActivity,
                                    jlong handle) {
    LOG_TRACE("terminateNativeCode_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        delete code;
    }
}

static void onStart_native(JNIEnv *env, jobject javaGameActivity,
                           jlong handle) {
    ALOGV("onStart_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->callbacks.onStart != NULL) {
            code->callbacks.onStart(code);
        }
    }
}

static void onResume_native(JNIEnv *env, jobject javaGameActivity,
                            jlong handle) {
    LOG_TRACE("onResume_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->callbacks.onResume != NULL) {
            code->callbacks.onResume(code);
        }
    }
}

struct SaveInstanceLocals {
    JNIEnv *env;
    jbyteArray array;
};

static jbyteArray onSaveInstanceState_native(JNIEnv *env,
                                             jobject javaGameActivity,
                                             jlong handle) {
    LOG_TRACE("onSaveInstanceState_native");

    SaveInstanceLocals locals{
        env, NULL};  // Passed through the user's state prep function.

    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->callbacks.onSaveInstanceState != NULL) {
            code->callbacks.onSaveInstanceState(
                code,
                [](const char *bytes, int len, void *context) {
                    auto locals = static_cast<SaveInstanceLocals *>(context);
                    if (len > 0) {
                        locals->array = locals->env->NewByteArray(len);
                        if (locals->array != NULL) {
                            locals->env->SetByteArrayRegion(
                                locals->array, 0, len, (const jbyte *)bytes);
                        }
                    }
                },
                &locals);
        }
    }
    return locals.array;
}

static void onPause_native(JNIEnv *env, jobject javaGameActivity,
                           jlong handle) {
    LOG_TRACE("onPause_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->callbacks.onPause != NULL) {
            code->callbacks.onPause(code);
        }
    }
}

static void onStop_native(JNIEnv *env, jobject javaGameActivity, jlong handle) {
    LOG_TRACE("onStop_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->callbacks.onStop != NULL) {
            code->callbacks.onStop(code);
        }
    }
}

static void readConfigurationValues(NativeCode *code, jobject javaConfig) {
    if (gConfigurationClassInfo.colorMode != NULL) {
        gConfiguration.colorMode = code->env->GetIntField(
            javaConfig, gConfigurationClassInfo.colorMode);
    }

    gConfiguration.densityDpi =
        code->env->GetIntField(javaConfig, gConfigurationClassInfo.densityDpi);
    gConfiguration.fontScale =
        code->env->GetFloatField(javaConfig, gConfigurationClassInfo.fontScale);

    if (gConfigurationClassInfo.fontWeightAdjustment != NULL) {
        gConfiguration.fontWeightAdjustment = code->env->GetIntField(
            javaConfig, gConfigurationClassInfo.fontWeightAdjustment);
    }

    gConfiguration.hardKeyboardHidden = code->env->GetIntField(
        javaConfig, gConfigurationClassInfo.hardKeyboardHidden);
    gConfiguration.mcc =
        code->env->GetIntField(javaConfig, gConfigurationClassInfo.mcc);
    gConfiguration.mnc =
        code->env->GetIntField(javaConfig, gConfigurationClassInfo.mnc);
    gConfiguration.navigation =
        code->env->GetIntField(javaConfig, gConfigurationClassInfo.navigation);
    gConfiguration.navigationHidden = code->env->GetIntField(
        javaConfig, gConfigurationClassInfo.navigationHidden);
    gConfiguration.orientation =
        code->env->GetIntField(javaConfig, gConfigurationClassInfo.orientation);
    gConfiguration.screenHeightDp = code->env->GetIntField(
        javaConfig, gConfigurationClassInfo.screenHeightDp);
    gConfiguration.screenLayout = code->env->GetIntField(
        javaConfig, gConfigurationClassInfo.screenLayout);
    gConfiguration.screenWidthDp = code->env->GetIntField(
        javaConfig, gConfigurationClassInfo.screenWidthDp);
    gConfiguration.smallestScreenWidthDp = code->env->GetIntField(
        javaConfig, gConfigurationClassInfo.smallestScreenWidthDp);
    gConfiguration.touchscreen =
        code->env->GetIntField(javaConfig, gConfigurationClassInfo.touchscreen);
    gConfiguration.uiMode =
        code->env->GetIntField(javaConfig, gConfigurationClassInfo.uiMode);

    checkAndClearException(code->env, "Configuration.get");
}

static void onConfigurationChanged_native(JNIEnv *env, jobject javaGameActivity,
                                          jlong handle, jobject javaNewConfig) {
    LOG_TRACE("onConfigurationChanged_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        readConfigurationValues(code, javaNewConfig);

        if (code->callbacks.onConfigurationChanged != NULL) {
            code->callbacks.onConfigurationChanged(code);
        }
    }
}

static void onTrimMemory_native(JNIEnv *env, jobject javaGameActivity,
                                jlong handle, jint level) {
    LOG_TRACE("onTrimMemory_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->callbacks.onTrimMemory != NULL) {
            code->callbacks.onTrimMemory(code, level);
        }
    }
}

static void onWindowFocusChanged_native(JNIEnv *env, jobject javaGameActivity,
                                        jlong handle, jboolean focused) {
    LOG_TRACE("onWindowFocusChanged_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->callbacks.onWindowFocusChanged != NULL) {
            code->callbacks.onWindowFocusChanged(code, focused ? 1 : 0);
        }
    }
}

static void onSurfaceCreated_native(JNIEnv *env, jobject javaGameActivity,
                                    jlong handle, jobject surface) {
    ALOGV("onSurfaceCreated_native");
    LOG_TRACE("onSurfaceCreated_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        code->setSurface(surface);

        if (code->nativeWindow != NULL &&
            code->callbacks.onNativeWindowCreated != NULL) {
            code->callbacks.onNativeWindowCreated(code, code->nativeWindow);
        }
    }
}

static void onSurfaceChanged_native(JNIEnv *env, jobject javaGameActivity,
                                    jlong handle, jobject surface, jint format,
                                    jint width, jint height) {
    LOG_TRACE("onSurfaceChanged_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        ANativeWindow *oldNativeWindow = code->nativeWindow;
        // Fix for window being destroyed behind the scenes on older Android
        // versions.
        if (oldNativeWindow != NULL) {
            ANativeWindow_acquire(oldNativeWindow);
        }
        code->setSurface(surface);
        if (oldNativeWindow != code->nativeWindow) {
            if (oldNativeWindow != NULL &&
                code->callbacks.onNativeWindowDestroyed != NULL) {
                code->callbacks.onNativeWindowDestroyed(code, oldNativeWindow);
            }
            if (code->nativeWindow != NULL) {
                if (code->callbacks.onNativeWindowCreated != NULL) {
                    code->callbacks.onNativeWindowCreated(code,
                                                          code->nativeWindow);
                }

                code->lastWindowWidth =
                    ANativeWindow_getWidth(code->nativeWindow);
                code->lastWindowHeight =
                    ANativeWindow_getHeight(code->nativeWindow);
            }
        } else {
            // Maybe it was resized?
            int32_t newWidth = ANativeWindow_getWidth(code->nativeWindow);
            int32_t newHeight = ANativeWindow_getHeight(code->nativeWindow);

            if (newWidth != code->lastWindowWidth ||
                newHeight != code->lastWindowHeight) {
                code->lastWindowWidth = newWidth;
                code->lastWindowHeight = newHeight;

                if (code->callbacks.onNativeWindowResized != NULL) {
                    code->callbacks.onNativeWindowResized(
                        code, code->nativeWindow, newWidth, newHeight);
                }
            }
        }
        // Release the window we acquired earlier.
        if (oldNativeWindow != NULL) {
            ANativeWindow_release(oldNativeWindow);
        }
    }
}

static void onSurfaceRedrawNeeded_native(JNIEnv *env, jobject javaGameActivity,
                                         jlong handle) {
    LOG_TRACE("onSurfaceRedrawNeeded_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->nativeWindow != NULL &&
            code->callbacks.onNativeWindowRedrawNeeded != NULL) {
            code->callbacks.onNativeWindowRedrawNeeded(code,
                                                       code->nativeWindow);
        }
    }
}

static void onSurfaceDestroyed_native(JNIEnv *env, jobject javaGameActivity,
                                      jlong handle) {
    LOG_TRACE("onSurfaceDestroyed_native");
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;
        if (code->nativeWindow != NULL &&
            code->callbacks.onNativeWindowDestroyed != NULL) {
            code->callbacks.onNativeWindowDestroyed(code, code->nativeWindow);
        }
        code->setSurface(NULL);
    }
}

extern "C" void GameActivity_setImeEditorInfo(GameActivity *activity,
                                              int inputType, int actionId,
                                              int imeOptions) {
    NativeCode *code = static_cast<NativeCode *>(activity);
    write_work(code->mainWorkWrite, CMD_SET_IME_EDITOR_INFO, inputType,
               actionId, imeOptions);
}

extern "C" int GameActivity_getColorMode(GameActivity *) {
    return gConfiguration.colorMode;
}

extern "C" int GameActivity_getDensityDpi(GameActivity *) {
    return gConfiguration.densityDpi;
}

extern "C" float GameActivity_getFontScale(GameActivity *) {
    return gConfiguration.fontScale;
}

extern "C" int GameActivity_getFontWeightAdjustment(GameActivity *) {
    return gConfiguration.fontWeightAdjustment;
}

extern "C" int GameActivity_getHardKeyboardHidden(GameActivity *) {
    return gConfiguration.hardKeyboardHidden;
}

extern "C" int GameActivity_getKeyboard(GameActivity *) {
    return gConfiguration.keyboard;
}

extern "C" int GameActivity_getKeyboardHidden(GameActivity *) {
    return gConfiguration.keyboardHidden;
}

extern "C" int GameActivity_getMcc(GameActivity *) {
    return gConfiguration.mcc;
}

extern "C" int GameActivity_getMnc(GameActivity *) {
    return gConfiguration.mnc;
}

extern "C" int GameActivity_getNavigation(GameActivity *) {
    return gConfiguration.navigation;
}

extern "C" int GameActivity_getNavigationHidden(GameActivity *) {
    return gConfiguration.navigationHidden;
}

extern "C" int GameActivity_getOrientation(GameActivity *) {
    return gConfiguration.orientation;
}

extern "C" int GameActivity_getScreenHeightDp(GameActivity *) {
    return gConfiguration.screenHeightDp;
}

extern "C" int GameActivity_getScreenLayout(GameActivity *) {
    return gConfiguration.screenLayout;
}

extern "C" int GameActivity_getScreenWidthDp(GameActivity *) {
    return gConfiguration.screenWidthDp;
}

extern "C" int GameActivity_getSmallestScreenWidthDp(GameActivity *) {
    return gConfiguration.smallestScreenWidthDp;
}

extern "C" int GameActivity_getTouchscreen(GameActivity *) {
    return gConfiguration.touchscreen;
}

extern "C" int GameActivity_getUIMode(GameActivity *) {
    return gConfiguration.uiMode;
}

static bool onTouchEvent_native(JNIEnv *env, jobject javaGameActivity,
                                jlong handle, jobject motionEvent) {
    if (handle == 0) return false;
    NativeCode *code = (NativeCode *)handle;
    if (code->callbacks.onTouchEvent == nullptr) return false;

    static GameActivityMotionEvent c_event;
    GameActivityMotionEvent_fromJava(env, motionEvent, &c_event);
    return code->callbacks.onTouchEvent(code, &c_event);

}

static bool onKeyUp_native(JNIEnv *env, jobject javaGameActivity, jlong handle,
                           jobject keyEvent) {
    if (handle == 0) return false;
    NativeCode *code = (NativeCode *)handle;
    if (code->callbacks.onKeyUp == nullptr) return false;

    static GameActivityKeyEvent c_event;
    GameActivityKeyEvent_fromJava(env, keyEvent, &c_event);
    return code->callbacks.onKeyUp(code, &c_event);
}

static bool onKeyDown_native(JNIEnv *env, jobject javaGameActivity,
                             jlong handle, jobject keyEvent) {
    if (handle == 0) return false;
    NativeCode *code = (NativeCode *)handle;
    if (code->callbacks.onKeyDown == nullptr) return false;

    static GameActivityKeyEvent c_event;
    GameActivityKeyEvent_fromJava(env, keyEvent, &c_event);
    return code->callbacks.onKeyDown(code, &c_event);
}

static void onTextInput_native(JNIEnv *env, jobject activity, jlong handle,
                               jobject textInputEvent) {
    if (handle == 0) return;
    NativeCode *code = (NativeCode *)handle;
    GameTextInput_processEvent(code->gameTextInput, textInputEvent);
}

static void onWindowInsetsChanged_native(JNIEnv *env, jobject activity,
                                         jlong handle) {
    if (handle == 0) return;
    NativeCode *code = (NativeCode *)handle;
    if (code->callbacks.onWindowInsetsChanged == nullptr) return;
    for (int type = 0; type < GAMECOMMON_INSETS_TYPE_COUNT; ++type) {
        jobject jinsets;
        // Note that waterfall insets are handled differently on the Java side.
        if (type == GAMECOMMON_INSETS_TYPE_WATERFALL) {
            jinsets = env->CallObjectMethod(
                code->javaGameActivity,
                gGameActivityClassInfo.getWaterfallInsets);
        } else {
            jint jtype = env->CallStaticIntMethod(
                gWindowInsetsCompatTypeClassInfo.clazz,
                gWindowInsetsCompatTypeClassInfo.methods[type]);
            jinsets = env->CallObjectMethod(
                code->javaGameActivity, gGameActivityClassInfo.getWindowInsets,
                jtype);
        }
        ARect &insets = code->insetsState[type];
        if (jinsets == nullptr) {
            insets.left = 0;
            insets.right = 0;
            insets.top = 0;
            insets.bottom = 0;
        } else {
            insets.left = env->GetIntField(jinsets, gInsetsClassInfo.left);
            insets.right = env->GetIntField(jinsets, gInsetsClassInfo.right);
            insets.top = env->GetIntField(jinsets, gInsetsClassInfo.top);
            insets.bottom = env->GetIntField(jinsets, gInsetsClassInfo.bottom);
        }
    }
    GameTextInput_processImeInsets(
        code->gameTextInput, &code->insetsState[GAMECOMMON_INSETS_TYPE_IME]);
    code->callbacks.onWindowInsetsChanged(code);
}

static void setInputConnection_native(JNIEnv *env, jobject activity,
                                      jlong handle, jobject inputConnection) {
    NativeCode *code = (NativeCode *)handle;
    GameTextInput_setInputConnection(code->gameTextInput, inputConnection);
}

static void onContentRectChangedNative_native(JNIEnv *env, jobject activity,
                                              jlong handle, jint x, jint y,
                                              jint w, jint h) {
    if (handle != 0) {
        NativeCode *code = (NativeCode *)handle;

        if (code->callbacks.onContentRectChanged != nullptr) {
            ARect rect;
            rect.left = x;
            rect.top = y;
            rect.right = x+w;
            rect.bottom = y+h;
            code->callbacks.onContentRectChanged(code, &rect);
        }
    }
}

static const JNINativeMethod g_methods[] = {
    {"initializeNativeCode",
     "(Ljava/lang/String;Ljava/lang/String;"
     "Ljava/lang/String;Landroid/content/res/AssetManager;"
     "[BLandroid/content/res/Configuration;)J",
     (void *)initializeNativeCode_native},
    {"getDlError", "()Ljava/lang/String;", (void *)getDlError_native},
    {"terminateNativeCode", "(J)V", (void *)terminateNativeCode_native},
    {"onStartNative", "(J)V", (void *)onStart_native},
    {"onResumeNative", "(J)V", (void *)onResume_native},
    {"onSaveInstanceStateNative", "(J)[B", (void *)onSaveInstanceState_native},
    {"onPauseNative", "(J)V", (void *)onPause_native},
    {"onStopNative", "(J)V", (void *)onStop_native},
    {"onConfigurationChangedNative", "(JLandroid/content/res/Configuration;)V",
     (void *)onConfigurationChanged_native},
    {"onTrimMemoryNative", "(JI)V", (void *)onTrimMemory_native},
    {"onWindowFocusChangedNative", "(JZ)V",
     (void *)onWindowFocusChanged_native},
    {"onSurfaceCreatedNative", "(JLandroid/view/Surface;)V",
     (void *)onSurfaceCreated_native},
    {"onSurfaceChangedNative", "(JLandroid/view/Surface;III)V",
     (void *)onSurfaceChanged_native},
    {"onSurfaceRedrawNeededNative", "(JLandroid/view/Surface;)V",
     (void *)onSurfaceRedrawNeeded_native},
    {"onSurfaceDestroyedNative", "(J)V", (void *)onSurfaceDestroyed_native},
    {"onTouchEventNative", "(JLandroid/view/MotionEvent;)Z",
     (void *)onTouchEvent_native},
    {"onKeyDownNative", "(JLandroid/view/KeyEvent;)Z",
     (void *)onKeyDown_native},
    {"onKeyUpNative", "(JLandroid/view/KeyEvent;)Z", (void *)onKeyUp_native},
    {"onTextInputEventNative",
     "(JLcom/google/androidgamesdk/gametextinput/State;)V",
     (void *)onTextInput_native},
    {"onWindowInsetsChangedNative", "(J)V",
     (void *)onWindowInsetsChanged_native},
    {"setInputConnectionNative",
     "(JLcom/google/androidgamesdk/gametextinput/InputConnection;)V",
     (void *)setInputConnection_native},
    {"onContentRectChangedNative", "(JIIII)V",
     (void *)onContentRectChangedNative_native},
};

static const char *const kGameActivityPathName =
    "com/google/androidgamesdk/GameActivity";

static const char *const kInsetsPathName = "androidx/core/graphics/Insets";
static const char *const kConfigurationPathName =
    "android/content/res/Configuration";
static const char *const kWindowInsetsCompatTypePathName =
    "androidx/core/view/WindowInsetsCompat$Type";

#define FIND_CLASS(var, className)   \
    var = env->FindClass(className); \
    LOG_FATAL_IF(!var, "Unable to find class %s", className);

#define GET_METHOD_ID(var, clazz, methodName, fieldDescriptor)  \
    var = env->GetMethodID(clazz, methodName, fieldDescriptor); \
    LOG_FATAL_IF(!var, "Unable to find method %s", methodName);

#define GET_STATIC_METHOD_ID(var, clazz, methodName, fieldDescriptor) \
    var = env->GetStaticMethodID(clazz, methodName, fieldDescriptor); \
    LOG_FATAL_IF(!var, "Unable to find static method %s", methodName);

#define GET_FIELD_ID(var, clazz, fieldName, fieldDescriptor)  \
    var = env->GetFieldID(clazz, fieldName, fieldDescriptor); \
    LOG_FATAL_IF(!var, "Unable to find field %s", fieldName);

static int jniRegisterNativeMethods(JNIEnv *env, const char *className,
                                    const JNINativeMethod *methods,
                                    int numMethods) {
    ALOGV("Registering %s's %d native methods...", className, numMethods);
    jclass clazz = env->FindClass(className);
    LOG_FATAL_IF(clazz == nullptr,
                 "Native registration unable to find class '%s'; aborting...",
                 className);
    int result = env->RegisterNatives(clazz, methods, numMethods);
    env->DeleteLocalRef(clazz);
    if (result == 0) {
        return 0;
    }

    // Failure to register natives is fatal. Try to report the corresponding
    // exception, otherwise abort with generic failure message.
    jthrowable thrown = env->ExceptionOccurred();
    if (thrown != NULL) {
        env->ExceptionDescribe();
        env->DeleteLocalRef(thrown);
    }
    LOG_FATAL("RegisterNatives failed for '%s'; aborting...", className);
}

extern "C" int GameActivity_register(JNIEnv *env) {
    ALOGD("GameActivity_register");
    jclass activity_class;
    FIND_CLASS(activity_class, kGameActivityPathName);
    GET_METHOD_ID(gGameActivityClassInfo.finish, activity_class, "finish",
                  "()V");
    GET_METHOD_ID(gGameActivityClassInfo.setWindowFlags, activity_class,
                  "setWindowFlags", "(II)V");
    GET_METHOD_ID(gGameActivityClassInfo.getWindowInsets, activity_class,
                  "getWindowInsets", "(I)Landroidx/core/graphics/Insets;");
    GET_METHOD_ID(gGameActivityClassInfo.getWaterfallInsets, activity_class,
                  "getWaterfallInsets", "()Landroidx/core/graphics/Insets;");
    GET_METHOD_ID(gGameActivityClassInfo.setImeEditorInfoFields, activity_class,
                  "setImeEditorInfoFields", "(III)V");

    jclass insets_class;
    FIND_CLASS(insets_class, kInsetsPathName);
    GET_FIELD_ID(gInsetsClassInfo.left, insets_class, "left", "I");
    GET_FIELD_ID(gInsetsClassInfo.right, insets_class, "right", "I");
    GET_FIELD_ID(gInsetsClassInfo.top, insets_class, "top", "I");
    GET_FIELD_ID(gInsetsClassInfo.bottom, insets_class, "bottom", "I");

    jclass configuration_class;
    FIND_CLASS(configuration_class, kConfigurationPathName);

    if (android_get_device_api_level() >= 26) {
        GET_FIELD_ID(gConfigurationClassInfo.colorMode, configuration_class,
                     "colorMode", "I");
    }

    GET_FIELD_ID(gConfigurationClassInfo.densityDpi, configuration_class,
                 "densityDpi", "I");
    GET_FIELD_ID(gConfigurationClassInfo.fontScale, configuration_class,
                 "fontScale", "F");

    if (android_get_device_api_level() >= 31) {
        GET_FIELD_ID(gConfigurationClassInfo.fontWeightAdjustment,
                     configuration_class, "fontWeightAdjustment", "I");
    }

    GET_FIELD_ID(gConfigurationClassInfo.hardKeyboardHidden,
                 configuration_class, "hardKeyboardHidden", "I");
    GET_FIELD_ID(gConfigurationClassInfo.keyboard, configuration_class,
                 "keyboard", "I");
    GET_FIELD_ID(gConfigurationClassInfo.keyboardHidden, configuration_class,
                 "keyboardHidden", "I");
    GET_FIELD_ID(gConfigurationClassInfo.mcc, configuration_class, "mcc", "I");
    GET_FIELD_ID(gConfigurationClassInfo.mnc, configuration_class, "mnc", "I");
    GET_FIELD_ID(gConfigurationClassInfo.navigation, configuration_class,
                 "navigation", "I");
    GET_FIELD_ID(gConfigurationClassInfo.navigationHidden, configuration_class,
                 "navigationHidden", "I");
    GET_FIELD_ID(gConfigurationClassInfo.orientation, configuration_class,
                 "orientation", "I");
    GET_FIELD_ID(gConfigurationClassInfo.screenHeightDp, configuration_class,
                 "screenHeightDp", "I");
    GET_FIELD_ID(gConfigurationClassInfo.screenLayout, configuration_class,
                 "screenLayout", "I");
    GET_FIELD_ID(gConfigurationClassInfo.screenWidthDp, configuration_class,
                 "screenWidthDp", "I");
    GET_FIELD_ID(gConfigurationClassInfo.smallestScreenWidthDp,
                 configuration_class, "smallestScreenWidthDp", "I");
    GET_FIELD_ID(gConfigurationClassInfo.touchscreen, configuration_class,
                 "touchscreen", "I");
    GET_FIELD_ID(gConfigurationClassInfo.uiMode, configuration_class, "uiMode",
                 "I");

    jclass windowInsetsCompatType_class;
    FIND_CLASS(windowInsetsCompatType_class, kWindowInsetsCompatTypePathName);
    gWindowInsetsCompatTypeClassInfo.clazz =
        (jclass)env->NewGlobalRef(windowInsetsCompatType_class);
    // These names must match, in order, the GameCommonInsetsType enum fields
    // Note that waterfall is handled differently by the insets API, so we
    // exclude it here.
    const char *methodNames[GAMECOMMON_INSETS_TYPE_WATERFALL] = {
        "captionBar",
        "displayCutout",
        "ime",
        "mandatorySystemGestures",
        "navigationBars",
        "statusBars",
        "systemBars",
        "systemGestures",
        "tappableElement"};
    for (int i = 0; i < GAMECOMMON_INSETS_TYPE_WATERFALL; ++i) {
        GET_STATIC_METHOD_ID(gWindowInsetsCompatTypeClassInfo.methods[i],
                             windowInsetsCompatType_class, methodNames[i],
                             "()I");
    }
    return jniRegisterNativeMethods(env, kGameActivityPathName, g_methods,
                                    NELEM(g_methods));
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_google_androidgamesdk_GameActivity_initializeNativeCode(
    JNIEnv *env, jobject javaGameActivity, jstring internalDataDir,
    jstring obbDir, jstring externalDataDir, jobject jAssetMgr,
    jbyteArray savedState, jobject javaConfig) {
    GameActivity_register(env);
    jlong nativeCode = initializeNativeCode_native(
        env, javaGameActivity, internalDataDir, obbDir, externalDataDir,
        jAssetMgr, savedState, javaConfig);
    return nativeCode;
}
