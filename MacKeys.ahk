#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------------------------------------------------------
; Mac-style editing shortcuts: the Win key stands in for Cmd, so copy, paste
; and select-all sit under the same thumb position as they do on macOS.
;
;   Win+C -> Ctrl+C   Win+V -> Ctrl+V   Win+A -> Ctrl+A   Win+R -> Ctrl+R
;   Win+T -> Ctrl+T   Win+Shift+T -> Ctrl+Shift+T   Win+W -> Ctrl+W
;   Win+Shift+N -> Ctrl+Shift+N (incognito window in Chrome)
;   Win+Click -> Ctrl+Click (open link in a new tab)
; ---------------------------------------------------------------------------

#c::MacKey("c")
#v::MacKey("v")
#a::MacKey("a")
#r::MacKey("r")   ; refresh; replaces the Run dialog
#t::MacKey("t")   ; new tab; replaces taskbar cycling
#w::MacKey("w")   ; close tab/window; replaces the Widgets board

; No separate handling needed for Shift: MacKey sends {Blind}, which leaves the
; Shift you're already holding untouched, so this comes out as Ctrl+Shift+T.
#+t::MacKey("t")
#+n::MacKey("n")   ; incognito window in Chrome

; Fires on button-down, so a Win+drag becomes a plain click rather than a drag.
#LButton::MacClick()

MacKey(key) {
    DropWin()
    Send "{Blind}{LCtrl down}{" key "}{LCtrl up}"
}

MacClick() {
    DropWin()
    Send "{Blind}{LCtrl down}"
    Click                       ; no coords: clicks wherever the cursor already is
    Send "{Blind}{LCtrl up}"
}

; Let go of the Win key the user is physically holding, without the Start menu
; appearing. Windows opens it whenever Win is pressed and released with nothing
; in between, and sending Ctrl+<key> requires releasing Win. vkE8 is an
; unassigned virtual key: tapping it while Win is still down makes Windows
; count the hold as "Win + something" and suppress the menu.
;
; We never press Win back down. AutoHotkey ignores its own injected input, so
; it still sees the key as held and holding Win to repeat the shortcut works.
DropWin() {
    Send "{Blind}{vkE8}"
    Send "{Blind}{LWin up}"
}

A_IconTip := "Mac-style Edit Keys (Win+C/V/A)"
A_TrayMenu.Insert("1&", "Reload", (*) => Reload())
