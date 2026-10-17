# Step 1b — Fork Build Dependencies

Part 2 of [step 1](01-minimal-bare-install.md).

**Why this part exists:** `pacman -S hyprland` would pull all of these
automatically as declared dependencies. Building
`pranav244872/Hyprland @ invisible-ss` from source has no such metadata, so they
are installed explicitly. They are exactly the dependencies the official
`hyprland` package declares. Versions as of 2026-10-15.

## 2a. Build toolchain

```bash
sudo pacman -S --needed --noconfirm base-devel cmake python git
```

| Package | Version | What it's for |
|---|---|---|
| `base-devel` | 1-2 | gcc, make, pkgconf — build essentials |
| `cmake` | 4.4.4-1 | Hyprland's build system |
| `python` | 3.14.8-1 | Interpreter for build codegen / shader scripts |
| `git` | 2.56.0-1 | Fetch and update the fork |

## 2b. hypr\* ecosystem libraries (runtime + headers)

```bash
sudo pacman -S --needed --noconfirm aquamarine hyprcursor hyprgraphics hyprlang hyprutils \
  hyprwire hyprtoolkit hyprland-guiutils hyprland-protocols hyprwayland-scanner
```

| Package | Version | What it's for |
|---|---|---|
| `aquamarine` | 0.15.1-1 | hypr* backend/DRM library (rendering + session/seat handling) |
| `hyprcursor` | 0.1.13-7 | hyprcursor cursor-theme format library |
| `hyprgraphics` | 0.5.1-4 | Graphics helpers (image loading, icons) |
| `hyprlang` | 0.6.8-5 | hypr* config-language parser |
| `hyprutils` | 0.14.2-1 | Core utility library (OS, math, IPC, signals, animations) |
| `hyprwire` | 0.3.1-3 | IPC wire-protocol library — **required by `hyprctl`** |
| `hyprtoolkit` | 0.6.0-1 | GUI toolkit used by hypr* utility apps |
| `hyprland-guiutils` | 0.2.2-4 | `hyprland-dialog`, `hyprland-run`, `hyprland-welcome` |
| `hyprland-protocols` | 0.7.1-1 | hypr* Wayland protocol definitions |
| `hyprwayland-scanner` | 0.4.6-1 | Wayland protocol code generator (build-time tool) |

## 2c. System libraries (Wayland / X11 / graphics)

```bash
sudo pacman -S --needed --noconfirm cairo pango libdrm libinput libxkbcommon pixman wayland \
  wayland-protocols libglvnd glslang lcms2 muparser re2 tomlplusplus util-linux-libs xcb-proto \
  xcb-util xcb-util-errors xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm \
  libx11 libxcb libxcomposite libxcursor libxfixes libxrender xorg-xwayland lua
```

| Package | Version | What it's for |
|---|---|---|
| `cairo` | 1.18.6-1 | 2D vector graphics (rendering surfaces) |
| `pango` | 1:1.58.2-1 | Text layout/rendering |
| `libdrm` | 2.4.134-1 | Kernel DRM interface |
| `libinput` | 1.32.0-1 | Input device handling (mouse/touchpad/keyboard) |
| `libxkbcommon` | 1.13.2-1 | Keyboard layout/mapping handling |
| `pixman` | 0.46.4-1 | Pixel manipulation (software rendering paths) |
| `wayland` | 1.26.0-1 | Wayland client/server libraries |
| `wayland-protocols` | 1.49-1 | Standard Wayland protocol definitions |
| `libglvnd` | 1.7.0-3 | OpenGL/EGL vendor-neutral dispatch layer |
| `glslang` | 1:1.4.363.0-1 | GLSL shader compiler (Hyprland's internal shaders) |
| `lcms2` | 2.19.1-1 | Color management (ICC profiles) |
| `muparser` | 2.3.5-2 | Math parser (bezier/animation evaluation) |
| `re2` | 2:2025.11.05-6 | Regex engine (window/layer rules + hyprctl) |
| `tomlplusplus` | 3.4.0-2 | TOML parser (hyprpm / hyprctl bits) |
| `util-linux-libs` | 2.42.4-1 | libuuid and friends |
| `xcb-proto` | 1.17.0-4 | XCB XML protocol descriptions |
| `xcb-util` | 0.4.1-2 | XCB utility glue (atoms etc.) |
| `xcb-util-errors` | 1.0.1-2 | Human-readable XCB errors |
| `xcb-util-image` | 0.4.1-3 | XCB image helpers |
| `xcb-util-keysyms` | 0.4.1-5 | XCB keysym constants |
| `xcb-util-renderutil` | 0.3.10-2 | XCB render helpers |
| `xcb-util-wm` | 0.4.2-2 | XCB WM hints (ICCCM/EWMH — XWayland windows) |
| `libx11` | 1.8.13-2 | X11 client library (XWayland) |
| `libxcb` | 1.17.0-1 | X protocol C binding |
| `libxcomposite` | 0.4.7-1 | X composite extension |
| `libxcursor` | 1.2.3-1 | X cursor handling |
| `libxfixes` | 6.0.2-1 | X fixes extension |
| `libxrender` | 0.9.12-1 | X render extension |
| `xorg-xwayland` | 24.1.14-1 | XWayland — legacy X apps inside the session |
| `lua` | 5.5.1-1 | Config engine (`hyprland.lua`); fork needs >=5.5, <5.6 |

Packages with no reverse dependency that therefore **must stay explicit**
because nothing else pulls them: `glslang`, `muparser`, `re2`,
`xcb-util-errors`, `libxcomposite`, `xorg-xwayland`.

Two build inputs are not packaged at all and are fetched during the build:
**glaze v7.2.0** (CMake FetchContent, needs network on first configure) and the
**udis86** git submodule (initialise before building).
