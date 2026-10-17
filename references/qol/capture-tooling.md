# Capture Tooling

**Status: ✅ screenshots done 2026-10-16** — own quickshell utility; `grim` + `slurp` installed for plumbing. Recording/OCR still open.

## What Omarchy does

Nine `omarchy-capture-*` commands:

```
omarchy-capture-screenshot           omarchy-capture-screenrecording-with-webcam
omarchy-capture-region               omarchy-capture-screenrecording-process
omarchy-capture-screen               omarchy-capture-webcam-list
omarchy-capture-text                 omarchy-capture-webcam-resize
omarchy-capture-screenrecording
```

`capture-text` is OCR (select region → get selectable text).

## What it would take here

| Feature | Packages | Notes |
|---|---|---|
| screenshot / region | `grim` capture + own quickshell selector/annotation (`slurp` installed as fallback, both in `extra`) | own UI replaces hyprshot 2026-10-16 |
| screen recording | `wf-recorder` (in `extra`) | the old setup had a `screenrecord` script |
| webcam / overlay capture | — | niche, skip unless wanted |
| OCR text capture | heavier (tesseract) | probably not worth it |

## Old setup's binds (currently missing)

| Bind | Old behaviour |
|---|---|
| `PRINT` | own screenshot utility: captures, opens annotation (Save/Copy/Discard; Print/Esc closes) |
| `SUPER+PRINT` | screenshot window (old hyprshot; now a mode inside the utility) |
| `SHIFT+PRINT` | screenshot region (old hyprshot; now a mode inside the utility) |
| `SUPER+SHIFT+R` | recording menu |

Target dir is already decided: `~/Pictures/Screenshots` (shared with mpv).

## Annotation (shipped in our utility, no extra packages)

Native QML: pen strokes (6 colours, 1–12px slider + presets), movable/resizable text labels, undo/redo (`Ctrl+Z` / `Ctrl+Shift+Z`), `B`/`T`/`[`/`]` shortcuts. Full notes in [notes/screenshot.md](../notes/screenshot.md).
