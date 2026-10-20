# Bluetooth tab

The dashboard's third tab: a Bluetooth manager built as a study of **Blueberry**
(Linux Mint's app, itself a thin GTK wrapper around `gnome-bluetooth`), rebuilt
in the Chaldea frame. It replaces nothing — there was no Bluetooth UI before.

## What Blueberry does (read from source, 2026-10-20)

`blueberry.py` + `blueberry.ui` are mostly the **status page**; the device
widget is gnome-bluetooth's.

| Blueberry | Behaviour | Ours |
|---|---|---|
| header switch | one on/off switch, plus an rfkill error icon | header `Toggle` |
| stack | `main-page` ⇄ `status-page` | one content area, five states |
| no adapter | *"No Bluetooth adapters found"*, switch insensitive | `NO BLUETOOTH ADAPTER` |
| hard block | *"Bluetooth is disabled by hardware switch"*, insensitive | `DISABLED BY HARDWARE SWITCH`, no action |
| soft block | *"Bluetooth is disabled"*, switch **actionable** | `BLUETOOTH IS BLOCKED (RFKILL)` + `[UNBLOCK]` |
| rfkill error | error icon whose tooltip names udev/rfkill-group permissions | error line (`COULD NOT UNBLOCK — CHECK RFKILL PERMISSIONS`) |
| settings popover | adapter **Name**, OBEX receive, tray icon | footer: `VISIBLE AS <alias>` (click to edit) + `DISCOVERABLE` |
| adapter line | *"Visible as "arch"."* | the footer's alias |
| device list | one list, discovered rows read **"Not Set Up"** | `MY DEVICES` / `AVAILABLE` sections |
| device detail | second page: connection switch, Paired/Type/Address, settings buttons, Forget | inline expansion: address, type, battery, connect/pair/forget |
| forget | modal *"Forget Device?"* | `FORGET` → `CONFIRM` (3 s), no modal |
| pairing | PIN/passkey dialogs from a registered BlueZ agent | `bluetoothctl --agent NoInputNoOutput` (see below) |

**Skipped on purpose:** OBEX file receive (`bluez-obex`), the "Sound / Mouse /
Keyboard settings" buttons (they launch DE panels we don't have), the tray icon
(we have a bar, not a tray), OBEX/`Send Files…`.

## API: Quickshell 0.3.2 has native BlueZ

`import Quickshell.Bluetooth` — no `bluetoothctl` parsing, no extra package.

| Object | Used for |
|---|---|
| `Bluetooth.defaultAdapter` | `name`, `enabled` (writable), `state`, `discoverable` + timeout, `discovering`, `devices` |
| `BluetoothAdapterState` | `Disabled / Enabled / Enabling / Disabling / **Blocked**` |
| `BluetoothDevice` | `name` (alias, writable), `deviceName`, `address`, `icon`, `state`, `connected`, `paired`, `pairing`, `trusted`, `batteryAvailable`, `battery`, `connect()/disconnect()/pair()/cancelPair()/forget()` |
| `BluetoothDeviceState` | `Disconnected / Connected / Disconnecting / Connecting` |

Two facts that cost time:

- **`battery` is 0..1**, not a percentage — Quickshell scales BlueZ's 0–100 by
  `0.01` (`device.cpp`). Multiply before printing.
- **The module registers no pairing agent** (there is no agent source in the
  module). `pair()` calls BlueZ `Pair()` and nothing answers the request.

## Pairing: a short-lived agent

BlueZ needs an agent for *any* pairing, including JustWorks. Quickshell cannot
register one, and `python-gobject` is not installed (so no zero-package Python
agent either). What does work with zero packages:

```
bluetoothctl --agent NoInputNoOutput     # prints "Agent registered"
```

`NoInputNoOutput` makes BlueZ auto-confirm JustWorks and numeric-comparison
requests. The section starts it on demand (`Process` with `stdinEnabled: true`
keeps it alive without a TTY), waits for the *Agent registered* line (1.5 s
fallback), then calls `pair()`, sets `trusted = true` on success, and SIGTERMs
the process. A 15 s cap reports `PAIRING TIMED OUT`.

**Limitation:** a device that *requires* a PIN/passkey entry cannot be paired
from the tab. Pair it once from a terminal (`bluetoothctl`, then `pair <MAC>`);
later connects work from the tab. Caelestia and DMS get dialogs by writing their
own agent into a native daemon — out of scope for a QML-only shell.

## rfkill

`adapter.state === Blocked` covers both block kinds, so the *detail* comes from
`rfkill -J -o SOFT,HARD,DEVICE`: any entry whose device contains `bluetooth` or
starts with `hci` counts; soft = blocked in `soft`, hard = blocked in `hard`.

- `/dev/rfkill` is `crw-rw-r--+ root:rfkill` with a logind ACL for the seat user,
  so `rfkill unblock bluetooth` works without a password (verified on this
  machine: `rfkill` listed both `ideapad_bluetooth` and `hci0` soft-blocked, then
  unblocked by the user's wireless switch).
- The `[UNBLOCK]` flow: `rfkill unblock` → re-probe → when `blocked` flips false
  `onBlockedChanged` sets `enabled = true` (Quickshell refuses `enabled = true`
  while `Blocked`, `adapter.cpp`). If it never flips: `STILL BLOCKED — CHECK THE
  HARDWARE SWITCH`.
- Polkit is not needed; `pkexec` remains the fallback if a machine lacks the ACL.

## Behaviour details

- **Only the visible tab works**: `discovering` starts on `activate()` and stops
  on `deactivate()` (same rule as the network scan), so a background tab is idle.
- **Grouping** (`bluetooth_model.js`): connected → paired → unpaired; real names
  before bare MACs; then alphabetical. Section headers carry a count.
- **Unpaired devices are not filtered**: they live in BlueZ memory for the boot
  only, so the list is honest; `FORGET` on an unpaired row removes it from BlueZ.
- **Failure inference**: `pair()`/`connect()` are fire-and-forget in Quickshell.
  A 500 ms watcher treats "pairing stopped, not paired" (after 1.2 s) as failure,
  and "connect returned to Disconnected" as failure — the error line names it.
- **Bench**: `preview_bluetooth.qml` renders six mock states (saved+expanded,
  available+expanded, off, rfkill, empty, no adapter) without touching the radio.

## Files

| Path | What |
|---|---|
| `modules/bluetooth/BluetoothSection.qml` | tab body: states, list, footer, processes |
| `modules/bluetooth/BluetoothRow.qml` | one device + inline detail |
| `modules/bluetooth/bluetooth_model.js` | sorting, grouping, BlueZ→Material icons, battery text |
| `modules/dashboard/DashboardContent.qml` | third tab + `syncActive()` per-tab activation |
| `modules/Theme.qml` | `btScan` / `btOff` / `btSearching` glyphs |
| `preview_bluetooth.qml` | six-state bench |

## Verification (2026-10-20)

| Check | Result |
|---|---|
| Bench, six states | rendered, no QML errors (`/tmp/opencode/preview_bluetooth.png`) |
| Shell load | `Configuration Loaded`, 0 errors, single instance |
| IPC | `qs ipc call dashboard tab bluetooth` → `tabName` = `bluetooth` |
| Live OFF state | tab showed `BLUETOOTH IS OFF` while `bluetoothctl show` said `PowerState: off` |
| rfkill copy | bench only — a live blocked screenshot was missed (the switch was unblocked between checks) |
| Interactive (TURN ON, toggle, discoverable, alias edit, UNBLOCK) | **pending** — the session idle-locked mid-test |
| Pairing | **deferred** — no device to test with; agent registration proven by hand |

## Traps

- **Restart racing**: `qs kill` is asynchronous; starting `qs -n` one second later
  can print *"An instance of this configuration is already running"* and leave
  nothing running. Verify `pgrep -c -x qs` = 1, and never restart while locked.
- **`StdioCollector.text` notifies `dataChanged`, not `textChanged`** — a
  `textChanged` handler never runs, so the "Agent registered" watcher would
  silently degrade to its 1.5 s fallback. Use `onDataChanged`.
- The lock closes the sheet (`LockState.locked` → `DashboardHost.close()`), so a
  locked session cannot be used to drive the tab.
- An inline `component SectionHeader: Item` inside a ListView delegate needs an
  explicit `width` (only `height` is supplied by the delegate) or its right-aligned
  count lays out against a zero-width row and never appears.
- The header/body copy is state-first: `PAIRING…` / `CONNECTING…` outrank
  `PAIRED` / `CONNECTED`, so a transition never looks idle.
