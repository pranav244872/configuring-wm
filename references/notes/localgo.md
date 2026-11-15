# LocalSend in the shell (localgo)

File transfer to a phone with **no browser and no KDE stack**: the phone runs
LocalSend, the desktop runs `localgo serve`, and our drawer drives the daemon's
control socket.

Back to [notes index](README.md) - [docs index](../README.md)

## Shape

```text
LocalSend app ── HTTPS (LocalSend v2.2) ── localgo serve ── Unix socket ── LocalgoService.qml
```

`localgo serve` owns discovery (multicast + subnet scan), TLS, the pending
approvals and the download directory. The shell never parses the TLS link; it
only reads state and posts decisions.

**Trigger:** the bottom-left 8×8 hover zone (300 ms dwell), the bar's LocalSend
mark, or `SUPER + ALT + P`. The drawer is full height, flush with the left bezel
(no gap, no bezel-side border — same body as the launcher) and slides in from
the edge, so it comes to the pointer instead of covering the right side.

## Measured alternatives (why not the usual suspects)

| Option | Packages | Disk | Notes |
|---|---|---|---|
| `kdeconnect` | 386 | 1556 MiB | pulls `kwallet` via `kio` |
| `warpinator` | 233 | 1020 MiB | GTK3 + python-grpc + polkit |
| `r-quick-share` / `open-quickshare` | — | ~200 MB | GTK3 + WebKit, GUI only |
| `localgo-bin` | **0 deps** | **12.5 MiB** | single binary, IPC socket |

The Quick Share ports avoid a phone app but are GUI-only and still drag in
WebKit; LocalSend + localgo is the only combination that is both an app and
scriptable.

## Control socket

`$XDG_CACHE_HOME/localgo/ipc.sock` (ours: `~/.cache/localgo/ipc.sock`), only
with `--ipc`. Endpoints are the ones the shell uses:

| Endpoint | Use |
|---|---|
| `GET /v1/status` | alias, port, protocol, downloadDir, pendingCount |
| `GET /v1/devices` | peers with `ip`, `port`, `protocol`, `available`, `deviceType` |
| `GET /v1/pending` | `pendingId`, sender, `files[]` with name/size |
| `GET /v1/transfer/accept?pendingId=` | let the upload run |
| `GET /v1/transfer/reject?pendingId=` | drop it |
| `GET /v1/events` | SSE: `transfer_pending`, `transfer_progress`, `transfer_complete`, `transfer_rejected`, `device_discovered` |

SSE `data:` lines are the **whole Event object** (`{id,time,type,data}`), not
just the payload: parse `evt.type` and `evt.data`. The stream sends a
`: keepalive` comment every 15 s, so an idle stream is not a dead one.

Without `--ipc`, an incoming transfer blocks on a terminal prompt and the
drawer shows nothing.

## Traps

- **A discovery hit is not a listening phone.** `/v1/devices` keeps peers from
  their last announcement (`available` is the cache's view), while `send` needs
  the app live. In the shell, the discovery cache showed the phone as
  `available: true` and `localgo send` still answered *"recipient not found on
  network after all discovery tiers"*, then a direct dial got *connection
  refused*. LocalSend stops listening when the app is backgrounded — the app
  must be in the foreground. The drawer therefore only enables SEND FILES for
  `available !== false` and prints `PHONE OFFLINE — OPEN LOCALSEND` otherwise.
- **`send --ip` is HTTP, the phone is HTTPS.** `--ip 192.168.1.3:53317` skipped
  discovery and posted to `http://…/prepare-upload`, which a LocalSend phone
  refuses. Use `--to <alias>` so the protocol comes from discovery; `--ip` is
  only the fallback for HTTP peers.
- **`localgo send` exits 0 on a failed transfer.** The failure is a
  `{"type":"error"}` NDJSON event on stdout, and the human text on stderr. The
  service treats the event as the failure signal and keeps stderr only for the
  message.
- **Exactly one file picker, no drag-and-drop.** Quickshell 0.3.2 layer
  surfaces do not accept DnD, so SEND FILES opens `zenity --file-selection`
  (already installed) and parses one path per line.
- **No cancel for outbound sends.** The CLI has no cancel verb; the drawer
  shows progress and completion only. Inbound cancellations come for free
  through `/v1/events`.
- **The file chooser is a portal window.** zenity is GTK4, so the dialog that
  actually maps is `xdg-desktop-portal-gtk`, not `zenity` — a float rule
  matching only `zenity` left it tiled and behind. `windowrules.lua` floats the
  portal class (and centres it).
- **The drawer must be unmapped before the chooser maps.** A layer surface with
  `keyboardFocus: Exclusive` keeps the dialog from being focused: the first
  attempt pressed Escape and closed the drawer instead of the chooser, and
  `hyprctl activewindow` stayed on the terminal. Fix: `visible: open && !picking`
  on the drawer, `picking` set 220 ms *before* zenity starts, reset when it
  exits (it reappears with the transfer row).

## QML traps hit while building it

- **A `pragma Singleton` rooted on `QtObject` cannot hold inline objects**:
  there is no default property, so `Component { … }` and `Timer { … }` at the
  top level fail with *"Cannot assign to non-existent default property"*. Put
  them in properties (`readonly property Component getComponent: Component
  { … }`).
- **Same-directory singletons** (`LocalgoFmt`) resolve through the implicit
  import; an explicit `import qs.modules.localgo` inside the module is not
  needed.
- **The drawer is content-sized** (`height: min(content.implicitHeight + 2 ×
  margins, screen − 88)`), with the middle in a `Flickable` capped at 420 px.
  A fixed 640 px drawer was mostly empty with one device.

## Verification (2026-11-15)

Proven without a phone by pointing the shell at a mock daemon (same socket
paths, fake status/devices/pending and a scripted SSE stream): the pending card
with ACCEPT/REJECT, inbound progress, the completed row moving to RECEIVED, and
the offline state with START LOCALGO.

Proven with the real phone:

| Check | Result |
|---|---|
| bottom-left hover zone | `--move 4 1076` → `localgo isOpen` true, dashboard and wallpaper stay closed |
| drawer geometry | left-anchored, `width 380`, full height at `x=0` (flush, slides from `-width`) |
| peer discovery | `SMART STRAWBERRY 192.168.1.3` in the card, `available: true` |
| floating chooser | portal dialog `938×503` at `491,304`, `float=true`, `activewindow` = `xdg-desktop-portal-gtk` |
| chooser cancel | drawer unmaps for the chooser, comes back when it exits |
| outbound start | row appears immediately as `WAITING`, then progresses to `DONE` |
| outbound end to end | file accepted on the phone, row `DONE` (sender timeout raised to 120 s so a human can reach the phone) |
| inbound end to end | phone → `arch`: INCOMING card, ACCEPT, file in `~/Downloads`, row moves to RECEIVED |

## Files

| Path | What |
|---|---|
| `modules/localgo/LocalgoService.qml` | socket client, SSE, send/accept/reject |
| `modules/localgo/LocalgoHost.qml` | drawer window, IPC (`toggle`/`sendFile`/…), LockState |
| `modules/localgo/LocalgoContent.qml` | layout + device selection |
| `modules/localgo/{LocalgoPending,LocalgoDevices,LocalgoTransfers,LocalgoRecent}.qml` | sections |
| `modules/bar/BarLocalgo.qml` | bar mark + transfer rule |
| `~/.config/systemd/user/localgo.service` | `localgo serve --ipc --no-clipboard` |
