# Battery & Power

**Status: ⬜ not started** — but `quickshell` is already installed, which is the
piece this needs.

## What Omarchy does

**Low-battery warning** (`omarchy-battery-low <percent>`)
- Sends a notification (icon `󱐋`, critical urgency) and fires an extensible hook:
  `omarchy-hook battery-low <level>`.
- The trigger is a **quickshell service**: `shell/plugins/services/battery/Service.qml`
  - reads **UPower** over D-Bus, not sysfs
  - *"Follows power-profiles-daemon's change signals, so nothing polls it"*
  - fires **once per discharge** — a persisted `notifiedLowBattery` flag
    (quickshell `PersistentProperties`) prevents repeat warnings
  - drops the request if a warning is already in flight

**Battery status for the bar** (`omarchy-battery-status [--shell]`)
- formatted percentage + power draw/charge, read from
  `/sys/class/power_supply` (override with `OMARCHY_POWER_SUPPLY_PATH`)

**Power profiles** (laptop performance switching)
- `omarchy-powerprofiles-init` → `omarchy-powerprofiles-set autodetect` on boot
  (performance on AC, power-saver on battery)
- `omarchy-powerprofiles-set` / `-list` for manual control

**Sleep & suspend handling**
- `omarchy-system-sleep-lock.service` — locks the session before suspend
- `omarchy-toggle-suspend`, `omarchy-sleep-disabled`, `omarchy-debug-idle`
- `omarchy-power-present` (desktops without a battery)

## What it would take here

| Piece | Cost | Notes |
|---|---|---|
| Power profiles | `power-profiles-daemon` + one user service | best value: automatic on AC/battery for the i3-10110U |
| Battery warning surface | **none yet — we have no notification daemon** | mako was removed deliberately; a minimal quickshell notification/battery service is the quickshell-native answer |
| Sleep-lock | needs `hypridle` + `hyprlock` (rice phase) | pointless before those exist |

## Open question

A battery warning needs somewhere to appear. Options, in order of preference:
1. minimal **quickshell** service (battery + a small OSD), no extra package
2. skip the reminder entirely and rely on the bar showing the percentage
