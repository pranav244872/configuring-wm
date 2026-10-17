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
| Caffeine toggle (manual, Wayland inhibitor) | held | held | held |

Music therefore still lets the session lock (the lock sits over the player) while
a fullscreen video/game holds everything.

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
It is advisory: Hyprland honours an inhibitor on a **layer surface** because
`LayerSurface.cpp` assigns the `CLayerSurface` as the surface's view and
`recheckIdleInhibitorStatus()` sets `PROTO::idle->setInhibit(true)` when
`view()->aliveAndVisible()` (source read + live A/B probe). State is
intentionally not persisted: it resets to off on a shell restart.

## Verifying it (don't guess)

- **Caffeine**: a second `qs -p` process shares the compositor's idle state, so an
  `IdleMonitor { timeout: 3; respectInhibitors: true }` probe prints idle after
  ~3 s with caffeine off and stays quiet with it on.
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
already owns the timers, so the inhibitor only has to be honoured by the
compositor for *our* monitors — and it is. For reference, end-4 ships a plain
`hypridle.conf` (5 m lock / 10 m dpms / 15 m suspend, `inhibit_sleep = 3`).
