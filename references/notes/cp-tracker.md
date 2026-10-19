# CP tracker widget (built by another agent)

A draggable desktop card with Codeforces/AtCoder ratings, the next target
contest and an upcoming-contest schedule, sitting on the **background layer**
next to the calendar.

**Attribution:** built by a *different* agent (Antigravity / Gemini) on
2026-10-19 at the user's request — not by the shell agent. It was reviewed,
verified and documented here; treat its internals as third-party until touched.

## Files

| Path | Lines | What |
|---|---|---|
| `~/.config/quickshell/tools/cp_tracker.py` | 341 | the data backend |
| `~/.config/quickshell/modules/cp_tracker/CpTrackerCard.qml` | 442 | the card |
| `~/.config/quickshell/modules/cp_tracker/CpTrackerWidget.qml` | 86 | fullscreen background window + drag/position |
| `~/.config/quickshell/preview_cp_tracker.qml` | 37 | bench (renders to `/tmp/preview_cp_tracker.png`) |
| `~/.config/quickshell/shell.qml` | — | `import qs.modules.cp_tracker` + `CpTrackerWidget {}` after `CalendarWidget {}` |

## Data backend (`cp_tracker.py`)

- **No API keys, stdlib only** (`urllib.request`): Codeforces's public API
  (`codeforces.com/api`) and AtCoder's public pages (scraped — the brittle half).
  8 s timeout per request.
- Handles are CLI args with defaults `--cf-handle` / `--ac-handle` =
  `pranav244872`; the card invokes plain `python3 … --json`, so changing a handle
  means editing the card's command or passing args.
- Contest selection is rating-aware: `LevelMatcher.evaluate()` filters by
  `effective_rating = max(cf_rating, ac_rating)` with a floor of 800, so only
  contests in range are listed.
- Cache: `~/.cache/quickshell/cp_data.json`, written **atomically**
  (`cp_data.json.tmp` + `os.replace`). `--json` prints a fresh result;
  `--print-cache` returns the file only if it is younger than **10 minutes**.
- Cache shape: `status`, `last_updated_epoch/str`, `user`
  (`cf_handle/cf_rating/cf_rank/ac_*/effective_rating`), `featured_contest`
  (`platform/id/name/start_epoch/duration_*/url/rated_range/tier/badge/badge_color/start_formatted/countdown/hours_until`),
  `upcoming_contests[]` (8 entries as of 2026-10-19).

## The card

- Reads the cache on frame 0 (`Process` + `sh -c cat`, the shell's usual shape),
  so the numbers are on screen before any network call finishes.
- Refreshes every **15 min** (`Timer`) with a 60 s countdown ticker and a manual
  refresh glyph (`Theme.glyphs.shotReselect`).
- Uses `Theme.colors.*`, `Theme.frame.*`, `Theme.font.*` only — so it follows the
  matugen palette like the rest of the shell (no hex of its own).
- The name is elided, and the Lua-independent bits (`boundW/boundH`, `dragging`,
  `dragFinished()`) are its public API.
- `CpTrackerWidget`: fullscreen `PanelWindow`, `WlrLayer.Background`,
  `keyboardFocus: None`, transparent, with `mask: card.dragging ? grabAll : card`
  → click-through except on the card. Position is read from
  `~/.cache/quickshell/cp_widget_pos.json` (`x`,`y`, clamped to the screen) and
  saved on drag-finish through `Quickshell.execDetached`. Default placement is
  left of the right edge, `y = 44`. `visible: host.posLoaded` avoids a frame-0
  flash at the wrong spot.

## Verification (reviewer, 2026-10-19)

| Check | Result |
|---|---|
| Tool run | `python3 tools/cp_tracker.py --json` → `status: success`, 8 upcoming |
| Card render | bench PNG: frame, ratings blocks, featured countdown, schedule list |
| Shell load | restarted shell logged `Configuration Loaded` with **0** errors |
| Mount | `hyprctl layers` shows one extra fullscreen background surface from the shell pid |
| On screen | desktop screenshot (empty workspace 4): card top-right, calendar top-left, both fine |
| APIs used | `Quickshell.execDetached` exists in 0.3.2; `Theme.glyphs.shotReselect` exists (Theme.qml:344) |

## Traps

- **It is a background-layer surface**, so tiled windows cover it by design —
  check it on an empty workspace, not on a workspace with windows.
- Switching workspaces from a script: `hyprctl dispatch 'hl.dsp.focus({ workspace = 4 })'`
  (bare dispatchers are rejected by the fork).
- Restarting the shell through a *dispatched* one-liner
  (`hl.dsp.exec_cmd("qs kill; …; setsid qs -n &")`) left **no** shell running.
  Start it directly (`setsid qs -n`) and assert `pgrep -c -x qs` = 1.
- State lives in `~/.cache/quickshell/` (`cp_data.json`, `cp_widget_pos.json`) and
  is deliberately **not** mirrored into `configuring-wm` — it is runtime state.
- Only one fetch per 15 min per shell instance; an AtCoder HTML change breaks the
  scrape until the parser is updated.
