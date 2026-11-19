# Hyprland Notes

Animation units and the quirks of our 0.57.2-based fork. Read before touching `hyprland.lua` or the modules.

Back to [notes index](README.md) - [docs index](../README.md)

## Animation speed units

**`duration_ms = speed × 100` → LOWER speed value = FASTER.**

Source (`hyprutils` `src/animation/AnimatedVariable.cpp::getPercent()`):

```cpp
percent = std::clamp((elapsed_ms / 100.f) / pValues->internalSpeed, 0.f, 1.f);
```

Measured against the installed hyprutils 0.14.2 with a small C++ benchmark
(`/tmp/opencode/animtest.cpp`, linked against the real `libhyprutils`):

| speed | 10 | 8 | 4.79 | 4 | 2 | 1.49 | 1 | 0.5 |
|---|---|---|---|---|---|---|---|---|
| measured ms | 1003 | 803 | 482 | 404 | 202 | 151 | 102 | 52 |

Related facts:
- The fork initialises `global` with `speed = 8` (≈800 ms). **Any leaf you do
  not set inherits that** — so set `global` explicitly or everything feels slow.
- **Springs ignore `speed` entirely**; stiffness/damping decide. The old
  config's spring (250/25) measured ~640 ms to settle → slowest option here.
- Animation leaves form a tree; disabling or changing a node propagates to its
  children (`AnimationConfigTree::setAnimForChildren`, `pValues` inheritance).
  Disabling `workspaces` also kills `workspacesIn/Out` and `specialWorkspace`.
- Lua leaf names must exist in the tree (`global`, `windows`, `windowsIn`,
  `windowsOut`, `fade`, `fadeIn`, `fadeOut`, `layers`, `layersIn/Out`,
  `workspaces`, `border`, `zoomFactor`, `monitorAdded`, …).


## Version quirks in this fork (0.57.2 base)

- **VFR moved**: `misc.vfr` is invalid → it is `debug.vfr` (bool, default `true`).
  `--verify-config` catches this class of mistake instantly.
- **Fullscreen mode enum**: `FSMODE_NONE = 0`, `FSMODE_MAXIMIZED = 1`,
  `FSMODE_FULLSCREEN = 2`. "Fake fullscreen" (client-only) =
  `hl.dsp.window.fullscreen_state({ internal = 0, client = 2 })` — app is told
  it's fullscreen, Hyprland keeps the window in the layout. Real fullscreen is
  `SUPER + W`.
- **`no_screen_share`** is a bool effect on **window and layer rules**; windows/
  layers carrying it are skipped during screenshare capture. Layer rules match on
  `namespace`, window rules on `class`/`title`. The rule and the
  `SHARE_WORKSPACE` path are **upstream since 0.57.0**
  (`CRenderContext::shouldRenderContent()`), but upstream still **black-boxes**
  `SHARE_MONITOR`/`SHARE_REGION`; fork commit `930aed4fa` re-composites
  `renderMonitor()` instead, so the area shows what is behind the window (hidden,
  not black). See [setup/04](../setup/04-hyprland-fork-build.md).
- **0.57.0 starts a systemd session target.** Commit `34839b4f6` installs
  `hyprland-session.target` (`BindsTo=graphical-session.target`) and starts it
  unless `MANAGERPID` is set (UWSM) or `HYPRLAND_NO_SD_VARS` is enabled. Any
  user unit with `WantedBy=graphical-session.target` now autostarts at login —
  this is what made Sunshine start (and open a share picker) after the update;
  see [sunshine.md](sunshine.md).
- **String dispatchers are gone (0.57.0).** Keybinds take Lua objects
  (`hl.dsp.window.close()`); `hyprctl dispatch` wants the Lua form
  (`hyprctl dispatch 'hl.dsp.exit()'`).
- Lua config modules run in separate error scopes; a plain (non-`local`)
  assignment in `hyprland.lua` (e.g. `colors = require(...)`) is visible to
  the modules that `require` it afterwards.
- `require` of a *missing* module is a hard error that kills the main config —
  use `pcall(require, ...)` if something is optional.

## System upgrades under the source build

The fork links the system `hyprutils`/`aquamarine`, so check them after a
`pacman -Syu`:

```bash
hyprctl systeminfo | grep -E "Hyprutils|Aquamarine"
# Hyprutils: built against 0.14.3, system has 0.14.4
```

That line is informational, not fatal. What matters is the **major/minor ABI**
in the version string (`..._aq_0.16_hu_0.14_...`) and the soname: a patch bump
(`0.14.3 → 0.14.4`) keeps `libhyprutils.so.13` and the fork runs untouched; a
`0.15`/soname bump needs a rebuild (`setup/04`). Same for aquamarine.

Verified 2026-11-19 (hyprutils 0.14.4 under the 0.14.3 build): `--verify-config`
→ `config ok`, the running compositor log had `0` `[ ERROR ]` lines, and a
throwaway nested instance (`Hyprland -c min.lua`, no autostart) came up on
`wayland-2` with a monitor and clean startup — so a restart is safe. The running
compositor keeps the pre-upgrade library mapped until it restarts; that is
normal and not a reason to reboot.

Quick health probe after any upgrade: `hyprctl version`, `hyprctl monitors -j`,
`hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'` (string dispatchers do not
exist, see above), and `hyprctl reload`.
