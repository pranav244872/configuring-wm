# Audio Helpers

**Status: ⬜ not started** — volume/mute keys already work (silently).

## What Omarchy does

Nine `omarchy-audio-*` commands:

```
omarchy-audio-input-mute             omarchy-audio-output-volume
omarchy-audio-input-set-default      omarchy-audio-sink-availability
omarchy-audio-output-set-default     omarchy-audio-source-switch
omarchy-audio-output-sink            omarchy-audio-output-switch
omarchy-audio-tuning
```

Plus a user service `omarchy-speaker-tuning.service` (EQ/tuning per output
device) and a menu entry `omarchy-menu-input` for microphone selection.

## What we already have

| Need | Our solution | Status |
|---|---|---|
| volume ± / mute | `XF86Audio*` → `wpctl` (±5 %, ±1 % with ALT) | ✅ working |
| mic mute | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` | ✅ |
| output switching | — (old setup had a script; needs `pactl`+`jq` or `wpctl`) | ⬜ |
| device picker | uosc? no — that's mpv. mpv has audio-device menu | ✅ (mpv only) |
| tuning/EQ | — | ⏸ not needed |

## What's still missing

- **Desktop audio-output switching** (the old `SUPER + XF86AudioMute` bind).
  Cheap version: a small script using `wpctl`/`pactl` without extra packages;
  Omarchy's equivalent is `omarchy-audio-output-switch`.
- Notification-free feedback: our keys are silent by choice, so switching
  outputs gives no visual confirmation.
