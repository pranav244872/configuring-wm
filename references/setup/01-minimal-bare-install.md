# Step 1 — Minimal Bare Install

**Status: ✅ complete — installed 2026-10-15**

The smallest package set that gives a working, fast Hyprland session on a fresh
Arch Linux install. It splits in two:

| Part | What | Detail file |
|---|---|---|
| 1 — runtime | what any Hyprland user needs | [02-runtime-packages.md](02-runtime-packages.md) |
| 2 — fork build deps | only needed because the compositor is built from source | [03-fork-build-deps.md](03-fork-build-deps.md) |

Every package listed in those files is an explicit `pacman -S` argument;
transitive dependencies are resolved by pacman and not listed. Versions as of
2026-10-15 (repo `extra`).

## Prerequisites (standard Arch install)

mesa (OpenGL/Vulkan), glib2, fontconfig, polkit, pipewire + wireplumber.
Install them first if missing.

## Commands

```bash
# Part 1 — runtime packages
sudo pacman -S --needed --noconfirm \
  kitty wl-clipboard qt6-wayland ttf-jetbrains-mono-nerd intel-media-driver brightnessctl \
  xdg-desktop-portal-hyprland hyprpolkitagent

# Part 2a — build toolchain
sudo pacman -S --needed --noconfirm base-devel cmake python git

# Part 2b — hypr* ecosystem libraries
sudo pacman -S --needed --noconfirm aquamarine hyprcursor hyprgraphics hyprlang hyprutils \
  hyprwire hyprtoolkit hyprland-guiutils hyprland-protocols hyprwayland-scanner

# Part 2c — system libraries
sudo pacman -S --needed --noconfirm cairo pango libdrm libinput libxkbcommon pixman wayland \
  wayland-protocols libglvnd glslang lcms2 muparser re2 tomlplusplus util-linux-libs xcb-proto \
  xcb-util xcb-util-errors xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm \
  libx11 libxcb libxcomposite libxcursor libxfixes libxrender xorg-xwayland lua
```

## Order of operations

1. Install part 1 + part 2 (2a → 2b → 2c).
2. Build and install the compositor → [step 4](04-hyprland-fork-build.md).
3. Write the config → [step 5](05-hyprland-config.md).
4. Later additions (playerctl, fish, zoxide, firefox) can be installed at any
   point — listed in [step 2](02-runtime-packages.md#added-after-the-initial-install-same-day).

## Verify

```bash
# every explicit package present
pacman -Q kitty wl-clipboard qt6-wayland ttf-jetbrains-mono-nerd intel-media-driver \
  brightnessctl xdg-desktop-portal-hyprland hyprpolkitagent hyprwire lua

# compositor is installed and is ours (no pacman package owns it)
pacman -Qo /usr/bin/Hyprland   # expect: no package owns ...
```

## Notes

- Don't add packages "just in case" — this list is deliberately minimal; see
  [../preferences.md](../preferences.md) for the philosophy and the
  deliberately-deferred list.
- If a `pacman` run is interrupted, a stale lock can block the next one — see
  [notes/system.md](../notes/system.md).
