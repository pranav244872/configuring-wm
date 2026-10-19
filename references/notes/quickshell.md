# quickshell 0.3.2 Notes

QML/API traps we hit building our shell. Read before writing any QML; how to verify
the result (real clicks, probes) is in [ui-verification.md](ui-verification.md).

Back to [notes index](README.md) - [docs index](../README.md)

## QML and API traps in 0.3.2

Checked against installed quickshell 0.3.2 + source ([../references.md](../references.md)).

**QML language**

- `pragma Singleton` needs a **`QtObject`** root, not a `Singleton { }` block → `Singleton is not a type`.
- A `pragma Singleton` therefore has **no default property** — non-visual children (`IpcHandler`, a `PanelWindow`) cannot live in one; it must hold only properties/functions. Put the objects in a window instead (0.3.2 has no `Singleton` type to root on).
- A property named `on<Something>` is parsed as a **signal handler**, so `onError:` fails with *"Cannot assign a value to a signal"*. Never name properties `onX`.
- `StyledText is not a type` → the file imports `qs.modules` but not `qs.modules.widgets`.
- `TypeError: Property 'close' of object <PanelWindow> is not a function` — `PanelWindow`
  has no callable `close`. Declare thin `function show() / close() / toggleVisible()` on
  the window and call those from key handlers, the dismiss area and IPC.
- A `Behavior` cannot target a **read-only** property (`implicitWidth`, `readonly property`).
- A `Behavior` cannot **swap its animation object** while running (*"Cannot change the animation assigned to a Behavior"*).
- `\uXXXX` is **exactly 4 hex digits**. Use `String.fromCharCode()`.
- `grabToImage()` works on items created by QML, not on a layer-shell `contentItem`. Grab an inner item.
- Canvas images: `loadImage(url)` + `onImageLoaded` + `drawImage(url-string)`. Drawing from a hidden `Image` element is flaky (black first frame).
- StackView lives in `QtQuick.Controls`, not Layouts (separate import).
- `QsMenuOpener` + `QsMenuEntry` (core) drive app tray menus: `menu`, `children`, `triggered()` — no platform menu needed.
- Built-in `drag.target` + `filterChildren` + `threshold` + `smoothed` + min/max beats hand-rolled deltas (they jitter). Anchored items can't drag; dragging breaks `x`/`y` bindings, so position imperatively and mirror for save.
- Never redeclare `clicked`/`pressed`/`onX` signals — `MouseArea` already has them (`Duplicate signal name`).
- **Sibling order is input priority**: a later sibling stacks above an earlier one
  and receives the event first, so a full-item `MouseArea` declared *after* a child
  swallows that child's clicks. The notification card's card-wide catcher sat after
  the column and ate every click meant for the ✕ (fixed 2026-10-19 — it fired
  `cardClicked`, which looked like success in the toast stack and was dead in the
  dashboard). Declare the background catcher **first**, interactive children after
  it (or give the child `z: 1`).
- `MouseArea.onWheel: (event) => …` exists and does not steal clicks; a wheel event
  the topmost item does not handle propagates down the stack, so a catcher *under*
  a row of cells can own the wheel for the whole row.
- Inner properties shadow outer ids: `LockSurface { lock: lock }` self-binds when the surface
  declares its own `lock` (binding loop, null value). Name host ids distinctly (`sessionLock`).
- **A destroyed QObject held in a `var` property is a dead wrapper, not `null`.**
  When NetworkManager deletes a network object (its AP disappeared) the JS value
  stays non-null, so `x !== null`, `??` and `?.` all pass — but any property read
  throws *"Value is null and could not be converted to an object"*. Probe inside a
  function and catch (`try { void obj.name; return obj } catch (e) { return fallback }`),
  and **call it at each use**: a one-shot `property var x: …` binding evaluates once
  and keeps the dead wrapper, because nothing changes when the object dies.
- **Never store a live QObject in a `ListModel` role.** Once the owner destroys the
  object the role is a dangling C++ pointer and the next read segfaults inside
  `QQmlListModel::data`. Keep the model rows plain data and the live objects in a JS
  map keyed by id (the notification service does exactly this).
- **A row from `ListModel.get()` stops answering once its row is removed** — every
  role reads back `undefined` afterwards, so a copy taken too late writes empty
  records. Copy the row into plain data *before* `remove()` (this is what wrote `[{}]`
  history entries, fixed 2026-10-19).
- **A JS-array model hands each delegate a converted copy of its element**, so
  `modelData` is not the object that went into the array (`modelData === arr[0]` is
  false, probed 2026-10-19). Matching a row back to its source by identity then
  silently matches nothing: the dashboard's history ✕ ran
  `history.filter(e => e !== entry)` and removed no row at all, which read as "the
  button is dead". Match on the element's own fields (`notifId` + `timestamp`) or
  on its index.
- `Text` is `AutoText`: it renders markup (and `<img>`) from any string it is given,
  even when the source does not advertise markup. Force `textFormat: Text.PlainText`
  for text you did not write (a notification body is attacker-controlled).
- A `ListModel` delegate with `required property <type> <roleName>` works: each
  declared role arrives as a change-notifying property, so `onSummaryChanged:` on the
  delegate fires when the service rewrites that role.
- `height: visible ? implicitHeight : 0` is a **self-referencing binding** and trips
  QML's loop detector on every re-layout (`TrayMenu` title row, fixed 2026-10-18).
  A `Column`/`Row` does not position invisible items, so `visible` alone is enough.
- `WlSessionLock.unlock()` is a private slot in 0.3.2 (verified in source) — unlock via
  `lock.locked = false`; `PamContext` does have `onPamMessage` (emitted after each message update).
- `Item.mapToGlobal()` returns window-local coords on layer-shell (the client never
  learns the compositor-assigned window pos). Add the known window origin yourself;
  `mapToScene()` is pure client math and safe (see tray menu anchor).
- A click mask tracks its item: reshaping it mid-gesture stutters. Widen to fullscreen for
  the gesture, shrink back after.
- PanelWindow sizes from explicit `implicitWidth/Height` (TopBar pattern); unsized content falls back tiny (calendar rendered 100×100).
- Anchors pin positions: `anchors.left` kills an `x` binding silently (launcher drawer stuck on screen — no left anchor on sliding panels, ever).
- Plain `qs` allows duplicate instances (only `-n` refuses): doubled surfaces, IPC races, focus fights. One instance; always start with `qs -n`.
- Hot reload stacks IPC handlers: toggles flap after a day of edits; restart `qs` to clear.
- Keep annotation coordinates float: rounding every mousemove eats sub-pixel steps at zoom.

**Icons**

- Nerd Font PUA glyphs carry near-zero advances in Qt (e.g. 6 px at 30 px font size).
- Fix: `ttf-material-symbols-variable` ligature names in `"Material Symbols Rounded"` (e.g. `text: "volume_up"`).
- Keep icons in fixed-size boxes; express state via different icons (bins), never by animating `font.pixelSize`.

**Windowing & LayerShell**

- `PanelWindow` has no `opacity`, `x`, `y` or `width`. Animate an inner child `Item`.
- `anchors` only has `left`/`right`/`top`/`bottom`. An axis with no anchor is auto-centered.
- Setting `exclusiveZone` requires 1 or 3 anchors. With `anchors { top: true }`, setting `exclusiveZone: surface.implicitHeight` pushes down tiled windows.
- Transparent items still intercept clicks. Use `mask: Region { item: surface }` (details in [shell-ui.md](shell-ui.md)).

**Services (PipeWire & UPower & Clock)**

- PipeWire: volume/mute live on `node.audio`, and `PwObjectTracker` bound to that node is mandatory.
- PipeWire volume is a factor over base volume. Use `wpctl set-volume <n>%` to write and `wpctl get-volume` to read.
- `Quickshell.Services.UPower`: provides `UPower.displayDevice` (`percentage` 0.0..1.0, `state`, `isLaptopBattery`).
- `SystemClock`: `hours` and `minutes` are `quint32` integers, not strings. Format with `Qt.formatDateTime(clock.date, "HH:mm")`.

**Hyprland Compositor IPC**

- Import is `Quickshell.Hyprland` and the singleton is **`Hyprland`** (not `Hypr`).
- Use `Hyprland.focusedWorkspace` and `Hyprland.workspaces`. Empty workspaces may be absent until active.
- Lua mode dispatch: our compositor runs a **Lua config**, so dispatchers must be Lua
  (`hl.dsp.focus({ workspace = id })`); the plain `workspace N` form gets wrapped into
  `hl.dispatch(workspace N)` and errors (`')' expected near '8'`). **`Hyprland.usingLua`
  reports `false` on our fork** — don't gate on it, send the Lua form unconditionally
  (see `WorkspaceIndicator.focusWorkspace`; `Hyprland.dispatch` returns void, so you
  can't branch on success).

**Animations & Colour**

- `Behavior on color` **requires `ColorAnimation`**; `NumberAnimation` fails.
- Colour functions (`mix`, `transparentize`, `overlay`) live on `ColorUtils`, not `Theme.colors`.
- Individual corner radii (`topLeftRadius`, `bottomLeftRadius`, etc.) are supported in QtQuick `Rectangle` and `RectangularShadow`.

**IPC & CLI**

- `IpcHandler` functions must declare argument and return types: `function fn(): void`.
- `qs` = run default config, `-n` = single instance, `-d` = daemonize, `-c <name>` / `-p <path>`.
  **`qs -k` does not exist in 0.3.2** — kill with the subcommand (`qs kill`, `qs list`, `qs log`, `qs ipc`).

## Launcher (0.3.2)

- IpcHandler is `Quickshell.Io`, not `Quickshell` / `Quickshell.Ipc`.
- App data is `DesktopEntries.applications.values` (core singleton); launch with `entry.execute()`.
- Icons: `import Quickshell.Widgets`, use `IconImage { implicitSize: 20 }` (no `size`).
- Keep `filteredApps` as a plain property refreshed via `onAllAppsChanged` (ObjectModel updates async).

## Matching flared corners (bar + launcher)

- Both surfaces draw a 30px "flare" corner block with `PathCubic`, from the `Theme.bar`
  tokens (`flare` 30, `flareC1` 17, `flareC2` 13 — 0.57/0.43 ≈ the quarter-circle
  constant; caelestia gets the same look from `PathArc` + rounding tokens).
- The launcher's flares are the bar's rotated 90° (it bends off the left edge, the bar
  off the top edge).
- The only copies of the geometry are `BarSurface.qml` and `LauncherSurface.qml`; the
  bar, the launcher and every preview bench render through them. Retune the tokens in
  Theme — never re-type curve numbers into a bench. That is exactly how the mismatch
  happened (the launcher was 6/18 = 0.25/0.75, a visibly different angle; fixed
  2026-10-16).
