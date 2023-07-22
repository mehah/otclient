package com.otclient

import android.content.Context
import android.util.AttributeSet
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.InputConnection
import android.view.inputmethod.EditorInfo

class FakeEditText : View, View.OnKeyListener {
    lateinit var ic: InputConnection

    init {
        isFocusableInTouchMode = true
        isFocusable = true
        setOnKeyListener(this)
    }

    constructor(context: Context?) : this(context, null)

    constructor(context: Context?, attrs: AttributeSet?) : this(context, attrs, -1)

    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : this(context, attrs, defStyleAttr, -1)

    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int, defStyleRes: Int) : super(context, attrs, defStyleAttr, defStyleRes)

    override fun onCheckIsTextEditor(): Boolean {
        return true
    }

    // This handles the hardware keyboard input
    override fun onKey(v: View, keyCode: Int, event: KeyEvent): Boolean {
        if (event.isPrintingKey) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                ic.commitText(event.unicodeChar.toChar().toString(), 1)
            }
            return true
        }
        if (event.action == KeyEvent.ACTION_DOWN) {
            onNativeKeyDown(keyCode)
            return true
        } else if (event.action == KeyEvent.ACTION_UP) {
            onNativeKeyUp(keyCode)
            return true
        }
        return false
    }

    override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection {
        return NativeInputConnection(this, true).also { ic = it }
    }

    external fun onNativeKeyDown(keyCode: Int)
    external fun onNativeKeyUp(keyCode: Int)
}