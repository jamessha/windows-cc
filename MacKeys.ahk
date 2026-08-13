#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------------------------------------------------------
; Mac-style editing shortcuts: the Win key stands in for Cmd, so copy, paste
; and select-all sit under the same thumb position as they do on macOS.
;
;   Win+C -> Ctrl+C   Win+V -> Ctrl+V   Win+A -> Ctrl+A   Win+R -> Ctrl+R
;   Win+T -> Ctrl+T   Win+Shift+T -> Ctrl+Shift+T
; ---------------------------------------------------------------------------

#c::MacKey("c")
#v::MacKey("v")
#a::MacKey("a")
#r::MacKey("r")   ; refresh; replaces the Run dialog
#t::MacKey("t")   ; new tab; replaces taskbar cycling

; No separate handling needed for Shift: MacKey sends {Blind}, which leaves the
; Shift you're already holding untouched, so this comes out as Ctrl+Shift+T.
#+t::MacKey("t")

MacKey(key) {
    ; Windows opens the Start menu when Win is pressed and released with
    ; nothing in between -- and sending Ctrl+C requires letting go of Win.
    ; vkE8 is an unassigned virtual key: tapping it while Win is still down
    ; makes Windows count this as "Win + something" and suppress the menu.
    Send "{Blind}{vkE8}"

    ; Release Win for Windows' benefit, then send the real shortcut. We never
    ; press Win back down -- AutoHotkey ignores its own injected input, so it
    ; still sees the key as held and holding Win to repeat the shortcut works.
    Send "{Blind}{LWin up}{LCtrl down}{" key "}{LCtrl up}"
}

A_IconTip := "Mac-style Edit Keys (Win+C/V/A)"
A_TrayMenu.Insert("1&", "Reload", (*) => Reload())
