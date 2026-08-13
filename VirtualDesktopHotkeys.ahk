#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------------------------------------------------------
; Win+1 .. Win+6  ->  jump straight to virtual desktop 1..6.
; If that desktop doesn't exist, the hotkey does nothing.
;
; How it works: Windows exposes no "go to desktop N" hotkey, so we read the
; desktop list and the current desktop out of the registry, then send
; Win+Ctrl+Left/Right the right number of times. No undocumented COM
; interfaces, so this survives Windows updates.
; ---------------------------------------------------------------------------

HopDelay   := 40    ; ms between each Win+Ctrl+Left/Right hop
StaleAfter := 500   ; ms to trust our own prediction before re-reading registry

predictedIndex := 0
predictedAt    := 0

#1::GoToDesktop(1)
#2::GoToDesktop(2)
#3::GoToDesktop(3)
#4::GoToDesktop(4)
#5::GoToDesktop(5)
#6::GoToDesktop(6)

GoToDesktop(target) {
    global predictedIndex, predictedAt, HopDelay, StaleAfter

    info := GetDesktopInfo()
    if !info
        return

    current := info.current

    ; Explorer writes CurrentVirtualDesktop only after the switch animation
    ; finishes, so during a fast burst of presses trust where we just went.
    if (predictedIndex && A_TickCount - predictedAt < StaleAfter && predictedIndex <= info.count)
        current := predictedIndex

    if (!current || target > info.count || target = current)
        return

    delta := target - current
    key   := delta > 0 ? "{Right}" : "{Left}"

    ; {Blind} leaves the Win key the user is already holding untouched --
    ; pressing/releasing it ourselves would confuse later hotkeys in the same
    ; hold and can pop the Start menu.
    Send "{Blind}{LCtrl down}"
    Loop Abs(delta) {
        Send "{Blind}" key
        Sleep HopDelay
    }
    Send "{Blind}{LCtrl up}"

    predictedIndex := target
    predictedAt    := A_TickCount
}

; Returns {count, current} where current is a 1-based index, or 0 if the
; registry layout isn't what we expect.
GetDesktopInfo() {
    static root := "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"

    ids := ""
    try ids := RegRead(root "\VirtualDesktops", "VirtualDesktopIDs")
    if (ids = "")
        return 0

    ; REG_BINARY comes back as a hex string: 16 bytes / 32 chars per GUID.
    cur := ""
    try cur := RegRead(root "\VirtualDesktops", "CurrentVirtualDesktop")
    if (cur = "")
        try cur := RegRead(root "\SessionInfo\1\VirtualDesktops", "CurrentVirtualDesktop")

    index := 0
    if (cur != "" && (pos := InStr(ids, cur)))
        index := (pos - 1) // 32 + 1

    return { count: StrLen(ids) // 32, current: index }
}

A_IconTip := "Virtual Desktop Hotkeys (Win+1..6)"
tray := A_TrayMenu
tray.Insert("1&", "Reload", (*) => Reload())
