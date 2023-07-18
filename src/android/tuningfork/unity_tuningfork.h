/*
 * Copyright 2018 The Android Open Source Project
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

#pragma once

#include <jni.h>

#include "tuningfork.h"

/**
 * Functions used by the Tuning Fork Unity plugin.
 * Not for external use.
 */

#ifdef __cplusplus
extern "C" {
#endif

jint JNI_OnLoad(JavaVM* vm, void* reserved);

TuningFork_ErrorCode Unity_TuningFork_init_with_settings(
    TuningFork_Settings* settings);

TuningFork_ErrorCode Unity_TuningFork_init(
    TuningFork_FidelityParamsCallback fidelity_params_callback,
    const TuningFork_CProtobufSerialization* training_fidelity_params,
    const char* endpoint_uri_override);

bool Unity_TuningFork_swappyIsEnabled();

TuningFork_ErrorCode Unity_TuningFork_findFidelityParamsInApk(
    const char* filename, TuningFork_CProtobufSerialization* fp);

TuningFork_ErrorCode Unity_TuningFork_saveOrDeleteFidelityParamsFile(
    TuningFork_CProtobufSerialization* fps);

#ifdef __cplusplus
}
#endif
