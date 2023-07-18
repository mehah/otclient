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

/**
 * @addtogroup GameActivity Game Activity Events
 * The interface to use Game Activity Events.
 * @{
 */

/**
 * @file GameActivityEvents.h
 */
#ifndef ANDROID_GAME_SDK_GAME_ACTIVITY_EVENTS_H
#define ANDROID_GAME_SDK_GAME_ACTIVITY_EVENTS_H

#include <android/input.h>
#include <jni.h>
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The maximum number of axes supported in an Android MotionEvent.
 * See https://developer.android.com/ndk/reference/group/input.
 */
#define GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT 48

/**
 * \brief Describe information about a pointer, found in a
 * GameActivityMotionEvent.
 *
 * You can read values directly from this structure, or use helper functions
 * (`GameActivityPointerAxes_getX`, `GameActivityPointerAxes_getY` and
 * `GameActivityPointerAxes_getAxisValue`).
 *
 * The X axis and Y axis are enabled by default but any other axis that you want
 * to read **must** be enabled first, using
 * `GameActivityPointerAxes_enableAxis`.
 *
 * \see GameActivityMotionEvent
 */
typedef struct GameActivityPointerAxes {
    int32_t id;
    int32_t toolType;
    float axisValues[GAME_ACTIVITY_POINTER_INFO_AXIS_COUNT];
    float rawX;
    float rawY;
} GameActivityPointerAxes;

/** \brief Get the toolType of the pointer. */
inline int32_t GameActivityPointerAxes_getToolType(
    const GameActivityPointerAxes* pointerInfo) {
    return pointerInfo->toolType;
}

/** \brief Get the current X coordinate of the pointer. */
inline float GameActivityPointerAxes_getX(
    const GameActivityPointerAxes* pointerInfo) {
    return pointerInfo->axisValues[AMOTION_EVENT_AXIS_X];
}

/** \brief Get the current Y coordinate of the pointer. */
inline float GameActivityPointerAxes_getY(
    const GameActivityPointerAxes* pointerInfo) {
    return pointerInfo->axisValues[AMOTION_EVENT_AXIS_Y];
}

/**
 * \brief Enable the specified axis, so that its value is reported in the
 * GameActivityPointerAxes structures stored in a motion event.
 *
 * You must enable any axis that you want to read, apart from
 * `AMOTION_EVENT_AXIS_X` and `AMOTION_EVENT_AXIS_Y` that are enabled by
 * default.
 *
 * If the axis index is out of range, nothing is done.
 */
void GameActivityPointerAxes_enableAxis(int32_t axis);

/**
 * \brief Disable the specified axis. Its value won't be reported in the
 * GameActivityPointerAxes structures stored in a motion event anymore.
 *
 * Apart from X and Y, any axis that you want to read **must** be enabled first,
 * using `GameActivityPointerAxes_enableAxis`.
 *
 * If the axis index is out of range, nothing is done.
 */
void GameActivityPointerAxes_disableAxis(int32_t axis);

/**
 * \brief Get the value of the requested axis.
 *
 * Apart from X and Y, any axis that you want to read **must** be enabled first,
 * using `GameActivityPointerAxes_enableAxis`.
 *
 * Find the valid enums for the axis (`AMOTION_EVENT_AXIS_X`,
 * `AMOTION_EVENT_AXIS_Y`, `AMOTION_EVENT_AXIS_PRESSURE`...)
 * in https://developer.android.com/ndk/reference/group/input.
 *
 * @param pointerInfo The structure containing information about the pointer,
 * obtained from GameActivityMotionEvent.
 * @param axis The axis to get the value from
 * @return The value of the axis, or 0 if the axis is invalid or was not
 * enabled.
 */
float GameActivityPointerAxes_getAxisValue(
    const GameActivityPointerAxes* pointerInfo, int32_t axis);

inline float GameActivityPointerAxes_getPressure(
    const GameActivityPointerAxes* pointerInfo) {
    return GameActivityPointerAxes_getAxisValue(pointerInfo,
                                                AMOTION_EVENT_AXIS_PRESSURE);
}

inline float GameActivityPointerAxes_getSize(
    const GameActivityPointerAxes* pointerInfo) {
    return GameActivityPointerAxes_getAxisValue(pointerInfo,
                                                AMOTION_EVENT_AXIS_SIZE);
}

inline float GameActivityPointerAxes_getTouchMajor(
    const GameActivityPointerAxes* pointerInfo) {
    return GameActivityPointerAxes_getAxisValue(pointerInfo,
                                                AMOTION_EVENT_AXIS_TOUCH_MAJOR);
}

inline float GameActivityPointerAxes_getTouchMinor(
    const GameActivityPointerAxes* pointerInfo) {
    return GameActivityPointerAxes_getAxisValue(pointerInfo,
                                                AMOTION_EVENT_AXIS_TOUCH_MINOR);
}

inline float GameActivityPointerAxes_getToolMajor(
    const GameActivityPointerAxes* pointerInfo) {
    return GameActivityPointerAxes_getAxisValue(pointerInfo,
                                                AMOTION_EVENT_AXIS_TOOL_MAJOR);
}

inline float GameActivityPointerAxes_getToolMinor(
    const GameActivityPointerAxes* pointerInfo) {
    return GameActivityPointerAxes_getAxisValue(pointerInfo,
                                                AMOTION_EVENT_AXIS_TOOL_MINOR);
}

inline float GameActivityPointerAxes_getOrientation(
    const GameActivityPointerAxes* pointerInfo) {
    return GameActivityPointerAxes_getAxisValue(pointerInfo,
                                                AMOTION_EVENT_AXIS_ORIENTATION);
}

/**
 * The maximum number of pointers returned inside a motion event.
 */
#if (defined GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT_OVERRIDE)
#define GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT \
    GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT_OVERRIDE
#else
#define GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT 8
#endif

/**
 * \brief Describe a motion event that happened on the GameActivity SurfaceView.
 *
 * This is 1:1 mapping to the information contained in a Java `MotionEvent`
 * (see https://developer.android.com/reference/android/view/MotionEvent).
 */
typedef struct GameActivityMotionEvent {
    int32_t deviceId;
    int32_t source;
    int32_t action;

    int64_t eventTime;
    int64_t downTime;

    int32_t flags;
    int32_t metaState;

    int32_t actionButton;
    int32_t buttonState;
    int32_t classification;
    int32_t edgeFlags;

    uint32_t pointerCount;
    GameActivityPointerAxes
        pointers[GAMEACTIVITY_MAX_NUM_POINTERS_IN_MOTION_EVENT];

    int historySize;
    int64_t* historicalEventTimesMillis;
    int64_t* historicalEventTimesNanos;
    float* historicalAxisValues;

    float precisionX;
    float precisionY;
} GameActivityMotionEvent;

float GameActivityMotionEvent_getHistoricalAxisValue(
    const GameActivityMotionEvent* event, int axis, int pointerIndex,
    int historyPos);

inline int GameActivityMotionEvent_getHistorySize(
    const GameActivityMotionEvent* event) {
    return event->historySize;
}

inline float GameActivityMotionEvent_getHistoricalX(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_X, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalY(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_Y, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalPressure(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_PRESSURE, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalSize(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_SIZE, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalTouchMajor(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_TOUCH_MAJOR, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalTouchMinor(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_TOUCH_MINOR, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalToolMajor(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_TOOL_MAJOR, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalToolMinor(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_TOOL_MINOR, pointerIndex, historyPos);
}

inline float GameActivityMotionEvent_getHistoricalOrientation(
    const GameActivityMotionEvent* event, int pointerIndex, int historyPos) {
    return GameActivityMotionEvent_getHistoricalAxisValue(
        event, AMOTION_EVENT_AXIS_ORIENTATION, pointerIndex, historyPos);
}

/** \brief Handle the freeing of the GameActivityMotionEvent struct. */
void GameActivityMotionEvent_destroy(GameActivityMotionEvent* c_event);

/**
 * \brief Convert a Java `MotionEvent` to a `GameActivityMotionEvent`.
 *
 * This is done automatically by the GameActivity: see `onTouchEvent` to set
 * a callback to consume the received events.
 * This function can be used if you re-implement events handling in your own
 * activity.
 * Ownership of out_event is maintained by the caller.
 */
void GameActivityMotionEvent_fromJava(JNIEnv* env, jobject motionEvent,
                                      GameActivityMotionEvent* out_event);

/**
 * \brief Describe a key event that happened on the GameActivity SurfaceView.
 *
 * This is 1:1 mapping to the information contained in a Java `KeyEvent`
 * (see https://developer.android.com/reference/android/view/KeyEvent).
 * The only exception is the event times, which are reported as
 * nanoseconds in this struct.
 */
typedef struct GameActivityKeyEvent {
    int32_t deviceId;
    int32_t source;
    int32_t action;

    int64_t eventTime;
    int64_t downTime;

    int32_t flags;
    int32_t metaState;

    int32_t modifiers;
    int32_t repeatCount;
    int32_t keyCode;
    int32_t scanCode;
    int32_t unicodeChar;
} GameActivityKeyEvent;

/**
 * \brief Convert a Java `KeyEvent` to a `GameActivityKeyEvent`.
 *
 * This is done automatically by the GameActivity: see `onKeyUp` and `onKeyDown`
 * to set a callback to consume the received events.
 * This function can be used if you re-implement events handling in your own
 * activity.
 * Ownership of out_event is maintained by the caller.
 */
void GameActivityKeyEvent_fromJava(JNIEnv* env, jobject motionEvent,
                                   GameActivityKeyEvent* out_event);

#ifdef __cplusplus
}
#endif

/** @} */

#endif  // ANDROID_GAME_SDK_GAME_ACTIVITY_EVENTS_H
