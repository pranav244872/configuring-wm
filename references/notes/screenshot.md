# Screenshot Utility Notes

Our own screenshot + annotation UI (`modules/screenshot/`). Capture plumbing
copied from hyprshot source (`/tmp/opencode/hyprshot`); selection UX from
end-4's region selector and Caelestia's area picker; month-grid math for the
calendar is end-4's `calendar_layout.js` approach, Monday-first.

Back to [notes index](README.md) - [docs index](../README.md)

## Two stages, always in this order

1. **Take**: Print captures the output with `grim` *before* opening, so the
   overlay never appears in its own shot. Region (default) drags on a dimmed
   frozen frame with aim lines; window mode hover-picks `hyprctl clients`
   rects; fullscreen has a shutter button. `F`/`R`/`W` switch modes, Enter
   confirms fullscreen.
2. **Annotate**: a floating window showing only the crop (titlebar move,
   SE-grip aspect-locked resize, status bar), over the dimmed full capture
   with a crop-origin marker. Toolbar: reselect / pen+text / swatches+width
   menu / undo+redo / Save+Copy+Discard.

## Window pick is workspace-scoped (2026-10-16)

- The window-pick list keeps only clients on the captured output's **active
  workspace** (`workspace.id == monitor.activeWorkspace.id`) — the rule
  hyprshot uses in `grab_window` (their jq `contains(...)` substring vs our
  numeric compare). Source: `/tmp/opencode/hyprshot`.
- Why it was needed: `at`/`size` in `hyprctl clients -j` are
  `GEOMETRIC_GOAL` (the last layout rect), so on this single-output laptop
  every workspace's windows passed a monitor-only filter and became
  **phantom hover/click targets** over the real screen.
- **Do not use the `visible` field** for this: a live probe showed ws1/2/3
  windows all `visible=true`; the fork's `CWindow::visible()` is
  `!m_hidden && m_isMapped && visibleByAlpha()` — no workspace component.
- Known limit (user chose strict hyprshot parity): scratchpad windows are not
  pickable while shown; use region mode.

## Annotation model

- Strokes are crop-coordinate polylines on one `Canvas`; text labels are
  transparent QML items (no rounding issues) — click selects, drag moves,
  SE grip resizes. Positions stay float: rounding every mousemove eats
  sub-pixel steps and makes dragging stick at high zoom.
- Undo/redo are seq-ordered stacks; new input clears redo. Shortcuts: `B`
  pen, `T` text, `[`/`]` width, `Ctrl+Z` / `Ctrl+Shift+Z` / `Ctrl+Y`.
- Width menu: live 1–12px slider plus Fine/Medium/Bold presets; line previews
  render in the current pen colour.
- Export grabs exactly the crop body (`grabToImage` works on QML-created
  items, never on a layer-shell `contentItem`). Save stamps
  `screenshot-YYYY-MM-DD-HHMMSS.png` into `xdg-user-dir PICTURES` + `/Screenshots`;
  Copy pipes through `wl-copy --type image/png`.
- **That directory is not `~/Pictures/Screenshots` on this machine.** There is no
  `~/.config/user-dirs.dirs`, so `xdg-user-dir PICTURES` answers `$HOME` and saves
  land in **`~/Screenshots`** (verified 2026-10-19 with three test saves). mpv's
  own config writes to `~/Pictures/Screenshots`, so the two disagree until
  `XDG_PICTURES_DIR="$HOME/Pictures"` is set.
- **The editor must be created last of the overlay windows.** Everything on
  `WlrLayer.Overlay` is stacked by creation order, so `ScreenshotHost` sits at the
  *end* of `shell.qml`. Created before the wallpaper picker instead, its toolbar
  was drawn **under** the picker's sheet — and the sheet's full-screen dismiss
  mask swallowed the clicks, so Save/Copy were unreachable ("I cannot copy or save
  screenshot", 2026-10-19). Prove that fix by **clicking** the real button, not by
  looking: `wl-paste --list-types` must answer `image/png`.

## Canvas image loading (do it this way)

- Images go through `Canvas.loadImage(url)` + `onImageLoaded` +
  `drawImage(url-string)` — the documented pattern. Drawing from a hidden
  `Image` element is flaky (proven: black first frame, image only after a
  later repaint).
- A 12px checkerboard is painted under the image: the standard transparency
  backdrop, visible for alpha content and while a capture loads.
- Rounded window corners: the canvas clips its own bottom-rounded path, so
  no square content pokes through the chrome.

## Close behaviour (user's call)

- Print and Esc close from anywhere — selection, drawing, mid-text-edit —
  and unsaved work is dropped. Temp files under
  `/tmp/quickshell-screenshot/` are removed on every close path, plus stale
  ones at startup (a `pkill` skips cleanup).
- A second Print during the ~200ms capture sets a cancel flag: the finished
  capture is discarded instead of opening.
- Region drags and crop rects are clamped to the output; an overshooting
  drag used to store a negative rect, which rendered as a gap strip.

## Desktop calendar (same feature area)

- `modules/calendar/`: end-4 grid math in `calendar_layout.js`, card in
  `CalendarCard.qml`, background-layer window in `CalendarWidget.qml`.
- Background layer + click-through mask (only the card takes input);
  fullscreen surface so the card can sit anywhere. Dragging uses the
  built-in C++ `drag.target` with `filterChildren` (never hand-rolled
  deltas — they jitter); position persists to
  `~/.cache/quickshell/calendar_pos.json`.
- Today pill follows a 60s timer (midnight + month-boundary rollover);
  `•` prefix marks a shifted month, clicking the title jumps back.
