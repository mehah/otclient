/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#pragma once

#include <cstdint>
#include <numbers>

#define DEG_TO_RAD (std::acos(-1.f)/180.f)
#define RAD_TO_DEC (180.f/std::acos(-1.f))

#ifndef BUILD_TYPE
#define BUILD_TYPE "unknown"
#endif

#ifndef BUILD_ARCH
#if defined(__amd64) || defined(_M_X64)
#define BUILD_ARCH "x64"
#elif defined(__i386) || defined(_M_IX86) || defined(_X86_)
#define BUILD_ARCH "x86"
#elif defined(__arm__)
#define BUILD_ARCH "ARM"
#elif defined(__EMSCRIPTEN__)
#define BUILD_ARCH "WASM32"
#else
#define BUILD_ARCH "unknown"
#endif
#endif

namespace Fw
{
    // clang c++20 dont support std::numbers::pi
    static constexpr float pi = std::numbers::pi_v<float>;
    static constexpr float MIN_ALPHA = 0.003f;

    enum Key : uint8_t
    {
        KeyUnknown = 0,
        KeyEscape = 1,
        KeyTab = 2,
        KeyBackspace = 3,
        //KeyReturn = 4,
        KeyEnter = 5,
        KeyInsert = 6,
        KeyDelete = 7,
        KeyPause = 8,
        KeyPrintScreen = 9,
        KeyHome = 10,
        KeyEnd = 11,
        KeyPageUp = 12,
        KeyPageDown = 13,
        KeyUp = 14,
        KeyDown = 15,
        KeyLeft = 16,
        KeyRight = 17,
        KeyNumLock = 18,
        KeyScrollLock = 19,
        KeyCapsLock = 20,
        KeyCtrl = 21,
        KeyShift = 22,
        KeyAlt = 23,
        //KeyAltGr = 24,
        KeyMeta = 25,
        KeyMenu = 26,
        KeySpace = 32,        // ' '
        KeyExclamation = 33,  // !
        KeyQuote = 34,        // "
        KeyNumberSign = 35,   // #
        KeyDollar = 36,       // $
        KeyPercent = 37,      // %
        KeyAmpersand = 38,    // &
        KeyApostrophe = 39,   // '
        KeyLeftParen = 40,    // (
        KeyRightParen = 41,   // )
        KeyAsterisk = 42,     // *
        KeyPlus = 43,         // +
        KeyComma = 44,        // ,
        KeyMinus = 45,        // -
        KeyPeriod = 46,       // .
        KeySlash = 47,        // /
        Key0 = 48,            // 0
        Key1 = 49,            // 1
        Key2 = 50,            // 2
        Key3 = 51,            // 3
        Key4 = 52,            // 4
        Key5 = 53,            // 5
        Key6 = 54,            // 6
        Key7 = 55,            // 7
        Key8 = 56,            // 8
        Key9 = 57,            // 9
        KeyColon = 58,        // :
        KeySemicolon = 59,    // ;
        KeyLess = 60,         // <
        KeyEqual = 61,        // =
        KeyGreater = 62,      // >
        KeyQuestion = 63,     // ?
        KeyAtSign = 64,       // @
        KeyA = 65,            // a
        KeyB = 66,            // b
        KeyC = 67,            // c
        KeyD = 68,            // d
        KeyE = 69,            // e
        KeyF = 70,            // f
        KeyG = 71,            // g
        KeyH = 72,            // h
        KeyI = 73,            // i
        KeyJ = 74,            // j
        KeyK = 75,            // k
        KeyL = 76,            // l
        KeyM = 77,            // m
        KeyN = 78,            // n
        KeyO = 79,            // o
        KeyP = 80,            // p
        KeyQ = 81,            // q
        KeyR = 82,            // r
        KeyS = 83,            // s
        KeyT = 84,            // t
        KeyU = 85,            // u
        KeyV = 86,            // v
        KeyW = 87,            // w
        KeyX = 88,            // x
        KeyY = 89,            // y
        KeyZ = 90,            // z
        KeyLeftBracket = 91,  // [
        KeyBackslash = 92,    // '\'
        KeyRightBracket = 93, // ]
        KeyCaret = 94,        // ^
        KeyUnderscore = 95,   // _
        KeyGrave = 96,        // `
        KeyLeftCurly = 123,   // {
        KeyBar = 124,         // |
        KeyRightCurly = 125,  // }
        KeyTilde = 126,       // ~
        KeyDel = 127,       // DEL (Ctrl + Backspace)
        KeyF1 = 128,
        KeyF2 = 129,
        KeyF3 = 130,
        KeyF4 = 131,
        KeyF5 = 132,
        KeyF6 = 134,
        KeyF7 = 135,
        KeyF8 = 136,
        KeyF9 = 137,
        KeyF10 = 138,
        KeyF11 = 139,
        KeyF12 = 140,
        KeyNumpad0 = 141,
        KeyNumpad1 = 142,
        KeyNumpad2 = 143,
        KeyNumpad3 = 144,
        KeyNumpad4 = 145,
        KeyNumpad5 = 146,
        KeyNumpad6 = 147,
        KeyNumpad7 = 148,
        KeyNumpad8 = 149,
        KeyNumpad9 = 150,
        KeyLast
    };

    enum LogLevel : uint8_t
    {
        LogFine = 0,
        LogDebug,
        LogInfo,
        LogWarning,
        LogError,
        LogFatal
    };

    enum AspectRatioMode : uint8_t
    {
        IgnoreAspectRatio,
        KeepAspectRatio,
        KeepAspectRatioByExpanding
    };

    enum AlignmentFlag : uint32_t
    {
        AlignNone = 0,
        AlignLeft = 1 << 0,
        AlignRight = 1 << 1,
        AlignTop = 1 << 2,
        AlignBottom = 1 << 3,
        AlignHorizontalCenter = 1 << 4,
        AlignVerticalCenter = 1 << 5,
        AlignTopLeft = AlignTop | AlignLeft, // 5
        AlignTopRight = AlignTop | AlignRight, // 6
        AlignBottomLeft = AlignBottom | AlignLeft, // 9
        AlignBottomRight = AlignBottom | AlignRight, // 10
        AlignLeftCenter = AlignLeft | AlignVerticalCenter, // 33
        AlignRightCenter = AlignRight | AlignVerticalCenter, // 34
        AlignTopCenter = AlignTop | AlignHorizontalCenter, // 20
        AlignBottomCenter = AlignBottom | AlignHorizontalCenter, // 24
        AlignCenter = AlignVerticalCenter | AlignHorizontalCenter // 48
    };

    enum AnchorEdge : uint8_t
    {
        AnchorNone = 0,
        AnchorTop,
        AnchorBottom,
        AnchorLeft,
        AnchorRight,
        AnchorVerticalCenter,
        AnchorHorizontalCenter
    };

    enum FocusReason : uint8_t
    {
        MouseFocusReason = 0,
        KeyboardFocusReason,
        ActiveFocusReason,
        OtherFocusReason
    };

    enum AutoFocusPolicy : uint8_t
    {
        AutoFocusNone = 0,
        AutoFocusFirst,
        AutoFocusLast
    };

    enum InputEventType : uint8_t
    {
        NoInputEvent = 0,
        KeyTextInputEvent,
        KeyDownInputEvent,
        KeyPressInputEvent,
        KeyUpInputEvent,
        MousePressInputEvent,
        MouseReleaseInputEvent,
        MouseMoveInputEvent,
        MouseWheelInputEvent
    };

    enum MouseButton : uint8_t
    {
        MouseNoButton = 0,
        MouseLeftButton,
        MouseRightButton,
        MouseMidButton,
        MouseXButton
    };

    enum MouseWheelDirection : uint8_t
    {
        MouseNoWheel = 0,
        MouseWheelUp,
        MouseWheelDown
    };

    enum KeyboardModifier : uint8_t
    {
        KeyboardNoModifier = 0,
        KeyboardCtrlModifier = 1,
        KeyboardAltModifier = 2,
        KeyboardShiftModifier = 4
    };

    enum WidgetState : int32_t
    {
        InvalidState = -1,
        DefaultState = 0,
        ActiveState = 1 << 0,
        FocusState = 1 << 1,
        HoverState = 1 << 2,
        PressedState = 1 << 3,
        DisabledState = 1 << 4,
        CheckedState = 1 << 5,
        OnState = 1 << 6,
        FirstState = 1 << 7,
        MiddleState = 1 << 8,
        LastState = 1 << 9,
        AlternateState = 1 << 10,
        DraggingState = 1 << 11,
        HiddenState = 1 << 12,
        LastWidgetState = 1 << 13
    };
}
