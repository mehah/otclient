package com.otclient

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.inputmethod.InputMethodManager

class AndroidManager(
    private val context: Context,
    private val editText: FakeEditText,
) {
    private val handler = Handler(Looper.getMainLooper())

    /*
     * Methods called from JNI
     */

    fun showSoftKeyboard() {
        handler.post {
            editText.visibility = View.VISIBLE
            editText.requestFocus()
            val imm = editText.context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.showSoftInput(editText, 0)
        }
    }

    fun hideSoftKeyboard() {
        handler.post {
            editText.visibility = View.INVISIBLE
            val imm = editText.context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.hideSoftInputFromWindow(editText.windowToken, 0)
        }
    }

    fun getDisplayDensity(): Float = context.resources.displayMetrics.density

    external fun nativeInit()
}