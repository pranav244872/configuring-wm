# Keep-Awake (Idle Inhibit)

How the bar's caffeine toggle stops the session going idle, and the verified
rules behind it. Read before touching `Caffeine.qml`, `BarCaffeine.qml`,
`TopBar.qml` or `IdleService.qml`.

Back to [notes index](README.md) - [docs index](../README.md)

## The mechanism

- `Quickshell.Wayland.IdleInhibitor` is the client side: it needs `enabled: true`
  **and** a non-null `window` (the inhibitor is attached to that surface).
- It is **advisory** — the compositor decides. Hyprland does honour an inhibitor
  on a **layer surface**, which is what makes attaching it to the bar work:
  `LayerSurface.cpp` assigns the `CLayerSurface` as the surface's view, and
  `recheckIdleInhibitorStatus()` sets `PROTO::idle->setInhibit(true)` when
  `view()->aliveAndVisible()` — true for a mapped layer surface. (Verified by
  source read + live A/B probe, 2026-10-17.)
- Our `IdleService` `IdleMonitor`s use `respectInhibitors: true`, which maps to
  `ext_idle_notifier_v1.get_idle_notification` (honours inhibitors) instead of
  `get_input_idle_notification` (ignores them). One inhibitor therefore stops
  **all** of lock (3m), screen-off (5m) and suspend (10m).
- State is intentionally **not persisted**: it resets to off on a shell restart.

## Where it lives

- `modules/Caffeine.qml` — a `pragma Singleton` `QtObject` holding only
  `enabled` + `toggle()`/`setEnabled()`. It cannot hold the `IpcHandler` or a
  window (see the singleton trap in [quickshell.md](quickshell.md)).
- `modules/bar/TopBar.qml` — holds the `IdleInhibitor { enabled: Caffeine.enabled;
  window: bar }` and the `IpcHandler` (`target: "caffeine"`).
- `modules/bar/BarCaffeine.qml` — the coffee button (lit `primary` when active,
  dim otherwise).

## Verifying it (don't guess)

A standalone probe config beats waiting 3 minutes for the real lock. A second
`qs -p` process shares the compositor's idle state, so:

1. caffeine off → an `IdleMonitor { timeout: 3; respectInhibitors: true }` probe
   prints idle after ~3s;
2. `qs ipc call caffeine enable` → the same probe stays non-idle;
3. `qs ipc call caffeine disable` → idle again.

## Why not hypridle

`hypridle` is the same idea as a session daemon (`~/.config/hypr/hypridle.conf`;
`ext-idle-notify-v1` plus dbus/loginctl inhibit). We don't need it: `IdleService`
already owns the idle timers in-shell, so the inhibitor only has to be honoured
by the compositor for *our* monitors — and it is.
