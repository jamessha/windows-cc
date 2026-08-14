# windows-cc

Three small AutoHotkey v2 scripts that give Windows 11 the macOS-style window,
desktop and editing shortcuts it doesn't ship with:

| Script | What it does |
| --- | --- |
| [`VirtualDesktopHotkeys.ahk`](VirtualDesktopHotkeys.ahk) | `Win`+`1`..`6` jump straight to that virtual desktop |
| [`WindowSnap.ahk`](WindowSnap.ahk) | `Win`+`←`/`→`/`↑` snap the active window to fixed fractions of the screen |
| [`MacKeys.ahk`](MacKeys.ahk) | Mac-style editing and tab shortcuts — `Win` stands in for `Cmd` on `C`/`V`/`A`/`R`/`T`/`W` and their `Shift` variants |

[`WindowsCC.ahk`](WindowsCC.ahk) is the entry point: it `#Include`s all three so
they share one process, one tray icon and one startup entry. Each file is still
a complete script, so you can run just one on its own — it simply won't carry
the custom tray tip the launcher sets.

## Requirements

- Windows 11
- [AutoHotkey v2](https://www.autohotkey.com/) (v2 syntax; these will not run under v1)

## Install

Double-click `WindowsCC.ahk` to run everything. To start it at login, put a
shortcut in the startup folder — open the Run dialog from `Win`+`X` → Run
(`Win`+`R` is remapped once these are loaded), paste `shell:startup`, and point
the shortcut at:

```
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "<path>\WindowsCC.ahk"
```

Because the shortcut references the scripts by path, edits take effect on next
login without touching it. After editing, right-click the tray icon → **Reload**.

A syntax error in any one file stops the whole launcher loading, so it's worth
checking a file before reloading:

```
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /validate "<path>\WindowsCC.ahk"
```

## VirtualDesktopHotkeys.ahk

| Key | Action |
| --- | --- |
| `Win`+`1` … `Win`+`6` | Switch to virtual desktop 1–6 |

Pressing a number higher than your current desktop count does nothing.

**Overrides:** `Win`+`1`..`6` normally launch or focus the first six apps pinned
to your taskbar. `Win`+`7` and up are untouched.

### How it works

Windows exposes no "go to desktop N" command, and the COM interface usually used
for this (`IVirtualDesktopManagerInternal`) has an unstable GUID that breaks on
most Windows build updates.

Instead the script reads two `REG_BINARY` values under
`HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops`:

- `VirtualDesktopIDs` — every desktop's GUID, 16 bytes each, in order
- `CurrentVirtualDesktop` — the GUID of the desktop you're on

Desktop count is `len(VirtualDesktopIDs) / 16`; the current index is the offset
of `CurrentVirtualDesktop` within that list. From there it sends
`Win`+`Ctrl`+`←`/`→` the required number of times. Nothing undocumented, so it
survives Windows updates.

Two details that matter:

- Explorer only writes `CurrentVirtualDesktop` *after* the switch animation
  finishes. During a fast burst of keypresses the registry is stale, so the
  script caches the desktop it just moved to for `StaleAfter` ms (default 500)
  and trusts that instead. Without this, mashing `Win`+`3` then `Win`+`1` reads
  a stale position and lands on the wrong desktop.
- Sends use `{Blind}` so the script never presses or releases the `Win` key
  you're physically holding. Managing it directly desynchronises the modifier
  state, which breaks the second hotkey in a single `Win` hold and can pop the
  Start menu on release.

### Tuning

At the top of the file:

- `HopDelay` (default `40`) — ms between hops. Raise to ~80 if a long jump
  (desktop 1 → 6) ever lands short.
- `StaleAfter` (default `500`) — how long to trust the cached index over the
  registry.

Long jumps animate each hop, so 1 → 6 is visibly slower than a direct switch. If
that becomes annoying, [`VirtualDesktopAccessor.dll`](https://github.com/Ciantic/VirtualDesktopAccessor)
wraps the COM interface for instant jumps — at the cost of needing an update
whenever Windows changes the interface.

## WindowSnap.ahk

| Key | Result | Fraction of work area |
| --- | --- | --- |
| `Win`+`←` | Left 60% | 0% → 60% |
| `Win`+`→` | Right 60% | 40% → 100% |
| `Win`+`↑` | Centered 50% | 25% → 75% |

Left and right deliberately overlap in the middle 20%.

Snapping happens on whichever monitor holds the window's centre, and respects
the work area, so the taskbar is never covered.

**Overrides:** `Win`+`↑` no longer maximizes, and `Win`+`←`/`→` no longer
trigger Snap Assist. `Win`+`↓` still minimizes/restores natively, and
double-clicking a title bar still maximizes.

### How it works

Three things a naive `WinMove` gets wrong:

- **Invisible resize borders.** `WinMove` positions the *window rect*, which for
  most modern windows extends a few pixels past the visible frame. Moving to
  `x=0` leaves a gap on the left and an overlap at the split. The script reads
  `DWMWA_EXTENDED_FRAME_BOUNDS` via `dwmapi`, diffs it against the window rect,
  and compensates — so edges land exactly where asked.
- **Maximized windows silently ignore `WinMove`.** It restores first, then waits
  for the animation to settle before measuring.
- **Multi-monitor.** It resolves the monitor from the window's centre point and
  uses that monitor's work area rather than the primary display's.

### Tuning

Edit the fractions in the hotkey lines:

```ahk
#Left::Snap(0.00, 0.60)    ; -> Snap(0.00, 0.50) for a half-width left snap
```

Then right-click the tray icon and choose **Reload**.

## MacKeys.ahk

| Key | Sends |
| --- | --- |
| `Win`+`C` | `Ctrl`+`C` (copy) |
| `Win`+`V` | `Ctrl`+`V` (paste) |
| `Win`+`A` | `Ctrl`+`A` (select all) |
| `Win`+`R` | `Ctrl`+`R` (refresh) |
| `Win`+`T` | `Ctrl`+`T` (new tab) |
| `Win`+`Shift`+`T` | `Ctrl`+`Shift`+`T` (reopen closed tab) |
| `Win`+`W` | `Ctrl`+`W` (close tab/window) |
| `Win`+`Shift`+`N` | `Ctrl`+`Shift`+`N` (incognito window in Chrome) |
| `Win`+click | `Ctrl`+click (open link in a new tab) |
| `Win`+`E` | `End` (end of line) |

The Win key sits roughly where Cmd does on a Mac keyboard, so this puts the
common editing shortcuts back under the same thumb.

The `Shift` variants need no special handling. `MacKey` sends with `{Blind}`,
which leaves a physically-held Shift untouched, so laying Ctrl on top of it
comes out as `Ctrl`+`Shift`+*key* on its own.

`Win`+click fires on button-down and emits a complete click, so holding Win and
dragging produces a plain click rather than a drag.

`Win`+`E` is the one binding that isn't `Win` → `Ctrl`. End-of-line on Windows
is the `End` key; `Ctrl`+`E` focuses the search box in Explorer and some
browsers, which isn't what you want. It goes through `BareKey` rather than
`MacKey` for that reason.

Every binding is global rather than scoped to a browser, so it forwards to
whatever app has focus — `Win`+`Shift`+`N` in File Explorer creates a new
folder, that being Explorer's own `Ctrl`+`Shift`+`N`. To limit one to Chrome,
wrap it in a context block:

```ahk
#HotIf WinActive("ahk_exe chrome.exe")
#+n::MacKey("n")
#HotIf
```

**Overrides:** `Win`+`V` is clipboard history, `Win`+`A` is Quick Settings,
`Win`+`C` opens Copilot, `Win`+`R` is the Run dialog (still reachable from
`Win`+`X` → Run), `Win`+`T` cycles taskbar buttons, `Win`+`W` opens the Widgets
board, and `Win`+`E` opens File Explorer (still on `Win`+`X` → File Explorer).

### What can't be rebound: Win+L

`Win`+`L` is handled below the low-level keyboard hook, so no AutoHotkey hotkey
can intercept it. The only way to free it is the registry policy
`DisableLockWorkstation=1`, and that disables *every* route to locking — the
`LockWorkStation()` API, the Start menu entry and the Ctrl+Alt+Del entry
included — so you cannot free `Win`+`L` and still bind a replacement lock
shortcut. Every other `Win`+*key* combination here rebinds normally.

### How it works

The awkward part is that `Win`+`C` has to send `Ctrl`+`C` *while the Win key is
physically held down*, which means releasing Win mid-shortcut. Windows opens the
Start menu whenever Win is pressed and released with nothing in between, so the
obvious `#c::Send "^c"` can leave the Start menu popping open on every copy.

The fix is to tap `vkE8` — an unassigned virtual key that does nothing — while
Win is still down. Windows then counts the hold as "Win + something" and
suppresses the menu. Only then does the script release Win and send the real
shortcut.

It deliberately never presses Win back down. AutoHotkey ignores its own injected
input, so it still considers the key held, and holding Win to repeat the
shortcut keeps working.

### Adding more

One line per shortcut, e.g. cut and undo:

```ahk
#x::MacKey("x")
#z::MacKey("z")
```

If you want Mac-style muscle memory generally rather than a handful of keys, the
usual approach is remapping the whole Win key to Ctrl and vice versa, which gets
`Win`+`T`, `Win`+`W`, `Win`+`L` and the rest for free. That's a much larger
behavioural change than this script makes.

## Caveats

- **Elevated windows won't move.** AutoHotkey can't manipulate windows owned by
  an admin-elevated process unless it's elevated too. To fix without a UAC
  prompt every login, run the scripts from a Task Scheduler task with *Run with
  highest privileges* instead of a startup shortcut.
- **AutoHotkey trips some antivirus products** and is blocked outright in some
  managed corporate environments, since it's general input automation. Not an
  issue on a personal machine.

## Uninstall

Right-click the tray icon → **Exit**, and delete `WindowsCC.lnk` from
`shell:startup`.
