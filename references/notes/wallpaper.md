# Wallpaper: in-shell drawing + the picker carousel

Our shell **draws the wallpaper itself** — a background-layer surface
(`WallpaperBackground.qml`) — and the picker is a bottom sheet with a
**filmstrip** of the library. No `swww` / `hyprpaper` / `awww` daemon: one
toolkit, no extra process. The strip reads an ffmpeg thumbnail cache
([wallpaper-thumbnails.md](wallpaper-thumbnails.md)) and the footer cycles the
library on a timer ([wallpaper-cycling.md](wallpaper-cycling.md)). Choosing an
image recolours the desktop through matugen ([matugen.md](matugen.md)).

Back to [notes index](README.md) - [docs index](../README.md)

## Module map (`~/.config/quickshell/modules/wallpaper/`)

| File | Role |
|---|---|
| `WallpaperService.qml` | singleton, no visuals: the library (`FolderListModel`), `current`, the state file, `apply()`/`indexOf()`/`pathAt()`/`adopt()` |
| `WallpaperBackground.qml` | background-layer surface, transparent, two fixed image slots, crossfade on change |
| `WallpaperHost.qml` | the sheet window: overlay layer, slide-up from the bottom edge, Escape / click-away, IPC target `wallpaper`; sets `WallpaperCycler.suspended` while open |
| `WallpaperContent.qml` | header row + rule + strip + cycling footer; owns the centre slot (`activate`/`step`/`applyCurrent`) |
| `WallpaperCarousel.qml` | the strip: `ListView` + `StrictlyEnforceRange`, slides, dimming, wheel; reads `WallpaperThumbs.pathFor()` |
| `WallpaperSurface.qml` | sheet body: hairline frame + corner ticks (shared with the bench) |
| `WallpaperThumbs.qml` | singleton: the ffmpeg JPEG cache and the source→thumb map ([thumbnails](wallpaper-thumbnails.md)) |
| `WallpaperCycler.qml` | singleton: the cycle timer, shuffle, pauses and the settings file ([cycling](wallpaper-cycling.md)) |

Wired in `shell.qml` (`WallpaperBackground` is created before the bar/calendar,
`WallpaperHost` last), `modules/Theme.qml` (`wallpaper` tokens,
`glyphs.wallpaperApplied`), and `preview_wallpaper.qml` (bench).

## Library and state

- Library: **`~/Pictures/Wallpapers`**, flat (20 files here — PNG and JPEG,
  seeded from the repo's `Wallpapers/`; the repo stays the git source of truth).
- Listing: `Qt.labs.folderlistmodel` — quickshell **0.3.2 has no
  `FileSystemModel`**. Names filtered to common image types, `sortField: Name`,
  and the model is handed straight to the `ListView` (`filePath`/`fileName`
  roles).
- **Adopt only on `Status === Ready`.** Rows arrive while the model is
  `Loading` and are not in the configured sort yet, so acting on the first count
  change settles on an arbitrary image (it picked `5.png`, index 2, on
  2026-10-19).
- State: `~/.cache/quickshell/wallpaper.json` (`{"path": "…"}`), read with one
  `sh` `cat` via `Process` + `StdioCollector` (like the notification DND file).
  `hydrated` gates every write so the startup fallback cannot clobber the saved
  choice, and `mock` stops the bench from editing the real file.
- A first run, or a library that moved, falls back to the first image (a saved
  path that is still in the library is never touched).

## Drawing

The shell paints it on a background-layer surface with a decode-then-flip
crossfade between two fixed slots, so a change never flashes the compositor
colour. Geometry, the `exclusionMode` trap and the measured decode are in
[wallpaper-drawing.md](wallpaper-drawing.md).

## The carousel

- `interactive: false` + `highlightRangeMode: StrictlyEnforceRange`: the **index
  drives the view**, the pointer never drags the strip. Flickable snapping
  drifts against the deck spacing and desyncs from the host (DMS's
  `WallpaperCarousel` documents the same).
- **It wraps**: past the last slide comes the first, and back from the first
  lands on the last (`(i + delta + count) % count` in both `WallpaperContent.step()`
  and the wheel handler) — that is what makes it a carousel.
- **Browsing never applies.** Wheel / `←` / `→` only step the centre slot; a
  **click applies** that slide and the sheet **stays open**, because seeing the
  choice land behind the sheet is the point. The applied slide carries a solid
  accent check badge (our selected-row treatment); `Enter` is keyboard parity
  with a click.
- The centre slot is `2px` accent (our `border_size`, borrowed from a focused
  Hyprland window) and grows by `slideFocusScale` (1.08) — `scale` is layout-free,
  so no label moves. Neighbours dim to `neighbourAlpha` (0.5). No rotation, no
  rounding: our language is flat.
- `ListView` resets its own `currentIndex` when the model changes or reloads, so
  `syncList()` re-asserts it; `activate()` re-centres on the applied wallpaper
  every time the sheet opens (and recovers if the library changed).

### Traps that cost a debugging round

- **Distance must subtract `list.contentX`.** A delegate's `x` is in *content*
  coordinates; without the scroll offset every slide computes "one pitch away"
  and the whole strip renders at the dimmed alpha, centred slide included
  (measured: the accent border came out `#517e82`, exactly primary at 50%, while
  a corner tick rendered the true `#80d4dc`).
- **The wheel catcher is declared last on purpose**: a later sibling gets the
  event first, and `acceptedButtons: Qt.NoButton` means it can never take a
  click, so the slides below keep every press. (The dashboard tab row does the
  opposite — it relies on an unhandled wheel reaching a catcher declared
  *first*; owning the wheel from above is deterministic for a `ListView`, since
  a `ListView` is a `Flickable`.)
- The sheet has **no backdrop image** behind the strip: a dimmed copy of the
  centred slide made it read as noisy (rejected 2026-10-19).
- **The lock screen draws its own copy of the wallpaper.** The compositor hides
  every other surface while the session is locked, so the background-layer
  `WallpaperBackground` is not on screen there (verified 2026-10-19: with the
  lock surface transparent the locked screen is black, not the desktop). The
  lock paints the wallpaper, blurred under a scrim — see
  [shell.md](../shell.md) and `modules/lock/LockBackdrop.qml`.
- An empty library says so in the frame's own voice
  (`NO WALLPAPERS IN ~/PICTURES/WALLPAPERS`) instead of a blank sheet.
- A **bench** that parks the applied badge must wait for the service to settle:
  the library lists asynchronously *and* the state file arrives later still, and
  either overwrites `current` (gate on `hydrated` **and** `FolderListModel.Ready`).
  Setting it too early left the badge on a slide outside the shot, so the preview
  silently disagreed with the live picker.
- The badge belongs to its slide, so a non-centred applied slide shows it
  **dimmed** with the rest of the slide; only the centred slide renders it at
  full accent (verified: a 16×16 `#80d4dc` block).

## Trigger

| Route | How |
|---|---|
| bottom-right corner hot zone | `bottomright` in `~/.config/hypr/modules/hotzones.lua`; closes the dashboard first |
| keyboard | `SUPER + SHIFT + W` (`keybinds.lua`) |
| IPC | `qs ipc call wallpaper <toggle\|open\|close\|isOpen\|current\|index\|next\|prev\|apply>` |
| cycling | footer toggle, `SUPER + ALT + W`, `qs ipc call wallpaper cycleNext\|cyclePrev` — see [wallpaper-cycling.md](wallpaper-cycling.md) |

Read [hotzones.md](hotzones.md) before touching the corner: the dwell counts
*residence*, so a slow slide along the bottom edge opens the dashboard first —
approach the corner directly.

## Verified live

2026-10-19: a click applies and survives a shell restart (state file) · wheel
steps and **wraps both ways** · `←`/`→`/`Escape`/`Enter` with injected keys ·
click-away closes · bench PNG inspected · empty-library branch renders its
label · `mock` leaks no state write.

2026-10-20: the strip renders from the thumbnail cache (probe: 20/20 mapped) ·
the footer's toggle / interval presets / `SHUFFLE` chip drive the cycler and
persist · a 1-minute tick advanced the image and its matugen palette · the
settings survived a hard restart.

## Debts and rejected paths

- **Adopted**: DMS `Modules/DDash/WallpaperCarousel.qml` (`StrictlyEnforceRange`
  + `interactive: false`, deck spacing) and caelestia-shell
  (`background/Wallpaper.qml` crossfade); DMS `WallpaperCyclingService`'s shape
  for the scheduler ([cycling](wallpaper-cycling.md)).
- **Rejected**: `swww`/`hyprpaper`/`awww` (a daemon for what the shell already
  composites), end-4's *ImageMagick* thumbnail generator (no `magick` here — the
  cache uses ffmpeg, [thumbnails](wallpaper-thumbnails.md)), and
  configuring-wm's old rofi picker (`~/.config/rofi/scripts/wallpaper_menu.sh`).
- **Deferred**: pausing the cycle while a window is fullscreen (no toplevel
  fullscreen state in the installed Quickshell); multi-output wallpaper.

Last verified: 2026-10-20
