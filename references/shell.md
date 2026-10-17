# Our Shell (quickshell)

**Status: 🔄 in progress** — OSD, bar, launcher, screenshots, calendar, tray icons, keep-awake toggle **done**; lock screen built, live auth test pending; notifications next.

## What exists today

`~/.config/quickshell/`

| File | Role |
|---|---|
| `shell.qml` | entry point (`ShellRoot`); loads bar, OSD, launcher, screenshots, calendar |
| `preview.qml` | visual test bench (dark bg) |
| `preview_topbar.qml` | bar-flare A/B geometry bench (white bg) |
| `preview_white.qml` | full mock screen: bar + launcher + OSD, for curve/icon critique |
| `modules/Theme.qml` | palette → semantic colors → rounding/font/sizes/frame/animation tokens (`frame`: hairlines, ticks, tracking) |
| `modules/Icons.qml` + `ColorUtils.qml` | value→icon bins (never scale); colour maths |
| `modules/widgets/` | `StyledShadow`, `StyledText`, `StyledBar`, `Slider`, `Glyph`, `Ripple`, `CornerTicks` |
| `modules/osd/` (`OsdHost`, `OsdIndicator`) | volume/brightness pill: reactive PipeWire, IPC brightness, drag-to-set, 1.4s hide |
| `modules/bar/TopBar.qml` | top bar window: 30px square island, exclusiveZone 30 (12px gap = gaps_out) |
| `modules/bar/BarSurface.qml` | square island: 1px hairline border + corner ticks (shared) |
| `modules/bar/BarIsland.qml` | surface + tracked clock/dividers/workspaces/battery row, 1px optical lift |
| `modules/bar/BarTray.qml` | tray icons left of clock, hidden when empty; left = activate, right = menu (opens under the clicked icon, flips up at the bottom edge), wheel = scroll |
| `modules/bar/TrayMenu.qml` + `TrayMenuHost.qml` | app context menu (QsMenuOpener stack) in an overlay; `TrayState` singleton shares open state |
| `modules/bar/BarClock.qml` + `BarBattery.qml` | weekday/date/time clock + UPower battery, tracked mono |
| `modules/bar/WorkspaceIndicator.qml` | workspaces 1..5 + active/occupied >5; sliding block, pill-tracked digits, occupied tick markers, dim empties (center module) |
| `modules/bar/BarBattery.qml` | UPower battery indicator with dynamic charge icons and percentage (right module) |
| `modules/launcher/LauncherWindow.qml` + `AppTracker.qml` | full-height left drawer on Super+F / IPC; frequencies persist to cache |
| `modules/lock/LockHost.qml` | real WlSessionLock + IPC (`lock`/`unlock`/`isLocked`); password-only PAM; SUPER+L |
| `modules/lock/LockSurface.qml` | per-output lock surface: near-black backdrop, centered card |
| `modules/lock/LockCard.qml` | formation card: user chip, big clock+date, password field + submit |
| `modules/lock/LockAuth.qml` | password-only PAM machine (`login` stack); buffer cleared every path |
| `modules/lock/IdleService.qml` | staged IdleMonitors: lock 3m, screen-off 5m (floor 1%), suspend 10m |
| `modules/launcher/LauncherSurface.qml` | full-height drawer: layer0 fill, ticks, no bezel-side borders (shared) |
| `modules/launcher/LauncherContent.qml` | tracked header + rule, square search, ranked list, footer hint (shared) |
| `modules/launcher/LauncherItem.qml` | square rows, uppercase names, solid primary selection + ripple |
| `modules/launcher/LauncherWindow.qml` | full-height left drawer on Super+F / `qs ipc call launcher toggle` |
| `modules/screenshot/ScreenshotHost.qml` | Print captures output → select (region/window/full) → annotate in a floating window; Print+Esc always close (`qs ipc call screenshot toggle`) |
| `modules/screenshot/ScreenshotStore.qml` | crop view, strokes, movable/resizable text labels, undo/redo stacks, tool state |
| `modules/screenshot/ScreenshotSelector.qml` | dimmed capture + region drag (aim lines, clamped) + window hover-pick (active workspace only) |
| `modules/screenshot/AnnotationStage.qml` | canvas: checkerboard, cropped capture, pen strokes, text labels; the export target |
| `modules/screenshot/ScreenshotEditor.qml` | floating window: titlebar move, SE resize (aspect-locked), status bar |
| `modules/screenshot/AnnotationToolbar.qml` | reselect / pen+text / swatches+width menu / undo+redo / save+copy+discard pill |
| `modules/calendar/` (`CalendarWidget`, `CalendarCard`, `calendar_layout.js`) | desktop month window: background layer, click-through mask, drag anywhere, Monday-first grid |
| `modules/Caffeine.qml` | keep-awake singleton (`enabled`); the bar holds the wayland idle inhibitor |
| `modules/bar/BarCaffeine.qml` | coffee toggle at the right end of the bar (`qs ipc call caffeine toggle`) |

Run: autostarted at login (`qs -n`) · stop: `qs -k` · restart: `SUPER + SHIFT + O`.
`SUPER + F` toggles launcher, `PRINT` toggles screenshots.

**Keep-awake (caffeine)** — the coffee button at the right of the bar toggles a
wayland idle inhibitor held by the bar window (`TopBar.qml`). `IdleService` uses
`respectInhibitors: true`, so lock / screen-off / suspend all stop while it is
on. Not persisted: it resets to off on a shell restart. IPC: `qs ipc call
caffeine <toggle|enable|disable|isEnabled>`. Mechanism and the layer-surface
proof are in [notes/idle-inhibit.md](notes/idle-inhibit.md). Verified 2026-10-17.

## Preview benches (use them, don't guess)

Each `/preview*.qml` is a standalone bench: renders real components, saves a PNG, quits; safe while the main `qs` instance is up.

```bash
qs -p ~/.config/quickshell/preview.qml        # → /tmp/opencode/preview.png
qs -p ~/.config/quickshell/preview_white.qml  # → /tmp/opencode/preview_white.png
qs -p ~/.config/quickshell/preview_screenshot.qml # → /tmp/opencode/preview_screenshot.png
qs -p ~/.config/quickshell/preview_calendar.qml # → /tmp/opencode/preview_calendar.png
```

| Bench | What it renders | Uses |
|---|---|---|
| `preview.qml` | two bar variants + all four OSD states — dark bg | icon bins, chip styling |
| `preview_white.qml` | 960×560 mock screen: bar, launcher drawer (real Papirus icons, frequency-sorted), OSD — with marked screen boundary | frame language check, overall trip |
| `preview_screenshot.qml` | floating editor + toolbar with mock strokes/texts (no capture) | pen rendering, toolbar layout |
| `preview_calendar.qml` | desktop calendar card on dark bg | grid math, today pill, chrome |
| `preview_lock.qml` | formation card in typing + failed states (no session lock) | card visuals, auth states |

Open the PNG (or hand it to an image-reading agent) and critique what is rendered — that is how the bar/launcher curve mismatch was caught.

**The Top Bar**: 30px square island, 1px hairline + corner ticks.
`exclusiveZone: 30` reserves exactly the bar height, so the bar gap always equals `gaps_out` (12px, same as edges).
All geometry lives in `Theme.bar`; `BarSurface` / `BarIsland` render it for the screen and the benches alike.
The content row sits 1px high: optical centering over the bottom-only border.

**The App Launcher**: 400×520 drawer on the left screen edge, same flare tokens as the bar rotated 90°.
Apps are sorted dynamically by launch frequency (highest to lowest), falling back to alphabetical, with Papirus icons, live search filter, and full keyboard navigation (Up, Down, Enter, Esc).

## The principle (user's decision)

> A lot of the packages installed by the old `configuring-wm` script are external
> tools. We should **write our own versions with quickshell instead**, wherever
> it is practical to do so.

Why this fits this setup: it is the same philosophy as "bare minimum" — fewer packages, fewer processes, one toolkit (`quickshell` + QML) instead of a dozen small daemons. It also serves the "mouse UI over keybinds" preference: everything lives in one shell that we control.

## What quickshell already gives us

Verified module inventory (`/usr/lib/qt6/qml/Quickshell/`):

| Module | Gives us |
|---|---|
| `Quickshell` (core) | `ShellRoot`, `PanelWindow`, `Timer`, `Process`, `Variants` |
| `Quickshell.Services.SystemTray` | tray icons |
| `Quickshell.Services.Notifications` | **notification daemon** (replaces mako) |
| `Quickshell.Services.Mpris` | media sessions (play/pause, metadata) |
| `Quickshell.Services.UPower` | battery + power state (event-driven) |
| `Quickshell.Services.Pipewire` | audio/pw-volume → volume control |
| `Quickshell.Services.Bluetooth` | BT devices |
| **`Quickshell.Services.Pam`** | **PAM authentication → a real lock screen is possible** |
| `Quickshell.Services.Polkit` | polkit prompts |
| `Quickshell.Hyprland` | compositor IPC: windows, workspaces, focus grab |
| `Quickshell.Wayland.WlrLayerShell` | panels/overlays anchored to screen edges |
| `Quickshell.Wayland.IdleNotify` / `IdleInhibitor` | idle detection & inhibition |
| `Quickshell.Wayland.ScreenCopy` | screenshots |
| `Quickshell.Wayland.ToplevelManagement` | window list |
| `Quickshell.Widgets` | rounded rects, clipping, icon images |

## What we replace with our own code

| External tool (old setup) | Our quickshell version | Caveats | Status |
|---|---|---|---|
| `swayosd` (was AUR) | volume/brightness OSD panel | built 2026-10-15: volume reactive off PipeWire, brightness via IPC | ✅ done |
| `waybar` | status bar | built 2026-10-15, restyled 2026-10-16: floating island bar, sliding workspace pill, HH:mm clock, battery | ✅ done |
| `rofi` (launcher) | app launcher drawer | built 2026-10-15, restyled 2026-10-16: Papirus icons, frequency ranking, flare drawer, ripple rows, SUPER+F | ✅ done |
| `rofi` (powermenu, keybinds) | power menu, clipboard history | powermenu & cliphist next | ⬜ |
| `hyprsunset` | night-light overlay (ramped tint) | colour overlay via `WlrLayerShell` | ⬜ |
| `hypridle` | idle service (dim, lock, suspend) | `IdleNotify` + our own timer logic | ⬜ |
| `hyprlock` | lock screen (clock, input, PAM auth) | **security-sensitive**: UI ours, auth must stay in PAM (`Services.Pam`) | ⬜ |
| `hyprshot` | screenshot UI (region flash, "saved" toast) | replaced 2026-10-16 by our own utility (Print); capture still uses `grim` | ✅ done |
| `hyprpicker` | colour picker | uses `ScreenCopy` | ⬜ |
| `pavucontrol` | audio quick-settings panel | `Services.Pipewire` | ⬜ |
| `blueberry` (was AUR) | BT panel | `Services.Bluetooth` | ⬜ |
| `matugen`, `hyprtoolkit` GUIs | generate palette in-shell / custom dialogs | low priority | ⏸ |
| `gpu-screen-recorder`, `awww`/wallpaper daemons | keep external | encoding/wallpaper plumbing, not UI | ⏸ keep |

### Staying external (not UI — no point rewriting)
`ffmpeg`, `grim`, `slurp`, `jq`, `pipewire`, `wl-clipboard`, `kitty`, `mpv`,
`fish`, `zoxide`, `power-profiles-daemon`, browsers, build tools.

## Suggested build order

1. **OSD** (replaces swayosd) — small, makes the volume/brightness keys visible
2. **Bar** (replaces waybar) — the centrepiece
3. **Notifications** (replaces mako) — also unlocks the battery reminder
4. **App launcher + power menu** (replaces rofi usage)
5. **Night light** (replaces hyprsunset)
6. **Idle + lock** (replaces hypridle/hyprlock) — security-sensitive, do late
7. Screenshot UI ✅ done 2026-10-16 (Print → select → annotate → Save/Copy), clipboard history, audio/BT panels next

Each item also closes an entry in [qol/](qol/README.md) when adopted.

## Ground rules for our own shell

- **Bare minimum by default, but ask before adding packages** — a package that
  removes a pile of workaround code is worth installing (see
  [preferences.md](preferences.md)).
- **Icons come from two sources**: Material Symbols (`ttf-material-symbols-variable`)
  for UI controls via ligatures; Papirus (`papirus-icon-theme`) for desktop apps via
  `//@ pragma IconTheme Papirus` at line 1 of `shell.qml` and `Quickshell.iconPath()`.
- **Architecture comes from references**: end-4 / caelestia / DMS, checked
  against the quickshell source at our exact version.
- Config lives in `~/.config/quickshell/`; keep it small, commented, and driven by `qs -c <name>` configs rather than one giant file.
- Every key-driven feature also gets a mouse path (user preference).
- Quickshell autostarts at login (`autostart.lua`); `SUPER + SHIFT + O` restarts it.
