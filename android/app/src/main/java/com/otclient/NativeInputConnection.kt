package com.otclient

import android.view.KeyEvent
import android.view.inputmethod.BaseInputConnection

class NativeInputConnection(
    private val targetView: FakeEditText,
    fullEditor: Boolean,
) : BaseInputConnection(targetView, fullEditor) {

    // This handles the keycodes from soft keyboard
    override fun sendKeyEvent(event: KeyEvent): Boolean {
        val keyCode = event.keyCode
        if (event.action == KeyEvent.ACTION_DOWN) {
            if (event.isPrintingKey) {
                commitText(event.unicodeChar.toChar().toString(), 1)
            }
            targetView.onNativeKeyDown(keyCode)
            return true
        } else if (event.action == KeyEvent.ACTION_UP) {
            targetView.onNativeKeyUp(keyCode)
            return true
        }
        return super.sendKeyEvent(event)
    }

    // Typed text
    override fun commitText(text: CharSequence, newCursorPosition: Int): Boolean {
        nativeCommitText(text.toString())
        return super.commitText(text, newCursorPosition)
    }

    // Workaround to capture backspace key
    override fun deleteSurroundingText(beforeLength: Int, afterLength: Int): Boolean {
        return if (beforeLength == 1 && afterLength == 0) {
            (super.sendKeyEvent(
                KeyEvent(
                    KeyEvent.ACTION_DOWN,
                    KeyEvent.KEYCODE_DEL
                )
            )
                    && super.sendKeyEvent(
                KeyEvent(
                    KeyEvent.ACTION_UP,
                    KeyEvent.KEYCODE_DEL
                )
            ))
        } else super.deleteSurroundingText(beforeLength, afterLength)
    }

    private external fun nativeCommitText(text: String)
}