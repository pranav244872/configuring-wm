# Gaming (Steam)

Windows games run via the normal **Steam client** (`pacman` `steam`, from
multilib). First game: The Spike Cross (SUNCYAN volleyball, App ID `3983810`,
depot `3983811`, F2P).

Back to [docs index](README.md).

## Status 2026-10-16 (post-purge)

- A full no-Steam stack was built first (steamcmd + GE-Proton runner +
  Goldberg emu + a hand-written `steam_api64.dll` shim) and **purged** the
  same day: the game's first boot waits on a server-minted credential that
  only a real, logged-in Steam session can provide.
  Boot chain (reverse-engineered from `data.win` + wininet traces): language
  files → Firebase token refresh (`securetoken.googleapis.com`, 400s without
  creds) → `SuncyanNet` → `obj_LoginScreen_manager`. Goldberg's
  `GetAuthTicketForWebApi` is a stub returning 0; the ticket exchange with
  `suncyan.com/thespike/auth_check` can never complete. Server-side wall —
  no client-side emulator passes it.
- Everything from that experiment is gone: the whole `~/Games` tree
  (steamcmd, runner, prefix, shim, Goldberg dlls, `play.sh`), the
  `mingw-w64-gcc` chain, and the Steam symlinks it needed. Nothing lives
  outside Steam's own directories now.
- The game is downloaded through the Steam UI and managed by Steam
  (download, update, prefix).

## Layout (standard Steam)

```
~/.local/share/Steam/              # client (~/.steam/root -> here)
  steamapps/common/                # game files (Steam-managed)
  steamapps/compatdata/<appid>/    # per-game Proton prefix (= saves)
```

## What was configured (once)

- `sudo pacman -S steam` — pulls the `lib32-*` chain; multilib was already
  enabled. `vulkan-intel` (driver) is required: DXVK needs a Vulkan ICD or
  games die with `DXGI_ERROR_UNSUPPORTED` (surfaces as a silent `EXIT=5`).
- **Steam Play for all titles** pre-seeded in
  `~/.local/share/Steam/config/config.vdf` so no GUI toggle is needed:

  ```
  "CompatToolMapping" { "0" { "name" "proton_experimental" "config" "" "priority" "75" } }
  ```

  A `"0"` entry with priority `75` is exactly what the GUI checkbox writes
  (pattern verified against `docker-steam-headless`). GUI equivalent:
  Settings → Compatibility → *Enable Steam Play for all other titles*.
  Steam rewrites `config.vdf` on exit; if Steam Play ever misbehaves,
  re-check this key first.
- Official Proton only (Proton Experimental installs on first game launch).
  GE-Proton via Steam would additionally need the Steam Linux Runtime 4.0
  container (`require_tool_appid 4183110` in its tool manifest) — not used.

## Play

Steam library → The Spike Cross → Play. First launch builds the Proton
prefix (~1 min) and performs the Steam→Firebase login handshake.

## Host quirks worth remembering (cost hours)

- **Broken IPv6 default route**: the host has an IPv6 default route that
  dead-ends (connect fails instantly; IPv4 works). Wine tries IPv6 first
  with no Happy-Eyeballs fallback, so HTTPS inside any prefix can fail with
  wininet error `12029`. Fix inside a prefix (while wine is not running):
  `Tcpip6\Parameters\DisabledComponents = dword:ffffffff`.
- Wine network/HTTP debugging flags: `WINEDEBUG=+winsock,+wininet`.
- steamcmd (only if a download-only job ever comes up again): needs
  `+@sSteamCmdForcePlatformType windows` for Windows-only depots, and a
  logged-in owner account — anonymous gets `No subscription` even for F2P.

## Caveats

- Steam's CEF helpers cost ~1 GB RAM idle — that was the whole reason the
  standalone route was attempted first; the login wall made it unshippable.
- Achievements, cloud saves, gacha/live events need this real session anyway.
