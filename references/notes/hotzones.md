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
- **Slam** (corners only): resting on the exact outermost pixel of a **corner**
  fires immediately, bypassing the dwell. Edges deliberately do not slam — a
  dragged cursor clamps onto an edge line, so an edge slam fires by accident.
  Edges always wait out the dwell (the dashboard's bottom edge uses 900 ms).
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

## Verifying / rolling back

- After arming: `hyprctl configerrors` must be empty (the *running* binary must
  know the keys — an older binary logs "unknown config key").
- Push the cursor into the zone; the action fires. Integration is easy to
  confirm with a logging action (`exec, sh -c 'echo hit >> /tmp/hz.log'`).
- Disarm: `enabled = false` (reloads live). Roll the compositor back:
  `sudo cp -a /usr/bin/Hyprland.bak /usr/bin/Hyprland` then restart Hyprland.
