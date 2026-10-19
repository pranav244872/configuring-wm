# Verifying Our UI Without Guessing

How to prove a shell surface really behaves — hover, clicks, which item wins an
event — instead of reading the QML and hoping. Everything here was used on the
bar, the dashboard and the notification cards.

Back to [notes index](README.md) - [docs index](../README.md)

## What can not prove it

- `hyprctl dispatch movecursor` does **not** drive hover: no motion/enter event
  reaches the layer surface (a debug `MouseArea` in the window stayed silent), so
  hover needs motion from a real pointer — see the injector below.
- `grim` + `qs ipc call` prove geometry and state, never hovering.
- `dbus-monitor --system` cannot see NetworkManager method calls (unprivileged
  monitoring falls back to eavesdropping): read a property and watch *it* change
  ([dashboard.md](dashboard.md) uses `LastScan`).
- `Item.childAt(x, y)` is **not** an input test: it returns the topmost item
  *geometrically*. Over the notification ✕ it returned the card's decorative
  `CornerTicks` (a 340×72 plain `Item`, no `hoverEnabled`) while a real click was
  in fact delivered to the ✕'s `MouseArea` — an item with no mouse handlers does
  not accept the event. Concluding "the click is swallowed" from `childAt` cost a
  wrong fix (2026-10-19).

## Real clicks: `tools/uclick.py`

```bash
python3 ~/.config/quickshell/tools/uclick.py 1288 764         # move there and left-click
python3 ~/.config/quickshell/tools/uclick.py --move 1650 103  # move only (drives hover)
python3 ~/.config/quickshell/tools/uclick.py --wheel up       # one wheel notch in place
python3 ~/.config/quickshell/tools/uclick.py --key escape     # press a key
python3 ~/.config/quickshell/tools/uclick.py --combo meta+shift+w   # modifiers held
```

- A virtual mouse on `/dev/uinput` (our user has uaccess there, from Sunshine's
  udev rule; `ydotool`/`dotool`/`wtype` are not installed).
- Creating the device needs the legacy `uinput_user_dev` struct written before
  `UI_DEV_CREATE`, or the kernel answers `EINVAL`. ioctls used:
  `UI_SET_EVBIT|KEYBIT|RELBIT = 0x40045564/5/6`, `UI_DEV_CREATE = 0x5501`;
  `input_event` packs as `llHHi` (24 bytes) with the timestamp left at 0.
- Movement is **closed-loop**: emit ≤24 px relative steps 50 ms apart, read
  `hyprctl cursorpos` back, correct. A clamped 100 px step overshot by 52 px
  (pointer acceleration plus a stale readback), and because the script clicked
  anyway that press landed past the sheet, on the desktop. It now **refuses to
  click** unless it is within 3 px of the target.
- `--move` is the hover test on its own: injected motion is real motion.
- `--wheel up|down` sends one `REL_WHEEL` notch at the current position (for a
  carousel's wrap) and pairs with `--move`; `--key <name>` and `--combo
  <mod+mod+key>` press keys (e.g. `meta+shift+w` for a real keybind test).

### Keys and combos: declare the modifier bits or they vanish

uinput **silently drops** an event whose key was never declared with
`UI_SET_KEYBIT` before `UI_DEV_CREATE`. The device originally declared only the
`KEYS` codes, so every `--combo` degraded to a bare key — `meta+shift+w` arrived
as `w`, hit no bind, and the keybind was written off as broken (2026-10-19).
`MODS` values must be declared too.

- The `KEYS`/`MODS` maps hold only what verification needed
  (`escape`/`enter`/`←`/`→`/`↑`/`↓`/`tab`/`w`/`f`/`r`, and the left-hand
  modifiers — `f`/`r` were added for the screenshot selector's mode keys), and
  an unknown name fails **loudly** (`unknown key in combo: meta+s`). Do not pipe
  the injector's stderr to `/dev/null` while using it — that is how a bad combo
  reads as "the bind does not work".
- Prove the *modifier* path separately from the bind, but only with a key that
  is actually mapped: a combo's letter must exist in `KEYS` (add it if the probe
  needs it). `meta+s` cannot work, so "the modifier is broken" is the wrong
  conclusion to draw from it.
- Verified this way on 2026-10-19: `SUPER + SHIFT + W` opens the wallpaper
  picker, and `Escape` closes it.

## Finding the coordinate

`grim` captures from the screen origin, so pixel coordinates in a screenshot are
the coordinates the injector wants. Crop what you care about
(`grim -g "x,y WxH"`), read the target inside the crop, add the offset;
`hyprctl layers` prints each surface's `xywh`. Do **not** use
`Item.mapToGlobal()` on a layer surface — it returns window-local values (the
client never learns where the compositor put the window).

## Assert on state, not on the picture

| What | How |
|---|---|
| toasts / history rows | `qs ipc call notifications count` / `historyCount` |
| sheet open, current tab | `qs ipc call dashboard isOpen` / `tabName` |
| an action fired | `dbus-monitor --session "interface='org.freedesktop.Notifications'"` → `ActionInvoked` |

`grim` is for finding coordinates and for the record: a screenshot shows what is
on screen, not what a click did.

## Benches: probes that pay for themselves

`qs -p ~/.config/quickshell/probe_x.qml` (cwd must be the config dir) runs a
throwaway QML root; `console.log` + `grep` answers in seconds what no doc does —
"is a delegate handed a copy of its model element?" was settled by printing
`modelData === array[0]`
([quickshell.md](quickshell.md#qml-and-api-traps-in-032)). Delete the probe once
it has answered: a probe **on the overlay layer draws above fullscreen windows**
(the real bar sits on level `top`, which the compositor hides), so "the bar does
not hide in fullscreen" gets reported as a bug, and a probe carries no
`TrayMenuHost`, so tray right-click looks dead in it. Both were reported while a
probe was live.

## Proofs recorded 2026-10-19 (notification ✕, hover)

| Path | Expected | Seen |
|---|---|---|
| toast ✕ | toast gone, **no** `ActionInvoked` | `count` 1→0, no signal |
| toast body | `ActionInvoked(id, "default")` then close | signal + `NotificationClosed`, `count` 1→0 |
| dashboard history ✕ | row gone, sheet open, same tab | `historyCount` 1→0, `isOpen` true, `tabName` notifications |
| hover a toast | countdown pauses | parked 12 s past an 8 s expiry: still 1 |
| leave the toast | countdown resumes | expired within 9 s: 0 |
| hot zones (`--move` only) | each zone fires its own surface | bottom→dashboard, right→session menu, bottom-right→wallpaper |
| `--combo meta+shift+w` | the picker opens | `wallpaper isOpen` true |

The ✕ needed two fixes to get there (sibling order, then model identity) — see
[dashboard.md](dashboard.md) and [notifications.md](notifications.md).
