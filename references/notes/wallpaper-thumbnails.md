# Wallpaper thumbnails: an ffmpeg cache for the picker

The picker's slides used to decode the **full** library image. `sourceSize`
does not help a PNG (PNG is not size-scalable), so opening the strip paid
**142–308 ms per slide** — the browsing stall measured on 2026-10-19. A cache
of small JPEGs removes it.

Back to [notes index](README.md) - [docs index](../README.md)

## The cache

`WallpaperThumbs.qml` (singleton, no visuals) builds
`~/.cache/quickshell/wallpaper-thumbs/<md5(path)>.jpg`:

- **448×252** — 2× the 224×126 slide, so a scaled display stays sharp. Built
  with `scale=…:force_original_aspect_ratio=increase,crop=448:252`, the same
  centred crop the slide's `PreserveAspectCrop` shows.
- JPEG `-q:v 6`: 20 library files came to **436 KB total (~22 KB each)**; the
  first full pass took **2.7 s**.
- The name is the md5 of the **absolute path**, not the file contents, so a
  replaced or touched image regenerates (`[ "$f" -nt "$t" ]`) and a renamed one
  gets a new entry.
- ffmpeg, not ImageMagick: there is no `magick`/`convert` on this machine and
  end-4's `generate-thumbnails-magick.sh` needs it. ffmpeg is already installed
  for screenshots, so this costs no package.

Decode, same 1920×1080 source (`ffmpeg -benchmark … -f null -`):
**51 ms → 2 ms**. The Qt path is slower than either figure, which is the
142–308 ms above.

## How the strip uses it

- One `sh` pass loops the folder and prints `source<TAB>thumb` lines for every
  thumb that exists; `WallpaperThumbs.thumbs` is that map, replaced wholesale
  after each pass.
- `WallpaperCarousel` sets
  `source: "file://" + (WallpaperThumbs.pathFor(filePath) || filePath)` — the
  **full image is the fallback**, so a first open (or a library change) shows
  real slides while the pass catches up, never blanks.
- The pass re-runs when `FolderListModel.count` changes **and every time the
  picker opens** (`WallpaperHost.onOpenChanged`): the pass is stat-only when
  nothing changed, and a source newer than its thumb is rebuilt — so an image
  replaced in place is fresh without a shell restart. A request while one is
  running sets `pending` and runs once more, so a library that lists in two
  chunks is not left half-cached.
- **The background and the lock do not use thumbs.** They need full resolution;
  deleting the cache only costs browsing speed.

## Traps

- **The temp file needs a `.jpg` extension.** `ffmpeg … "$t.tmp"` fails with
  `Unable to choose an output format for '…jpg.tmp'` — the muxer is chosen by
  extension. Write `"$t.tmp.jpg"`, then `mv`.
- A `Process`-based singleton is **killed with the bench** that started it
  (`qs -p …`), so a 700 ms preview cannot generate a cache. Generate once from
  a shell (or let the live shell do it), then render.
- The bench touches the **real** cache: the pass is idempotent, so that is
  harmless — but it also means the preview can disagree with the live strip if
  a source changed in between.
- `ffmpeg -benchmark` prints `bench: utime=… rtime=…` **and** a `maxrss` line;
  `-v quiet` hides both.

## Verified live (2026-10-20)

Cache built for all 20 library entries · probe printed `thumbs=20 library=20`
and resolved three sources to their thumbs · live picker renders the strip
from the cache · bench PNG inspected · first pass 2.7 s, 436 KB · decode
51 ms (full 1080p PNG) vs 2 ms (thumb) · `touch` on a source then opening the
picker rebuilt exactly that thumb (mtime followed the source).

Last verified: 2026-10-20
