# Cheatsheet (Wayland screen-analysis overlay)

A GTK4 layer-shell overlay that screenshots the screen with `grim`, sends it to
[antigravity-relay](antigravity-relay.md) (`:8081`) and shows the answer.
Repo: `pranav244872/cheatsheet`, local clone `~/del/cheatsheet`, branch
**`single-machine`** (the Wayland overlay; `main` is the old Windows/Moonlight
version).

Back to [notes index](README.md) - [docs index](../README.md)

## Pieces

| Piece | Detail |
|---|---|
| overlay | GTK4 + `gtk4-layer-shell` (via `LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so`), namespace `cheatsheet`, default 650×500 |
| capture | `grim` full-screen, overlay hidden for ~0.25 s |
| hotkeys | `python-evdev` grabs every keyboard and forwards events through its own `uinput` device (`cheatsheet-vkbd`); hotkey presses are consumed |
| backend | OpenAI-compatible `POST /v1/chat/completions` on `http://localhost:8081` |
| venv | `.venv` **with `--system-site-packages`** so `gi`/GTK and the distro `evdev` are visible |

`run.sh` sleeps 1.5 s (release keys), exports `LD_PRELOAD`/`PYTHONPATH` and execs
`.venv/bin/python3 main.py`.

## Setup as done (2026-11-02)

```bash
sudo pacman -S --needed gtk4 gtk4-layer-shell python-gobject python-httpx python-evdev
cd ~/del/cheatsheet && git checkout single-machine
python3 -m venv --system-site-packages .venv
.venv/bin/pip install -r requirements.txt   # dotenv, httpx, Pillow
./run.sh
```

`requirements.txt` does not list `evdev`/`gi` — they come from the two pacman
packages above. `grim` and `slurp` were already installed for the rice.

### Input access (udev uaccess)

`/dev/input/event*` is `root:input 0660`; this user is not in `input`. Rather
than joining the group (needs re-login), a udev rule grants the **active seat
user** an ACL:

```udev
# /etc/udev/rules.d/70-input-uaccess.rules
SUBSYSTEM=="input", KERNEL=="event*", TAG+="uaccess"
```

```bash
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=input --action=change
getfacl -p /dev/input/event0 | grep user:   # user:pranav:rw-
```

Trade-off: this is the same read access as the `input` group, i.e. everything
can read every key. It is what the overlay's design requires. `/dev/uinput`
already had an ACL from Sunshine's rule.

## Hotkeys

Numpad keys; this laptop's internal keyboard advertises `KEY_KP0`–`KEY_KP7` and
`KEY_KPPLUS/MINUS/DOT` (Fn combos), verified with `evdev`.

| Key | Action |
|---|---|
| KP1 | screenshot → analyze (stateless) |
| KP2/KP3/KP4 | queue screenshot as MCQ / code / general |
| KP5 | process the queue |
| KP6 | clear queue |
| KP7 | cycle model (low → medium → high) |
| KP0 | show/hide overlay |
| KP+/KP− | scroll (Ctrl = opacity) |
| KP. | cancel (Ctrl = theme) |

## Models

The relay exposes only `gemini-3.8-flash-{low,medium,high}`; the overlay cycles
those and defaults to **medium** (`src/providers.py`). The old gemini-web-server
names (`-think`, `gemini-3.1-pro`, `3.5-flash-lite`) are gone.

The relay is **stateless**: requests still carry `temporary`/`metadata`, but the
relay ignores them, so there is no server-side conversation to resume.

## Live verification (2026-11-02)

Because the overlay reads only keyboards it grabbed, the test injects a virtual
keyboard **before** starting the app so it is grabbed too:

1. a small `evdev` `UInput` device (`cheatsheet-test-kbd`, full key range) is
   created and waits;
2. `./run.sh` starts and logs `Grabbed: cheatsheet-test-kbd` +
   `Grabbed: AT Translated Set 2 keyboard`;
3. the helper emits `KEY_KP1`; the app captures, hides, screenshots and posts.

Result:

```
[src.providers] INFO — Calling gemini-3.8-flash-medium (stream)...
[httpx] INFO — POST http://localhost:8081/v1/chat/completions "HTTP/1.1 200 OK"
[src.providers] INFO — OK (stream)
```

and the relay logged the same POST + a 200 from
`daily-cloudcode-pa.sandbox.googleapis.com/v1internal:streamGenerateContent`.
The answer appears in the overlay (`sessions/<ts>/chat.log` records it).

The helper's device is closed while grabbed, so the reader thread logs one
`OSError: [Errno 19] No such device` — a test artifact, not an app bug.

## Logging fix

`main.py` now calls `logging.basicConfig(..., force=True)`. A dependency installs
a WARNING-level handler at import time, so the plain `basicConfig` was a no-op
and **every INFO line was silently dropped** — the overlay looked dead while it
was running fine.

## Running / stopping

```bash
cd ~/del/cheatsheet && ./run.sh          # foreground
pkill -f "[c]heatsheet/.venv/bin/python3 main.py"
```

No autostart is configured. While running it holds an exclusive grab on every
keyboard and forwards events through `cheatsheet-vkbd`; quitting releases the
grab immediately.

## Traps

- **Wayland only** (`grim`, layer-shell, `wlr` protocols). The `main` branch's
  `pygetwindow`/`mss` path does not work here.
- The overlay needs the relay **running and authenticated**; otherwise KP1 shows
  a connect error. Check `curl http://localhost:8081/health`.
- Run `run.sh` from the repo dir (it derives `PYTHONPATH` from its own path, so
  it is fine either way, but `.env`/`settings.json` live there).
- `gtk4-layer-shell` is loaded with `LD_PRELOAD`; launching `main.py` directly
  without it will create a normal window instead of a layer surface.
