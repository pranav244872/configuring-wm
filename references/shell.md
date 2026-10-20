# Our Shell (quickshell)

**Status: 🔄 in progress** — OSD, bar, launcher, screenshots, calendar, tray icons, keep-awake toggle, session menu, dashboard (tabbed: network + bluetooth + notifications + audio), bar network status (hover tooltip), the **notification daemon + toasts**, the **wallpaper (drawn in-shell + picker carousel with a thumbnail cache and a cycling footer)**, the **low-battery warning (toast + hook)** and the **CP tracker card** (third-party, [notes/cp-tracker.md](notes/cp-tracker.md)) **done**; lock screen built — it draws the wallpaper behind the card (lock/unlock verified 2026-10-17 and 2026-10-19, PAM auth test pending).

## What exists today

`~/.config/quickshell/`

| File | Role |
|---|---|
| `shell.qml` | entry point (`ShellRoot`); loads bar, OSD, launcher, screenshots, calendar |
| `preview.qml` | visual test bench (dark bg) |
| `preview_topbar.qml` | bar-flare A/B geometry bench (white bg) |
| `preview_white.qml` | full mock screen: bar + launcher + OSD, for curve/icon critique |
| `modules/Theme.qml` | palette → semantic colors → rounding/font/sizes/frame/animation tokens (`frame`: hairlines, ticks, tracking); the palette binds to `Scheme` (wallpaper-derived, hex is the fallback) |
| `modules/Scheme.qml` | matugen palette: reads `~/.config/quickshell/colors.json`, runs `matugen image …` when the wallpaper changes, exposes roles to `Theme.palette` |
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
| `modules/bar/BarBattery.qml` | battery indicator with dynamic charge icons and percentage (right module); reads `BatteryWatch` and owns the `battery` IPC |
| `modules/power/` (`BatteryWatch`, `battery_model.js`) | the shared UPower reading + the low-battery warnings (20% / 10%, once per discharge), local toasts, the `~/.config/quickshell/hooks/battery-low` hook — see [qol/battery-and-power.md](qol/battery-and-power.md) |
| `modules/launcher/LauncherWindow.qml` + `AppTracker.qml` | full-height left drawer on Super+F / IPC; frequencies persist to cache |
| `modules/lock/LockHost.qml` | real WlSessionLock + IPC (`lock`/`unlock`/`isLocked`); password-only PAM; locks on idle (3m) or `Fn+F9`; keeps `LockState` in step |
| `modules/lock/LockSurface.qml` | per-output lock surface: the wallpaper (blurred, scrimmed) with the centred formation card over it |
| `modules/lock/LockBackdrop.qml` | the lock's background: current wallpaper, blurred under a 40% scrim (shared with the bench) |
| `modules/lock/LockState.qml` | singleton: is the session locked? Surfaces refuse to open (and close) while it is — the compositor does not suppress our hot zones for a session lock |
| `modules/lock/LockCard.qml` | formation card: user chip, big clock+date, password field + submit |
| `modules/lock/LockAuth.qml` | password-only PAM machine (`login` stack); buffer cleared every path |
| `modules/lock/IdleService.qml` | staged IdleMonitors: lock 3m, screen-off 5m (floor 1%), suspend 10m; fullscreen holds all three, MPRIS playback holds blank+suspend |
| `modules/launcher/LauncherSurface.qml` | full-height drawer: layer0 fill, ticks, no bezel-side borders (shared) |
| `modules/launcher/LauncherContent.qml` | tracked header + rule, square search, ranked list, footer hint (shared) |
| `modules/launcher/LauncherItem.qml` | square rows, uppercase names, solid primary selection + ripple |
| `modules/launcher/LauncherWindow.qml` | full-height left drawer on Super+F / `qs ipc call launcher toggle` |
| `modules/screenshot/ScreenshotHost.qml` | Print captures output → select (region/window/full) → annotate in a floating window; Print+Esc always close (`qs ipc call screenshot toggle`); saves land in `~/Pictures/Screenshots` (`xdg-user-dir PICTURES` + `/Screenshots`, probed once at shell start). Created **last** in `shell.qml`: on one layer, creation order decides stacking, and behind the wallpaper picker's sheet its Save/Copy toolbar was unreachable |
| `modules/screenshot/ScreenshotStore.qml` | crop view, strokes, movable/resizable text labels, undo/redo stacks, tool state |
| `modules/screenshot/ScreenshotSelector.qml` | dimmed capture + region drag (aim lines, clamped) + window hover-pick (active workspace only) |
| `modules/screenshot/AnnotationStage.qml` | canvas: checkerboard, cropped capture, pen strokes, text labels; the export target |
| `modules/screenshot/ScreenshotEditor.qml` | floating window: titlebar move, SE resize (aspect-locked), status bar |
| `modules/screenshot/AnnotationToolbar.qml` | reselect / pen+text / swatches+width menu / undo+redo / save+copy+discard pill |
| `modules/calendar/` (`CalendarWidget`, `CalendarCard`, `calendar_layout.js`) | desktop month window: background layer, click-through mask, drag anywhere, Monday-first grid |
| `modules/cp_tracker/` (`CpTrackerWidget`, `CpTrackerCard`) | desktop CP tracker card (Codeforces/AtCoder ratings + contest schedule) on the background layer, draggable, 15-minute polls — **built by another agent**, see [notes/cp-tracker.md](notes/cp-tracker.md) |
| `modules/Caffeine.qml` | keep-awake singleton (`enabled`); the bar holds the wayland idle inhibitor |
| `modules/bar/BarCaffeine.qml` | coffee toggle at the right end of the bar (`qs ipc call caffeine toggle`) |
| `modules/bar/BarNetwork.qml` | signal meter at rest; tooltip on 300ms hover (SSID · strength · security · IP) 6px under the bar; click opens the dashboard. Native `Quickshell.Networking`, IP from a one-shot `ip` |
| `modules/bar/NetworkTooltip.qml` | tooltip frame content (layer0 fill, hairline + corner ticks); shared with the bench |
| `modules/powermenu/PowerMenuHost.qml` | session menu: content-sized panel on the right, vertically centred, slides in from the bezel; opened by the right-edge hot zone or `qs ipc call powermenu toggle`; Escape / click-away closes |
| `modules/powermenu/PowerMenuContent.qml` + `PowerMenuItem.qml` | entries Lock / Log out / Suspend / Reboot / Shut down; Chaldea rows with the accent fill sliding in on hover (shared with the bench) |
| `modules/powermenu/PowerMenuSurface.qml` | floating framed panel: layer0 fill, 1px hairline + corner ticks (shared) |
| `modules/dashboard/DashboardHost.qml` | bottom sheet: `Theme.sizes.dashboardWidth` wide (720), 40% of the monitor height (52% on the audio tab, animated), centred; bottom-edge hot zone / `qs ipc call dashboard toggle`; Escape / click-away closes; `←`/`→` change tab |
| `modules/dashboard/DashboardTabs.qml` | the tab row: equal-width numbered cells, solid accent block on the active one (slides on the move curve), wheel to step; each section is one tab |
| `modules/dashboard/DashboardContent.qml` | tab host: the tab row over a `StackLayout` of the sections, and the one place that decides which section is allowed to work (`syncActive()`: the network list scans, the bluetooth list discovers, the audio tab tracks nodes and runs its meter — each only while its own tab is visible) |
| `modules/dashboard/NetworkSection.qml` | wifi switch, scanning list, inline passphrase, connect / disconnect / forget, portal + off states; scans only while the sheet is open |
| `modules/dashboard/NetworkRow.qml` | one network: signal + SSID + security/state; expands in place for the passphrase, or for Disconnect / Forget + IP when connected |
| `modules/bluetooth/` (`BluetoothSection`, `BluetoothRow`, `bluetooth_model.js`) | dashboard Bluetooth tab: toggle, no-adapter / rfkill-blocked / off states, `MY DEVICES` + `AVAILABLE` lists with inline detail (address, type, battery, connect / pair / forget), adapter alias + discoverable footer; pairing uses a short-lived `bluetoothctl --agent NoInputNoOutput` — see [notes/bluetooth.md](notes/bluetooth.md) |
| `modules/audio/` (`AudioSection`, `AudioRow`, `audio_model.js`) | dashboard Audio tab: output/input device pickers with master volume + mute, a live mic peak meter, and per-app volume/mute with the sink each app plays on; master writes go through `wpctl` (hardware-volume devices), rows are `{id,name}` snapshots — see [notes/audio.md](notes/audio.md) |
| `modules/dashboard/network_list.js` | sort rank (connected → connecting → saved → signal), signal level, PSK validation rules |
| `modules/notifications/NotificationService.qml` | the daemon: `NotificationServer` singleton (bus name `org.freedesktop.Notifications`), toast model, lifetimes, DND (persisted), session history |
| `modules/notifications/NotificationHost.qml` | toast stack overlay (top-right, clear of the bar), per-toast countdown, IPC target `notifications` |
| `modules/notifications/NotificationCard.qml` | one notification: avatar/app/summary/body, urgency strip, countdown drain, hover ✕ — shared with the dashboard history |
| `modules/dashboard/NotificationsSection.qml` | DND switch + toast history; rows reuse `NotificationCard` |
| `modules/bar/BarDnd.qml` | bell-off button, shown only while DND is on; click toggles |
| `modules/wallpaper/WallpaperService.qml` | the wallpaper singleton: library (`FolderListModel` over `~/Pictures/Wallpapers`), `current`, state file (`~/.cache/quickshell/wallpaper.json`), `apply`/`indexOf`/`adopt` |
| `modules/wallpaper/WallpaperBackground.qml` | background-layer surface: two fixed image slots, decode-then-flip crossfade; `exclusionMode: Ignore` so it spans the whole output behind the bar |
| `modules/wallpaper/WallpaperHost.qml` | picker sheet: bottom sheet, slides up from the edge, Escape / click-away, IPC target `wallpaper` (picker + cycling); suspends the cycle while open |
| `modules/wallpaper/WallpaperContent.qml` | the sheet's header + rule + strip + cycling footer; owns the centre slot, the wrap and applying |
| `modules/wallpaper/WallpaperCarousel.qml` | the filmstrip: `ListView` + `StrictlyEnforceRange`, index-driven, click-to-apply, wheel catcher; slides read the thumbnail cache |
| `modules/wallpaper/WallpaperSurface.qml` | sheet body: hairline frame + corner ticks (shared with the bench) |
| `modules/wallpaper/WallpaperThumbs.qml` | ffmpeg JPEG thumbnails for the strip (`~/.cache/quickshell/wallpaper-thumbs`), source→thumb map — [notes/wallpaper-thumbnails.md](notes/wallpaper-thumbnails.md) |
| `modules/wallpaper/WallpaperCycler.qml` | the cycle timer: presets 5–120 min, shuffle, lock/picker pauses, settings file — [notes/wallpaper-cycling.md](notes/wallpaper-cycling.md) |
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
workspace pill. Four tabs: **network** (wifi switch, a scanning list, and an
inline passphrase prompt whose Connect stays disabled until the input validates
for the security type — WEP: 5/13 chars or 10/26 hex; otherwise 8–64 — rules
ported from plasma-nm's applet), **bluetooth** (adapter states, saved + available
devices) and **audio** (output/input pickers, mic meter, per-app volume), plus
**notifications** (DND switch, count, `CLEAR`, and the session's toast history,
full width with arrival times). The section titles live in the tabs; each tab's
controls row is switch + label on the left, list controls on the right. Switch
tabs by clicking a cell, wheeling over the row, `←`/`→` while the sheet is open,
or `qs ipc call dashboard tab <network|bluetooth|notifications|audio|next|prev>`
(`tabName` reads it back); the choice survives closing the sheet. The audio tab
needs a mixer's room, so the sheet grows to 52 % while it is showing and shrinks
back on the next tab. Night light is the next tab.
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

**Wallpaper** — the shell **draws the wallpaper itself** (`WallpaperBackground.qml`, a background-layer surface) instead of running swww/hyprpaper/awww: one toolkit, no daemon. The picker is a bottom sheet with a **filmstrip** — `ListView` + `StrictlyEnforceRange`, so the index drives the strip and the pointer never drags it. The centred slide carries a 2px accent border and grows 8%, neighbours dim to 50%, a **click applies** it (the sheet stays open so you watch it land behind the sheet) and the applied slide wears an accent check; wheel and `←`/`→` step and **wrap** both ways, `Enter` applies, Escape / click-away closes. The slides read a 448×252 **ffmpeg thumbnail cache** (the full PNG costs 142–308 ms to decode; a thumb is a few ms), falling back to the source until it exists. The library is `~/Pictures/Wallpapers` listed with `FolderListModel` (0.3.2 has no `FileSystemModel`), and the choice persists to `~/.cache/quickshell/wallpaper.json`. Under the strip a **cycling footer** holds an `AUTO` switch, the interval (click to step 5/10/15/30/60/120 min) and a `SHUFFLE` chip; the sheet grew 240 → 272 px for it, the cycle pauses while the sheet is open or the session locked, and `SUPER + ALT + W` steps to the next image without the sheet (`qs ipc call wallpaper cycleNext`). Settings live in `~/.cache/quickshell/wallpaper-cycling.json`. Opened by the **bottom-right corner hot zone**, `SUPER + SHIFT + W`, or `qs ipc call wallpaper toggle`. A change is a crossfade between two fixed image slots, and the incoming PNG is decoded *before* the slots flip — a 4 MB PNG takes 142–308 ms and flipping early showed the bare compositor colour. Design rules, the `contentX` dimming bug and the corner trap are in [notes/wallpaper.md](notes/wallpaper.md), the surface in [notes/wallpaper-drawing.md](notes/wallpaper-drawing.md); verified live 2026-10-19 and 2026-10-20. Choosing a wallpaper also regenerates the whole desktop palette through matugen — the shell recolours live (see [notes/matugen.md](notes/matugen.md)).

**Lock** — a real `WlSessionLock`, not a fake overlay, and it draws the **wallpaper** itself: the compositor hides every other surface while locked, so the background-layer `WallpaperBackground` is not on screen there (proved 2026-10-19 — with the lock surface transparent the locked screen is black, not the desktop). `LockBackdrop` paints the current wallpaper blurred under a 40% black scrim (the treatment caelestia's lock and DMS's `LockScreenBackground` use; values follow DMS, since the GPU here is an Intel UHD 620) and follows a wallpaper change. It is a shared component, so `preview_lock.qml` reviews that look without locking the session.

Two lock traps, both proved live and both logged in [notes/hotzones.md](notes/hotzones.md) and [notes/quickshell.md](notes/quickshell.md):
- the compositor's hot zones keep firing **while locked** (Hyprland's `InputManager::isLocked()` means "a pointer constraint is active", not "the session is locked"), so the corner opened the picker behind the lock — the hosts now consult `LockState` and refuse, and close when a lock starts;
- 0.3.2's `WlSessionLock` does not notify `locked` on the way back to `false`, so `LockState` is driven from the shell's own `engage()`/`disengage()` — and the **password** unlock path (`LockAuth.unlocked`) has to be routed through `disengage()` as well: it unlocks directly, and on 2026-10-19 missing that left the flag set, so every guarded surface refused to open until the shell was restarted. A 1-second timer re-syncs it from `sessionLock.locked` (which always *reads* correctly) as a backstop.

## Preview benches (use them, don't guess)

Each `/preview*.qml` is a standalone bench: renders real components, saves a PNG, quits; safe while the main `qs` instance is up.

```bash
qs -p ~/.config/quickshell/preview.qml        # → /tmp/opencode/preview.png
qs -p ~/.config/quickshell/preview_white.qml  # → /tmp/opencode/preview_white.png
qs -p ~/.config/quickshell/preview_screenshot.qml # → /tmp/opencode/preview_screenshot.png
qs -p ~/.config/quickshell/preview_calendar.qml # → /tmp/opencode/preview_calendar.png
qs -p ~/.config/quickshell/preview_powermenu.qml # → /tmp/opencode/preview_powermenu.png
qs -p ~/.config/quickshell/preview_dashboard.qml # → /tmp/opencode/preview_dashboard.png
qs -p ~/.config/quickshell/preview_audio.qml # → /tmp/opencode/preview_audio.png
qs -p ~/.config/quickshell/preview_network.qml # → /tmp/opencode/preview_network.png
qs -p ~/.config/quickshell/preview_notifications.qml # → /tmp/opencode/preview_notifications.png (+ _dnd)
qs -p ~/.config/quickshell/preview_wallpaper.qml # → /tmp/opencode/preview_wallpaper.png
qs -p ~/.config/quickshell/preview_lock.qml # → /tmp/opencode/preview_lock.png
```

| Bench | What it renders | Uses |
|---|---|---|
| `preview.qml` | two bar variants + all four OSD states — dark bg | icon bins, chip styling |
| `preview_white.qml` | 960×560 mock screen: bar, launcher drawer (real Papirus icons, frequency-sorted), OSD — with marked screen boundary | frame language check, overall trip |
| `preview_screenshot.qml` | floating editor + toolbar with mock strokes/texts (no capture) | pen rendering, toolbar layout |
| `preview_calendar.qml` | desktop calendar card on dark bg | grid math, today pill, chrome |
| `preview_cp_tracker.qml` | CP tracker card on a dark plate (third-party widget) | ratings blocks, featured countdown, schedule list |
| `preview_lock.qml` | the formation card in typing + failed states over the real lock backdrop (wallpaper, blurred + scrimmed) | card visuals, auth states, the lock's background |
| `preview_powermenu.qml` | session menu panel on the right over a mock desktop, hover fill pinned on a row | frame language, row fill/hover, panel sizing |
| `preview_dashboard.qml` | the network and notifications tabs on a mock desktop: the network tab with a **mocked** list (connected / saved / secured / open) and the passphrase prompt pinned open, the notifications tab with a mocked history (timestamps) | tab row + active block, section layout, row states, inline PSK |
| `preview_bluetooth.qml` | the Bluetooth tab in six mock states: saved devices with one expanded, a discovered device expanded (PAIR / FORGET), powered off, rfkill-blocked, empty, no adapter | all tab states, section headers, row + detail layout, footer |
| `preview_audio.qml` | the Audio tab twice side by side: populated (headset default, built-in alternative, mic with a pinned meter level, two apps) and muted/empty (no apps, no input devices) | device/app rows, master writes layout, `DEFAULT`/`USE` tags, meter, empty notes, 52 % sheet |
| `preview_network.qml` | the live bar network item plus every state mocked (strong / weak / portal / offline / radio off) and the tooltip content | meter states, tooltip copy, elide |
| `preview_notifications.qml` | every card state (normal with countdown, sticky critical, low with avatar, icon fallback), the bar island, and the dashboard section with a mocked history — saved twice, DND off then on | card layout, urgency accents, DND bell |
| `preview_wallpaper.qml` | the picker sheet over the **real** library (thumbnails) on a mock desktop, centre slot on the 4th image, applied badge on the 2nd (dimmed — a non-centred slide carries its own dimming), cycling footer forced on | slide frame + focus growth, neighbour dimming, the applied badge, label row, header counter, footer (toggle/interval/SHUFFLE) |

Open the PNG (or hand it to an image-reading agent) and critique what is rendered — that is how the bar/launcher curve mismatch was caught.

## Clicking for real (`tools/uclick.py`)

A bench PNG and `qs ipc call` still cannot prove a click or a hover. `tools/uclick.py`
creates a virtual mouse on `/dev/uinput` and drives the real pointer at a screen
coordinate (`python3 ~/.config/quickshell/tools/uclick.py X Y`, add `--move` for
hover only, `--wheel`/`--key`/`--combo` to step a carousel or fire a keybind, and
it refuses to click unless it is on target). Coordinate maths, the
state assertions to read back, and the proofs it recorded (the notification ✕ paths,
the hover pause, all three hot zones, `SUPER + SHIFT + W`) are in
[notes/ui-verification.md](notes/ui-verification.md) — including the uinput trap
that silently degraded every combo to a bare key.

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
| `Quickshell.Services.UPower` | battery + power state (event-driven) — read once by `BatteryWatch`, shared by the bar and the warnings |
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
3. ✅ **Notifications** (replaces mako) — done 2026-10-19; the same machinery unlocked our own toasts (low battery ✅ 2026-10-20)
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
