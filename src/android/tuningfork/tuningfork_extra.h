/*
 * Copyright 2019 The Android Open Source Project
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
 * @defgroup tuningfork_extra Tuning Fork extra utilities
 * Extra utility functions to use Tuning Fork.
 * @{
 */

#pragma once

#include "tuningfork.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Load fidelity params from assets/tuningfork/\<filename\>
 * Ownership of @p fp is passed to the caller: call
 * TuningFork_CProtobufSerialization_free to deallocate
 * data stored in the struct.
 * @param env JNIEnv
 * @param context Application context
 * @param filename The filename to load
 * @param[out] fidelity_params Protocol buffer serialization of fidelity
 * parameters found.
 * @return TUNINGFORK_ERROR_OK if no error
 */
TuningFork_ErrorCode TuningFork_findFidelityParamsInApk(
    JNIEnv* env, jobject context, const char* filename,
    TuningFork_CProtobufSerialization* fidelity_params);

/**
 * @brief Download fidelity parameters on a separate thread.
 * A download thread is activated to retrieve fidelity params and retries are
 *    performed until a download is successful or a timeout occurs.
 * Downloaded params are stored locally and used in preference of default
 *    params when the app is started in future.
 * Requests will timeout according to the initial_request_timeout_ms and
 *  ultimate_request_timeout_ms fields in the TuningFork_Settings struct with
 * which Tuning Fork was initialized.
 * @param default_params A protobuf serialization containing the fidelity params
 * that will be used if there is no download connection and there are no saved
 * parameters.
 * @param fidelity_params_callback is called with any downloaded params or with
 * default / saved params.
 * @return TUNINGFORK_ERROR_OK if no error
 */
TuningFork_ErrorCode TuningFork_startFidelityParamDownloadThread(
    const TuningFork_CProtobufSerialization* default_params,
    TuningFork_FidelityParamsCallback fidelity_params_callback);

/**
 * @brief The TuningFork_init function will save fidelity params to a file
 *  for use when a download connection is not available. With this function,
 *  you can replace or delete the saved file.
 * @param env JNIEnv
 * @param context Application context.
 * @param fidelity_params The parameters to save. The save file will be deleted
 * if fidelity_params is NULL.
 * @return TUNINGFORK_ERROR_OK if no error
 */
TuningFork_ErrorCode TuningFork_saveOrDeleteFidelityParamsFile(
    JNIEnv* env, jobject context,
    const TuningFork_CProtobufSerialization* fidelity_params);

#ifdef __cplusplus
}
#endif

/** @} */
