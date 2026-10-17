# Hyprland Notes

Animation units and the quirks of our 0.56.2-based fork. Read before touching `hyprland.lua` or the modules.

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


## Version quirks in this fork (0.56.2 base)

- **VFR moved**: `misc.vfr` is invalid → it is `debug.vfr` (bool, default `true`).
  `--verify-config` catches this class of mistake instantly.
- **Fullscreen mode enum**: `FSMODE_NONE = 0`, `FSMODE_MAXIMIZED = 1`,
  `FSMODE_FULLSCREEN = 2`. "Fake fullscreen" (client-only) =
  `hl.dsp.window.fullscreen_state({ internal = 0, client = 2 })` — app is told
  it's fullscreen, Hyprland keeps the window in the layout. Real fullscreen is
  `SUPER + W`.
- **`no_screen_share`** (the fork's feature) is a bool effect on **window and
  layer rules**; windows/layers carrying it are skipped during screenshare
  capture. Layer rules match on `namespace`, window rules on `class`/`title`.
- Lua config modules run in separate error scopes; a plain (non-`local`)
  assignment in `hyprland.lua` (e.g. `colors = require(...)`) is visible to
  the modules that `require` it afterwards.
- `require` of a *missing* module is a hard error that kills the main config —
  use `pcall(require, ...)` if something is optional.
