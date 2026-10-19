# Dashboard (the bottom sheet)

**Status: tabbed since 2026-10-19** — network and notifications are tabs, not
columns (the split view left both halves narrow and neither owned the width).

Back to [notes index](README.md) - [docs index](../README.md)

## Shape

`TopBar`-style frame: `Theme.sizes.dashboardWidth` (720) wide, 40 % of the
monitor height, centred on the bottom edge, opened by a bottom-edge hot zone
(`bottom = "exec, qs ipc call dashboard toggle"`) or IPC, closed by Escape or a
click away. It slides up (the sheet's `y` stays unanchored, so the binding
survives), and the whole surface is a `WlrLayer.Overlay` with
`exclusiveMode: Ignore`.

```
01 NETWORK │ 02 NOTIFICATIONS     DashboardTabs: equal cells, block on the active one
──────────────────────────────    hairline
[toggle] WI-FI        07  ⟳       controls row: switch + label left, list right
──────────────────────────────    rule (network only: doubles as the scan track)
list / history                    StackLayout, one section visible
```

- `modules/dashboard/DashboardHost.qml` — the window, the hot-zone/IPC surface,
  Escape and `←`/`→`.
- `modules/dashboard/DashboardContent.qml` — the tab host: it owns `currentTab`,
  exposes `tabName()/setTab()/stepTab()/setTabByName()` and is the one place that
  decides which section may work.
- `modules/dashboard/DashboardTabs.qml` — the row itself.
- One section per tab (`NetworkSection`, `NotificationsSection`); the section
  titles moved into the tab labels, so a controls row starts with its switch.

## The tab row

Equal-width cells, `01 … 05` numbered, tracked-uppercase labels centred, and a
**solid primary block behind the active cell** with dark text — the bar's
workspace treatment (checked against caelestia's `dashboard/Tabs.qml`, which
slides a 3px material pill, and end-4's `waffle/looks/WToolbarTabBar.qml`, which
slides a filled block carrying an accent mark; ours is the Chaldea version).
Inactive numbers keep the accent colour, labels sit at `subtext`, and hover is a
`stateHover` rectangle on **inactive cells only** (the active one has the block).

The block slides on `moveDuration` + `curveMove` (70 ms, slight overshoot), the
same as the workspace pill, so tab switching moves like everything else.

## Only the visible tab works

Both sections stay instantiated in a `StackLayout` (they are light), but
`DashboardContent.syncScanning()` hands the network section
`activate()/deactivate()`: the wifi list scans only while the sheet is open **and**
the network tab is showing. `activate()` rebuilds the snapshot and restarts the
scan, so switching back is instantly current.

Verified against NetworkManager rather than assumed: `LastScan` on the wifi device
advances every ~10 s while the network tab is up (quickshell's
`src/network/nm/wireless.hpp` sets `mScanIntervalMs = 10001`) and does **not move
at all across 25 s** on the notifications tab. Read it with
`busctl --system get-property org.freedesktop.NetworkManager
/org/freedesktop/NetworkManager/Devices/2
org.freedesktop.NetworkManager.Device.Wireless LastScan` (device type 2 = wifi;
the value's units are not seconds, only the *change* matters — and note
`dbus-monitor --system` is useless here: unprivileged monitoring falls back to
eavesdropping and cannot see method calls).

## Moving between tabs

| Path | How |
|---|---|
| Mouse | click a cell; **wheel** anywhere over the row (the row-wide catcher owns the wheel, and unhandled wheel events propagate down to it) |
| Keyboard | `←`/`→` while the sheet is open — they only arrive when no inner item wants them, so the passphrase field keeps them as cursor movement |
| IPC | `qs ipc call dashboard tab <network\|notifications\|next\|prev>`, `tabName` reads it back |

The selected tab lives in `DashboardContent`, so it survives closing and reopening
the sheet and only resets on a shell restart (no cache file — same reasoning as
the caffeine toggle).

## History rows in the notifications tab

The whole 684 px width is used by the reusable `NotificationCard` at full width,
with the arrival time drawn at the right of the app line (`showTime`, `HH:MM`):
a one-line notification in a 684 px row looks half-empty without a right-hand
anchor next to the ✕. Toasts themselves stay untimed (a toast is happening now),
and the history rows show no countdown — there is no clock left to run.

## Trap: the ✕ had two independent causes

1. **Sibling order is input priority.** The tab row declares its row-wide catcher
   (wheel) **first** and the per-cell `MouseArea`s after it, because a later sibling
   takes the click. The same rule bit `NotificationCard`: its card-wide catcher was
   declared after the content column, so the ✕ never received a click — it fired
   `cardClicked` (invoke-and-dismiss) instead, which looked correct in the toast stack
   and was simply dead in the dashboard.
2. **A `ListView` hands a JS-array model's delegates a *converted copy*** of each
   element, so `history.filter(e => e !== entry)` matched no row however well the
   click arrived. `removeHistory` matches `notifId` + `timestamp` now.

Fixing only the first changed nothing visible, which is why the ✕ was reported broken
twice. Both were then proved with a real pointer click (`tools/uclick.py`; recipe in
[ui-verification.md](ui-verification.md)): `historyCount` 1→0, sheet still open, tab
still notifications — plus the two toast paths (✕ dismisses with no `ActionInvoked`,
a body click fires it). Full trap list in
[quickshell.md](quickshell.md#qml-and-api-traps-in-032).
