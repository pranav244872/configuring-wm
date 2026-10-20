# Wallpaper drawing: the background-layer surface

Our shell **draws the wallpaper itself** — a background-layer surface
(`WallpaperBackground.qml`) — instead of running `swww` / `hyprpaper` / `awww`:
one toolkit, no daemon, and the picker can preview a change instantly behind
its own sheet. The picker is [wallpaper.md](wallpaper.md).

Back to [notes index](README.md) - [docs index](../README.md)

## The surface

- `exclusionMode: ExclusionMode.Ignore` (not `Auto`): `Auto` insets the surface
  into the usable area, so the wallpaper stopped 30 px short of the top edge and
  the strip either side of the centred bar showed the bare compositor colour.
  `Ignore` spans the whole output and the bar (level `top`) merely draws over
  it.
- An empty `Region` mask: a full-screen layer surface that accepted input would
  eat the hot zones and the desktop calendar.
- `color: "transparent"`: the surface only shows its image slots.

## No black flash: decode first, then flip

- **Two fixed slots**, one texture each. A change loads the new source into the
  *hidden* slot and swaps `front` only once it is `Image.Ready`. Flipping
  immediately fades the old wallpaper out into an empty slot, showing the bare
  compositor colour for as long as the image takes to decode — **measured
  142–308 ms for a 4 MB PNG on 2026-10-19: a visible black flash**.
- Two fixed slots (instead of create/destroy) keep the previous wallpaper
  instant to pick back.
- `sourceSize` keeps the decode to the drawn size, and the *same* value in the
  lock backdrop (`LockBackdrop`) makes that load a cache hit. **PNG decode does
  not get cheaper with `sourceSize`** — PNG is not size-scalable — so the
  background pays it regardless; that is what the flip-on-ready dance hides.

## Where it is created

`shell.qml` creates `WallpaperBackground` **before** the bar/calendar and
`WallpaperHost` last: on one layer, creation order decides stacking.

## Verified live (2026-10-19)

Full-screen coverage (the bar sits on the wallpaper, no black sides) · no black
flash on change (the decode happens behind the old wallpaper) · the lock
backdrop hits the same decoded size · transparent surface passes clicks to the
hot zones.

Last verified: 2026-10-19
