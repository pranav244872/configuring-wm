# Wallpaper cycling: a timer, in order or shuffled

The library advances itself while the session is idle: same apply path as a
pick, so the crossfade and the matugen palette refresh come along. The switch,
the interval and shuffle live in the picker's footer, and the palette changes
with every image by design.

Back to [notes index](README.md) - [docs index](../README.md)

## The scheduler

`WallpaperCycler.qml` (singleton, no visuals) + one `Timer`:

- `intervalMinutes` from presets **5 / 10 / 15 / 30 / 60 / 120** (default 30),
  `shuffle` (default off), `enabled` (default off).
- On tick it calls `WallpaperService.apply(pathAt(index))` — the very path a
  click takes. Nothing bypasses the service, so the two fixed background slots
  crossfade and `Scheme.sync` runs matugen exactly as for a manual choice.
- **Sequential** steps `(current + 1) % count` (wraps). **Shuffle** retries up
  to 8 random indices that differ from the current one, then falls back to the
  next slide — "never the same image twice" without a shuffle bag.
- Any change to `current` **restarts the countdown** (`appliedWatch`), so a
  fresh manual pick is not cycled away seconds later.
- Persisted to `~/.cache/quickshell/wallpaper-cycling.json`
  (`{"enabled":…,"shuffle":…,"intervalMinutes":…}`). `hydrated` gates writes so
  the defaults cannot clobber the file; `mock` keeps benches out of it.

## When it pauses

- **Locked** (`LockState.locked`) — the lock draws its own wallpaper and must
  not change under the card.
- **Picker open** — `WallpaperHost.onOpenChanged` sets `suspended`, so the
  desktop never changes under a sheet someone is browsing.
- Fewer than two images: nothing to cycle.
- **Fullscreen is not paused**: the installed Quickshell 0.3.2 exposes no
  toplevel fullscreen state here (the Hyprland qmltypes have none), so unlike
  DMS's `WallpaperCyclingService` a video is not protected. Documented debt.

`syncTimer()` starts/stops explicitly: binding `running` to a condition breaks
the moment `restart()` is called (the assignment overrides the binding).

**The condition is a function (`runnable()`), not a bound property.** A
`readonly property bool shouldRun` read from inside its own change handler
still returned the *old* value: `setCycling(true)` logged
`enabled=true … should=false` and left the timer stopped until an unrelated
change re-evaluated it (found 2026-10-20, verified by toggling over IPC).

## Surface

| Route | How |
|---|---|
| picker footer | `Toggle` + `AUTO` + interval (click the value to step presets) + `SHUFFLE` chip; sheet height 240 → **272** |
| manual step | `qs ipc call wallpaper cycleNext\|cyclePrev` |
| keyboard step | `SUPER + ALT + W` → `qs ipc call wallpaper cycleNext` (`keybinds.lua`, modmask 72) |
| settings | `qs ipc call wallpaper setCycling true\|false`, `setShuffle`, `setCycleInterval <min>` (clamped 1–1440), `nextCycleInterval` |
| introspection | `qs ipc call wallpaper cycleState` → `off` / `paused` / `running` / `idle` |

The footer sits under the strip inside the same frame; `AUTO` greys out when
cycling is off, and the interval value turns accent on hover.

## Cost

Each tick is a matugen run (~1 s of CPU plus a full desktop recolour). That is
the point of the rice, but it is why the default is **30 minutes** and the
shortest preset is 5 — a 1-minute cycle is a strobe.

## Verified live (2026-10-20)

Interval forced to 1 min → the tick advanced from `a_pixel_art_of_a_building.png`
to `a_car_with_luggage_on_top_of_it.jpg` (shuffle on, different image) and
`colors.json`'s `image` followed · footer toggle → `cycling=true` and the JSON
file written · `SHUFFLE` chip → `shuffle=true` · interval value clicked 30 → 60
→ 120 → 5, each persisted · written config survived a hard restart
(`cycling=true shuffle=true interval=30 state=running`, current image intact) ·
`cycleNext` advanced and `SUPER + ALT + W` is registered · opening the sheet
reports `paused`, closing resumes · toggling off → `off`, on → `running`.

Traps: a tick test that shows nothing usually means the **sheet was still
open** (suspended) — ask `cycleState` before waiting. After editing QML the IPC
answers `Not ready to accept queries yet` while the shell hot-reloads; wait a
few seconds. Do not conclude "no shell" from `pgrep -x qs` alone — a defunct
`qs` CLI can match while the live instance is the `quickshell`/`qs -n` process;
`qs ipc call dashboard isOpen` is the honest check.

## References

DMS `quickshell/Services/WallpaperCyclingService.qml` for the shape (pause on
lock/fullscreen, sequential/random, manual next/prev) — ours has no server, so
the timer is in the shell.
