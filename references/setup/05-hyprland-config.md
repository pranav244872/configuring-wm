# Step 3 — Hyprland Config (speed-first, modular)

**Status: ✅ complete — written and validated 2026-10-15**

See also: [../preferences.md](../preferences.md) (why these values) and
[notes/hyprland.md](../notes/hyprland.md#animation-speed-units) (animation speed units).

- Location: `~/.config/hypr/` (live config, read directly by Hyprland)
- Format: **Lua** — split into modules exactly like the old `configuring-wm` repo.
- Validation: `Hyprland --verify-config` → **`config ok`** ✅

## File layout

```
~/.config/hypr/
├── hyprland.lua              # entry point: colours + require() list
├── modules/
│   ├── colors.lua            # Material teal palette (from old wallpaper)
│   ├── monitors.lua          # eDP-1 1920x1080@60
│   ├── env.lua               # cursor, toolkit, XDG, Qt env vars
│   ├── input.lua             # us layout, natural scroll, 3-finger gesture
│   ├── keybinds.lua          # all keybindings (table below)
│   ├── autostart.lua         # hyprpolkitagent + quickshell (`qs -n`)
│   ├── decorations.lua       # speed-first look + quick animations
│   ├── layouts.lua           # dwindle (+ master/scrolling defaults)
│   ├── misc.lua              # VFR, no logo/wallpaper
│   └── windowrules.lua       # house-keeping rules + no_screen_share
└── scripts/
    └── brightness.sh         # brightness step with a 1% floor (used by 4 binds)
```

`hyprland.lua` does `colors = require("modules.colors")` first (decorations uses
it for borders), then requires the rest. Each module is a separate scope — an
error in one file doesn't kill the others (Hyprland `require` behaviour).

## Keybinds (current, bare set)

| Bind | Action |
|---|---|
| `SUPER + RETURN` | kitty terminal |
| `SUPER + Q` | close window |
| `SUPER + M` | exit Hyprland |
| `SUPER + V` | toggle float |
| `SUPER + W` | toggle fullscreen |
| `CTRL + SHIFT + F` | fake fullscreen (client-only; for Moonlight) |
| `SUPER + P` | pseudo-tile |
| `SUPER + J` | toggle split (dwindle) |
| `SUPER + ←↑→↓` | move focus |
| `SUPER + [0-9]` | switch workspace (10 = key 0) |
| `SUPER + SHIFT + [0-9]` | move window to workspace |
| `SUPER + S` / `SUPER + SHIFT + S` | scratchpad toggle / send to scratchpad |
| `SUPER + scroll` | next/prev existing workspace |
| `SUPER + LMB / RMB` | drag / resize window |
| `XF86Audio*` / `XF86MonBrightness*` | volume ±5% / mute / mic mute / brightness ±5% |
| `ALT + XF86Audio*` / `ALT + XF86Mon*` | same, precise ±1% steps |
| `XF86AudioPlay/Pause/Next/Prev` | playerctl media keys |

Volume/mic via `wpctl`, brightness via `brightnessctl` — silent, no OSD
(decision: bare install). Deferred binds (rofi, screenshots, playerctl, …) are
listed as comments at the bottom of `keybinds.lua`.

## Speed-first decisions

| Setting | Choice | Why |
|---|---|---|
| `decoration.blur` | **off** | official "lowest power" tip; biggest GPU saving |
| `decoration.shadow` | **off** | second-biggest saving |
| window opacity | 1.0 / 1.0 | no per-frame compositing of transparent windows |
| animations | easeOutQuint beziers, speeds 1.5–2 | ~150–200 ms. **Units: `duration_ms = speed × 100`, so LOWER = faster** (measured against hyprutils 0.14.2) |
| `workspaces` animation | speed 1.2 fade | ~120 ms transition — user wants *some* motion, just fast (`enabled = false` for instant) |
| `debug.vfr` | on (default) | only render when something changes |
| `debug.damage_tracking` | default (`full`) | leave as-is, wiki says do not change |
| gaps/borders/rounding | same as old (8/20, 2px, 20) | kept the familiar teal look — costs ~nothing |

## Validation commands

```bash
# syntax check all lua files
find ~/.config/hypr -name '*.lua' -exec luac -p {} +

# real check (part of the fork binary, does not launch Hyprland)
Hyprland --verify-config        # → prints "config ok"
```

If the config ever breaks, Hyprland still registers emergency binds:
`SUPER + Q` terminal, `SUPER + R` launcher, `SUPER + M` exit.

## Notes for a fresh install

- `misc.vfr` no longer exists in this version — VFR is `debug.vfr` (on by default).
- Config is **live only** for now (no copy in this repo). TODO when building the
  installer: snapshot `~/.config/hypr/` so a fresh system can recreate it.
- Mako (installed in step 1) is left **dormant**: not autostarted, no config port.
- `hyprland.lua` and all modules must be valid Lua 5.5 (pacman `lua`, used
  `luac -p` for checks).

## Deferred to step 4 (rice layer)

rofi (launcher / powermenu / keybinds menu), dolphin, hyprshot screenshots,
audio-output-switch script, wallpaper daemon + picker,
waybar, hypridle + hyprlock, hyprsunset, swayosd OSD, wf-recorder, mako theme,
caffeine / sshd-toggle scripts.
