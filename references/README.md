# Hyprland Setup — Reference & Memory

Machine: pranav @ Arch Linux — Intel i3-10110U, Intel UHD 620, 7.5 GiB RAM, 60 Hz panel
Started: 2026-10-15 · Last updated: 2026-10-19

**This directory is the persistent memory of this setup** — for future sessions
and for other models. A reference to rebuild the machine from scratch, not a
session log. Short, factual, one topic per file.

## Where things are

```
references/
├── README.md               # you are here — index, current state, ground rules
├── preferences.md          # the "why": philosophy, look & feel, workflow
├── apps.md                 # per-app decisions: mpv, notifications, quickshell
├── references.md           # where ideas came from, and what we took
├── package-management.md   # packages we install, AUR rule, paru, cache timer
├── shell.md                # our own quickshell UI — what's built, what's next
├── gaming.md               # games via Steam (The Spike Cross)
│
├── setup/                  # rebuild in order
│   ├── README.md           #   step index + status
│   ├── 01-minimal-bare-install.md
│   ├── 02-runtime-packages.md
│   ├── 03-fork-build-deps.md
│   ├── 04-hyprland-fork-build.md
│   ├── 05-hyprland-config.md
│   └── 06-rice.md
│
├── notes/                  # verified traps, one topic per file
│   ├── README.md           #   index
│   ├── hyprland.md         #   animation units, fork quirks
│   ├── validation.md       #   how to validate each config
│   ├── quickshell.md       #   QML 0.3.2 traps, the input trap, dragging values
│   ├── shell-ui.md         #   building our own UI, verifying it
│   ├── display.md          #   brightnessctl / backlight
│   ├── mpv.md              #   uosc, script loading
│   ├── packages.md         #   paru, the cargo→rust merge
│   ├── cache.md            #   paccache.timer, why and whether it costs boot time
│   ├── system.md           #   sudo, /tmp, aborted runs, Docker
│   ├── launch-performance.md #  Firefox/kitty launch speed on the spinning disk
│   ├── opencode-mcp.md     #   MCP wiring traps, the agentmemory experiment
│   └── free-llm-access.md  #   free LLM providers, limits, what actually works
│
└── qol/                    # backlog: features from reference setups, not adopted
    └── README.md
```

## Where to start reading

| If you want to… | Read |
|---|---|
| change something and understand why | [preferences.md](preferences.md) |
| know why an app is configured that way | [apps.md](apps.md) |
| rebuild the machine from scratch | [setup/](setup/README.md) |
| avoid a trap that already bit us | [notes/](notes/README.md) |
| install a package | [package-management.md](package-management.md) |
| work on our own UI | [shell.md](shell.md) |
| play The Spike Cross / use Steam | [gaming.md](gaming.md) |
| know where an idea came from | [references.md](references.md) |
| see what's still missing | [qol/](qol/README.md) |

## Current state at a glance

- **Compositor**: own fork, built from source → `/usr/bin/Hyprland` 0.56.2
  (`pranav244872/Hyprland @ invisible-ss`), no pacman package owns it.
  Source + incremental build dir: `~/del/Hyprland`.
- **Config**: Lua, split into modules, live at `~/.config/hypr/`
  (`hyprland.lua` + `modules/*.lua`) plus `scripts/brightness.sh`.
  Not mirrored in this repo yet.
- **Shell**: `fish` (login shell) with `zoxide` driving `cd`.
- **Terminal**: `kitty` with config at `~/.config/kitty/`.
- **Media player**: `mpv` with **uosc** as the UI (`~/.config/mpv`, vendored
  script; right-click = menu). Bare config — see
  [apps.md](apps.md).
- **Editor**: `neovim` 0.12.6 with the `configuring-wm` config deployed
  verbatim (`vim.pack` + pinned revs, LSP via mason, locally compiled
  treesitter, fzf-lua pickers). Theme is a committed matugen JSON, so colours
  are static and the `matugen` binary is not installed — see
  [notes/neovim.md](notes/neovim.md).
- **Desktop shell**: our own **quickshell** UI — **OSD** (volume + brightness
  draggable pill) and **Top bar** (centered floating pill island with dynamic
  1..10 workspace indicator and 24h clock, `~/.config/quickshell/`). Autostarted
  at login (`qs -n`); `SUPER + SHIFT + O` restarts it. Icons from
  Material Symbols. See [shell.md](shell.md).
- **Packages**: `paru` installed for the rare AUR case; weekly cache trim via
  `paccache.timer` — see [package-management.md](package-management.md).
- **Games**: The Spike Cross via the normal **Steam** client. The earlier
  standalone Proton/Goldberg experiment was purged 2026-10-16 — see
  [gaming.md](gaming.md).
- **Memory**: `references/` is the memory layer — hand-curated and
  authoritative. An automatic alternative (agentmemory) was installed and
  **removed on 2026-10-15**; the lessons are in
  [notes/opencode-mcp.md](notes/opencode-mcp.md).
- **Launch**: no display manager — `start-hyprland` from TTY, `SUPER + M` to exit.
- **Autostart inside Hyprland**: `hyprpolkitagent` + our quickshell (`qs -n`, warm at login).

## Ground rules

- **Bare minimum by default** — but *ask* before installing anything new; a
  package that removes a pile of workaround code earns its place. See
  [preferences.md](preferences.md).
- **Never invent architecture** — take it from well-known, actively maintained
  repos (cloned to `/tmp/opencode`), see [references.md](references.md).
- **No display manager, no uwsm** — TTY launch.
- **Compositor built from source** (fork feature `no_screen_share`); everything
  else from official repos where possible.
- **AUR on demand** — no AUR by default. `paru` is available for the rare
  package that isn't in `extra`, but ask first. See
  [package-management.md](package-management.md).
- Package lists contain only explicit `pacman -S` arguments.
- **Update these docs in the same change** as any install/config edit.
- **One topic per file** — if a file grows past ~150 lines, split it and add it
  to the right index.
- **Version-controlled copy**: this folder is mirrored into the `configuring-wm`
  repo (`~/del/configuring-wm/references/`). After any edit here, copy it over
  and commit there too — see the skill's *Persistent Memory Hygiene* section.

## Status legend

✅ done · 🔄 in progress · ⬜ planned · ⏸ deferred
