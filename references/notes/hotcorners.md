# Hot corners & edges (shell)

Edge/corner hover triggers implemented **in quickshell**, not in the
compositor: no Hyprland patch, no ABI rebuild after a compositor update, and the
same file works on any wlroots compositor.

Back to [notes index](README.md) - [docs index](../README.md)

## Shape

`modules/hotcorners/HotCorners.qml` — one tiny transparent `PanelWindow` per
zone per screen:

| Zone | Size | Action |
|---|---|---|
| right edge | 4 × (height − 8) | `qs ipc call powermenu toggle` |
| bottom edge | (width − 8) × 4 | `qs ipc call dashboard toggle` |
| bottom-right corner | 8 × 8 | `dashboard close`, then `wallpaper toggle` |

The strips are trimmed by `cornerPx` so they stop where the corner square
begins — they must never overlap (see the stacking trap below).

A layer surface only sees the pointer while the pointer is over it, so a zone
must be its own surface at the screen edge — there is no global pointer
position to poll in 0.3.2.

```qml
PanelWindow {
    WlrLayershell.layer: WlrLayer.Top        // NOT Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    anchors { right: true; top: true; bottom: true }
    implicitWidth: 4

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton          // hover only: the zone is not a button
        onEntered: dwell.restart()
        onExited: dwell.stop()
    }
    Timer { id: dwell; interval: 300; onTriggered: if (area.containsMouse) fire() }
}
```

## Why these choices

- **`WlrLayer.Top`, not `Overlay`.** Hyprland draws fullscreen windows above
  top-layer surfaces (the bar lives there too), so a fullscreen video or game
  swallows the pointer and every zone goes quiet — fullscreen suppression with
  no state to consult. `Overlay` would sit above fullscreen and steal the
  pointer there.
- **Hover + a 300 ms dwell.** The pointer crosses corners on the way elsewhere;
  firing on contact is a feature you turn off within a day.
- **The strips never overlap the corner square.** Each edge is anchored with a
  `margins` trim of `cornerPx` on the side that touches a corner. Relying on
  creation order was wrong: same-layer surfaces do not stack in creation order,
  so an overlapping bottom strip took the pointer at the corner and fired the
  dashboard there.
- **A fired zone goes cold until the pointer moves.** Escape closes a sheet but
  leaves the pointer inside the zone; the sheet unmapping makes the surface
  re-enter, and the dwell would reopen it 300 ms later. `cold` is cleared only
  when the pointer travels more than 6 px from the fire position.
- **Unassigned zones are not created at all.** A window with no action would
  still swallow clicks in its band.
- **`visible: !LockState.locked`.** The compositor does not suppress a shell
  surface while the session is locked, and keybinds *are* blocked, so a hover
  zone is the only way to open something behind the lock — see
  [quickshell.md](quickshell.md) and `modules/lock/LockState.qml`.
- **Actions are IPC calls**, the same strings the keybinds use, so the zones
  cannot drift from `SUPER + ESCAPE` / `SUPER + D` / `SUPER + SHIFT + W`.

## Trap: a case-sensitive suffix test made a full-screen surface

The first version derived the anchors from
`side.endsWith("Right")`. `"right"` is lowercase, so the *right edge* matched
neither `Left` nor `Right` and got `anchors.left + anchors.right` — a
1920 × 1080 transparent surface on the top layer that swallowed every click.

Debug signature: `hyprctl layers` showed
`quickshell:hotedge:right  0 0 1920 1080` instead of `1916 0 4 1080`.
Fix: explicit lists per side (`side === "right" || side === "topRight" || …`).

## Trap: an overlapping strip won the corner

The first working version let the strips run the full screen and put the 8 × 8
corner on top. `hyprctl layers` showed the right geometry, but hovering the
corner fired `dashboard toggle` (bottom strip) and the right edge fired
`wallpaper toggle`. Same-layer surfaces do **not** stack in creation order, so
overlap has no defined winner.

Debug signature: log the zone name in `onEntered` — the pointer entered
`bottom` and `right` before the corner. Fix: trim each strip by `cornerPx` at
the corner end, so each pixel belongs to exactly one zone.

## Trap: Escape reopened the sheet it closed

With the pointer still on the edge, `Escape` closed the sheet, the sheet
unmapped, the zone's `MouseArea` re-entered, and 300 ms later the same zone
fired again — the sheet could not be dismissed by keyboard. Fix: the `cold`
flag described above.

## Verify

```bash
hyprctl layers | grep hotedge
# right    1916 0    4x1080
# bottom   0    1076 1920x4
# bottomRight 1912 1072 8x8
```

Hover needs real pointer motion (`/dev/uinput`): `hyprctl dispatch movecursor`
no longer exists in 0.57 and would not drive QML hover anyway. **Approach each
zone from its own side** — `uclick.py` moves in 24 px steps, so a diagonal from
the centre reaches the bottom row early and crawls *along* the bottom strip into
the corner, firing the dashboard first:

```bash
python3 ~/.config/quickshell/tools/uclick.py --move 1800 500    # park east of centre
python3 ~/.config/quickshell/tools/uclick.py --move 1918 500    # right edge
sleep 1; qs ipc call powermenu isOpen                           # true
```

Measured 2026-11-15 (kernel 7.3.4, compositor `2ea169764`):

| Approach | Opened | After `Escape` |
|---|---|---|
| park (1800,500) → (1918,500) | session menu | closed, stays closed |
| park (900,700) → (900,1078) | dashboard | closed, stays closed |
| park (1700,860) → (1916,1076) | wallpaper picker | closed, stays closed |

`uinput` needed one manual `sudo modprobe uinput` after the reboot (no udev
autoload rule), and `/dev/uinput` is udev-`uaccess`-owned so no root is needed
to write to it.

## Files

| Path | What |
|---|---|
| `modules/hotcorners/HotCorners.qml` | the zones |
| `shell.qml` | created after `TopBar`, before the sheets |
| `modules/lock/LockState.qml` | why the zones hide while locked |
