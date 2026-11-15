# Idle: Inhibitors, Suppression and Keep-Awake

How the session decides it is idle, what holds it back, and the traps found on
the way. Read before touching `IdleService.qml`, `Caffeine.qml`,
`BarCaffeine.qml` or `TopBar.qml`.

Back to [notes index](README.md) - [docs index](../README.md)

## The timers

`modules/lock/IdleService.qml` owns three staged `IdleMonitor`s: lock 3 m,
screen-off 5 m (backlight floor 1 %), suspend 10 m. They use
`respectInhibitors: true`, which maps to
`ext_idle_notifier_v1.get_idle_notification` (honours inhibitors) rather than
`get_input_idle_notification` (ignores them). `LockHost` turns `lockRequested`
into the real `WlSessionLock`.

## Suppression matrix

A held stage is implemented by **disabling its monitor**, not by leaning on the
compositor — caelestia's `IdleMonitors.qml` and DMS's `IdleService` do the same,
because a bar-surface `zwp_idle_inhibit` goes inactive when a fullscreen window
occludes the bar.

| Source | lock | blank | suspend |
|---|---|---|---|
| Fullscreen window on the focused workspace | held | held | held |
| Any MPRIS player reporting `isPlaying` | — | held | held |
| Caffeine toggle (manual, local flag) | held | held | held |

Music therefore still lets the session lock (the lock sits over the player) while
a fullscreen video/game holds everything.

Caffeine used to work only through the bar's Wayland inhibitor, and that is
what made it look inconsistent: Hyprland sets `idle->setInhibit(true)` only
while the inhibiting view is `aliveAndVisible()`, so a **fullscreen window
(YouTube, a video player) occludes the bar and silently drops the inhibitor** —
the session then locked at 3 m with the coffee button lit. `IdleService` now
reads `Caffeine.enabled` directly and disables the monitors, exactly like the
fullscreen flag; the inhibitor in `TopBar.qml` is kept only for clients outside
this shell. Measured 2026-11-15 (10 s lock timer): caffeine on → no lock; off →
lock; fullscreen → no lock; leaving fullscreen → lock again on the next timer.

- Media is **native MPRIS** (`Quickshell.Services.Mpris`):
  `Mpris.players.values.some(p => p.isPlaying)` — no `playerctl` spawning.
- Fullscreen needs **two** things: `Hyprland.focusedWorkspace.hasFullscreen`
  *and* a `Hyprland.refreshToplevels()` on its change. The IPC `fullscreen`
  event only flips the workspace flag (`FullscreenController.cpp` posts
  `mode != FSMODE_NONE`), while `Toplevel.lastIpcObject` is refreshed by *other*
  events — without the pull, `lastIpcObject.fullscreen` stays stale and never
  becomes true. The `> 1` test then excludes state 1 ("maximized", i.e. fake
  fullscreen), so a maximized window does not suppress idle.

## What we honour, and what we cannot

hypridle recognises three inhibitor sources (`ignore_wayland_inhibit`,
`ignore_dbus_inhibit`, `ignore_systemd_inhibit`) and **serves**
`org.freedesktop.ScreenSaver` itself. We get the first only:

- Wayland `zwp_idle_inhibit_v1` — honoured ✓ (this is what Caffeine uses).
- D-Bus `org.freedesktop.ScreenSaver` / `org.gnome.SessionManager` — **not
  honoured**: quickshell 0.3.2 has no generic D-Bus API, so the shell cannot
  serve or observe that interface the way hypridle and DMS's daemon do.
- systemd/logind inhibit — not honoured.

Apps that inhibit through the **XDG portal** (`org.freedesktop.portal.Inhibit`,
present on this machine) or their own Wayland inhibitor are covered; apps that
speak only `org.freedesktop.ScreenSaver` are not.

## Keep-awake (caffeine)

`modules/Caffeine.qml` is a `pragma Singleton` `QtObject` holding `enabled` +
`toggle()`/`setEnabled()` — it cannot hold the `IpcHandler` or a window (see the
singleton trap in [quickshell.md](quickshell.md)).
`modules/bar/TopBar.qml` holds `IdleInhibitor { enabled: Caffeine.enabled;
window: bar }` and the `IpcHandler` (`target: "caffeine"`);
`modules/bar/BarCaffeine.qml` is the coffee button (lit `primary` when active).

The **flag** is what holds our timers (`IdleService.lockHeld/blankHeld/
suspendHeld`). The inhibitor is for other consumers: Hyprland honours an
inhibitor on a **layer surface** only while that surface's view is
`aliveAndVisible()` (`LayerSurface.cpp` → `recheckIdleInhibitorStatus()`), and a
fullscreen window makes the bar's surface not visible. So never make caffeine
depend on it.

State is intentionally not persisted: it resets to off on a shell restart.

## Verifying it (don't guess)

- **State first**: `qs ipc call idle state` prints the flags
  (`fullscreen`, `media`, `caffeine`, the three `*Held`s, `lockSecs`) in one
  line. It is the fastest way to tell which rule is holding a stage.
- **Caffeine A/B**: temporarily set `lockSecs: 10`, restart, then `caffeine
  enable` → `qs ipc call lock isLocked` stays false after 15 s; `caffeine
  disable` → it locks. `qs ipc call lock unlock` disengages without a password,
  so the test is safe. Restore `lockSecs: 180` when done.
- **Suppression**: add temporary `console.log`s on the held flags, then toggle a
  window fullscreen without stealing focus
  (`hyprctl dispatch 'hl.dsp.window.fullscreen({ action = "toggle", window =
  "class:kitty" })'`) and read the main instance log. Pick the log by content —
  probe runs create their own `by-id` dirs, so `ls -t` selects the wrong file.
- The qslog is effectively one enormous line: extract with
  `grep -ao "marker[^[]{0,80}"`; plain `grep` dumps the whole file.

## Why not hypridle

`hypridle` is the same idea as a session daemon (one `listener` per timeout,
`ext-idle-notify-v1` + dbus/logind inhibit). We don't need it: `IdleService`
already owns the timers *and* the suppression flags, so no compositor inhibitor
is required for our own monitors (the one we do hold is for external clients). For reference, end-4 ships a plain
`hypridle.conf` (5 m lock / 10 m dpms / 15 m suspend, `inhibit_sleep = 3`).
