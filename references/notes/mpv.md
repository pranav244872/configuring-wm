# mpv + uosc Notes

Vendored uosc, the bare mpv config, and how to prove a script actually loaded.

Back to [notes index](README.md) - [docs index](../README.md)

## mpv + uosc

- **uosc is vendored, not packaged.** Install = drop `uosc.zip` contents into
  `~/.config/mpv/` and `uosc.conf` into `~/.config/mpv/script-opts/`
  (release assets on GitHub: `tomasklaen/uosc`). `scripts/uosc/bin` (ziggy,
  ~18 MB, subtitle search) was **deleted on purpose**.
- uosc **replaced modernz + select.lua**. The previous config (modernz v0.3.1,
  select.lua, thumbfast, autoload, playlistmanager, a 381-line modernz.conf) is
  parked at `~/del/mpv-legacy-config/mpv`; rollback = move the files back into
  `~/.config/mpv/`.
- **uosc builds its menu from `input.conf` comments**:
  `#!Title > Submenu > Item` on a line makes that bind clickable; using `#`
  instead of a key makes a menu-only entry (no keybind at all). Right-click is
  bound to `script-binding uosc/menu`.
- mpv **0.41 has no `--list-scripts`**. To prove a script loaded, start mpv with
  `--input-ipc-server=/tmp/x.sock` and send
  `script-message-to <name> flash-elements timeline` over IPC: a real script
  answers `success`, a bogus name answers `error running command`.
- mpv's **default keybindings are baked into the binary**, not a config file.
  List them with:
  `strings /usr/bin/mpv | sed -n '/#default-bindings start/,/#default-bindings end/p' | grep -E '^#[^ #]'`
  (196 of them). `no-input-default-bindings` wipes them all — we deliberately
  do **not** use it.
- `keep-open=yes/always` makes headless test runs hang forever — override with
  `--keep-open=no --idle=no` and wrap in `timeout`.
- If select.lua ever comes back: it needs `~/.config/mpv/menu.conf` or it
  errors on load (`attempt to index local 'menu_conf' (a nil value)`); Arch's
  mpv package does not ship upstream's `etc/menu.conf`.
