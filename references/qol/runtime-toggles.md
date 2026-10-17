# Runtime Toggles

**Status: ⬜ not started** — we already hard-set most of these, a toggle makes
them switchable without editing config.

## What Omarchy does

16 CLI toggles (`omarchy-toggle-*`):
`animations`, `bar`, `crash-capture`, `enabled`, `fullscreen-desktop`,
`hybrid-gpu`, `idle`, `input-device`, `nightlight`, `notification-silencing`,
`screensaver`, `suspend`, `theme-sync`, `touchpad`, `touchscreen`, `fullscreen`.

The interesting ones are implemented as small Hyprland **Lua modules** in
`default/hypr/toggles/`:

```
bar-glassy.lua            no-animations.lua        window-opaque.lua
corners-rounded.lua       flags.lua                window-no-gaps.lua
corners-sharp.lua         window-glassy.lua
single-window-aspect-ratio.lua
```

Each flips live config with `hl.config` and has a keybind. (end-4's
dots-hyprland uses the same idea — toggles are a common pattern in Lua Hyprland
configs.)

## What it would take here

| Toggle | Our current state | Action when implemented |
|---|---|---|
| `no-animations` | animations on: global 2, windows 2, speed 1.2–1.8 | one key → `enabled = false` everywhere (gaming / battery) |
| `window-opaque` | already 1.0/1.0 opacity, blur & shadows off | nothing to do |
| `window-no-gaps` | gaps 8/20 | for fullscreen-ish single windows |
| `corners-sharp` | rounding 20 | cosmetic |
| `nightlight` | — | would replace the deferred `hyprsunset` idea |
| `notification-silencing` | no notifications at all | n/a today |

## Notes

- Toggles are cheap: a Lua module that sets config values, no new packages.
- The "no animations" one is the most valuable here (fast + battery), and pairs
  with the animation-units knowledge in [../notes/hyprland.md](../notes/hyprland.md#animation-speed-units).
