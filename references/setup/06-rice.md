# Step 4 — Rice Layer

**Status: 🔄 partially done** — the shell, OSD, lock screen and screenshots were
replaced by our own quickshell work (see [../shell.md](../shell.md)), so this
table now tracks the *remaining* rice packages. Off it, **`eza`** is done
(2026-10-18, fish `ls`/`lt` — see [../preferences.md](../preferences.md)); the
rest of the extras are not installed.

Everything deferred on purpose so the WM could be usable and fast first. All of
it is in official repos. Install order is up to taste, but each item needs the
previous layer's pieces (e.g. a bar wants a font + theme colours).

| Piece | Packages | Binds it would serve (from the old setup) |
|---|---|---|
| Launcher + menus | `rofi` (+ port `.config/rofi` from `configuring-wm`) | `SUPER+F` launcher · `SUPER+ESCAPE` powermenu · `SUPER+K` keybind menu · `SUPER+SHIFT+R` recording |
| Status bar | `waybar` — or a custom **quickshell** (Qt/QML) shell if waybar isn't enough; quickshell is already installed | — |
| Wallpaper | `hyprpaper` (or `swww`/`awww`) + picker | `SUPER+SHIFT+W` |
| Lock + idle | `hyprlock` + `hypridle` (old confs: lock 3 min, screen off 5 min, suspend 10 min) | `SUPER+L` |
| OSD | `swayosd` | makes the volume/brightness keys show feedback (currently silent) |
| Screenshots | own quickshell utility (`PRINT`: capture → annotate → Save/Copy/Discard) + `grim`/`slurp` plumbing | `PRINT` (mode buttons inside for output/window/region) |
| Screen recording | `wf-recorder` | `SUPER+SHIFT+R` |
| Night light | `hyprsunset` | autostart |
| Notifications | *(none — mako was removed; build one with quickshell if ever wanted)* | — |
| Theme / extras | `qt6ct`, `matugen`, `adw-gtk-theme`, `eza`, `bat`, `fzf`, `starship` | fish prompt + aliases |
| Audio helper | `pavucontrol`, `bluez-utils` | `SUPER+XF86AudioMute` output switch script |

See [../preferences.md](../preferences.md) for the look these should match (teal
Material palette, no blur, fast animations).
