# Application Decisions

Per-application choices and the reason behind each. The "why" of the setup
lives here; what is actually built lives in [shell.md](shell.md) and
[notes/](notes/README.md).

Back to [preferences.md](preferences.md) - [docs index](README.md)

## Media player (mpv)

- **UI-first, not keybind-first.** The user does not want to memorise keys:
  everything reachable must be clickable. `right-click` anywhere opens uosc's
  searchable menu; speed and volume are bars you scroll/drag.
- **UI = uosc** (vendored from its GitHub release, *not* a pacman package —
  vendoring beats the AUR route). It replaced **modernz** and **select.lua**;
  the old config is
  parked at `~/del/mpv-legacy-config/mpv` (rollback = move files back).
- Config rebuilt **from scratch, bare**: `~/.config/mpv/mpv.conf` plus a
  one-line `input.conf`. mpv's own default keys stay untouched
  (no `no-input-default-bindings`).
- Kept from the old setup: Netflix Sans fonts for OSD + subtitles
  (`~/.config/mpv/fonts`), screenshots → `~/Pictures/Screenshots`,
  `vo=gpu-next` + `gpu-api=opengl`, anime-first audio/subtitle language.
- uosc's subtitle-search binaries (ziggy) were deleted — not wanted.

## Text editor (Neovim)

- `neovim` **0.12.6** plus `fzf`, `tree-sitter-cli`, `unzip`, `fd` (2026-10-19,
  see [package-management.md](package-management.md)). The config is the
  `configuring-wm` one, deployed **verbatim** — `diff -rq
  ~/del/configuring-wm/.config/nvim ~/.config/nvim` prints nothing, the same
  rule the rest of this repo follows.
- Built on **`vim.pack`** (0.12's built-in manager): `nvim-pack-lock.json` pins
  every plugin rev. No lazy.nvim. The config needs 0.12 — `vim.pack` and
  `vim.lsp.config`/`enable` don't exist in 0.11.
- **LSP through mason**: `lua_ls`, `clangd`, `pyrefly` ensured on start, living
  in `~/.local/share/nvim/mason/bin` (mason builds its own venv for the pypi
  one, so `python-pip` is not needed).
- **Treesitter** uses the `main` branch API and **compiles** c/cpp/markdown/
  markdown_inline locally — that is what `tree-sitter-cli` + gcc are for, and
  why there is no prebuilt download to quietly fail.
- **Theme** is read from `~/.config/nvim/matugen-colors.json`, which the
  matugen template `.config/matugen/templates/nvim-colors.json` generates. The
  JSON is committed, so colours are static and the `matugen` **binary is not
  installed** — install `extra/matugen` only to make the editor follow the
  wallpaper.
- **`Space` is the leader**: `ff` files · `fg` live grep · `fb` buffers · `fh`
  help · `fk` keymaps · `en` nvim config · `p` package UI · `rd`/`cw` oil
  floats · `z{j,k,a,A,R,M,f}` folds · `ca` code actions. LSP: `grn` rename,
  `grd`/`grD`/`grt` definitions, `grr` references, `gri` implementations,
  `gO`/`gW` symbols, `K` pretty hover, `th` inlay hints. `C-h/j/k/l` move
  splits (creating one at the edge), `A-h/j/k/l` resize.
- **Mouse on** (`mouse=a`) and clipboard `unnamedplus`, so `wl-clipboard` is
  load-bearing for yank/paste parity with the rest of the rice.
- Dead weight found in the config and deliberately left alone:
  `lua/plugins/mini-pairs.lua` (its plugin is missing from `vim.pack.add`, so
  the `pcall` skips it — harmless, `autoclose.nvim` does the same job) and
  `matugen.lua` (a generated base16 colourscheme nothing requires). Details,
  bootstrap commands and the verification method: [notes/neovim.md](notes/neovim.md).

## Notifications

- **Our shell is the notification daemon** (built 2026-10-19) — see
  [shell.md](shell.md) and [notes/notifications.md](notes/notifications.md). It
  was not always so: `mako` was installed in step 1 and **removed on
  2026-10-15** (the user did not use notifications then, and nothing else
  depended on it), and for a while nothing owned
  `org.freedesktop.Notifications` at all. `quickshell`'s `NotificationServer` now
  takes the bus name, so **do not install a daemon back in**: no mako, dunst or
  swaync, and no `libnotify` either.
- Toasts are sent to us over plain D-Bus, which is also how they are tested:
  `gdbus call --session --dest org.freedesktop.Notifications --object-path
  /org/freedesktop/Notifications --method org.freedesktop.Notifications.Notify
  "App" 0 "" "Summary" "Body" "[]" "{'urgency': <byte 2>}" 0` (no library needed).

## Desktop shell (quickshell)

- `quickshell` (QtQuick/QML toolkit) is installed and is the **preferred way to
  build our own UI**. The old `configuring-wm` script installed a lot of
  external tools for shell functions (hyprlock, hypridle, hyprsunset, waybar,
  rofi, mako, swayosd, hyprshot, hyprpicker, pavucontrol, blueberry …) — the
  user wants those **replaced by our own quickshell versions wherever practical**.
- Reason: fewer packages and daemons, one toolkit we control, consistent look,
  and it fits "mouse UI over keybinds".
- Plan, candidate list and build order: **[shell.md](shell.md)**.
- Non-UI plumbing (ffmpeg, grim/slurp, pipewire, …) stays external on purpose.
- **Layout** (the shape future UI pieces should copy):
  `shell.qml` (ShellRoot) → `modules/<feature>/` → `modules/widgets/` →
  `modules/{Theme,ColorUtils}.qml` singletons. Palette → semantic colors →
  components, so a theme swap only touches the palette.
- **Icons**: `ttf-material-symbols-variable` (official extra), ligature *names*
  (`"volume_up"`) in `"Material Symbols Rounded"` — the approach end-4 and
  caelestia use. Nerd Fonts stay for the terminal only.
- **UI text is JetBrains Mono** (`ttf-jetbrains-mono`, official extra): the
  Chaldea look needs the exact family for tracked-out uppercase micro-labels
  (the Nerd variant registers a different family name and won't match).
- **Chaldea frame language** (our teal kept): square 1px hairline borders,
  accent corner ticks (`CornerTicks`), tracked uppercase labels, 1px divider
  rules, solid-accent selection rows with dark text. No rounding, no pills.
- **Icons are binned, never scaled**: a value picks a *different* icon
  (`Icons.volume()` mute/low/normal, `Icons.brightness()` seven bins, like
  end-4's battery icons) instead of growing one. The pill width is a fixed
  token and the icon sits in a fixed-size box, so nothing in the OSD can resize
  the pill — the user flagged scaling as bad design and asked for bins.
- **The OSD is mouse-first, drag-only** (the user's call): press anywhere on
  the bar to jump there, drag to follow, release to finish. **No wheel
  handling** — the volume/brightness keys already step, and the user doesn't
  want a second way to do it. The handle appears on hover/drag; **no value
  tooltip**, because the percentage next to the pill already says it.
- **Spacing follows end-4's `OsdValueIndicator`**: asymmetric padding (left 12,
  right 20 — *"an icon is circle ish, a column isn't"*), icon↔column 12, and
  only ~7 px between the label row and the bar. The bar's layout slot is kept
  tight (8 px) and the drag target is inflated from it instead, so the bar sits
  close to its label while staying easy to grab. Asked for after the first
  spacing pass looked loose.
- **Dragging writes through the same tools we read with** (`wpctl`,
  `brightness.sh`), coalesced to ~20 writes/second, instead of writing
  PipeWire directly like the references do — see the hardware-volume trap in
  [notes/](notes/README.md).
- **A hidden OSD must not catch clicks** (user's call, 2026-10-15). The window
  is always on screen at a fixed size, and a transparent item still receives
  mouse events — so before the fix, clicking the bottom-centre of the screen
  where the invisible pill sits fired the slider and **changed the volume**.
  Fixed with `mask: Region { item: content; intersection: showing ? Combine : Xor }`,
  which is clickthrough-only and keeps the fade. Every future overlay needs
  this; `enabled: false` is not enough (the click is swallowed, not passed on).
  Full write-up in [notes/quickshell.md](notes/quickshell.md).
- **Verification**: `~/.config/quickshell/preview.qml` renders the real
  components to `/tmp/opencode/preview.png` (`qs -p
  ~/.config/quickshell/preview.qml`) so UI work can be *seen*, not guessed.
  Placement is checked with `hyprctl layers` rather than screen-grabbing.
