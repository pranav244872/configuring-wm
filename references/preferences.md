# User Preferences & Decisions

Standing record of what the user asked for and why. **Read this before changing
anything** — it is the reason behind the current setup. Per-application decisions
(mpv, notifications, the quickshell shell) live in [apps.md](apps.md); technical
traps live in [notes/](notes/README.md).

Last updated: 2026-10-16

## Philosophy

- **Bare minimum by default** — no bloat; every package must earn its place.
  But this is a *default*, not a hard rule: **when an install would make
  something simpler, safer or less code, ask the user** — don't refuse on
  principle, and don't install silently either. (Decided 2026-10-15 after the
  icon-font episode: quickshell's own UI couldn't render Nerd Font PUA glyphs,
  and one 9 MiB font package beat a pile of workarounds.)
- **Speed first** — animations short, effects off, VFR on. On an i3-10110U /
  UHD 620 laptop with a 60 Hz panel, GPU and battery win over looks.
- **"Boot speed" means power-on → login → Hyprland responsive** — the user's
  definition, stated explicitly after we measured the wrong thing. It is *not*
  `systemd-analyze time`, which stops at `graphical.target` and knows nothing
  about what happens between login and a usable desktop. Anything starting
  during the session competes for CPU inside exactly that window, so **prefer
  on-demand / socket activation over "enabled at login"**, and measure
  login→WM-ready when the claim matters.
- **Official repos first** — no AUR by default. Changed 2026-10-15: the user
  asked for `paru`, so the rule is now "AUR only through paru, only when a
  package genuinely isn't in the official repos, and only after asking".
  See [package-management.md](package-management.md).
- **No display manager** — launch Hyprland from a TTY (`start-hyprland`).
  No uwsm either.
- **Compositor built from source** — own fork for its screenshare-hiding feature.
- **Rice layer comes later** — the WM should be usable before it is pretty.
- **These docs are the memory layer — hand-curated, not automatic.** An
  automatic alternative (agentmemory) was installed and **removed the same day
  (2026-10-15)**: it captured well but only recalled by keyword without an LLM
  key, and it retained a transcript of all work indefinitely. Don't re-propose
  it without a reason. See [notes/opencode-mcp.md](notes/opencode-mcp.md).
- **Free LLM access is possible but limited** — see
  [notes/free-llm-access.md](notes/free-llm-access.md) before suggesting one.
  Groq's free tier is 8,000 tokens/min; only 3 of freellmapi's 34 providers are
  genuinely keyless.

## Look & feel (chosen)

| Setting | Value | Reason |
|---|---|---|
| `decoration.blur` | off | biggest GPU saving; official "lowest power" tip |
| `decoration.shadow` | off | second biggest saving |
| window opacity | 1.0 / 1.0 | no transparency compositing |
| gaps in / out | 6 / 12 | tightened 2026-10-16 for the frame look |
| border size | 2 | kept (teal) |
| rounding | 0 | straight edges 2026-10-16 to match the shell frames |
| bar gap | 12 (= gaps_out; exclusiveZone reserves exactly the 30px bar) | uniform with edges |
| colors | Material teal (`primary #80d4dc`) | kept from the old matugen palette |
| logo / mascot wallpaper | off | `disable_hyprland_logo`, `force_default_wallpaper = 0` |

- **Shell visual language**: Chaldea frames with our teal — square hairlines,
  corner ticks, tracked mono labels, solid selection rows. Fast as ever:
  anything that moves lands in 40–70ms. Decided 2026-10-16.

## Animations

- **~120–200 ms** everywhere. Workspace transitions are re-enabled as a fast
  fade (~120 ms) — the user does want *some* motion, just fast.
- Curve: `easeOutQuint` (fast start, eased landing).
- **No springs** — measured, they settle slower than the beziers here.
- `global` (fallback for any unset leaf) is set explicitly so nothing silently
  inherits a slow default.
- **UNITS GOTCHA: lower `speed` = faster** (`duration_ms = speed × 100`).
  See [notes/hyprland.md](notes/hyprland.md#animation-speed-units).

## Keybind philosophy

- `SUPER` is the main modifier. Layout:
  - Basics: `SUPER+RETURN` terminal · `SUPER+Q` close · `SUPER+M` exit ·
    `SUPER+V` float · `SUPER+W` fullscreen · `SUPER+P` pseudo · `SUPER+J` split
  - Focus: `SUPER` + arrows; workspaces `SUPER+[0-9]`, move with `SHIFT`;
    scratchpad = special workspace `magic` on `SUPER+S`
  - Mouse: `SUPER+LMB` drag, `SUPER+RMB` resize, `SUPER+scroll` workspaces
  - Multimedia keys: volume/mute/mic via `wpctl`, brightness via
    `~/.config/hypr/scripts/brightness.sh`, ±5 % steps **linear** (no exponent
    curve — `-e4` was tuned for a different panel and made a "5 %" press drop
    ~13 %), **±1 % with `ALT`**. Volume steps **unmute first** (keys and OSD
    slider); only the mute key mutes. Brightness **never goes below 1 %**, and
    raising it from the floor jumps back to 5 % so you don't crawl out one
    percent at a time. **Brightness binds also ping our quickshell OSD over
    IPC** (`qs ipc call osd brightness`); volume needs no call-out because the
    OSD watches PipeWire itself.
  - Media transport keys via `playerctl`
  - `SUPER+SHIFT+O` restarts our quickshell UI (`qs -n` — no duplicate instances).
    It autostarts at login (see `autostart.lua`).
  - `CTRL+SHIFT+F` = fake (client-only) fullscreen — for Moonlight sessions
    where `SUPER` is unavailable. Note kitty grabs this key itself.
- Config is split into modules under `~/.config/hypr/modules/` (same idea as
  the old `configuring-wm` repo).

## Shell & terminal

- **`fish` is the login shell** (`chsh -s /usr/bin/fish`), same as the old setup.
- **`zoxide` drives `cd`**: `zoxide init fish --cmd cd | source` — fuzzy jumps,
  falls back to real paths. `cdi` = interactive picker (needs fzf).
- `kitty` config ported verbatim from the old setup: JetBrainsMono Nerd Font
  Mono 12, 90 % opacity, teal palette, `ctrl+shift+t` new tab with cwd.
- **`eza` replaces `ls`** (installed 2026-10-18, `extra/eza` 0.23.5):
  `ls` = `eza -la --group-directories-first --icons=auto` and `lt` = a two-level
  tree with git status — the old setup's flags, restored in `config.fish`. `lt`
  is a **function, not an alias**: eza 0.23 prints *nothing* for a bare
  `eza --tree`, so the old alias would have looked broken here; ours passes `.`
  unless a path is given. Icons ride on the Nerd Font kitty already uses.
- Deliberately **not** ported yet (tools absent): starship prompt, mise, bat /
  fzf aliases, vssh tunnel helpers.

## Workflow — how the user wants us to work

- **Never invent architecture.** Look for well-known, actively maintained
  repositories (stars + recent commits) and copy their proven approach; clone
  them to `/tmp/opencode` to study. Check online docs for API patterns too
  (Qt docs settled our Canvas image-loading and drag implementation).
  Architecture decisions come from references, not from first principles.
- **Build only what is asked.** No extra features "while we're here" — say what
  is being built and why, then ask about anything unrequested.
- **Short and sweet comments.** Keep comments inside code and configs short,
  concise, and to the point — no long-winded commentary.
- **Ask first when told to plan.** State considerations and questions before
  implementing; propose options with a recommendation.
- **Verify, don't assume**: run the thing, check logs, render a picture of the
  UI. Report what was actually observed.
- **Update the docs in the same change** as any edit — this directory is memory
  for future sessions and other models.

## Explicitly rejected / deferred

| Item | Why |
|---|---|
| `qt5-wayland` | no Qt5 apps yet |
| `xdg-desktop-portal-gtk` | pulls gtk3; add when the first GTK app arrives |
| `uwsm` | user choice — direct launch |
| pacman `hyprland` | replaced by the source build |
| rofi / waybar / hyprpaper / hyprlock / hypridle / grim+slurp | rice phase |
| SDDM or any DM | TTY launch = fewer services, faster boot |

## How the user wants this directory maintained

- `references/` is **persistent memory** — for future sessions and for
  other models. Keep it factual, short, and free of session/audit noise.
- One topic per file; **split anything past ~150 lines** into its own file
  folder and index it (`setup/` for the rebuild steps, `notes/` for traps).
- Package lists contain **only explicit `pacman -S` arguments** (no transitive deps).
- Document *why*, not just *what*.
