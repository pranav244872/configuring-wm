# Battery & Power

**Status: 🔄 in progress** — the low-battery warning is built and verified
(2026-10-20). Power profiles and sleep-lock are still backlog.

Back to [qol index](README.md) - [docs index](../README.md)

## Low-battery warning (done)

`modules/power/BatteryWatch.qml` (singleton) + `modules/power/battery_model.js`
(pure decisions, so the table can be tested without draining the machine).

- **One reading shared with the bar**: `BarBattery` binds to `BatteryWatch.pct`
  / `state` / `charging`, so the warning and the indicator cannot disagree.
- **Event-driven**: UPower's own percentage and state updates. Omarchy polls a
  30 s timer; there is nothing to poll here.
- **Two levels, once each per discharge**: 20% → `BATTERY LOW` (normal urgency,
  **30 s** — the reference's timeout, our cap), 10% → `BATTERY CRITICAL`
  (critical = sticky, red icon). Neither repeats
  at the same level; skipping straight past 20% fires only the critical one.
- **Rearms** above 25% (hysteresis) or when the charger goes in — and going in
  also takes the warning toasts down (`NotificationService.dismissLocal`).
- **`device.ready` gate**: the UPower device object exists before its first
  `GetAll` lands and `percentage` reads 0 until then. Without the gate a shell
  start at 95% fired a bogus `0% · plug in now` critical toast (seen
  2026-10-20).
- **Both signals**: `UPower.onBattery` **and** `state === Discharging` — either
  alone lies for a moment right after a plug event.
- **Body**: `20% left · 1h 12m` from `device.timeToEmpty`, or
  `20% left · plug in soon` when UPower has no estimate; critical says
  `10% left · plug in now`.
- **Local toast, not `notify-send`**: `NotificationService.post()` puts a row in
  the same stack and history with a negative id — no D-Bus client, no libnotify
  (not installed; using it would be a package). It **bypasses DND on purpose**:
  the shell raising its own warning is intentional.
- **Hook**: an executable at `~/.config/quickshell/hooks/battery-low`, invoked
  with the level as `$1` (the analogue of `omarchy-hook battery-low <level>`).
  Missing or non-executable is a no-op.
- **IPC** (`target: battery`, owned by `BarBattery`, the always-present reader):
  `status`, `check`, and `warn <level>` — the `omarchy-battery-low <percent>`
  analogue, also the way to exercise the toast without a low battery.

### Verified live (2026-10-20)

- The decision table (12 cases: 100 / 30 / 25 edge / 26 rearm / 20 / 20 again /
  10 / 10 after 20 / 10 again / 5 from cold / 15 with critical up / recover)
  passes with zero failures.
- Forced-threshold integration (temporarily `discharging: true`, thresholds
  raised): the real `check()` posted the toast, the hook received `95`, and
  `battery status` reported `low-sent`, then `critical-sent`; reverted and
  re-verified (no toast at 95% on AC).
- `battery warn 20` → `BATTERY / BATTERY LOW / 20% left · plug in soon`, still up
  at 11.5 s and gone by 31.5 s (30 s timeout); `warn 10` → sticky
  `BATTERY CRITICAL` past 9.5 s until dismissed; both land in history.
- DND on → the warning still shows (bypass), DND restored afterwards.
- `clearWarnings()` removed a live toast (the plug-in dismissal path).
- Bench cards come from `summaryFor()`/`bodyFor()`, so the preview cannot drift.

### Traps

- `NotificationUrgency` lives in `Quickshell.Services.Notifications`;
  importing `qs.modules.notifications` alone is not enough (`ReferenceError` on
  the first live run).
- `post()` inserts with `Qt.callLater`, the same incubation rule as
  `onNotification`.

## What Omarchy does (reference)

`omarchy-battery-low <percent>` sends
`notify-send -u critical -t 30000` (glyph `󱐋`, icon `battery-caution`) and then
runs `omarchy-hook battery-low <level>`; its quickshell service polls every 30 s,
warns at 10% once per discharge (`PersistentProperties.notifiedLowBattery`), and
also switches power profiles on AC/battery.

## Still backlog

| Piece | Cost | Notes |
|---|---|---|
| Power profiles | `power-profiles-daemon` + one user service | auto performance on AC / power-saver on battery for the i3-10110U |
| Sleep-lock | `hypridle` (or our own idle service) | lock before suspend; we own the lock screen already |
| Power draw in the bar | none | UPower `energyRate`; the bar shows percent only today |
