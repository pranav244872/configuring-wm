# Our Shell (quickshell)

**Status: 🔄 in progress** — OSD, bar, launcher, screenshots, calendar, tray icons, keep-awake toggle, session menu, dashboard (tabbed: network + notifications), bar network status (hover tooltip) and the **notification daemon + toasts** **done**; lock screen built (lock/unlock verified 2026-10-17, PAM auth test pending).

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
| `modules/bar/BarIsland.qml` | surface + content row: tray, clock, workspaces, DND bell, network meter, battery, caffeine (1px optical lift) |
| `modules/bar/BarTray.qml` | tray icons left of clock, hidden when empty; left = activate, right = menu (hangs 6px under the bar, flips up at the bottom edge), wheel = scroll |
| `modules/bar/TrayMenu.qml` + `TrayMenuHost.qml` | app context menu (QsMenuOpener stack) in an overlay; `TrayState` singleton shares open state |
| `modules/bar/BarClock.qml` + `BarBattery.qml` | weekday/date/time clock + UPower battery, tracked mono |
| `modules/bar/WorkspaceIndicator.qml` | workspaces 1..5 + active/occupied >5; sliding block, pill-tracked digits, occupied tick markers, dim empties (center module) |
| `modules/bar/BarBattery.qml` | UPower battery indicator with dynamic charge icons and percentage (right module) |
| `modules/launcher/LauncherWindow.qml` + `AppTracker.qml` | full-height left drawer on Super+F / IPC; frequencies persist to cache |
| `modules/lock/LockHost.qml` | real WlSessionLock + IPC (`lock`/`unlock`/`isLocked`); password-only PAM; locks on idle (3m) or `Fn+F9` |
| `modules/lock/LockSurface.qml` | per-output lock surface: near-black backdrop, centered card |
| `modules/lock/LockCard.qml` | formation card: user chip, big clock+date, password field + submit |
| `modules/lock/LockAuth.qml` | password-only PAM machine (`login` stack); buffer cleared every path |
| `modules/lock/IdleService.qml` | staged IdleMonitors: lock 3m, screen-off 5m (floor 1%), suspend 10m; fullscreen holds all three, MPRIS playback holds blank+suspend |
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
| `modules/bar/BarNetwork.qml` | signal meter at rest; tooltip on 300ms hover (SSID · strength · security · IP) 6px under the bar; click opens the dashboard. Native `Quickshell.Networking`, IP from a one-shot `ip` |
| `modules/bar/NetworkTooltip.qml` | tooltip frame content (layer0 fill, hairline + corner ticks); shared with the bench |
| `modules/powermenu/PowerMenuHost.qml` | session menu: content-sized panel on the right, vertically centred, slides in from the bezel; opened by the right-edge hot zone or `qs ipc call powermenu toggle`; Escape / click-away closes |
| `modules/powermenu/PowerMenuContent.qml` + `PowerMenuItem.qml` | entries Lock / Log out / Suspend / Reboot / Shut down; Chaldea rows with the accent fill sliding in on hover (shared with the bench) |
| `modules/powermenu/PowerMenuSurface.qml` | floating framed panel: layer0 fill, 1px hairline + corner ticks (shared) |
| `modules/dashboard/DashboardHost.qml` | bottom sheet: `Theme.sizes.dashboardWidth` wide (720), 40% of the monitor height, centred; bottom-edge hot zone / `qs ipc call dashboard toggle`; Escape / click-away closes; `←`/`→` change tab |
| `modules/dashboard/DashboardTabs.qml` | the tab row: equal-width numbered cells, solid accent block on the active one (slides on the move curve), wheel to step; each section is one tab |
| `modules/dashboard/DashboardContent.qml` | tab host: the tab row over a `StackLayout` of the sections, and the one place that decides which section is allowed to work (the network list scans only while its tab is visible) |
| `modules/dashboard/NetworkSection.qml` | wifi switch, scanning list, inline passphrase, connect / disconnect / forget, portal + off states; scans only while the sheet is open |
| `modules/dashboard/NetworkRow.qml` | one network: signal + SSID + security/state; expands in place for the passphrase, or for Disconnect / Forget + IP when connected |
| `modules/dashboard/network_list.js` | sort rank (connected → connecting → saved → signal), signal level, PSK validation rules |
| `modules/notifications/NotificationService.qml` | the daemon: `NotificationServer` singleton (bus name `org.freedesktop.Notifications`), toast model, lifetimes, DND (persisted), session history |
| `modules/notifications/NotificationHost.qml` | toast stack overlay (top-right, clear of the bar), per-toast countdown, IPC target `notifications` |
| `modules/notifications/NotificationCard.qml` | one notification: avatar/app/summary/body, urgency strip, countdown drain, hover ✕ — shared with the dashboard history |
| `modules/dashboard/NotificationsSection.qml` | DND switch + toast history; rows reuse `NotificationCard` |
| `modules/bar/BarDnd.qml` | bell-off button, shown only while DND is on; click toggles |
| `modules/widgets/Toggle.qml` | square hairline toggle, shared by dashboard sections |
| `modules/widgets/Spinner.qml` | loading spinner: eight square dots chasing, snapped to whole pixels (rotating a glyph pixelates — `StyledText` uses `Text.NativeRendering`) |
| `modules/widgets/SignalBars.qml` | four-bar signal meter (rectangles, crisp at 16-20px) used by the network rows |

Run: autostarted at login (`qs -n`) · stop: `qs kill` · restart: `SUPER + SHIFT + O`.
`SUPER + F` toggles launcher, `PRINT` toggles screenshots.

**Keep-awake (caffeine)** — the coffee button at the right of the bar toggles a
wayland idle inhibitor held by the bar window (`TopBar.qml`). `IdleService` uses
`respectInhibitors: true`, so lock / screen-off / suspend all stop while it is
on. Not persisted: it resets to off on a shell restart. IPC: `qs ipc call
caffeine <toggle|enable|disable|isEnabled>`. Mechanism and the layer-surface
proof are in [notes/idle-inhibit.md](notes/idle-inhibit.md). Verified 2026-10-17.

**Session menu** — the right screen edge is a native hot zone
(`right = { action = "exec, qs ipc call powermenu toggle" }` in
`~/.config/hypr/modules/hotzones.lua`) that slides the session menu in. Hot zones
are a fork feature: config keys, geometry and the runtime API are in
[notes/hotzones.md](notes/hotzones.md).

**Dashboard** — the bottom screen edge is a hot zone
(`bottom = "exec, qs ipc call dashboard toggle"`) that slides a 720×40 % sheet
up. It is **tabbed** (`modules/dashboard/DashboardTabs.qml`): numbered
equal-width slots with a solid accent block on the active one, sliding like the
workspace pill. Two tabs: **network** (wifi switch, a scanning list, and an
inline passphrase prompt whose Connect stays disabled until the input validates
for the security type — WEP: 5/13 chars or 10/26 hex; otherwise 8–64 — rules
ported from plasma-nm's applet) and **notifications** (DND switch, count,
`CLEAR`, and the session's toast history, full width with arrival times). The
section titles live in the tabs; each tab's controls row is switch + label on the
left, list controls on the right. Switch tabs by clicking a cell, wheeling over
the row, `←`/`→` while the sheet is open, or
`qs ipc call dashboard tab <network|notifications|next|prev>` (`tabName` reads it
back); the choice survives closing the sheet. Bluetooth, audio (input/output) and
night light are the next tabs.
Networking uses quickshell's native `Quickshell.Networking` (NetworkManager over
DBus) — no `nmcli` spawning, unlike caelestia/end-4. Note the scan takes a few
seconds to fill the list after opening, and scanning runs **only** while the sheet
is open *and* the network tab is showing (proven with NM's `LastScan`: it advances
every ~10s on the network tab and never on the notifications tab). Design and
traps: [notes/dashboard.md](notes/dashboard.md).

The list is deliberately a **stable snapshot**, not a live binding: a binding over
the model re-sorts on every signal-strength tick during a scan, which reorders
rows and resets delegates **mid-typing**. So `rebuild()` only assigns when the
SSID order actually changes, and never while a row is expanded (plasma-nm freezes
its model the same way with `setDelayModelUpdates`). The passphrase text is owned
by the section, not the delegate, so nothing can lose it; and NM deletes network
objects when an AP disappears, so the row reads through `n()` — a probe that
catches the dead wrapper and falls back to an empty network
(see [notes/quickshell.md](notes/quickshell.md#qml-and-api-traps-in-032)).

Motion follows the theme tokens: rows fade their hover state, the expanded body
animates height + opacity, and the rule under the header doubles as a scan track
with an accent segment sweeping across it. Signal strength is a rectangle bar
meter and the spinner is a dot-chase — both drawn, not glyphs, because rotating
a `StyledText` glyph pixelates.

**Bar network status** — the right cluster ends with a signal meter
(`modules/bar/BarNetwork.qml`): meter only at rest, and on a 300ms hover a tooltip
drops 6px under the bar with SSID, strength, security and IP; clicking it opens the
dashboard (network section). Data is native `Quickshell.Networking`; the IP is the
only subprocess (one shot per hover — the toolkit exposes just the MAC). Verified
2026-10-18 with the user's mouse. Rules, anchoring lessons and the click-through
mask are in [notes/shell-ui.md](notes/shell-ui.md).

**Notifications** — our shell *is* the daemon: `NotificationServer` in
`NotificationService.qml` owns `org.freedesktop.Notifications` (no mako/dunst/
swaync installed), and `NotificationHost.qml` draws the toasts — top-right, clear
of the bar, on an overlay surface whose click mask is the toast column itself.
Lifetime follows omarchy: ≥5 s low, ≥8 s normal, sticky for critical, stretched up
to 30 s if the sender asks for longer; hovering pauses the countdown and a
content update restarts it; past four on screen the oldest leaves early, straight
to history. Bodies are drawn **plain text** (the toolkit renders markup even when
the server does not advertise it — an `<img>` body would be a remote GET beacon).
DND lives in the bar as a bell-off glyph that only appears while it is on, and in
the dashboard with the history; it is persisted to
`~/.cache/quickshell/notifications.json`, and a critical notification from a bare
CLI sender is the one thing that still gets through. History is a session ring of
20 (a shell restart clears it). IPC: `qs ipc call notifications <toggleDnd|setDnd
<bool>|dndState|dismissAll|dismissOne|invokeLast|clearHistory|count|historyCount>`.
Verified live 2026-10-19 with `gdbus` sends and `dbus-monitor` (capabilities,
8 s/5 s expiry, sticky critical, DND silence + critical bypass, `replaces_id`
rewrite, burst trim, `ActionInvoked`), then with **real pointer clicks**
(`tools/uclick.py`): a toast ✕ dismisses without firing its action, a body click
fires it, the dashboard ✕ removes exactly its row, and hovering a toast pauses its
countdown. Policy rationale and the `ListModel` traps we hit are in
[notes/notifications.md](notes/notifications.md).

## Preview benches (use them, don't guess)

Each `/preview*.qml` is a standalone bench: renders real components, saves a PNG, quits; safe while the main `qs` instance is up.

```bash
qs -p ~/.config/quickshell/preview.qml        # → /tmp/opencode/preview.png
qs -p ~/.config/quickshell/preview_white.qml  # → /tmp/opencode/preview_white.png
qs -p ~/.config/quickshell/preview_screenshot.qml # → /tmp/opencode/preview_screenshot.png
qs -p ~/.config/quickshell/preview_calendar.qml # → /tmp/opencode/preview_calendar.png
qs -p ~/.config/quickshell/preview_powermenu.qml # → /tmp/opencode/preview_powermenu.png
qs -p ~/.config/quickshell/preview_dashboard.qml # → /tmp/opencode/preview_dashboard.png
qs -p ~/.config/quickshell/preview_network.qml # → /tmp/opencode/preview_network.png
qs -p ~/.config/quickshell/preview_notifications.qml # → /tmp/opencode/preview_notifications.png (+ _dnd)
```

| Bench | What it renders | Uses |
|---|---|---|
| `preview.qml` | two bar variants + all four OSD states — dark bg | icon bins, chip styling |
| `preview_white.qml` | 960×560 mock screen: bar, launcher drawer (real Papirus icons, frequency-sorted), OSD — with marked screen boundary | frame language check, overall trip |
| `preview_screenshot.qml` | floating editor + toolbar with mock strokes/texts (no capture) | pen rendering, toolbar layout |
| `preview_calendar.qml` | desktop calendar card on dark bg | grid math, today pill, chrome |
| `preview_lock.qml` | formation card in typing + failed states (no session lock) | card visuals, auth states |
| `preview_powermenu.qml` | session menu panel on the right over a mock desktop, hover fill pinned on a row | frame language, row fill/hover, panel sizing |
| `preview_dashboard.qml` | both dashboard tabs on a mock desktop: the network tab with a **mocked** list (connected / saved / secured / open) and the passphrase prompt pinned open, the notifications tab with a mocked history (timestamps) | tab row + active block, section layout, row states, inline PSK |
| `preview_network.qml` | the live bar network item plus every state mocked (strong / weak / portal / offline / radio off) and the tooltip content | meter states, tooltip copy, elide |
| `preview_notifications.qml` | every card state (normal with countdown, sticky critical, low with avatar, icon fallback), the bar island, and the dashboard section with a mocked history — saved twice, DND off then on | card layout, urgency accents, DND bell |

Open the PNG (or hand it to an image-reading agent) and critique what is rendered — that is how the bar/launcher curve mismatch was caught.

## Clicking for real (`tools/uclick.py`)

A bench PNG and `qs ipc call` still cannot prove a click or a hover. `tools/uclick.py`
creates a virtual mouse on `/dev/uinput` and drives the real pointer at a screen
coordinate (`python3 ~/.config/quickshell/tools/uclick.py X Y`, add `--move` for
hover only, and it refuses to click unless it is on target). Coordinate maths, the
state assertions to read back, and the proofs it recorded (the notification ✕ paths
and the hover pause) are in [notes/ui-verification.md](notes/ui-verification.md).

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
| `mako` | notification daemon + toasts | built 2026-10-19: our `NotificationServer` owns the bus name; top-right toast stack, DND + history in the dashboard, plain-text bodies | ✅ done |
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
3. ✅ **Notifications** (replaces mako) — done 2026-10-19; the same machinery unlocks our own battery/script toasts
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
  Stop it with `qs kill` (there is no `-k` flag), restart with `qs -nd`.
- **Work lands in the dotfiles repo**: the live config and these docs are mirrored
  into `~/del/configuring-wm` (copied by hand, nothing syncs automatically) and
  pushed to `github.com/pranav244872/configuring-wm` — `git push` works as-is
  since 2026-10-19 (`gh` credentials, see [notes/packages.md](notes/packages.md#pushing-to-github)).
