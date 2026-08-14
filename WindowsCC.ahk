#Requires AutoHotkey v2.0
#SingleInstance Force

; ---------------------------------------------------------------------------
; Single entry point for all three utilities, so they share one process, one
; tray icon and one startup entry.
;
; Each included file is still a complete script and can be run on its own if
; you only want that piece -- it just won't carry the custom tray tip below.
; ---------------------------------------------------------------------------

#Include %A_ScriptDir%\VirtualDesktopHotkeys.ahk
#Include %A_ScriptDir%\WindowSnap.ahk
#Include %A_ScriptDir%\MacKeys.ahk

A_IconTip := "windows-cc — virtual desktops, window snapping, Mac keys"
A_TrayMenu.Insert("1&", "Reload", (*) => Reload())
