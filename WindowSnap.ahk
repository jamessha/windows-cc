#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------------------------------------------------------
; Win+Left   -> left 60%   (0% -> 60%)
; Win+Right  -> right 60%  (40% -> 100%)
; Win+Up     -> centered 50% (25% -> 75%)
;
; Snaps within whichever monitor the window is currently on, respects the
; taskbar, and compensates for the invisible resize border Windows puts
; around most windows (without that, snapped edges sit ~7px off).
; ---------------------------------------------------------------------------

#Left::Snap(0.00, 0.60)
#Right::Snap(0.40, 1.00)
#Up::Snap(0.25, 0.75)

Snap(fromFrac, toFrac) {
    hwnd := WinExist("A")
    if (!hwnd || IsShellWindow(hwnd))
        return

    ; A maximized or minimized window ignores WinMove until it's restored.
    if (WinGetMinMax(hwnd) != 0) {
        WinRestore hwnd
        Sleep 60          ; let the restore animation settle before measuring
    }

    area := GetWorkArea(hwnd)
    x := area.l + Round(area.w * fromFrac)
    w := Round(area.w * (toFrac - fromFrac))

    ; Ask for the *visible* rectangle; MoveVisible converts to the real one.
    MoveVisible(hwnd, x, area.t, w, area.h)
}

; Move a window so its visible edges land exactly on the given rectangle.
; WinMove works on the window rect, which for most modern windows is a few
; pixels larger on the left/right/bottom than what you actually see.
MoveVisible(hwnd, x, y, w, h) {
    off := FrameOffsets(hwnd)
    try WinMove x - off.l, y - off.t, w + off.l + off.r, h + off.t + off.b, hwnd
}

FrameOffsets(hwnd) {
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9
    none := { l: 0, t: 0, r: 0, b: 0 }

    rect := Buffer(16, 0)
    if (DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd
        , "uint", DWMWA_EXTENDED_FRAME_BOUNDS, "ptr", rect, "uint", 16) != 0)
        return none

    try WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    catch
        return none

    return { l: NumGet(rect,  0, "int") - wx
           , t: NumGet(rect,  4, "int") - wy
           , r: (wx + ww) - NumGet(rect,  8, "int")
           , b: (wy + wh) - NumGet(rect, 12, "int") }
}

; Work area (screen minus taskbar) of the monitor holding the window's centre.
GetWorkArea(hwnd) {
    WinGetPos(&x, &y, &w, &h, hwnd)
    cx := x + w // 2
    cy := y + h // 2

    Loop MonitorGetCount() {
        MonitorGet(A_Index, &ml, &mt, &mr, &mb)
        if (cx >= ml && cx < mr && cy >= mt && cy < mb) {
            MonitorGetWorkArea(A_Index, &l, &t, &r, &b)
            return { l: l, t: t, w: r - l, h: b - t }
        }
    }

    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    return { l: l, t: t, w: r - l, h: b - t }
}

IsShellWindow(hwnd) {
    static shell := Map("Progman", 1, "WorkerW", 1, "Shell_TrayWnd", 1)
    try return shell.Has(WinGetClass(hwnd))
    return true
}

A_IconTip := "Window Snap (Win+Left/Right/Up)"
A_TrayMenu.Insert("1&", "Reload", (*) => Reload())
