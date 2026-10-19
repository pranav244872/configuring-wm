# Environment variables

Everything the session needs is set in **one place**: `~/.config/hypr/modules/
env.lua`. Hyprland is started from a TTY (no display manager; `fish` → the
`start-hyprland` wrapper → `Hyprland`), `~/.profile`/`.bashrc`/fish config export
nothing, there is no `/etc/environment` content and no `environment.d` — so
anything not set here is simply absent.

Audited 2026-10-19 against: the Hyprland source (`getenv` call sites), the
installed Qt6/SDL/GTK binaries, the Hyprland wiki env page, and the old
configuring-wm / omarchy / end-4 sets.

## Set

| Variable | Read by | Why |
|---|---|---|
| `XCURSOR_SIZE=24` | Hyprland (`CursorManager`) | XCursor size |
| `HYPRCURSOR_SIZE=24` | Hyprland | hyprcursor size |
| `XDG_CURRENT_DESKTOP=Hyprland` | Hyprland itself, portals | nothing above the TTY sets it |
| `XDG_SESSION_TYPE=wayland` | portals, toolkits | ditto |
| `XDG_SESSION_DESKTOP=Hyprland` | portals | ditto |
| `QT_QPA_PLATFORM=wayland;xcb` | Qt6 | Wayland first, X11 fallback |
| `QT_QPA_PLATFORMTHEME=qt6ct` | Qt6 | applies the dark matugen palette (`~/.config/qt6ct`) |

## Deliberately not set

Each line is a variable that *looks* essential in rice configs but is either
unread on this machine or actively harmful.

| Variable | Verdict |
|---|---|
| `HYPRLAND_TRACE` | debug logging, costs performance |
| `GDK_BACKEND` | GTK already prefers Wayland when `WAYLAND_DISPLAY` is set |
| `SDL_VIDEODRIVER` | sdl2-compat/SDL3 auto-detect Wayland; forcing it breaks X11-only games |
| `QT_AUTO_SCREEN_SCALE_FACTOR` | Qt5-only: `grep` over the installed Qt6 libs finds the name **0 times** |
| `QT_WAYLAND_DISABLE_WINDOWDECORATION` | same: 0 hits in installed Qt6 libs |
| `MOZ_ENABLE_WAYLAND` | Firefox ≥ 121 defaults to Wayland (installed 157.0.1) |
| `ELECTRON_OZONE_PLATFORM_HINT`, `OZONE_PLATFORM` | no Electron/Chromium app installed |
| `_JAVA_AWT_WM_NONREPARENTING` | no Java GUI app (mise installs java, nothing graphical); add with the first IDE |
| `LIBVA_DRIVER_NAME` | libva auto-selects iHD: CometLake-U + `intel-media-driver`, `iHD_drv_video.so` present |
| `WLR_NO_HARDWARE_CURSORS` | the fork exposes `cursor:no_hardware_cursors` — use the option if a cursor ever breaks |
| `GDK_SCALE`, `GDK_DPI_SCALE` | eDP-1 runs at scale 1 |
| `XCURSOR_THEME` | only Adwaita cursors installed; the default resolves to them |
| `GTK_THEME` | GTK is themed via gsettings (`adw-gtk3-dark`, `color-scheme prefer-dark`); an env var would override each app's own choice |
| `XDG_DATA_DIRS` (flatpak dirs) | flatpak is not installed |
| `HYPRSHOT_DIR` | hyprshot is not used (our own screenshot UI) |

## Verified facts

- Hyprland's own `getenv` set is small: `HOME`, `PATH`, `HYPRLAND_CONFIG`,
  `XDG_*`, `XCURSOR_SIZE`, `XCURSOR_THEME`, `HYPRCURSOR_SIZE`. It does **not**
  read `HYPRCURSOR_THEME`; the cursor theme comes from `XCURSOR_THEME`.
- The Qt verdicts come from grepping the installed `libQt6Gui.so.6` and the
  platform/wayland plugins, not from documentation.
- `hyprctl keyword`/`dispatch` on the Lua fork needs the Lua form. To spawn a
  process as a Hyprland child (used to read a child's real env):

  ```bash
  hyprctl dispatch 'hl.dsp.exec_cmd("sleep 41")'
  tr '\0' '\n' < /proc/$(pgrep -f '^sleep 41$')/environ
  ```

- **Added variables apply on `hyprctl reload`; removed ones do not.** A reload
  puts `QT_QPA_PLATFORMTHEME=qt6ct` into newly spawned children immediately, but
  `GDK_BACKEND`/`SDL_VIDEODRIVER`/`MOZ_ENABLE_WAYLAND`/`QT_AUTO_SCREEN_SCALE_FACTOR`
  kept appearing in children after their lines were deleted — they come from the
  compositor's runtime env map and clear only at the next login. (The config file
  and `/proc/$(pgrep -x Hyprland)/environ` both show them absent, so nothing is
  re-setting them.)
- `XDG_SESSION_CLASS`, `XDG_SESSION_ID`, `XDG_SESSION_TYPE` are also present from
  logind/systemd; setting the two XDG values in `env.lua` is for the portal/TTY
  case, not a duplicate of a DM.

Related but *not* env: `xdg-user-dir PICTURES` returns `$HOME` (no
`~/.config/user-dirs.dirs`), while our screenshot UI saves to `~/Screenshots` and
mpv to `~/Pictures/Screenshots` — see [wallpaper.md](wallpaper.md)/[screenshot.md](screenshot.md)
if that ever needs unifying.
