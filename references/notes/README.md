# Notes — Verified Facts & Traps

Facts checked against the **installed** libraries, sources and hardware on this
machine, not remembered from docs. Read the relevant file before touching that
part of the setup.

Back to [docs index](../README.md)

| File | Covers |
|---|---|
| [hyprland.md](hyprland.md) | animation speed units, `debug.vfr`, fullscreen enum, `no_screen_share`, Lua `require` behaviour |
| [environment.md](environment.md) | the single env source (`hypr/modules/env.lua`): what is essential vs redundant here (Qt6/SDL/Firefox/iHD evidence, the Hyprland `getenv` set), and the reload-vs-login trap for removed vars |
| [validation.md](validation.md) | how to validate Hyprland Lua, kitty, mpv and quickshell before restarting anything |
| [quickshell.md](quickshell.md) | QML/API traps in 0.3.2 (singletons, `on*` names, `Behavior`, `PanelWindow`, `IpcHandler`, `Process`, PipeWire, `WlSessionLock.locked` notifying only on lock), the `opacity: 0` input trap and the `mask` fix |
| [shell-ui.md](shell-ui.md) | building our own UI: bar/launcher flares and stroke insets, the Chaldea frame language, motion + selection rows, escape/focus grabbing, bar tooltips |
| [ui-verification.md](ui-verification.md) | proving a shell surface really behaves: real clicks, hover, wheel and keybinds via `tools/uclick.py` on `/dev/uinput`, coordinate maths from `grim`, asserting on state instead of pixels — and why every combo silently degraded to a bare key |
| [idle-inhibit.md](idle-inhibit.md) | keep-awake: `IdleInhibitor` + `respectInhibitors`, why a barrier on a layer surface works, the probe test |
| [keyboard-fn-keys.md](keyboard-fn-keys.md) | the F-row vs Fn: hotkey mode, the `fn_lock` sysfs switch, why plain F9 is unbindable, and how to identify unknown keys |
| [hotzones.md](hotzones.md) | fork-native edge/corner hot zones: config keys, geometry/slam/re-arm, runtime API, the right-edge → session-menu and bottom-right → wallpaper wiring, the residence-not-rest dwell trap, the locked-session suppression bug, rollback |
| [screenshot.md](screenshot.md) | screenshot utility: grim-before-overlay capture, workspace-scoped window pick, native annotation, Print/Esc close rules |
| [audio.md](audio.md) | the dashboard's Audio tab (pavucontrol study): PipeWire typing facts (playback streams are `isStream && isSink`, volume 0..1, `preferred*` is only a hint), why the master slider writes through `wpctl` on hardware-volume devices, `{id,name}` snapshots against the node-removal segfault, the mic peak meter, and the WirePlumber-teardown test |
| [bluetooth.md](bluetooth.md) | the dashboard's Bluetooth tab: Blueberry/gnome-bluetooth study, `Quickshell.Bluetooth` API facts (battery is 0–1, no native pairing agent), the `bluetoothctl --agent NoInputNoOutput` workaround, rfkill detail + unblock flow, failure inference, verified states and the restart race |
| [notifications.md](notifications.md) | our notification daemon: server capabilities, lifetime/DND/history policy, toast placement, the `ListModel`/`tracked` traps, live verification |
| [cp-tracker.md](cp-tracker.md) | the desktop CP tracker card (Codeforces/AtCoder ratings, next target contest, schedule) — **built by another agent**; files, data flow, cache paths, live verification, and the background-layer/restart traps |
| [dashboard.md](dashboard.md) | the bottom sheet: tab row design, tab-gated wifi scanning (proved with NM's `LastScan`), tab movement (mouse/keyboard/IPC), full-width history rows, and the ✕ bug that had two independent causes |
| [wallpaper.md](wallpaper.md) | the wallpaper drawn by the shell (background layer, decode-then-flip crossfade) and the picker carousel: `StrictlyEnforceRange` strip, wrap, click-to-apply, the `contentX` dimming bug, the `FolderListModel` adopt gate, why the lock screen draws its own copy |
| [matugen.md](matugen.md) | wallpaper → matugen → every consumer: the trigger chain, template→output map, Theme role mapping, the live shell binding, per-consumer reloads, and what GTK/Qt actually honour |
| [display.md](display.md) | `brightnessctl` 0.5 raw units, the `-e4` stepping trap, the 1 % floor script |
| [mpv.md](mpv.md) | vendored uosc, uosc's `input.conf` menu, proving a script loaded |
| [neovim.md](neovim.md) | editor bootstrap and traps: `vim.pack` lockfile vs `vim.pack.add` (installed-but-inert plugins), `pcall(require,…)` hiding a missing plugin, treesitter `main` needing the CLI + a compiler, mason pypi needing no `python-pip`, why the `matugen` binary isn't needed, and driving a live nvim over its socket to verify the UI |
| [packages.md](packages.md) | Arch merging `cargo` into `rust`, paru's stale PKGBUILD, makepkg without a TTY, and how git pushes were finally authenticated (`gh`, 2026-10-19) |
| [system.md](system.md) | aborted pacman runs (`db.lck`, `download-*`), `/tmp` being wiped, rebuild workflow, Docker, measuring boot speed |
| [launch-performance.md](launch-performance.md) | why Firefox/kitty launched slowly on the spinning disk, what was changed, and why zswap must stay off |
| [cache.md](cache.md) | `paccache.timer`: the drop-in, why it exists, whether it slows boot, measured cache size |
| [opencode-mcp.md](opencode-mcp.md) | MCP wiring traps for opencode (restart the *service* not the TUI, npx first-connect timeout), plus the agentmemory experiment and why it was removed |
| [opencode-websearch.md](opencode-websearch.md) | websearch provider selection: the Firecrawl keyless refusal that silently empties results (why `random` never fails over), which providers work keyless, the one-line provider pin |
| [free-llm-access.md](free-llm-access.md) | getting free LLM access: which providers are genuinely free/keyless, which are dead, Groq's measured limits, and the freellmapi verdict |
| [hermes.md](hermes.md) | hermes' native `opencode-go` provider, and the verified opencode free-tier `FreeTierError` gate |

Last verified: 2026-10-20
