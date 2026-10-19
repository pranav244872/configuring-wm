# Wallpaper: in-shell drawing + the picker carousel

Our shell **draws the wallpaper itself** — a background-layer surface
(`WallpaperBackground.qml`) — and the picker is a bottom sheet with a
**filmstrip** of the library. No `swww` / `hyprpaper` / `awww` daemon, no
matugen: one toolkit, no extra process, and the theme stays static.

Back to [notes index](README.md) - [docs index](../README.md)

## Module map (`~/.config/quickshell/modules/wallpaper/`)

| File | Role |
|---|---|
| `WallpaperService.qml` | singleton, no visuals: the library (`FolderListModel`), `current`, the state file, `apply()`/`indexOf()`/`pathAt()`/`adopt()` |
| `WallpaperBackground.qml` | background-layer surface, transparent, two fixed image slots, crossfade on change |
| `WallpaperHost.qml` | the sheet window: overlay layer, slide-up from the bottom edge, Escape / click-away, IPC target `wallpaper` |
| `WallpaperContent.qml` | header row + rule + strip; owns the centre slot (`activate`/`step`/`applyCurrent`) |
| `WallpaperCarousel.qml` | the strip: `ListView` + `StrictlyEnforceRange`, slides, dimming, wheel |
| `WallpaperSurface.qml` | sheet body: hairline frame + corner ticks (shared with the bench) |

Wired in `shell.qml` (`WallpaperBackground` is created before the bar/calendar,
`WallpaperHost` last), `modules/Theme.qml` (`wallpaper` tokens,
`glyphs.wallpaperApplied`), and `preview_wallpaper.qml` (bench).

## Library and state

- Library: **`~/Pictures/Wallpapers`**, flat (11 PNGs, seeded from the repo's
  `Wallpapers/`; the repo stays the git source of truth).
- Listing: `Qt.labs.folderlistmodel` — quickshell **0.3.2 has no
  `FileSystemModel`**. Names filtered to common image types, `sortField: Name`,
  and the model is handed straight to the `ListView` (`filePath`/`fileName`
  roles).
- **Adopt only on `Status === Ready`.** Rows arrive while the model is
  `Loading` and are not in the configured sort yet, so acting on the first count
  change settles on an arbitrary image (it picked `5.png`, index 2, on
  2026-10-19).
- State: `~/.cache/quickshell/wallpaper.json` (`{"path": "…"}`), read with one
  `sh` `cat` through `Process` + `StdioCollector` (same shape as the
  notification DND file). `hydrated` gates every write, so the startup fallback
  cannot clobber the saved choice; `mock` stops writes, so the bench never edits
  the real file.
- A first run, or a library that moved, falls back to the first image (a saved
  path that is still in the library is never touched).

## Drawing: no black flash, full coverage

- `exclusionMode: ExclusionMode.Ignore` (not `Auto`): `Auto` insets the surface
  into the usable area, so the wallpaper stopped 30 px short of the top edge and
  the strip either side of the centred bar showed the bare compositor colour.
  `Ignore` spans the whole output and the bar (level `top`) merely draws over
  it.
- An empty `Region` mask: a full-screen layer surface that accepted input would
  eat the hot zones and the desktop calendar.
- **Decode first, then flip.** Two fixed slots each hold one texture; a change
  loads the new source into the *hidden* slot and only swaps `front` once it is
  `Image.Ready`. Flipping immediately fades the old wallpaper out into an empty
  slot, which shows the bare compositor colour for as long as the 4 MB PNG takes
  to decode — **measured 142–308 ms on 2026-10-19: a visible black flash**.
- `sourceSize` keeps the decode to the drawn size, but **PNG decode does not get
  cheaper with `sourceSize`** (PNG is not size-scalable) — that is why the fix
  is the flip-on-ready dance, not a thumbnail size. A pre-generated `ffmpeg`
  thumbnail cache is the deferred, proper fix (see Debts).

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
- An empty library says so in the frame's own voice
  (`NO WALLPAPERS IN ~/PICTURES/WALLPAPERS`) instead of a blank sheet.

## Trigger

| Route | How |
|---|---|
| bottom-right corner hot zone | `bottomright` in `~/.config/hypr/modules/hotzones.lua`; closes the dashboard first |
| keyboard | `SUPER + SHIFT + W` (`keybinds.lua`) |
| IPC | `qs ipc call wallpaper <toggle\|open\|close\|isOpen\|current\|index\|next\|prev\|apply>` |

Read [hotzones.md](hotzones.md) before touching the corner: the dwell counts
*residence*, so a slow slide along the bottom edge opens the dashboard first —
approach the corner directly.

## Verified live (2026-10-19)

Full-screen coverage (bar sits on the wallpaper, no black sides) · a click
applies and survives a shell restart (state file) · wheel steps and **wraps both
ways** · `←`/`→`/`Escape`/`Enter` with injected keys · click-away closes · no
black flash on change (142–308 ms decode hidden behind the old wallpaper) ·
bench PNG inspected · empty-library branch renders its label · `mock` leaks no
state write.

## Debts and rejected paths

- **Adopted**: DMS `Modules/DDash/WallpaperCarousel.qml` (StrictlyEnforceRange +
  `interactive: false`, deck spacing) and caelestia-shell (`background/Wallpaper.qml`
  in-shell crossfade, `sourceSize` thumbnails). Two fixed slots instead of
  create/destroy keeps the previous wallpaper instant to pick back.
- **Rejected**: `swww`/`hyprpaper`/`awww` (a daemon for what the shell already
  composites), matugen (the palette stays static — see
  [preferences.md](../preferences.md)), end-4's pre-generated thumbnails (needs
  a generator step we do not have yet), and configuring-wm's old rofi picker
  (`~/.config/rofi/scripts/wallpaper_menu.sh`) which drove awww + matugen.
- **Deferred**: an `ffmpeg` thumbnail cache to make browsing instant on this HDD.

Last verified: 2026-10-19
