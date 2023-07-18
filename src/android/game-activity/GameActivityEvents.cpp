/*
 * Copyright (C) 2022 The Android Open Source Project
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

#include "GameActivityEvents.h"

#include <sys/system_properties.h>

#include <string>

#include "GameActivityLog.h"

// TODO(b/187147166): these functions were extracted from the Game SDK
// (gamesdk/src/common/system_utils.h). system_utils.h/cpp should be used
// instead.
namespace {

std::string getSystemPropViaGet(const char *key,
                                const char *default_value = "") {
    char buffer[PROP_VALUE_MAX + 1] = "";  // +1 for terminator
    int bufferLen = __system_property_get(key, buffer);
    if (bufferLen > 0)
        return buffer;
    else
        return "";
}

std::string GetSystemProp(const char *key, const char *default_value = "") {
    return getSystemPropViaGet(key, default_value);
}

int GetSystemPropAsInt(const char *key, int default_value = 0) {
    std::string prop = GetSystemProp(key);
    return prop == "" ? default_value : strtoll(prop.c_str(), nullptr, 10);
}

}  // anonymous namespace

#ifndef NELEM
#define NELEM(x) ((int)(sizeof(x) / sizeof((x)[0])))
#endif

static bool enabledAxes[GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT] = {
    /* AMOTION_EVENT_AXIS_X */ true,
    /* AMOTION_EVENT_AXIS_Y */ true,
    // Disable all other axes by default (they can be enabled using
    // `GameActivityPointerAxes_enableAxis`).
    false};

extern "C" void GameActivityPointerAxes_enableAxis(int32_t axis) {
    if (axis < 0 || axis >= GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT) {
        return;
    }

    enabledAxes[axis] = true;
}

float GameActivityPointerAxes_getAxisValue(
    const GameActivityPointerAxes *pointerInfo, int32_t axis) {
    if (axis < 0 || axis >= GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT) {
        return 0;
    }

    if (!enabledAxes[axis]) {
        ALOGW("Axis %d must be enabled before it can be accessed.", axis);
        return 0;
    }

    return pointerInfo->axisValues[axis];
}

extern "C" void GameActivityPointerAxes_disableAxis(int32_t axis) {
    if (axis < 0 || axis >= GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT) {
        return;
    }

    enabledAxes[axis] = false;
}

float GameActivityMotionEvent_getHistoricalAxisValue(
    const GameActivityMotionEvent *event, int axis, int pointerIndex,
    int historyPos) {
    if (axis < 0 || axis >= GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT) {
        return 0;
    }

    if (!enabledAxes[axis]) {
        ALOGW("Axis %d must be enabled before it can be accessed.", axis);
        return 0;
    }

    return event->historicalAxisValues[event->pointerCount * historyPos + axis];
}

static struct {
    jmethodID getDeviceId;
    jmethodID getSource;
    jmethodID getAction;

    jmethodID getEventTime;
    jmethodID getDownTime;

    jmethodID getFlags;
    jmethodID getMetaState;

    jmethodID getActionButton;
    jmethodID getButtonState;
    jmethodID getClassification;
    jmethodID getEdgeFlags;

    jmethodID getHistorySize;
    jmethodID getHistoricalEventTime;

    jmethodID getPointerCount;
    jmethodID getPointerId;

    jmethodID getToolType;

    jmethodID getRawX;
    jmethodID getRawY;
    jmethodID getXPrecision;
    jmethodID getYPrecision;
    jmethodID getAxisValue;

    jmethodID getHistoricalAxisValue;
} gMotionEventClassInfo;

extern "C" void GameActivityMotionEvent_destroy(
    GameActivityMotionEvent *c_event) {
    delete c_event->historicalAxisValues;
    delete c_event->historicalEventTimesMillis;
    delete c_event->historicalEventTimesNanos;
}

extern "C" void GameActivityMotionEvent_fromJava(
    JNIEnv *env, jobject motionEvent, GameActivityMotionEvent *out_event) {
    static bool gMotionEventClassInfoInitialized = false;
    if (!gMotionEventClassInfoInitialized) {
        int sdkVersion = GetSystemPropAsInt("ro.build.version.sdk");
        gMotionEventClassInfo = {0};
        jclass motionEventClass = env->FindClass("android/view/MotionEvent");
        gMotionEventClassInfo.getDeviceId =
            env->GetMethodID(motionEventClass, "getDeviceId", "()I");
        gMotionEventClassInfo.getSource =
            env->GetMethodID(motionEventClass, "getSource", "()I");
        gMotionEventClassInfo.getAction =
            env->GetMethodID(motionEventClass, "getAction", "()I");
        gMotionEventClassInfo.getEventTime =
            env->GetMethodID(motionEventClass, "getEventTime", "()J");
        gMotionEventClassInfo.getDownTime =
            env->GetMethodID(motionEventClass, "getDownTime", "()J");
        gMotionEventClassInfo.getFlags =
            env->GetMethodID(motionEventClass, "getFlags", "()I");
        gMotionEventClassInfo.getMetaState =
            env->GetMethodID(motionEventClass, "getMetaState", "()I");
        if (sdkVersion >= 23) {
            gMotionEventClassInfo.getActionButton =
                env->GetMethodID(motionEventClass, "getActionButton", "()I");
        }
        if (sdkVersion >= 14) {
            gMotionEventClassInfo.getButtonState =
                env->GetMethodID(motionEventClass, "getButtonState", "()I");
        }
        if (sdkVersion >= 29) {
            gMotionEventClassInfo.getClassification =
                env->GetMethodID(motionEventClass, "getClassification", "()I");
        }
        gMotionEventClassInfo.getEdgeFlags =
            env->GetMethodID(motionEventClass, "getEdgeFlags", "()I");

        gMotionEventClassInfo.getHistorySize =
            env->GetMethodID(motionEventClass, "getHistorySize", "()I");
        gMotionEventClassInfo.getHistoricalEventTime = env->GetMethodID(
            motionEventClass, "getHistoricalEventTime", "(I)J");

        gMotionEventClassInfo.getPointerCount =
            env->GetMethodID(motionEventClass, "getPointerCount", "()I");
        gMotionEventClassInfo.getPointerId =
            env->GetMethodID(motionEventClass, "getPointerId", "(I)I");
        gMotionEventClassInfo.getToolType =
            env->GetMethodID(motionEventClass, "getToolType", "(I)I");
        if (sdkVersion >= 29) {
            gMotionEventClassInfo.getRawX =
                env->GetMethodID(motionEventClass, "getRawX", "(I)F");
            gMotionEventClassInfo.getRawY =
                env->GetMethodID(motionEventClass, "getRawY", "(I)F");
        }
        gMotionEventClassInfo.getXPrecision =
            env->GetMethodID(motionEventClass, "getXPrecision", "()F");
        gMotionEventClassInfo.getYPrecision =
            env->GetMethodID(motionEventClass, "getYPrecision", "()F");
        gMotionEventClassInfo.getAxisValue =
            env->GetMethodID(motionEventClass, "getAxisValue", "(II)F");

        gMotionEventClassInfo.getHistoricalAxisValue = env->GetMethodID(
            motionEventClass, "getHistoricalAxisValue", "(III)F");
        gMotionEventClassInfoInitialized = true;
    }

    int pointerCount =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getPointerCount);
    pointerCount =
        std::min(pointerCount, GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT);
    out_event->pointerCount = pointerCount;
    for (int i = 0; i < pointerCount; ++i) {
        out_event->pointers[i] = {
            /*id=*/env->CallIntMethod(motionEvent,
                                      gMotionEventClassInfo.getPointerId, i),
            /*toolType=*/
            env->CallIntMethod(motionEvent, gMotionEventClassInfo.getToolType,
                               i),
            /*axisValues=*/{0},
            /*rawX=*/gMotionEventClassInfo.getRawX
                ? env->CallFloatMethod(motionEvent,
                                       gMotionEventClassInfo.getRawX, i)
                : 0,
            /*rawY=*/gMotionEventClassInfo.getRawY
                ? env->CallFloatMethod(motionEvent,
                                       gMotionEventClassInfo.getRawY, i)
                : 0,
        };

        for (int axisIndex = 0;
             axisIndex < GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT; ++axisIndex) {
            if (enabledAxes[axisIndex]) {
                out_event->pointers[i].axisValues[axisIndex] =
                    env->CallFloatMethod(motionEvent,
                                         gMotionEventClassInfo.getAxisValue,
                                         axisIndex, i);
            }
        }
    }

    int historySize =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getHistorySize);
    out_event->historySize = historySize;
    out_event->historicalAxisValues =
        new float[historySize * pointerCount *
                  GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT];
    out_event->historicalEventTimesMillis = new int64_t[historySize];
    out_event->historicalEventTimesNanos = new int64_t[historySize];

    for (int historyIndex = 0; historyIndex < historySize; historyIndex++) {
        out_event->historicalEventTimesMillis[historyIndex] =
            env->CallLongMethod(motionEvent,
                                gMotionEventClassInfo.getHistoricalEventTime,
                                historyIndex);
        out_event->historicalEventTimesNanos[historyIndex] =
            out_event->historicalEventTimesMillis[historyIndex] * 1000000;
        for (int i = 0; i < pointerCount; ++i) {
            int pointerOffset = i * GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT;
            int historyAxisOffset = historyIndex * pointerCount *
                                    GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT;
            float *axisValues =
                &out_event
                     ->historicalAxisValues[historyAxisOffset + pointerOffset];
            for (int axisIndex = 0;
                 axisIndex < GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT;
                 ++axisIndex) {
                if (enabledAxes[axisIndex]) {
                    axisValues[axisIndex] = env->CallFloatMethod(
                        motionEvent,
                        gMotionEventClassInfo.getHistoricalAxisValue, axisIndex,
                        i, historyIndex);
                }
            }
        }
    }

    out_event->deviceId =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getDeviceId);
    out_event->source =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getSource);
    out_event->action =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getAction);
    out_event->eventTime =
        env->CallLongMethod(motionEvent, gMotionEventClassInfo.getEventTime) *
        1000000;
    out_event->downTime =
        env->CallLongMethod(motionEvent, gMotionEventClassInfo.getDownTime) *
        1000000;
    out_event->flags =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getFlags);
    out_event->metaState =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getMetaState);
    out_event->actionButton =
        gMotionEventClassInfo.getActionButton
            ? env->CallIntMethod(motionEvent,
                                 gMotionEventClassInfo.getActionButton)
            : 0;
    out_event->buttonState =
        gMotionEventClassInfo.getButtonState
            ? env->CallIntMethod(motionEvent,
                                 gMotionEventClassInfo.getButtonState)
            : 0;
    out_event->classification =
        gMotionEventClassInfo.getClassification
            ? env->CallIntMethod(motionEvent,
                                 gMotionEventClassInfo.getClassification)
            : 0;
    out_event->edgeFlags =
        env->CallIntMethod(motionEvent, gMotionEventClassInfo.getEdgeFlags);
    out_event->precisionX =
        env->CallFloatMethod(motionEvent, gMotionEventClassInfo.getXPrecision);
    out_event->precisionY =
        env->CallFloatMethod(motionEvent, gMotionEventClassInfo.getYPrecision);
}

static struct {
    jmethodID getDeviceId;
    jmethodID getSource;
    jmethodID getAction;

    jmethodID getEventTime;
    jmethodID getDownTime;

    jmethodID getFlags;
    jmethodID getMetaState;

    jmethodID getModifiers;
    jmethodID getRepeatCount;
    jmethodID getKeyCode;
    jmethodID getScanCode;
    jmethodID getUnicodeChar;
} gKeyEventClassInfo;

extern "C" void GameActivityKeyEvent_fromJava(JNIEnv *env, jobject keyEvent,
                                              GameActivityKeyEvent *out_event) {
    static bool gKeyEventClassInfoInitialized = false;
    if (!gKeyEventClassInfoInitialized) {
        int sdkVersion = GetSystemPropAsInt("ro.build.version.sdk");
        gKeyEventClassInfo = {0};
        jclass keyEventClass = env->FindClass("android/view/KeyEvent");
        gKeyEventClassInfo.getDeviceId =
            env->GetMethodID(keyEventClass, "getDeviceId", "()I");
        gKeyEventClassInfo.getSource =
            env->GetMethodID(keyEventClass, "getSource", "()I");
        gKeyEventClassInfo.getAction =
            env->GetMethodID(keyEventClass, "getAction", "()I");
        gKeyEventClassInfo.getEventTime =
            env->GetMethodID(keyEventClass, "getEventTime", "()J");
        gKeyEventClassInfo.getDownTime =
            env->GetMethodID(keyEventClass, "getDownTime", "()J");
        gKeyEventClassInfo.getFlags =
            env->GetMethodID(keyEventClass, "getFlags", "()I");
        gKeyEventClassInfo.getMetaState =
            env->GetMethodID(keyEventClass, "getMetaState", "()I");
        if (sdkVersion >= 13) {
            gKeyEventClassInfo.getModifiers =
                env->GetMethodID(keyEventClass, "getModifiers", "()I");
        }
        gKeyEventClassInfo.getRepeatCount =
            env->GetMethodID(keyEventClass, "getRepeatCount", "()I");
        gKeyEventClassInfo.getKeyCode =
            env->GetMethodID(keyEventClass, "getKeyCode", "()I");
        gKeyEventClassInfo.getScanCode =
            env->GetMethodID(keyEventClass, "getScanCode", "()I");
        gKeyEventClassInfo.getUnicodeChar =
            env->GetMethodID(keyEventClass, "getUnicodeChar", "()I");

        gKeyEventClassInfoInitialized = true;
    }

    *out_event = {
        /*deviceId=*/env->CallIntMethod(keyEvent,
                                        gKeyEventClassInfo.getDeviceId),
        /*source=*/env->CallIntMethod(keyEvent, gKeyEventClassInfo.getSource),
        /*action=*/env->CallIntMethod(keyEvent, gKeyEventClassInfo.getAction),
        // TODO: introduce a millisecondsToNanoseconds helper:
        /*eventTime=*/
        env->CallLongMethod(keyEvent, gKeyEventClassInfo.getEventTime) *
            1000000,
        /*downTime=*/
        env->CallLongMethod(keyEvent, gKeyEventClassInfo.getDownTime) * 1000000,
        /*flags=*/env->CallIntMethod(keyEvent, gKeyEventClassInfo.getFlags),
        /*metaState=*/
        env->CallIntMethod(keyEvent, gKeyEventClassInfo.getMetaState),
        /*modifiers=*/gKeyEventClassInfo.getModifiers
            ? env->CallIntMethod(keyEvent, gKeyEventClassInfo.getModifiers)
            : 0,
        /*repeatCount=*/
        env->CallIntMethod(keyEvent, gKeyEventClassInfo.getRepeatCount),
        /*keyCode=*/
        env->CallIntMethod(keyEvent, gKeyEventClassInfo.getKeyCode),
        /*scanCode=*/
        env->CallIntMethod(keyEvent, gKeyEventClassInfo.getScanCode),
        /*unicodeChar=*/
        env->CallIntMethod(keyEvent, gKeyEventClassInfo.getUnicodeChar)};
}
