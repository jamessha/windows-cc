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
;   Win+F -> Ctrl+F (find)
;
; Plus emacs-style line movement, as on macOS where Ctrl+A/Ctrl+E move within
; the line and Cmd+A selects all:
;
;   Ctrl+A -> Home   Ctrl+E -> End
; ---------------------------------------------------------------------------

#c::MacKey("c")
#v::MacKey("v")
#a::MacKey("a")
#r::MacKey("r")   ; refresh; replaces the Run dialog
#t::MacKey("t")   ; new tab; replaces taskbar cycling
#w::MacKey("w")   ; close tab/window; replaces the Widgets board
#f::MacKey("f")   ; find; replaces the Feedback Hub

; No separate handling needed for Shift: MacKey sends {Blind}, which leaves the
; Shift you're already holding untouched, so this comes out as Ctrl+Shift+T.
#+t::MacKey("t")
#+n::MacKey("n")   ; incognito window in Chrome

; Fires on button-down, so a Win+drag becomes a plain click rather than a drag.
#LButton::MacClick()

; True while MacKey is emitting its Ctrl+<key>.
;
; Win+A works by sending a synthetic Ctrl+A, and ^a:: below catches it -- so
; Win+A moved the caret Home instead of selecting all. AutoHotkey normally
; stops a script's own generated input from firing its hotkeys, but it does
; not hold here, so the guard is explicit. Measured with EM_GETSEL on "abc":
; selection came back 0,0 with ^a:: live, and 0,3 with it disabled.
Emitting := false

; Emacs-style line movement. Select-all still works, on Win+A above.
#HotIf !Emitting
^a::LineKey("Home")
^e::LineKey("End")
#HotIf

MacKey(key) {
    global Emitting
    Emitting := true
    try {
        DropWin()
        Send "{Blind}{LCtrl down}{" key "}{LCtrl up}"
    }
    finally {
        Emitting := false      ; never leave the line keys wedged off
        RestoreWin()
    }
}

; Ctrl has to come up first: held down, these arrive as Ctrl+Home / Ctrl+End,
; which jump to the start/end of the whole document rather than the line.
; Both sides are released since either Ctrl key can be the one held.
LineKey(key) {
    Send "{Blind}{LCtrl up}{RCtrl up}{" key "}"
}

MacClick() {
    DropWin()
    Send "{Blind}{LCtrl down}"
    Click                       ; no coords: clicks wherever the cursor already is
    Send "{Blind}{LCtrl up}"
    RestoreWin()
}

; Let go of the Win key the user is physically holding, without the Start menu
; appearing. Windows opens it whenever Win is pressed and released with nothing
; in between, and sending Ctrl+<key> requires releasing Win. vkE8 is an
; unassigned virtual key: tapping it while Win is still down makes Windows
; count the hold as "Win + something" and suppress the menu.
DropWin() {
    Send "{Blind}{vkE8}"
    Send "{Blind}{LWin up}{RWin up}"
}

; Put the Win key back down afterwards.
;
; Releasing it above also clears the state hotkeys are matched against, so a
; second shortcut in the same Win hold stops matching and leaks a raw character
; into whatever has focus -- hold Win and tap F twice and the second types "f".
; Measured before this: logical went 1 -> 0 across the send and stayed 0.
;
; Only restore a side still PHYSICALLY held. Pressing Win back down after the
; user let go would leave every later keystroke a Win+ combination. The
; trailing mask key keeps the Start menu shut on the eventual release.
;
; Physical state is also why this cannot be tested with synthetic input:
; AutoHotkey excludes injected keys from physical state, so a scripted Win
; hold always reads as up. Only a real keypress exercises this path.
RestoreWin() {
    if GetKeyState("LWin", "P")
        Send "{Blind}{LWin down}{vkE8}"
    else if GetKeyState("RWin", "P")
        Send "{Blind}{RWin down}{vkE8}"
}
