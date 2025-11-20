package com.otclient

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.TextView
import androidx.core.view.isVisible

class AndroidManager(
    private val context: Context,
    private val editText: FakeEditText,
    private val previewContainer: View,
    private val previewText: TextView,
) {
    private val handler = Handler(Looper.getMainLooper())
    private var isImeVisible = false
    private var shouldShowPreview = false
    private var pendingPreviewText: String = ""

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
            hidePreviewInternal(clearText = false)
        }
    }

    fun showInputPreview(text: String) {
        handler.post {
            pendingPreviewText = text
            shouldShowPreview = true
            if (isImeVisible) showPreviewInternal()
        }
    }

    fun updateInputPreview(text: String) {
        handler.post {
            pendingPreviewText = text
            if (shouldShowPreview && isImeVisible) showPreviewInternal(animate = false)
        }
    }

    fun hideInputPreview() {
        handler.post {
            shouldShowPreview = false
            pendingPreviewText = ""
            hidePreviewInternal(clearText = true)
        }
    }

    fun onImeVisibilityChanged(visible: Boolean) {
        handler.post {
            isImeVisible = visible
            if (visible) {
                if (shouldShowPreview) showPreviewInternal()
            } else {
                hidePreviewInternal(clearText = false)
            }
        }
    }

    fun getDisplayDensity(): Float = context.resources.displayMetrics.density

    external fun nativeInit()
    external fun nativeSetAudioEnabled(enabled: Boolean)

    private fun showPreviewInternal(animate: Boolean = true) {
        previewContainer.animate().cancel()
        previewText.text = pendingPreviewText
        if (!previewContainer.isVisible) {
            previewContainer.alpha = if (animate) 0f else 1f
            previewContainer.isVisible = true
            if (animate) {
                previewContainer.animate()
                    .alpha(1f)
                    .setDuration(120L)
                    .start()
            }
        } else if (animate) {
            previewContainer.animate()
                .alpha(1f)
                .setDuration(120L)
                .start()
        }
    }

    private fun hidePreviewInternal(animate: Boolean = true, clearText: Boolean) {
        previewContainer.animate().cancel()
        if (!previewContainer.isVisible) {
            if (clearText) previewText.text = ""
            return
        }

        if (animate) {
            previewContainer.animate()
                .alpha(0f)
                .setDuration(120L)
                .withEndAction {
                    previewContainer.isVisible = false
                    previewContainer.alpha = 1f
                    if (clearText) previewText.text = ""
                }
                .start()
        } else {
            previewContainer.alpha = 1f
            previewContainer.isVisible = false
            if (clearText) previewText.text = ""
        }
    }
}
