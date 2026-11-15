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
| right edge | 4 × full height | `qs ipc call powermenu toggle` |
| bottom edge | full width × 4 | `qs ipc call dashboard toggle` |
| bottom-right corner | 8 × 8 | `dashboard close`, then `wallpaper toggle` |

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
- **Corners are created after the edges.** On the same layer the later window
  wins the pointer, so the bottom-right corner is reachable where it overlaps
  the bottom/right strips.
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

## Verify

```bash
hyprctl layers | grep hotedge
# right    1916 0    4x1080
# bottom   0    1076 1920x4
# bottomRight 1912 1072 8x8
```

Hover test needs real pointer motion (`/dev/uinput`), because
`hyprctl dispatch movecursor` no longer exists in 0.57 and would not drive QML
hover anyway:

```bash
python3 ~/.config/quickshell/tools/uclick.py --move 1916 1076   # corner
sleep 0.5; qs ipc call wallpaper isOpen                          # true
```

On 2026-11-15 this was blocked: the box was running kernel 7.2.15 while only
the 7.3.4 module tree was installed, so `uinput` could not be loaded
(`/dev/uinput` opened with `ENODEV`). Geometry was verified; the hover run is
pending the reboot into 7.3.4.

## Files

| Path | What |
|---|---|
| `modules/hotcorners/HotCorners.qml` | the zones |
| `shell.qml` | created after `TopBar`, before the sheets |
| `modules/lock/LockState.qml` | why the zones hide while locked |
