# Notes — Verified Facts & Traps

Facts checked against the **installed** libraries, sources and hardware on this
machine, not remembered from docs. Read the relevant file before touching that
part of the setup.

Back to [docs index](../README.md)

| File | Covers |
|---|---|
| [hyprland.md](hyprland.md) | animation speed units, `debug.vfr`, fullscreen enum, `no_screen_share`, Lua `require` behaviour |
| [validation.md](validation.md) | how to validate Hyprland Lua, kitty, mpv and quickshell before restarting anything |
| [quickshell.md](quickshell.md) | QML/API traps in 0.3.2 (singletons, `on*` names, `Behavior`, `PanelWindow`, `IpcHandler`, `Process`, PipeWire), the `opacity: 0` input trap and the `mask` fix |
| [shell-ui.md](shell-ui.md) | building our own UI: drag-a-value slider rules, and how to verify quickshell UI without guessing |
| [idle-inhibit.md](idle-inhibit.md) | keep-awake: `IdleInhibitor` + `respectInhibitors`, why a barrier on a layer surface works, the probe test |
| [keyboard-fn-keys.md](keyboard-fn-keys.md) | the F-row vs Fn: hotkey mode, the `fn_lock` sysfs switch, why plain F9 is unbindable, and how to identify unknown keys |
| [hotzones.md](hotzones.md) | fork-native edge/corner hot zones: config keys, geometry/slam/re-arm, runtime API, the right-edge → session-menu wiring, rollback |
| [screenshot.md](screenshot.md) | screenshot utility: grim-before-overlay capture, workspace-scoped window pick, native annotation, Print/Esc close rules |
| [display.md](display.md) | `brightnessctl` 0.5 raw units, the `-e4` stepping trap, the 1 % floor script |
| [mpv.md](mpv.md) | vendored uosc, uosc's `input.conf` menu, proving a script loaded |
| [packages.md](packages.md) | Arch merging `cargo` into `rust`, paru's stale PKGBUILD, makepkg without a TTY |
| [system.md](system.md) | aborted pacman runs (`db.lck`, `download-*`), `/tmp` being wiped, rebuild workflow, Docker, measuring boot speed |
| [launch-performance.md](launch-performance.md) | why Firefox/kitty launched slowly on the spinning disk, what was changed, and why zswap must stay off |
| [cache.md](cache.md) | `paccache.timer`: the drop-in, why it exists, whether it slows boot, measured cache size |
| [opencode-mcp.md](opencode-mcp.md) | MCP wiring traps for opencode (restart the *service* not the TUI, npx first-connect timeout), plus the agentmemory experiment and why it was removed |
| [opencode-websearch.md](opencode-websearch.md) | websearch provider selection: the Firecrawl keyless refusal that silently empties results (why `random` never fails over), which providers work keyless, the one-line provider pin |
| [free-llm-access.md](free-llm-access.md) | getting free LLM access: which providers are genuinely free/keyless, which are dead, Groq's measured limits, and the freellmapi verdict |
| [hermes.md](hermes.md) | hermes' native `opencode-go` provider, and the verified opencode free-tier `FreeTierError` gate |

Last verified: 2026-10-17
