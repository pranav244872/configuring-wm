# QoL Feature Backlog

Quality-of-life features discovered while studying reference setups — mostly
[Omarchy](https://github.com/basecamp/omarchy) (530 CLI commands) and
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland). See
[references.md](../references.md).

**Nothing in here is installed or configured yet.** Each file is one area, with
what the reference does, what it would take here, and its status. When something
gets adopted, the status changes *and* the relevant step/preference docs are
updated in the same change.

## Status legend

⬜ not started · 🔄 in progress · ✅ done · ⏸ deliberately skipped

| Area | File | Status | One-line summary |
|---|---|---|---|
| Battery & power | [battery-and-power.md](battery-and-power.md) | 🔄 | low-battery toasts (20% / 10%) + hook done; power profiles and sleep-lock pending |
| Runtime toggles | [runtime-toggles.md](runtime-toggles.md) | ⬜ | one-key switches for animations, opacity, gaps, night light |
| Keyboard | [keyboard-takeover.md](keyboard-takeover.md) | ⬜ | kitty grabs `ctrl+shift+<letter>`, so those WM binds never fire |
| Audio helpers | [audio-helpers.md](audio-helpers.md) | ✅ | dashboard `AUDIO` tab: output/input pickers, mic meter, per-app volume — tuning skipped |
| Bluetooth | [notes/bluetooth.md](../notes/bluetooth.md) | 🔄 | dashboard tab: adapter states (rfkill/off/absent), saved + available devices, inline connect/pair/forget, alias + discoverable — pairing untested (no device yet) |
| Capture tooling | [capture-tooling.md](capture-tooling.md) | ⬜ | screenshot, region, screen recording, OCR, webcam |
| Menus & keybinding cheatsheet | [menus-and-keybindings.md](menus-and-keybindings.md) | ⬜ | searchable menus + auto-generated keybinding reference |
| Wallpaper library | [notes/wallpaper-thumbnails.md](../notes/wallpaper-thumbnails.md) + [notes/wallpaper-cycling.md](../notes/wallpaper-cycling.md) | ✅ | ffmpeg thumbnail cache (142–308 ms → a few ms) + interval/shuffle cycling with a picker footer |
| Robustness & session | [robustness-and-session.md](robustness-and-session.md) | ⬜ | crash recovery, stranded-lock detection, sleep-lock, systemd tuning |

## Ground rules for adopting any of these

1. **Bare minimum first** — a feature must earn its packages and its RAM. If it
   can be a three-line config change, prefer that over a daemon.
2. **Mouse over keybinds** — the user's preference: anything bound should also be
   reachable by mouse (see [preferences.md](../preferences.md)).
3. **Official repos first** — AUR only via `paru`, only when a package isn't in
   `extra`, and only after asking ([package-management.md](../package-management.md));
   vendored scripts (like uosc) are fine.
4. Update the matching step doc when something is actually adopted.
