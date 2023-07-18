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
#ifndef ANDROID_GAME_SDK_GAME_ACTIVITY_LOG_H_
#define ANDROID_GAME_SDK_GAME_ACTIVITY_LOG_H_

#define LOG_TAG "GameActivity"
#include <android/log.h>

#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__);
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__);
#define ALOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__);
#ifdef NDEBUG
#define ALOGV(...)
#else
#define ALOGV(...) \
    __android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, __VA_ARGS__);
#endif

/* Returns 2nd arg.  Used to substitute default value if caller's vararg list
 * is empty.
 */
#define __android_second(first, second, ...) second

/* If passed multiple args, returns ',' followed by all but 1st arg, otherwise
 * returns nothing.
 */
#define __android_rest(first, ...) , ##__VA_ARGS__

#define android_printAssert(cond, tag, fmt...) \
    __android_log_assert(cond, tag,            \
                         __android_second(0, ##fmt, NULL) __android_rest(fmt))

#define CONDITION(cond) (__builtin_expect((cond) != 0, 0))

#ifndef LOG_ALWAYS_FATAL_IF
#define LOG_ALWAYS_FATAL_IF(cond, ...)                                \
    ((CONDITION(cond))                                                \
         ? ((void)android_printAssert(#cond, LOG_TAG, ##__VA_ARGS__)) \
         : (void)0)
#endif

#ifndef LOG_ALWAYS_FATAL
#define LOG_ALWAYS_FATAL(...) \
    (((void)android_printAssert(NULL, LOG_TAG, ##__VA_ARGS__)))
#endif

/*
 * Simplified macro to send a warning system log message using current LOG_TAG.
 */
#ifndef SLOGW
#define SLOGW(...) \
    ((void)__android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__))
#endif

#ifndef SLOGW_IF
#define SLOGW_IF(cond, ...)                                                    \
    ((__predict_false(cond))                                                   \
         ? ((void)__android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)) \
         : (void)0)
#endif

/*
 * Versions of LOG_ALWAYS_FATAL_IF and LOG_ALWAYS_FATAL that
 * are stripped out of release builds.
 */
#if LOG_NDEBUG

#ifndef LOG_FATAL_IF
#define LOG_FATAL_IF(cond, ...) ((void)0)
#endif
#ifndef LOG_FATAL
#define LOG_FATAL(...) ((void)0)
#endif

#else

#ifndef LOG_FATAL_IF
#define LOG_FATAL_IF(cond, ...) LOG_ALWAYS_FATAL_IF(cond, ##__VA_ARGS__)
#endif
#ifndef LOG_FATAL
#define LOG_FATAL(...) LOG_ALWAYS_FATAL(__VA_ARGS__)
#endif

#endif

/*
 * Assertion that generates a log message when the assertion fails.
 * Stripped out of release builds.  Uses the current LOG_TAG.
 */
#ifndef ALOG_ASSERT
#define ALOG_ASSERT(cond, ...) LOG_FATAL_IF(!(cond), ##__VA_ARGS__)
#endif

#define LOG_TRACE(...)

#endif  // ANDROID_GAME_SDK_GAME_ACTIVITY_LOG_H_
