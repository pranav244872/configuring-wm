# Menus & Keybinding Cheatsheet

**Status: ⬜ not started**

## What Omarchy does

Fourteen `omarchy-menu-*` entries: `clipboard`, `emoji`, `emoji-insert`, `file`,
`images`, `input`, `keybindings`, `herdr-keybindings`, `tmux-keybindings`,
`plugin`, `select`, `share`, `timezone`, plus the main `omarchy-menu`.

**herdr** is a separate keybinding manager (`~/.config/herdr/config.toml`) that can
print an **annotated keybinding cheatsheet generated from the live keymap**:

```
omarchy-menu-herdr-keybindings   # interactive search menu
omarchy-refresh-herdr            # re-read config
omarchy-restart-herdr
```

This is the interesting part: the old `configuring-wm` had a hand-maintained
`keybinds-menu.sh`; herdr-style generation never goes stale.

## What we have today

| Need | Our solution | Status |
|---|---|---|
| app launcher | none (bare) — `SUPER+F` unbound | ⬜ |
| keybinding reference | none (the old `keybinds-menu.sh` was retired) | ⬜ |
| clipboard history | `wl-clipboard` installed, no history UI | ⬜ |
| powermenu | `SUPER+M` exits Hyprland; no power menu | ⬜ |

## Notes / options

- For a **keybinding cheatsheet**, the cheapest version is a script that greps
  `~/.config/hypr/modules/keybinds.lua` — zero packages, slightly stale.
- Launchers (rofi / anywalker / fuzzel / quickshell app grid) are all in
  official repos; a launcher is the biggest usability gap in the bare setup.
- uosc already covers *mpv's* menus; this is about the desktop, not the player.
