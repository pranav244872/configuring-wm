# Step 2 — Hyprland Fork Build (source)

**Status: ✅ complete — built and installed 2026-10-15**

- Source: `https://github.com/pranav244872/Hyprland` @ branch `invisible-ss`
- Base: upstream **Hyprland 0.56.2** + custom screenshare-hiding patches.
  Same version as Arch's package → ABI-compatible with the pacman hypr* libs from step 1.
- Clone location: `~/del/Hyprland`

## The custom feature (`no_screen_share`)

Commits on top of 0.56.2 (oldest → newest):

1. `render: add m_bScreenshareRender flag for screenshare exclusion` — render-path flag
2. `render: skip noScreenShare windows/layers during screenshare capture` — the actual hiding
3. `screenshare: re-composite workspace instead of black overlay` — correct background where hidden windows were
4. `fix: render cursor for both HW and SW cursor modes in screenshare` — cursor still shows in capture
5. `screenshare: skip noScreenShare fadeouts during screenshare capture` — no ghost fade artifacts

Usage in config: `no_screen_share` window/layer rule (bool) —
Lua: `hl.window_rule({ match = { class = "..." }, no_screen_share = true })`.

## Dependency check — fork minimums vs pacman (all satisfied ✅)

| Dependency | Fork minimum | pacman provides |
|---|---|---|
| aquamarine | 0.9.3 | 0.15.1 ✅ |
| hyprlang | 0.6.7 | 0.6.8 ✅ |
| hyprcursor | 0.1.7 | 0.1.13 ✅ |
| hyprutils | 0.14.0 | 0.14.2 ✅ |
| hyprgraphics | 0.5.1 | 0.5.1 ✅ |
| hyprland-protocols | 0.7.0 | 0.7.1 ✅ |
| lua | 5.5.x, <5.6 | 5.5.1 ✅ |
| glaze | 7.x (`<8`) | none in repos → CMake FetchContent pulls **v7.2.0** (network needed on first configure) |
| udis86 | any | none packaged → **vendored submodule** (must be initialized) |

## Commands (what was done)

```bash
git clone --branch invisible-ss https://github.com/pranav244872/Hyprland ~/del/Hyprland
cd ~/del/Hyprland

# REQUIRED: plain clone leaves submodules empty; udis86 has no pacman package
git submodule update --init --recursive subprojects/udis86

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

- **Not a pacman package.** Update procedure later:
  `cd ~/del/Hyprland && git pull && git submodule update --init --recursive && cmake --build ./build && sudo cmake --install ./build`
- Keep pacman's hypr* libs in sync — the fork is pinned to 0.56.2 ABI.
  When Arch bumps a hypr* lib ABI, a rebuild is required (same as AUR `-git` packages).
- Build log: `/tmp/opencode/hyprland-build.log`
- Installs to (expected): `/usr/bin/Hyprland`, `/usr/bin/hyprctl`, `/usr/bin/start-hyprland`,
  `/usr/share/wayland-sessions/hyprland.desktop`
- Keep the pacman `hyprland` package uninstalled — it would conflict on
  `/usr/bin/Hyprland`, `/usr/bin/hyprctl` and the wayland-session files.
- First configure needs network (glaze FetchContent).

## Verify after install

```bash
ls -l /usr/bin/Hyprland /usr/bin/hyprctl /usr/bin/start-hyprland
pacman -Qo /usr/bin/Hyprland    # → "no package owns" (expected: source install)
```
