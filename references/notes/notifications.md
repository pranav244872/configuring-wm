# Notifications (our own daemon + toasts)

**Status: built and verified 2026-10-19** — our shell *is* the notification
daemon. `Quickshell.Services.Notifications`' `NotificationServer` claims
`org.freedesktop.Notifications`, so no mako/dunst/swaync is installed; the toasts
are our own QML.

Back to [notes index](README.md) - [docs index](../README.md)

## Files

| File | Role |
|---|---|
| `modules/notifications/NotificationService.qml` | singleton: the server, the toast model, durations, DND, history, and `post()`/`dismissLocal()` for the shell's own toasts. Logic only — a 0.3.2 singleton roots on a bare `QtObject` and cannot hold windows or an `IpcHandler` |
| `modules/notifications/NotificationHost.qml` | `PanelWindow` overlay: the toast stack, the per-toast countdown, IPC target `notifications` |
| `modules/notifications/NotificationCard.qml` | presentation only — reused by the toast stack **and** the dashboard history list |
| `modules/dashboard/NotificationsSection.qml` | DND switch + history, its own tab in the dashboard sheet (the sheet is tabbed: network / notifications) |
| `modules/bar/BarDnd.qml` | bell-off glyph in the bar's right cluster, visible **only** while DND is on; click toggles |

## Flow

`onNotification` → `tracked = true` → snapshot the fields we draw → keep the live
object in `liveRefs[id]` → DND gate → `Qt.callLater` → drop a superseded id, drop
a duplicate, trim to `maxVisible`, `insert(0, row)` → the delegate runs the
countdown → dismissal/expiry archives a plain copy into `history`.

## Shell-originated toasts

The shell raises its own notification without a D-Bus client:
`NotificationService.post({app, appIcon, summary, body, urgency, expireTimeout})`
returns an id and inserts a plain row with a **negative** id (server ids are
positive, so they cannot collide). No live `Notification` exists behind it —
dismiss and expire already handle a null ref — and `dismissLocal(id)` takes it
down again. It ignores DND on purpose: a warning the shell raises itself is
intentional. Used by the low-battery toast
([qol/battery-and-power.md](../qol/battery-and-power.md)).

## Policy

| Rule | Value | Why |
|---|---|---|
| Lifetime | floor 5 s (low) / 8 s (normal); sender's `expire_timeout` stretched up to **30 s**; **critical = sticky** (no timer) | omarchy's policy; a rude sender cannot park a toast for an hour, and a critical alert must not vanish while you are away |
| Hover | pauses the countdown | reading a toast must not race it |
| Content update | restarts the countdown | new text deserves a full look |
| On screen at once | `maxVisible 4`; the **oldest leaves early** (into history) | a chat burst must not fill the screen |
| Duplicate content | the newest copy stays, the older one is dismissed at the server | a re-sent line does not stack a twin |
| History | session-only ring of 20, newest first | survives neither a shell restart nor a reload (omarchy files it to disk; that is the upgrade path) |
| DND | one boolean, persisted to `~/.cache/quickshell/notifications.json` (400 ms debounce, hydrated at startup) | a shell restart must not silently un-silence you |
| DND bypass | `app_name` is a bare CLI (`notify-send`, `busctl`, `gdbus`) **and** urgency is critical | chat apps mark everything critical; a scripted alert is the one that should get through |
| Silenced | non-ephemeral ones are written straight to history, then released (`tracked = false`) | "what did I miss while silenced" is what history is for |
| Ephemeral | `transient` hint set, or a CLI `app_name` | nothing to look back at |
| Click | runs the `default` action if the sender registered one, then dismisses | pressing a toast should do the thing |
| Body | **plain text only** (`textFormat: Text.PlainText`) | `Text` is AutoText, so markup would arrive even though the server does not advertise it — an `<img>` body would be a remote GET beacon |

Capabilities advertised (verified with `GetCapabilities`): `body`, `actions`,
`icon-static`. Server name `quickshell`, spec version 1.2.

## Placement and window

Full-screen overlay layer, `exclusionMode: Ignore`, never keyboard focus, mapped
only while a toast is up (`visible: popups.count > 0`). The click mask is the
toast column itself, so everything outside the cards falls through. Cards stack
top-right, clear of the bar: `topOffset 50` (30 bar + 12 `gaps_out` + 8),
`sideOffset 20`, width 340 (`Theme.notifications`). Cards fade in; nothing
animates out, because a dismissal must not leave a gap in the column.

In the dashboard the same card is reused for history, **full width** and with the
arrival time at the right of the app line (`showTime`, `HH:MM`) — a one-line
notification in a 684px row looks half-empty without a right-hand anchor — and no
countdown. There the ✕ removes the row from the list (`removeHistory`, matching
`notifId` + `timestamp` — history is plain data with no server object behind it, and
a `ListView` hands the delegate a *copy*, so the match can never be on the object),
while on a toast the same ✕ dismisses and a body click runs the default action.

## IPC

`qs ipc call notifications <toggleDnd|setDnd <bool>|dndState|dismissAll|dismissOne|invokeLast|clearHistory|count|historyCount>`
— `count`/`historyCount` exist so scripts and verification can assert state.

## Traps (all hit live)

- **`tracked = true` must be the first statement** of the handler: an untracked
  notification is destroyed the moment the handler returns, and every reference
  taken from it goes dead mid-flight.
- **Never put a live `Notification` in a `ListModel` role.** The object becomes a
  dangling C++ pointer when the server destroys it and the next read of that role
  segfaults inside `QQmlListModel::data`. The model holds plain snapshots; the
  objects live in a JS map (`liveRefs`) keyed by id.
- **A row returned by `ListModel.get()` stops answering once it is removed** —
  every role reads back `undefined`, which wrote `[{}]` into the history. Copy the
  row into plain data *before* `remove()` (see `copyRow`).
- `Text` is `AutoText`: a notification body renders markup even when
  `bodyMarkupSupported: false`. Force `textFormat: Text.PlainText`.
- `keepOnReload` defaults to **true**: a config reload re-emits every
  notification still on screen as a fresh one. Set it false.
- Mutating the model inside the signal handler crashes (`QV4::Object::insertMember`)
  while the `Repeater` is incubating — mutate inside `Qt.callLater`.
- The delegate, not the card, owns the countdown: the card is shared with the
  history list, where a clock is meaningless. Slots survive model changes because
  a `ListModel` insert only creates one delegate — a JS-array model would rebuild
  every delegate and reset every countdown and hover pause.
- **The card-wide click catcher must be declared before the content column**
  (sibling order = input priority). Declared after it, it swallowed the ✕: the
  button emitted `cardClicked` instead of `closeRequested`, which looked fine in
  the toast stack (invoke-then-dismiss) and was simply dead in the dashboard.
- **The ✕ then still did nothing, for a second, unrelated reason**: a `ListView`
  hands a JS-array model's delegates a converted copy of each element, so
  `history.filter(e => e !== entry)` matched no row at all. Removal matches
  `notifId` + `timestamp` now. Both fixes were needed (2026-10-19; story in
  [dashboard.md](dashboard.md), model trap in
  [quickshell.md](quickshell.md#qml-and-api-traps-in-032)).

## Verification (2026-10-19)

`gdbus call … Notify` against the live shell: normal toast expired at 8 s and
landed in history; a critical one was still up after 10 s; DND on silenced a
normal toast (count unchanged, history +1) while a critical one from `gdbus`
punched through; `replaces_id` rewrote the card in place (one toast, countdown
restarted); a burst of five left four on screen; the `default` action emitted
`ActionInvoked` (seen with `dbus-monitor`) and dismissed the toast; the DND file
round-tripped `{"dnd":true}` → `{"dnd":false}`, and a **real restart**
(`qs kill` + `qs -nd`) came back up hydrated (DND still on) with no errors and
toasts working. Dashboard rows render the archived text (screenshot). Card states
+ both bar states are in `preview_notifications`.

With a real pointer (`tools/uclick.py`, recipe in
[ui-verification.md](ui-verification.md)): clicking a toast's ✕ dismissed it with
**no** `ActionInvoked`, clicking its body emitted `ActionInvoked(id, "default")` and
closed it, and the dashboard's history ✕ removed exactly its row with the sheet still
open on the same tab. **Hover pauses the countdown** — parked on a toast 12 s past its
8 s expiry it was still up, and out it went within 9 s of leaving. `hyprctl dispatch
movecursor` can do none of this: it produces no motion/enter event for Qt.

## Deferred (v2, in order of likely value)

A sender of our own (battery/crash toasts carry an `app_name` we control plus a
click command as **argv data**, omarchy-style); file-backed history so it survives
restarts; hyperlinks + image bodies with `<img>` stripping; click-to-focus the
sender when there is no `default` action; per-app rules (DMS style); keybinds
(`SUPER+,` family); `inlineReplySupported`.

## Verification (2026-10-20)

`qs ipc call battery warn 20/10` (local posts): the normal toast was still up at
11.5 s and expired by 31.5 s (its 30 s `expire_timeout`) into history, critical
stayed up past 9.5 s, DND on still showed it (bypass), and `dismissLocal`
removed it (history +1). Card copy in the bench comes from the same helpers.
