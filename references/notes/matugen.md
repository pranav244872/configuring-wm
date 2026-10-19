# Dynamic colours (matugen)

The whole desktop palette follows the wallpaper. matugen quantises the current
image into a Material-3 scheme, writes it to each consumer's config path, and the
shell takes its own copy **live** — a wallpaper change repaints the bar, OSD,
dashboard, picker, notifications, lock card and screenshot chrome with no shell
restart.

Verified live 2026-10-19 (shell restart, wallpaper switch, per-consumer checks).

## Pipeline

```
wallpaper chosen (picker / bottom-right hot zone / SUPER+SHIFT+W / IPC)
  -> WallpaperService.current changes
     -> WallpaperHost.followWallpaper()      (skipped while WallpaperService.mock)
        -> Scheme.sync(path)                 modules/Scheme.qml
           -> matugen image <path> --mode dark --type scheme-content --prefer darkness
              |-- ~/.config/quickshell/colors.json   (no hook; Scheme re-reads it)
              |-- ~/.config/hypr/modules/colors.lua  (hook: hyprctl reload)
              |-- ~/.config/kitty/colors.conf        (hook: SIGUSR1 kitty)
              |-- nvim / gtk / qt6ct / btop / starship / opencode outputs
           -> Scheme re-reads colors.json
              -> Theme.palette re-evaluates (every role is a binding to Scheme)
                 -> Theme.colors (semantic layer) re-evaluates
                    -> every component using Theme.colors repaints
```

- `Scheme.qml` is state only (a 0.3.2 singleton roots on a bare `QtObject`): one
  `Process` to `cat` the JSON (same shape as the wallpaper state file) and one to
  run matugen. `WallpaperService.mock` keeps benches from generating.
- matugen writes its own source path into the output (`"image"` in colors.json,
  `image = "…"` in colors.lua), so startup can tell "palette already current"
  from "stale" and only regenerates when they differ. A fresh clone self-heals.
- The first JSON read completes about **1 s** after shell start under startup
  load (a 700 ms probe showed `hydrated: false`; 2 s showed 51 roles). Until then
  the palette is the built-in teal fallback.

## The command

```
matugen image <wallpaper> --mode dark --type scheme-content --prefer darkness
```

`scheme-content` keeps the wallpaper's own hues; the default `scheme-tonal-spot`
pulls everything toward one accent. `--prefer darkness` is what the old
configuring-wm setup passed. Mode, contrast, the template map and the post-hooks
live in `~/.config/matugen/config.toml`, so a manual run behaves identically.

## Templates → outputs

| Template | Output | Consumer |
|---|---|---|
| `hyprland-colors.lua` | `~/.config/hypr/modules/colors.lua` | `hyprland.lua`: `colors = require("modules.colors")`; decorations use `colors.primary` / `colors.surface_container_high` |
| `kitty-colors.conf` | `~/.config/kitty/colors.conf` | `kitty.conf` line 1: `include colors.conf` |
| `nvim-colors.json` | `~/.config/nvim/matugen-colors.json` | `daedlock/matugen.nvim` (`colors_path`, `watch = true`) |
| `quickshell-colors.json` | `~/.config/quickshell/colors.json` | `Scheme.qml` → `Theme.palette` |
| `gtk-colors.css` | `~/.config/gtk/gtk.css` | symlinked from `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` |
| `qtct-colors.conf` | `~/.config/qt6ct/colors/matugen.conf` | `qt6ct.conf` (`color_scheme_path`, `custom_palette=true`) |
| `btop-colors.theme` | `~/.config/btop/themes/matugen.theme` | `~/.config/btop/btop.conf`: `color_theme = "matugen"` (transparent `main_bg`); next btop start |
| `starship-colors.toml` | `~/.config/starship.toml` | fish: `starship init fish \| source`; read on every prompt |
| `opencode-colors.json` | `~/.config/opencode/themes/matugen.json` | `~/.config/opencode/tui.json`: `"theme": "matugen"` — v2 reads **tui.json**, not opencode.json; next start |

`quickshell-colors.json` is our own template: it emits every role matugen knows
plus `image`, e.g. `{"background": "#1d100f", …, "image": "…"}`.

## Theme role mapping (Theme.palette ← matugen)

| Theme | matugen | | Theme | matugen |
|---|---|---|---|---|
| background | background | | primary | primary |
| surface | surface_container † | | fgPrimary | on_primary |
| surfaceLowest | surface_container_lowest | | primaryContainer | primary_container |
| surfaceLow | surface_container_low | | fgPrimaryContainer | on_primary_container |
| surfaceContainer | surface_container | | secondary | secondary |
| surfaceHigh | surface_container_high | | secondaryContainer | secondary_container |
| surfaceHighest | surface_container_highest | | tertiary | tertiary |
| fgSurface | on_surface | | error | error |
| fgSurfaceVariant | on_surface_variant | | errorFg | on_error |
| outline | outline | | shadow | shadow |
| outlineVariant | outline_variant | | scrim | scrim |

† `palette.surface` mirrors `surfaceContainer` on purpose: in the old static teal
scheme it *was* the lifted surface (#1a2121), not M3's base surface. It is unused
by the semantic layer, so this only matters if a component starts using it.

The mapping was derived by matching every old palette hex against the old
generated `colors.lua` — no guessed role names. The hex literals left in
`Theme.qml` are the fallback for "no JSON yet"; the semantic `colors` layer and
all components are unchanged.

## Consumers and reload

| Consumer | Applies | Notes |
|---|---|---|
| quickshell | live | binding change; no restart, no signal |
| Hyprland | `hyprctl reload` post-hook | `hyprctl keyword` is **rejected** on this fork: "keyword can't work with non-legacy parsers. Use eval." A reload re-reads the Lua config; it does not restart the shell (autostart uses `hl.on("hyprland.start")`, which does not fire again) and windows survive |
| kitty | `SIGUSR1` post-hook | kitty reloads its config on that signal |
| nvim | immediately | the plugin `watch = true` sees the file change (proved by writing #ff00ff into the JSON: `Normal` bg became #fa53ff) |
| GTK | next app start / gsettings nudge | see below |
| qt6ct | next app start | `QT_QPA_PLATFORMTHEME=qt6ct` picks the palette up; verified with the qt6ct GUI |
| btop | next start | `color_theme = "matugen"`; the theme is read at launch |
| starship | every prompt | reads `starship.toml` per render |
| opencode | next start | `tui.json` → `"theme": "matugen"` |

## GTK (adw-gtk3-dark + prefer-dark)

configuring-wm's installer is the model: `adw-gtk-theme` + `qt6ct` packages,
`gtk-4.0/gtk.css` symlinked to `~/.config/gtk/gtk.css`, `gtk/settings.ini`
copied, then `gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark`
and `color-scheme prefer-dark` (its `setup_gtk()`).

Here: **one** canonical file `~/.config/gtk/gtk.css`, symlinked from *both*
`gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` (the old script only linked gtk-4.0, so
GTK3 apps never saw the overrides), plus `settings.ini` in both directories and
the two gsettings above.

What is verified:

- GTK is **dark** now: a zenity (GTK4 + libadwaita) dialog renders dark instead
  of the previous light Adwaita.
- `~/.config/gtk-4.0/gtk.css` **is loaded**: appending `* { color: #ff00ff; }`
  turned the dialog text magenta (rule removed afterwards).
- `adw-gtk3-dark`'s stylesheet references `window_bg_color` **220 times**, so GTK3
  apps that use that theme consume the matugen defines. No GTK3 app is installed
  here to exercise it live (Firefox draws its own chrome); this is static proof,
  not a live one.
- **Limitation:** plain libadwaita apps stay dark but *not* wallpaper-tinted.
  libadwaita's own palette wins over the `@define-color` overrides even though
  the user CSS loads. Tinting them would need a full CSS theme (all widget
  states), which is out of scope.

## Qt (qt6ct)

`qt6ct` + `QT_QPA_PLATFORMTHEME=qt6ct` in `env.lua`; `~/.config/qt6ct/qt6ct.conf`
already names `colors/matugen.conf` with `custom_palette=true`, so no manual
"select matugen" step is needed (the old repo left that as a manual post-install
step). Verified by launching `qt6ct` itself: window, title bar and preview are
dark with the wallpaper's rust palette.

## btop, starship, opencode (2026-10-19)

All three read a generated file directly — none needs a matugen hook.

- **btop** — `~/.config/btop/btop.conf` pins `color_theme = "matugen"`
  (`theme_background = True`; the theme's `main_bg` is empty, so btop stays
  transparent over the terminal). Verified by launching `kitty -e btop` and
  screenshotting it: meters and borders in the wallpaper's palette.
- **starship** — `starship init fish | source` in `~/.config/fish/config.fish`
  (previously a line in the "not ported yet" comment block). Verified with
  `starship prompt`: the escape emitted was `38;2;180;197;251`, i.e. the
  generated palette's primary.
- **opencode** — `~/.config/opencode/tui.json` holds `{"theme": "matugen"}`.

  **Trap:** opencode v2 selects the theme in `tui.json` — `theme` is *not* a key
  in `opencode.json` (`https://opencode.ai/config.json` has no such property,
  while `https://opencode.ai/tui.json` types `theme` as a string). Themes are
  loaded from `~/.config/opencode/themes/*.json`; ours defines `defs` plus 50
  `theme` groups with `{dark, light}` refs, which is the documented format.
  Verified by launching a throwaway TUI (`kitty -e opencode`) and screenshotting
  it: logo, prompt strip and model line render in the palette.



## What was pruned from the old setup

The configuring-wm config had 15 templates; it targeted waybar, rofi, mako,
swayosd, hyprlock and a base16 `neovim-colors.lua` (= the dead `matugen.lua`) as
well. None of those have a consumer on this machine (our quickshell UI replaced
the first five; our nvim uses the JSON plugin), so the live config references
only the ten above. The repo keeps the older template files, like it keeps
waybar/rofi/mako configs — they are not deployed.

The old config also wrote *into* the git repo (`~/del/configuring-wm/...`) and
had the installer copy out. The live config writes to the live paths instead;
the repo mirror is a separate copy step.

## Traps

- `hyprctl keyword general:col.active_border …` fails on the Lua fork — use the
  reload post-hook.
- A removed `hl.env` line does **not** unset the variable in the running session;
  it only disappears at the next login. Added vars do apply on `hyprctl reload`.
- `FileView` exists in quickshell 0.3.2 but `JsonAdapter` does not (checked the
  qmltypes), which is why Scheme uses `Process` + `JSON.parse`, matching
  `WallpaperService`.
- The generated files are tracked in `configuring-wm` (your choice): a wallpaper
  switch dirties the repo until the next mirror commit.
