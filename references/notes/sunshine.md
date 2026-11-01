# Sunshine (game streaming host)

Sunshine + Moonlight on this laptop. Read before touching the user unit or
`~/.config/sunshine/sunshine.conf`, and before wondering why a "share picker"
window appears at login.

Back to [notes index](README.md) - [docs index](../README.md)

## What is installed

- AUR `sunshine-bin` **2026.914.233613-1** (installed 2026-10-18).
- User unit `app-dev.lizardbyte.app.Sunshine.service` (alias `sunshine.service`),
  `WantedBy=graphical-session.target`, `ExecStartPre=/bin/sleep 5`.
- Web UI: `https://localhost:47990`.
- Config: `~/.config/sunshine/sunshine.conf`, logs `~/.config/sunshine/sunshine.log`.

## Why it "opened on startup" after the 0.57.0 update

Hyprland **0.57.0** added `session: add disable-able systemd session target`
(upstream `34839b4f6`), which installs `hyprland-session.target` and starts it
when there is no `MANAGERPID` (i.e. not already under UWSM):

```
hyprland-session.target --BindsTo--> graphical-session.target
```

Every user unit with `WantedBy=graphical-session.target` therefore started
autostarting. Sunshine's unit is one of those (the package preset enabled it at
install time on 2026-10-18, back when nothing started the target).

At login Sunshine immediately asks the portal for a screencast:

- first attempt fails (`org.freedesktop.portal.RemoteDesktop` not up yet),
- it retries a few seconds later and **spawns `hyprland-share-picker`** — the
  visible window that flashed for ~6 s on every login.

## Fix applied (2026-11-01)

`capture = wlr` in `~/.config/sunshine/sunshine.conf`:

```ini
capture = wlr
```

Sunshine's Linux capture choices are *autodetect* (empty), `wlr`, `x11`,
`portal`. Forcing `wlr` uses `zwlr_screencopy_manager_v1` directly, so **no
portal, no picker window**. Verified in the log after a service restart:

```
Info: Screencasting with Wayland's protocol
Info: [wlgrab] Selected monitor [BOE 0x0812  (eDP-1)] for streaming
Info: Starting main loop
```

No `portalgrab`, no `hyprland-share-picker` process. Mouse/keyboard/controller
injection is already disabled in the conf, so nothing else needed the portal.

## Commands

```bash
systemctl --user status  app-dev.lizardbyte.app.Sunshine.service
systemctl --user restart app-dev.lizardbyte.app.Sunshine.service
systemctl --user disable --now app-dev.lizardbyte.app.Sunshine.service  # no login autostart
systemctl --user start app-dev.lizardbyte.app.Sunshine.service          # manual start
```

If it should **never** start on login, disable the unit; the package stays
installed and `sunshine` (or the unit above) starts it on demand.

To opt out of the 0.57 session-target behaviour instead, export
`HYPRLAND_NO_SD_VARS=1` before Hyprland starts (`modules/env.lua` is too late —
the compositor checks its own process env). Not done here: portals are D-Bus
activated, so they don't depend on the target.

## Traps

- Forcing `capture = wlr` is what removes the picker; leaving it on autodetect
  re-enables the portal path and the popup on the next login.
- The unit's `Restart=on-failure` plus `StartLimitBurst=5` means a crash loop
  stops after five tries — check `systemctl --user status` before assuming it is
  running.
- No system tray is required for streaming; the "System tray created" log line
  is normal even though the shell has no SNI host.
