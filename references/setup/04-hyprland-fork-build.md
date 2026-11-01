# Step 2 — Hyprland Fork Build (source)

**Status: ✅ complete — rebuilt on upstream 0.57.0, installed 2026-11-01**

- Source: `https://github.com/pranav244872/Hyprland`, branch **`feat/hotzones`**
  (the old `invisible-ss` branch is obsolete — its patches are upstream now)
- Base: upstream **Hyprland 0.57.0** (`0aa6745f7`) + the native hot-zones feature.
  The pacman hypr* libs from step 1 are the ABI the build is compiled against.
- Clone location: `~/del/Hyprland`
- Installed binary: `Hyprland 0.57.0 … Tag: v0.57.0-3-gb629df6ed`

## What the fork still adds

Three commits on top of `v0.57.0` (all `hotzone:*`, see
[notes/hotzones.md](../notes/hotzones.md)):

1. `cce455e2d hotzones: native edge/corner hot zones (dwell + re-arm + suppression)`
2. `f8bf36e47 hotzones: instant slam is corner-only`
3. `b629df6ed hotzones: make the instant slam a config key (hotzone:slam, default off)`

**`no_screen_share` is no longer a fork patch.** Upstream 0.57.0 implements it
(`CRenderContext::shouldRenderContent()` + the rule), so the five old
screenshare commits were dropped. The config usage is unchanged —
`hl.window_rule({ match = { class = "..." }, no_screen_share = true })` /
`hl.layer_rule({ match = { namespace = "..." }, no_screen_share = true })`.

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
  git branch -f backup/hotzones-<old> HEAD          # rollback point
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
- **Rollback**: a copy is taken before every install.
  `/usr/bin/Hyprland.bak-0.56.2` is the 2026-10-17 0.56.2 build (the older
  `/usr/bin/Hyprland.bak` is the original 2026-10-15 one). Restore with
  `sudo cp -a /usr/bin/Hyprland.bak-0.56.2 /usr/bin/Hyprland` and restart the
  compositor (log out / back in).
- First configure needs network (glaze FetchContent).

## Verify after install

```bash
ls -l /usr/bin/Hyprland /usr/bin/hyprctl /usr/bin/start-hyprland
pacman -Qo /usr/bin/Hyprland    # → "no package owns" (expected: source install)
```
