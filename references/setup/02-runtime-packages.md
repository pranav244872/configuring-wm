# Step 1a — Runtime Packages

Part 1 of [step 1](01-minimal-bare-install.md): what any Hyprland user
needs, independent of the fork. Every row below is an explicit `pacman -S`
argument (versions as of 2026-10-15, repo `extra`).

```bash
sudo pacman -S --needed --noconfirm \
  kitty wl-clipboard qt6-wayland ttf-jetbrains-mono-nerd intel-media-driver brightnessctl \
  xdg-desktop-portal-hyprland hyprpolkitagent
```

| Package | Version | What it's for |
|---|---|---|
| `kitty` | 0.49.2-1 | GPU-accelerated terminal; bound to `SUPER + RETURN` |
| `wl-clipboard` | 1:2.3.0-1 | `wl-copy` / `wl-paste` for scripts, nvim, TUIs |
| `qt6-wayland` | 6.12.0-1 | Qt6 Wayland platform plugin — Qt apps native instead of XWayland |
| `ttf-jetbrains-mono-nerd` | 3.5.1-2 | Monospace font + Nerd glyphs (terminal now, bar later) |
| `intel-media-driver` | 26.3.5-1 | VA-API video decode for UHD 620 — battery + smoothness |
| `brightnessctl` | 0.5.1-3 | Backlight control for the `XF86MonBrightness*` keys |
| `xdg-desktop-portal-hyprland` | 1.4.1-2 | Portals: screen share (uses the fork's hiding feature), screenshots, global shortcuts, file dialogs |
| `hyprpolkitagent` | 0.2.0-1 | Polkit agent — GUI password prompts; the only thing autostarted |

## Added after the initial install (same day)

| Package | Version | What it's for |
|---|---|---|
| `playerctl` | 2.4.1-5 | Media transport keys (`XF86AudioPlay/Pause/Next/Prev`) |
| `fish` | 4.9.3-1 | Login shell — `chsh -s /usr/bin/fish` |
| `zoxide` | 0.10.0-1 | Smarter `cd` — `zoxide init fish --cmd cd \| source` in `~/.config/fish/config.fish` |
| `firefox` | 157.0.1-1 | Web browser |
| `mpv` | 0.41.0-1 | Media player (pulls in ffmpeg/ffprobe). UI is **uosc**, vendored into `~/.config/mpv` — not a pacman package, see [notes/mpv.md](../notes/mpv.md) |
| `quickshell` | 0.3.2-1 | QtQuick/QML toolkit for building a desktop shell (bar, dashboard, notifications). Installed, **not used yet** — rice phase |

```bash
sudo pacman -S --needed playerctl fish zoxide firefox
```

## Added for screenshots (2026-10-16)

| Package | Version | What it's for |
|---|---|---|
| `grim` | 1.5.0-2 | Screenshot capture plumbing for our own quickshell utility (Print) |
| `slurp` | 1.5.0-2 | Region-selection fallback for the screenshot utility |

```bash
sudo pacman -S --needed grim slurp
```

## Added for the Chaldea restyle (2026-10-16)

| Package | Version | What it's for |
|---|---|---|
| `ttf-jetbrains-mono` | 2.304-2 | Plain JetBrains Mono for the shell UI (tracked micro-labels need the exact family; the Nerd variant registers a different name) |

```bash
sudo pacman -S --needed ttf-jetbrains-mono
```

## Notes for a fresh install

- Audio (pipewire + wireplumber), polkit, mesa (GL/Vulkan), glib2 and fontconfig
  come from a standard Arch install / earlier steps — install first if missing.
- Keep the **mesa + `intel-media-driver`** pairing: mesa for OpenGL/Vulkan, the
  driver for VA-API decode.

## Deliberately deferred / rejected

| Item | Why |
|---|---|
| `qt5-wayland` | No Qt5 apps installed yet |
| `mako` | **Removed 2026-10-15** — user does not use notifications; nothing else depended on it. `quickshell` is the candidate if a notification UI is ever wanted |
| `xdg-desktop-portal-gtk` | Pulls gtk3 — add when the first GTK app arrives |
| `uwsm` | User choice: launch directly from TTY |
| pacman `hyprland` | Replaced by the fork source build (step 2) |
| waybar / rofi / hyprpaper / hyprlock / hypridle | Rice phase — step 4 |
| grim+slurp | Installed 2026-10-16 as capture plumbing (own quickshell screenshot UI, not hyprshot) |
| SDDM or any display manager | TTY launch = fewer services, faster boot |
