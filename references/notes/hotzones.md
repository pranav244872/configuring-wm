# Hot Zones (edge/corner)

Edge/corner hot zones are **native to the fork** (not a plugin): resting the
cursor against a bezel runs a dispatcher. Read before changing
`~/.config/hypr/modules/hotzones.lua` or `src/managers/HotZoneManager.*`.

Back to [notes index](README.md) - [docs index](../README.md)

## Config (`hotzone:*`, set from `modules/hotzones.lua`)

| Key | Default | Meaning |
|---|---|---|
| `hotzone:enabled` | `false` | **master switch** |
| `hotzone:dwell_ms` | `400` | rest time in a zone before firing (`0` = instant) |
| `hotzone:trigger_px` | `12` | zone thickness at the bezel, in px |
| `hotzone:rearm_margin_px` | `24` | travel *out* of a fired zone before it can fire again |
| `hotzone:corner_margin_px` | `10` | corners carve this much out of the neighbouring **edge** zones |
| `hotzone:slam` | `false` | corners fire instantly on the exact bezel pixel, bypassing the dwell |
| `hotzone:suppress_on_fullscreen` | `true` | skip while a covering fullscreen window is on that monitor |
| `<zone>:enabled` | `true` | per-zone switch |
| `<zone>:action` | `""` | `"<dispatcher>, <args>"`; an **empty action makes the zone inert** (it still locks out after firing) |
| `<zone>:dwell_ms` | `-1` | per-zone override (`-1` = use the global) |

Zones (8): `topleft` `topright` `bottomleft` `bottomright` `top` `bottom` `left` `right`.
Actions may use any registered dispatcher — `exec, <shell command>` is the usual one.

## Geometry

- A zone is the outer `trigger_px` of the monitor. Corners are `trigger_px`
  **squares**; edges are `trigger_px` strips that skip `corner_margin_px` at both
  ends so corners never clip.
- **Slam** is **opt-in** (`hotzone:slam`, default `false`) and corner-only: with it
  on, the exact outermost pixel of a **corner** fires immediately, bypassing the
  dwell. Off by default so every zone waits out the configured `dwell_ms` — an
  edge is a line the cursor clamps onto while dragging, and a slam there fires by
  accident.
- An edge with a monitor neighbour outside it is a shared/internal boundary and
  does **not** fire.
- Suppressed while: the session is locked, input is constrained (an exclusive
  layer surface has focus), a mouse button is held, or a covering fullscreen
  window is on that monitor.
- Only **entering** a zone is reported. There is no zone-exit event, so pair
  zones with something that closes itself (Escape / click-away).

## Runtime API

- Lua (for keybinds): `hl.hotzone.enable()` / `disable()` / `toggle_active()` /
  `is_enabled()`.
- Dispatcher: `hotzone <enable|disable|toggle>`.
- `isActive = hotzone:enabled AND runtime flag`, so the runtime API can only turn
  it *further off* — the config key is the master.
- From the shell only the Lua form works: `hyprctl dispatch 'hl.dsp.exit()'`;
  bare dispatcher names (`hyprctl dispatch exit`) are rejected by the fork.

## Where it lives (fork, branch `feat/hotzones`)

- `src/managers/HotZoneManager.{hpp,cpp}` — zone detection, dwell timer, slam,
  re-arm, suppression, action run through `KeybindManager::m_dispatchers`.
- Hooked from `InputManager::mouseMoveUnified`, after the `PMONITOR` null-check,
  gated on real mouse motion (warp/refocus paths pass `overridePos`).
- Created in `Compositor` at `STAGE_LATE`, reset in `cleanup()`.
- Committed as `9f7a38c7`.

## Our use: right edge opens the session menu

```lua
right = { action = "exec, qs ipc call powermenu toggle" },
```

## Our use: bottom edge opens the dashboard

```lua
bottom = { action = "exec, qs ipc call dashboard toggle" },
```

## Our use: bottom-right corner opens the wallpaper picker

```lua
bottomright = { action = "exec, qs ipc call dashboard close; qs ipc call wallpaper toggle" },
```

Corners win over the edges they sit in (`zoneAt` tests the four corners first),
so this does not steal the `right` (session menu) or `bottom` (dashboard) zones.
Both are bottom sheets, so the dashboard is closed first — two stacked reads as a
bug.

## Trap: the dwell counts *residence*, not rest

The config prose says "rest the cursor against a bezel", but the implementation
arms the timer on **zone entry** and fires while the cursor is still moving:
`onCursorMoved` early-returns once `ZONE == m_activeZone`, so continued motion
inside a zone neither restarts nor cancels the countdown.

Consequence for a corner that shares an edge: a cursor sliding **along** the
bottom edge toward the bottom-right corner spends its 300 ms in the `bottom`
zone first → the dashboard opens → and because `isSuppressed()` is checked
*before* `zoneAt()`, the sheet's exclusive keyboard layer surface now suppresses
**every** zone, so the corner can never fire at all. Measured 2026-10-19: the
dashboard opened between x=600→1000 at y=1075, the cursor then sat at (1917,1075)
— inside the corner's 12 px square — and `wallpaper isOpen` stayed false.

- **Not fixable from config**: a per-zone `dwell_ms = 0` on the corner fires
  instantly but still loses once the edge's timer has already fired (the
  suppression check comes first). Enlarging `corner_margin_px` only shifts where
  the edge zone *ends*, and the timer starts at entry.
- **Workaround**: approach the corner **directly** (diagonally). A diagonal
  reaches the bottom strip only in its last few px, so the edge's 300 ms never
  elapses. Verified live for all three zones.
- **The real fix** (not taken, user's call 2026-10-19) is in the fork: re-arm the
  dwell on every motion event inside the zone, i.e. make it measure a *rest*.
  That needs a rebuild + a Hyprland restart, so it was left alone.

## Trap: a locked session does **not** suppress the zones

`isSuppressed()` tests `g_pInputManager->isLocked()` for the "session is locked"
case, but in this codebase that function means **"a pointer constraint is
active"** — a game or window locking the cursor:

```cpp
bool CInputManager::isLocked() {
    if (!isConstrained()) return false;   // isConstrained() == a constraint owns the focused surface
    ...
    return CONSTRAINT && CONSTRAINT->isLocked();
}
```

So a session lock suppresses nothing, and resting on an edge while locked still
runs its action. Verified 2026-10-19: with the login card up, pushing into the
bottom-right corner opened the wallpaper picker *behind* the lock, and it was
still open after unlocking. Keybinds are a non-issue — Hyprland blocks them
while a session lock is up — so the hot zones are the only leak.

- The one-line fork fix is to test the protocol state instead:
  `g_pSessionLockManager->isSessionLocked()` (`SessionLockManager.cpp:143` →
  `PROTO::sessionLock->isLocked()`). Needs a rebuild + a Hyprland restart.
- What we do instead (no rebuild): `modules/lock/LockState.qml` is set by the
  lock host's `engage()`/`disengage()`, and the three hosts refuse to open while
  it is set, and close themselves when a lock starts.
- Either way, test it by locking and then driving each zone with injected
  motion; watch for a sheet that opens behind the card.

## Verifying / rolling back

- After arming: `hyprctl configerrors` must be empty (the *running* binary must
  know the keys — an older binary logs "unknown config key"). A per-zone key that
  does *not* exist answers "no such option" to `hyprctl getoption`, which is how
  to tell a live key from a stale binary.
- Push the cursor into the zone with real injected motion
  (`python3 ~/.config/quickshell/tools/uclick.py --move X Y`); the action fires.
  `hyprctl dispatch movecursor` does **not** drive them. Integration is easy to
  confirm with a logging action (`exec, sh -c 'echo hit >> /tmp/hz.log'`), and
  watch *both* sheets — a fired zone can suppress the one you are testing for.
- Getting to a corner: park just *outside* every zone first (e.g.
  `(1895, 1060)` for the bottom-right), then move straight in.
- Disarm: `enabled = false` (reloads live). Roll the compositor back:
  `sudo cp -a /usr/bin/Hyprland.bak /usr/bin/Hyprland` then restart Hyprland.
