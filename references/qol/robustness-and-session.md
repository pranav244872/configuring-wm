# Robustness & Session Safety

**Status: ⬜ not started** — nothing to fix today, but worth knowing what exists.

## What Omarchy does

**User services**
| Unit | Purpose |
|---|---|
| `omarchy-crash-watch.service` | watches for crashes and restarts what died |
| `omarchy-hyprland-session-lock-stranded` | detects a session stuck in the locked state |
| `omarchy-sleep-lock.service` | locks the session before suspend |
| `omarchy-recover-internal-monitor.service` | brings back a lost internal display |
| `omarchy-speaker-tuning.service` | per-device audio tuning |
| `bt-agent.service`, `omarchy-fcitx5.service`, `omarchy-tailscale-receive.service` | bluetooth / IME / Tailscale |

**CLI helpers**
`omarchy-refresh-*` (12 commands, re-apply a component without reboot),
`omarchy-restart-*` (16 commands), `omarchy-debug-idle`,
`omarchy-hyprland-session-locked`, `omarchy-hyprland-session-lock-stranded`.

**systemd tuning shipped as drop-ins**
```
faster-shutdown.conf                 # faster poweroff/reboot
zram-generator.conf.d/90-omarchy.conf
user/app.slice.d/10-oomd.conf       # OOM killer tuning
system/plocate-updatedb.service.d/10-omarchy.conf
system/supergfxd.service.d/delay-start.conf
system/v4l2-relayd@camlink.service.d/camlink.service   # hybrid GPU
system-sleep/{force-igpu,fprintd-resume,keyboard-backlight,unmount-fuse}
```

## What would apply here

| Idea | Worth it? |
|---|---|
| `faster-shutdown.conf` drop-in | maybe — measurable difference on shutdown/reboot |
| oomd tuning | only with many heavy apps; we run a bare session |
| sleep-lock | needs hypridle + hyprlock (rice phase) |
| crash-watch | only useful once a bar/menu layer exists |
| refresh/restart helpers | useful once there is a bar/daemon to restart |
| hybrid-GPU bits | n/a (single Intel GPU) |

## Note

Omarchy's model is "one command per component + a refresh command". Our setup has
two moving parts (polkit agent + quickshell), so most of this becomes relevant
only after the rice phase.
