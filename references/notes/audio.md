# Audio tab

The dashboard's fourth tab: output and input device pickers with volume, mute
and a live mic meter, plus per-app volume/mute. Built as a study of
**pavucontrol**, narrowed to what matters on this machine.

Back to [notes index](README.md) - [docs index](../README.md)

## What pavucontrol does -> ours

| pavucontrol | Ours |
|---|---|
| **Playback**: per-app volume, mute, "on <device>" | `APPS`: per-app volume + mute, target device shown read-only |
| **Output Devices**: volume, mute, "set as fallback", ports | `OUTPUT`: one master slider for the current default + a device list; click a row to make it default |
| **Input Devices**: volume, mute, live level meter | `INPUT`: same, with a real peak meter under the slider |
| **Configuration**: card profiles | **no** — not exposed by Quickshell; DMS parses `pactl -f json list cards` |
| Move an app to another device | **no** — Quickshell has no routing API; needs a `pactl move-sink-input` index bridge |
| Tabs for Playback/Recording/Configuration | one scrolling column; sections carry the same weight as the other dashboard tabs |

## What the references do

| Reference | Shape | Taken |
|---|---|---|
| **omarchy** (`shell/plugins/panels/audio`) | panel: hero output glyph + "mood" volume name, master slider, sink rows, input slider + peak meter, source rows, per-app sliders, full keyboard cursor model | section order, one master slider per direction, peak meter, `{id,name}` snapshots |
| **end-4** | volume-mixer dialog: per-app list + one device combo box | per-app rows are the useful part; a combo hides devices |
| **caelestia** | app-volumes subpage with sliders, own C++ audio provider | per-row sliders |
| **DMS** | control-centre tiles + per-device detail with port and profile pickers, separate output/mic OSDs | ports/profiles out of scope; it proves those need `pactl`, not Quickshell |

## API facts (Quickshell 0.3.2)

`import Quickshell.Services.Pipewire`. Verified on this machine:

| Thing | Fact |
|---|---|
| `Pipewire.ready` | **false at startup**; `defaultAudioSink`/`defaultAudioSource` are `null` until the initial sync. Nodes appear ~1.5 s in |
| device sinks | `isSink && !isStream && audio` (PipeWire `type` 17 here) |
| device sources | `!isSink && !isStream && audio` (type 9) |
| playback streams | `isStream && isSink && audio` (Firefox, type 21) — capture streams are stream sources |
| `PwNodeAudio.volume` | 0..1 **average**, `volumes` is a per-channel array (`[0.61, 0.61]`) |
| default switching | `Pipewire.preferredDefaultAudioSink/Source = node`; `defaultAudioSink` followed within one frame here (verified both ways) |
| `PwNodePeakMonitor` | `{ node, enabled }` -> `peak` 0..1; works on a device source |
| node lifetime | `PwObjectTracker { objects: [...] }` must hold every node whose `audio` you read |
| stream -> sink | `Pipewire.linkGroups`: a group whose `source.id` is the stream has the sink as `target` |
| properties | `node.properties["application.name"]` for app labels — only valid when `node.ready` |

## Volume writes go through wpctl

The OSD already proved this: on a **hardware-volume device** (this USB
Plantronics headset) writing `node.audio.volume` is not the level you hear. The
tab therefore writes the default sink/source with `wpctl set-volume -l 1` and
`wpctl set-mute`, coalescing a drag into one write per 50 ms, and unmuting first
(same rule as the volume keys). Reads still use `node.audio.volume`, which
matched `wpctl get-volume` on both sinks (0.35 / 0.61) and both sources.

Per-app streams have no hardware volume, so they write `node.audio.volume`
directly.

## Behaviour details

- **Only the visible tab works**: `activate()` rebuilds the snapshots and hands
  the tracker its node list; `deactivate()` clears both, so nothing is tracked
  and the peak monitor is off while another tab is showing.
- **The sheet grows to 52 %** on this tab (`Theme.sizes.dashboardAudioHeightRatio`)
  and returns to 40 % elsewhere. `DashboardHost` reads the tab through
  `content.tabName()`; the sheet is bottom-anchored, so `y` already follows the
  animated `height`.
- **Device rows are click-to-default**; the active row keeps a `DEFAULT` tag and
  the hovered one shows `USE` in the same fixed-width slot, so nothing shifts.
- **Muting dims the whole channel**: header value, slider, the device row's
  glyph and percentage. The meter drops to the subtext colour.
- **Apps show their sink** from the link graph (`ON <DEVICE>`), elided.

## Verification (2026-10-20)

| Check | Result |
|---|---|
| Bench, populated + muted/empty | `preview_audio.png`, no QML errors |
| Live rows | 2 sinks (Built-in 35 %, Headset 61 %) + 2 sources, matching `wpctl status` |
| Default switch | click Built-in -> `wpctl status` marks it, header % and slider follow; switching back restores the headset |
| Master slider | click at 40 % -> `wpctl get-volume` exactly `0.40` |
| Master mute | header glyph -> `[MUTED]`, UI dims; again -> unmuted |
| App row | Firefox listed with `ON BLACKWIRE C3220 …`; slider 100 % -> 50 % via `wpctl get-volume 74`; mute glyph works |
| Mic meter | three frames 0.6 s apart: 69 -> 84 -> 127 px of 660 (ambient room noise) |
| Mic mute | `@DEFAULT_AUDIO_SOURCE@` -> `[MUTED]`, `mic_off` glyph, meter dims |
| Graph teardown | `systemctl --user restart wireplumber` with the tab open: shell kept the same PID, devices re-enumerated under new ids (33/63), default restored, Firefox re-attached, no errors |
| Tabs | `qs ipc call dashboard tab audio|network` + `tabName`; sheet 52 % on audio, 40 % on network |
| Other tabs | network still scans and lists; dashboard bench unchanged |

## Traps

- **`Process` needs `import Quickshell.Io`** — without it the section fails to
  load with *"Process is not a type"*, and because it is imported by
  `DashboardContent` the whole dashboard goes with it. The bench catches it
  before a shell restart.
- **A delegate must not hold a live `PwNode`**: PipeWire deletes the QObject, and
  Qt dereferences it while building the next delegate (omarchy documents the
  segfault). Rows are `{id,name}` snapshots; the delegate resolves its node by
  that pair. The WirePlumber restart above is the test for it.
- **`node.properties` before `ready` is invalid** — reading it during stream
  churn destabilised omarchy's shell. `audio_model.js` guards on `ready`.
- **`preferredDefaultAudioSink` is a hint**, not the default; `defaultAudioSink`
  can briefly turn null on change. The section confirms after 700 ms and falls
  back to `wpctl set-default <id>` (the fallback never fired here).
- **A row-wide `MouseArea` on top eats the inline slider** — QML hit-testing
  gives the press to the topmost handler. Device rows put their click area
  *behind* the labels (plain items take no input); streams use a passive
  `HoverHandler` for the hover tint.
- **The V4L2 camera source has no `.audio`** and is filtered out; so are
  monitors, which appear only as sink monitor sources.
- The `audio` properties read 0 while a node is untracked — the OSD's
  `PwObjectTracker` note applies to every reader, not just the OSD.

## Files

| Path | What |
|---|---|
| `modules/audio/AudioSection.qml` | tab body: three sections, master writes, defaults, activation, meter |
| `modules/audio/AudioRow.qml` | device row / app row, inline slider, mute glyph, `DEFAULT` tag |
| `modules/audio/audio_model.js` | filtering, `{id,name}` snapshots, labels, glyphs |
| `modules/dashboard/DashboardContent.qml` | fourth tab + `syncActive()` case |
| `modules/dashboard/DashboardHost.qml` | 52 % height while the audio tab is visible |
| `modules/Theme.qml` | audio glyphs + `dashboardAudioHeightRatio` |
| `preview_audio.qml` | two-sheet bench: populated and muted/empty |
