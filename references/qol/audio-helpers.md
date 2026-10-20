# Audio Helpers

**Status: ✅ done (2026-10-20)** — the dashboard's `AUDIO` tab covers output and
input switching, both sliders, mute and a mic meter, so no `omarchy-audio-*`
scripts were ported.

Back to [qol index](README.md) - [notes/audio.md](../notes/audio.md)

## What Omarchy does

Nine `omarchy-audio-*` commands, a speaker-tuning user service and a menu entry
for microphone selection:

```
omarchy-audio-input-mute             omarchy-audio-output-volume
omarchy-audio-input-set-default      omarchy-audio-sink-availability
omarchy-audio-output-set-default     omarchy-audio-source-switch
omarchy-audio-output-sink            omarchy-audio-output-switch
omarchy-audio-tuning
```

## What we have now

| Need | Our solution | Status |
|---|---|---|
| volume ± / mute | `XF86Audio*` → `wpctl` (±5 %, ±1 % with ALT) | ✅ |
| mic mute | `XF86AudioMicMute` → `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle`, and the tab's mic glyph | ✅ |
| output switching | dashboard `AUDIO` → `OUTPUT` device rows (click = default) | ✅ |
| input switching | dashboard `AUDIO` → `INPUT` device rows | ✅ |
| mic level | `PwNodePeakMonitor` meter under the input slider, visible tab only | ✅ |
| per-app volume | `APPS` rows with inline sliders + mute | ✅ |
| tuning / EQ | — | ⏸ not needed (Omarchy needs a per-device filter chain) |

Deliberately not covered, because Quickshell 0.3.2 exposes no API for them:
moving a playing app to another device (`pactl move-sink-input` index bridge) and
card ports/profiles (`pactl -f json list cards`, DMS's route). Both are noted in
[../notes/audio.md](../notes/audio.md).
