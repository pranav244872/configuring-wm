# Building Our Shell UI

Rules for building the interactive parts of our own quickshell UI — top bar,
app launcher, OSD slider, input masks, and UI verification. The toolkit's own
API traps live in [quickshell.md](quickshell.md); what exists today is in
[../shell.md](../shell.md).

Back to [notes index](README.md) - [docs index](../README.md)

## Top Bar & Launcher: Caelestia Curves & Hyprland 2px Borders

- **Matching Hyprland Border**: All modules (top bar, launcher drawer, OSD pill)
  match Hyprland's `border_size = 2` and active border color (`Theme.colors.primary` / `#80d4dc`).
- **Open Border Strokes (No Edge Borders)**: Surfaces docked to monitor bezels must
  NOT draw borders along the screen edge:
  - *Top bar*: Closed `ShapePath` fills the body (`fillColor: Theme.colors.layer0`),
    while an open `ShapePath` strokes only the left flare, bottom edge, and right flare (omitting the top line at `y = 0`).
  - *Left launcher*: Closed `ShapePath` fills the body, while an open `ShapePath`
    strokes only the top flare, top edge, right side, bottom edge, and bottom flare (omitting the left line at `x = 0`).
- **Zero Shadows**: Comply strictly with user aesthetic (`decoration.shadow off`).
  Never use `StyledShadow` or blur elevation. Clean vector outlines only.
- **Shared Flare Geometry (`PathCubic`)**: Liquid transitions matching screen edges, tokenised in `Theme.bar` (`height` 30 = `flare` 30, `flareC1` 17, `flareC2` 13 — ≈ quarter-circle fractions; traps note in [quickshell.md](quickshell.md#matching-flared-corners-bar--launcher)). The launcher's flares are the bar's rotated 90° (it bends off the *vertical* screen edge, the bar off the top edge):
  - *Top bar* (`BarSurface.qml`): `(0, 0)` down to `(30, 30)` (stroke `y = 29`) via `PathCubic { x: 30; y: 29; control1X: 17; control1Y: 0; control2X: 13; control2Y: 29 }`.
  - *Left launcher* (`LauncherSurface.qml`): `(0, 0)` out to `(30, 30)` via `PathCubic { x: 30; y: 30; control1X: 0; control1Y: 17; control2X: 13; control2Y: 30 }`, bottom flare mirrored, right corners rounded with `PathArc` + `Theme.rounding.lg`. Retuned 2026-10-16 — the old 6/18 controls sat at different fractions and visibly bent at the wrong angle. **The geometry now exists only in those two components; the bar, launcher and all preview benches render through them.**
- **Stroke Inset Rule (Prevent FBO Clipping)**: In QtQuick `Shape` with `layer.enabled: true`,
  a 2px stroke centered at the container boundary ($y = H$ or $x = W$) has its outer 1px clipped by the FBO texture boundary (appearing as 1px). Strokes must be inset by 1px ($y = 29$ for the 30px bar, $x = \text{width} - 1$ for the launcher) to render the full 2px line.
- **Clean Launcher Cards**: App list is ranked by launch frequency descending, but
  opened count badges are suppressed to keep cards minimal and sleek.

## Chaldea frame language (2026-10-16, our teal kept)

Copied from Chaldea's players/notes (`/tmp/opencode/chaldea`): square 1px
hairline frames, accent corner ticks (`widgets/CornerTicks`, 7px arms),
tracked-out uppercase micro-labels (11px, spacing 2; titles spacing 3),
1px divider rules, solid-accent selection rows with dark text. JetBrains
Mono everywhere (`ttf-jetbrains-mono` — the Nerd variant registers a
different family and won't match). No rounding, no pills, no shadows.

## Optical alignment & desktop widgets

- **Optical centering beats geometric**: the bar row sits 1px high because the
  2px border lives on the bottom edge only — centre content on the visible
  mass, not the bounding box.
- **Desktop widgets** (calendar): background layer so windows cover them,
  click-through mask limited to the widget, fullscreen surface so it can sit
  anywhere. Persist free positions to cache (`calendar_pos.json` pattern).

## Motion & Interaction (end-4 language)

- **Movement is deliberately fast**: `curveMove [0.38, 1.21, 0.22, 1]` @ 70ms (`moveDuration`) — a touch of overshoot, well below the 120–200ms ceiling, because the user kept reading slower pills as lag (220ms → 100ms → 70ms over 2026-10-16). Fades and colours use `curveOut` @ 140ms (`valueDuration`).
- **State layers**: `Theme.colors.stateHover` (8 %) / `stateActive` (12 %) — M3 on-colour layers instead of bespoke hover colours.
- **Selection = solid `primaryContainer`** (launcher row), text flips to `fgPrimaryContainer`, subtitle at 35 % of it.
- **Click ripple**: `widgets/Ripple.qml` — call `press(x, y)` from the MouseArea, `release()` on released/cancelled; grow 300ms + fade 280ms. Needs a clipping parent (`Rectangle { clip: true }`); it reads the host from `parent`.
- **No scrollbar** in the launcher list — the user asked to hide it; wheel scrolling still works.

## Escape & Focus Grabbing

- **Avoid HyprlandFocusGrab on Overlays**: In Quickshell/Wayland, `HyprlandFocusGrab` is
  intended for desktop toplevel popups. On layer-shell overlays it triggers an immediate `onCleared` event upon surface mapping, closing the window in 0ms.
- **Layer-Shell Exclusive Focus**: Overlays should rely strictly on
  `WlrLayershell.keyboardFocus: host.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None`
  plus a full-window transparent `dismissArea` (`MouseArea`) for click-outside dismissal.
- **Immediate Text Focus**: A 40ms `focusTimer` + `searchField.forceActiveFocus()`
  ensures the text field immediately takes keyboard input and cursor focus upon mapping.
- **Instant Escape**: Root `FocusScope`, `panel`, and `searchField` all intercept
  `Qt.Key_Escape` to call `host.close()` immediately.

## Icons: Desktop Apps vs UI Controls

- **Desktop App Icons**: Desktop apps use Papirus via `//@ pragma IconTheme Papirus`
  at line 1 of `~/.config/quickshell/shell.qml` and `Quickshell.iconPath(raw, true)`.
- **UI Ligatures**: System controls use Material Symbols (`Theme.font.icon`).

## Workspace Indicator & OSD Guard

- **Persistent 1..5 + Dynamic**: 1..5 always shown; the active id and any occupied ids
  > 5 (e.g. 10) appended, sorted. Occupied numbers are brighter/Bold, empty ones sit at
  40 % alpha, and the active slot drops its hover layer (it has the pill).
- **Pill = circle at rest, trail while moving** (end-4 `TrailingIndicator`): 26px slots,
  22px pill (2px inset). A leading index snaps over in 40ms `OutSine`, the trailing one
  lags 70ms with `curveMove`, so mid-switch the pill is a capsule spanning old→new and
  then contracts — measured settle ~50ms. **Never stretch the resting pill toward
  occupied neighbours**: tried 2026-10-16, the pill edge then crowds the neighbouring
  digit (user: "almost overlapping"). Circle for every slot when at rest.
- **Digit colour tracks the pill**: `ColorUtils.mix(base, fgPrimary, coverage)` where
  coverage is the pill's overlap with a narrow band (`Theme.bar.dockHalf` = 9px) around
  the slot centre — digits go dark exactly while the pill covers them (end-4 does this
  with a colourizer mask; we need no shader) and flip just ahead of the pill edge. Two
  earlier versions were rejected on sight: a timed `Behavior on color` flipped the text
  before the pill moved, and the pill lagged the text because its body followed the slow
  trailing edge.
- **Clicking a slot dispatches Lua form only** — see the Hyprland trap in
  [quickshell.md](quickshell.md#hyprland-compositor-ipc) (plain `workspace N` is
  rejected by our compositor and `usingLua` lies).
- **Window Gap Math**: Bar height 30px with `exclusiveZone: 18` leaves exact 8px window gap with `gaps_out: 20` (18 + 20 - 30 = 8).
- **Startup Silence**: 1200ms `ready` timer in `OsdHost.qml` suppresses PipeWire sink initialization popup.
- **Input Trap Fix**: `mask: Region { item: surface; intersection: ... }` prevents clickthrough swallowing when hidden.

## Bar Network Item & Hover Tooltips

- **Glyph at rest, details on hover** (2026-10-18): the bar shows only the signal meter
  (`widgets/SignalBars`). An inline label that expanded on hover was built first and
  rejected on sight ("it looks ugly"); waybar splits it instead — `{icon}` in the bar,
  `{essid}` + details in the tooltip.
- **Native data, no polling**: `Networking.devices.values` → `DeviceType.Wifi` device →
  `networks.values.find(n => n && n.connected)` gives `name` + `signalStrength` (0.0–1.0);
  `Networking.wifiEnabled` is the radio, `Networking.connectivity`
  `Portal`/`Limited` the captive state (reads `Unknown` when NM's connectivity check is
  off, so the quiet "connected" look is the safe fallback). Down states swap the meter
  for the `wifi_find` / `signal_wifi_off` glyphs, like the dashboard rows.
- **Tooltip = `PopupWindow` anchored to the bar**: `mask: Region { item: null }` so it can
  never eat a click, a **300ms dwell** (hot-zone vocabulary — sweeping the bar must not
  flash tooltips) and a **6px gap** under the bar.
- **Anchor to the bar's bottom edge, not the icon's**: the item is vertically centred in
  the 30px bar, so `item.y + item.height` (≈23px) puts the popup *inside* the bar.
  `anchor.rect.y: window.height + 6` is the fix. The tray menu now follows the same rule
  (`Window.height + 6` in `BarTray.openMenuFor`), so a right-click menu and a hover
  tooltip hang at the same distance from the bar.
- **"On open" goes in the popup's `Component.onCompleted`**: with the bench's
  `pinTooltip` the tooltip is already visible at creation, so `onTooltipVisibleChanged`
  never fires and the IP lookup silently never ran. Triggers kept: pointer-enter
  (pre-fetch during the dwell, so the box opens at its final width), `onDevChanged` /
  `onOnlineChanged` (device or connection appearing while it is up) and that completion.
- **Re-anchor when the content resizes** (`onImplicitWidthChanged: Qt.callLater(anchor.updateAnchor)`):
  a popup's position is computed when it is shown, and the IP arriving or `9%` → `100%`
  changes the width — otherwise the box grows off-centre under the pointer.
- **The IP is the one non-native bit**: quickshell exposes only the *hardware* address
  (`NetworkDevice.address` is the MAC), so the tooltip runs
  `ip -4 -o addr show dev <if>` once per hover — a `Process`, never a poll.
- **Verification traps worth remembering**:
  - `hyprctl dispatch movecursor` does **not** drive hover: no motion/enter event reaches
    the layer surface (a debug MouseArea in the window stayed silent), so hover paths
    need a real pointer. `qs ipc call` + `grim` prove position and content, not hovering.
  - A bench that reproduces the bar on the **overlay** layer draws *above fullscreen
    windows* (the real bar is level `top`, which the compositor hides), so it looks like
    "the bar doesn't hide in fullscreen"; and it carries no `TrayMenuHost`, so tray
    right-click looks dead there. Both were reported as bugs while such a probe was live
    — keep probes temporary and delete them.
  - `TrayMenu` logs a benign `Binding loop detected for property "height"` (its title row)
    each time a menu opens — pre-existing, harmless, not yet chased.
