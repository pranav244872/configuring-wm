# Step 2 — Hyprland Fork Build (source)

**Status: ✅ complete — rebuilt on upstream 0.57.0, installed 2026-11-01**

- Source: `https://github.com/pranav244872/Hyprland`, branch **`feat/hotzones`**
  (the old `invisible-ss` branch is obsolete — its patches are upstream now)
- Base: upstream **Hyprland 0.57.0** (`0aa6745f7`) + the native hot-zones feature.
  The pacman hypr* libs from step 1 are the ABI the build is compiled against.
- Clone location: `~/del/Hyprland`
- Installed binary: `Hyprland 0.57.0 … commit 82499fcb8` (v0.57.0 + 4 commits)

## What the fork still adds

Four commits on top of `v0.57.0`:

1. `cce455e2d hotzones: native edge/corner hot zones (dwell + re-arm + suppression)`
2. `f8bf36e47 hotzones: instant slam is corner-only`
3. `b629df6ed hotzones: make the instant slam a config key (hotzone:slam, default off)`
4. `82499fcb8 screenshare: hide no_screen_share content instead of black boxes`

**`no_screen_share` — upstream covers half of it.** 0.57.0 implements the rule
(`CRenderContext::shouldRenderContent()`) and re-composites for
`SHARE_WORKSPACE`, but `SHARE_MONITOR` / `SHARE_REGION` still copy the mirror
texture and **paint black rectangles** over the excluded windows/layers (and
their popups). Fork commit `82499fcb8` ports the old `bb0ffc3e` behaviour onto
the context renderer: `renderMonitor()` re-renders the scene with
`m_renderingCapture = true`, so the excluded surfaces are dropped entirely and
the capture shows whatever is behind them (wallpaper/other windows) — no black
box. Config usage is unchanged:
`hl.window_rule({ match = { class = "..." }, no_screen_share = true })` /
`hl.layer_rule({ match = { namespace = "..." }, no_screen_share = true })`.
If upstream later re-composites monitor shares too, drop that commit.

Measured on 2026-11-02 with the **pre-patch** 0.57.0 binary and the cheatsheet
overlay (its layer rule has `no_screen_share = true`):

```bash
# with the overlay visible, then after killing it
grim -o eDP-1 /tmp/overlay.png; grim -o eDP-1 /tmp/plain.png
# crop the 650x500 overlay box (15,565) and compare
```

| capture | mean luminance | pure-black pixels |
|---|---|---|
| overlay visible (black-box path) | 0.0 | 100% |
| overlay killed (background) | 23.7 | 0% |

After the patched binary is running, the "overlay visible" crop must match the
background (≈23.7, 0% black) — that is the pass condition.

## 0.56.2 → 0.57.0 port notes

- **String dispatchers are gone.** 0.57 replaced `KeybindManager::m_dispatchers`
  with typed action functions and Lua dispatcher objects (`hl.dsp.*`). Hotzone
  `action` strings therefore accept **`exec, <cmd>`** (rules-aware) and
  **`execr, <cmd>`** only; anything richer must be a Lua keybind.
- **`hotzone <enable|disable|toggle>` dispatcher removed** with that map. Use
  `hl.hotzone.enable()` / `disable()` / `toggle_active()` (also from the shell:
  `hyprctl dispatch 'hl.hotzone.toggle_active()'`).
- Internal renames touched the port: `Log::logger->log(...)` → `LOG(...)`,
  `m_exclusiveLSes` → `m_exclusiveKeyboardLSes`, keybinds moved to
  `src/keybinds/` behind `Keybinds::mgr()`.
- **New required dependency:** `libcanberra` (added to the 0.57.0 CMake deps).

## Dependency check — fork minimums vs pacman (all satisfied ✅)

| Dependency | Fork minimum | pacman provides |
|---|---|---|
| aquamarine | 0.15.0 | 0.15.1 ✅ |
| hyprlang | 0.6.7 | 0.6.8 ✅ |
| hyprcursor | 0.1.7 | 0.1.13 ✅ |
| hyprutils | 0.14.3 | 0.14.3 ✅ |
| hyprgraphics | 0.5.1 | 0.5.1 ✅ |
| hyprland-protocols | 0.8.0 | 0.8.0 ✅ |
| libcanberra | any | 1:0.30+r2+gc0620e4-6 ✅ (new in 0.57.0) |
| lua | 5.5.x, <5.6 | 5.5.1 ✅ |
| glaze | 7.x (`<8`) | none in repos → CMake FetchContent pulls **v7.2.0** (network needed on first configure) |
| udis86 | any | none packaged → **vendored submodule** (must be initialized) |

## Commands (what was done)

```bash
git clone --branch feat/hotzones https://github.com/pranav244872/Hyprland ~/del/Hyprland
# tracking upstream for rebases:
git remote add upstream https://github.com/hyprwm/Hyprland
cd ~/del/Hyprland

# REQUIRED: plain clone leaves submodules empty; udis86 has no pacman package
git submodule update --init --recursive

# Configure (Release, install prefix /usr)
cmake --no-warn-unused-cli \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DCMAKE_INSTALL_PREFIX:STRING=/usr \
  -S . -B ./build

# Compile (running now)
cmake --build ./build --config Release -j$(nproc)

# Install — when the build finishes
sudo cmake --install ./build
```

Equivalent shorthand (repo's Makefile): `make release PREFIX=/usr && sudo make install PREFIX=/usr`

## Notes

- **Not a pacman package.** Update procedure (used for 0.57.0 on 2026-11-01):
  ```bash
  cd ~/del/Hyprland
  git fetch upstream --tags
  git rev-parse HEAD                               # note it: the only rollback ref
  git rebase --onto v<new> v<old>                  # replay only our hotzone commits
  git submodule update --init --recursive
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_INSTALL_PREFIX:STRING=/usr -S . -B ./build
  cmake --build ./build --config Release -j$(nproc)
  sudo cmake --install ./build
  Hyprland --verify-config
  ```
  Check for new required deps at configure time (0.57.0 added `libcanberra`).
- Keep pacman's hypr* libs in sync — the fork is compiled against their ABI
  (aquamarine 0.15 / hyprutils 0.14.3 / hyprlang 0.6.8 / hyprcursor 0.1.13 /
  hyprgraphics 0.5.1 / hyprland-protocols 0.8.0 on this build). `paru -Syu`
  bumping any of them requires a rebuild (same as AUR `-git` packages).
- Build log: `/tmp/opencode/hypr-build*.log` (scratch, wiped on reboot)
- Installs to (expected): `/usr/bin/Hyprland`, `/usr/bin/hyprctl`, `/usr/bin/start-hyprland`,
  `/usr/share/wayland-sessions/hyprland.desktop`
- Keep the pacman `hyprland` package uninstalled — it would conflict on
  `/usr/bin/Hyprland`, `/usr/bin/hyprctl` and the wayland-session files.
- **Rollback**: **no binary copies are kept** (all backups were removed on
  2026-11-03). To roll back, check out the previous commit (the SHA noted above),
  rebuild and reinstall, then restart the compositor (log out / back in). The
  source and build dir live in `~/del/Hyprland`, so this costs one build.
- First configure needs network (glaze FetchContent).

## Verify after install

```bash
ls -l /usr/bin/Hyprland /usr/bin/hyprctl /usr/bin/start-hyprland
pacman -Qo /usr/bin/Hyprland    # → "no package owns" (expected: source install)
```
