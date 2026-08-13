# windows-cc

Two small AutoHotkey v2 scripts that give Windows 11 a couple of macOS-style
window/desktop shortcuts it doesn't ship with:

| Script | What it does |
| --- | --- |
| [`VirtualDesktopHotkeys.ahk`](VirtualDesktopHotkeys.ahk) | `Win`+`1`..`6` jump straight to that virtual desktop |
| [`WindowSnap.ahk`](WindowSnap.ahk) | `Win`+`←`/`→`/`↑` snap the active window to fixed fractions of the screen |
| [`MacKeys.ahk`](MacKeys.ahk) | `Win`+`C`/`V`/`A` act as Mac-style copy, paste and select-all |

They're independent — run any one on its own.

## Requirements

- Windows 11
- [AutoHotkey v2](https://www.autohotkey.com/) (v2 syntax; these will not run under v1)

## Install

Double-click either `.ahk` file to run it. To start them at login, drop a
shortcut to each into the startup folder — paste `shell:startup` into the Run
dialog (`Win`+`R`) to open it, then point the shortcut at:

```
"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "<path>\WindowSnap.ahk"
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

The Win key sits roughly where Cmd does on a Mac keyboard, so this puts the
common editing shortcuts back under the same thumb.

**Overrides:** `Win`+`V` is clipboard history, `Win`+`A` is Quick Settings, and
`Win`+`C` opens Copilot.

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

Right-click the tray icon → **Exit**, and delete the shortcut from
`shell:startup`.
