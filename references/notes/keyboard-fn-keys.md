# Laptop Keyboard: the F-row and the Fn key

Hard-won facts about this machine's F-row (Lenovo IdeaPad 81WB). Read before
trying to bind an F-key, or before "fixing" a hotkey that appears to do nothing.

Back to [notes index](README.md) - [docs index](../README.md)

## Two behaviours per key

Every F-key has a hotkey function and an `Fn+F1`..`Fn+F12` function. Which one a
*plain* press gives is an EC/BIOS setting ("Hotkey Mode", aka Fn Lock):

| Fn Lock | plain `F2` | plain `F9` | `Fn+F2` | `Fn+F9` |
|---|---|---|---|---|
| **0** (default — hotkeys primary) | volume down | *firmware lock hotkey, invisible to Linux* | `F2` | `F9` |
| 1 (F-keys primary) | `F2` | `F9` | volume down | (hotkey) |

- Toggle with `Fn+Esc` (the kernel marks that event `KE_IGNORE` in
  `ideapad-laptop.c` — "handled by the firmware"), or from Linux:
  `echo 1 > /sys/devices/pci0000:00/0000:00:1f.0/PNP0C09:00/VPC2004:00/fn_lock`
  (read it back to verify; the `platform::fnlock` LED mirrors it).
- **Fn Lock flips the whole row.** Turning it on to reach `F9` bare also moves
  volume/brightness behind `Fn`, which is why it is left at 0 here.

## Plain F9 cannot be bound (verified 2026-10-17)

Lenovo's official hotkey list gives IdeaPad 3 the row: mute / vol− / vol+ / mic /
refresh / touchpad / airplane / camera / **lock screen (`F9`)** / display switch /
brightness. That lock hotkey is a firmware action:

- **No evdev keycode.** A raw `/dev/input` capture over every non-pointer device
  logged *nothing* for plain F9, while `Fn+F9` logged `KEY_F9` (code 67).
- **No ACPI notify.** `ideapad-laptop.c`'s sparse keymap has no screen-lock entry
  (only camera, mic-mute, touchpad, WLAN, video-mode, PROG1–4…), the driver logged
  no "Unknown event", and no WMI input device is registered.
- **Therefore no bind can catch it** — not by keysym, not by the wiki's
  `code:<n>` prefix (there is no keycode to name), not via acpid.

The lock bind is therefore on the `F9` keysym, and the real gesture is **`Fn+F9`**
(see `~/.config/hypr/modules/keybinds.lua`). On Windows this works bare only
because Lenovo's own driver handles the hotkey.

## Identifying an unknown key

There is no `wev`, `evtest`, or `libinput` binary here. Substitute: a ~20-line
Python reader on `/dev/input/eventN` (as root), mapping codes to names via
`/usr/include/linux/input-event-codes.h`. It prints raw key-down codes — exactly
what `wev` would. Note it logs **every** keystroke while running (passwords
included), so run it briefly and delete the log after.
