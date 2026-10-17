# Validation Recipes

How to check a config on this machine before restarting anything.

Back to [notes index](README.md) - [docs index](../README.md)

## Validating configs

- Lua: `luac -p file.lua` for syntax, and
  `Hyprland --verify-config` for the real thing (prints `config ok`; **does not
  start the compositor**). Run as your user, not root.
- kitty 0.49 **has no `--debug-config`** (removed). Validate with its embedded
  Python instead:
  ```bash
  kitty +runpy 'import kitty.config as c
  bad = []
  cfg = c.load_config("/home/pranav/.config/kitty/kitty.conf", accumulate_bad_lines=bad)
  print("BAD LINES:", bad if bad else "none")'
  ```
  - `cfg.map` is **emptied** by `load_config()` after keys are finalised
    (`config.py:198`) — empty is normal, not a failure.
  - Finalised mappings live in `cfg.keyboard_modes[""].keymap`, keyed by
    `SingleKey(mods, key)` objects, not strings.
  - When several mappings share a key, the **last one wins** (`keys.py:207-208`
    keeps `matches[-1]`); user mappings are appended after defaults, so they
    override kitty's defaults (e.g. `ctrl+shift+t` → `new_tab_with_cwd`).
  - Relative `include` paths in kitty.conf resolve against `~/.config/kitty/`.
