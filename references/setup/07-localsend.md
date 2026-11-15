# LocalSend file sharing (localgo)

Phone ↔ desktop file transfer with a real app on the phone and a single Go
binary on the desktop. No KDE stack, no browser, no account.

Back to [setup index](README.md) - [docs index](../README.md)

## Why localgo and not KDE Connect

`kdeconnect` resolves to **386 packages / 1.56 GiB** and pulls `kwallet` in
through `kio`. `localgo-bin` is **12.5 MiB with no dependencies** and exposes a
control socket our shell can drive. Warpinator (233 packages / 1.0 GiB) and the
GTK+WebKit Quick Share ports were rejected the same way; measurements are in
[notes/localgo.md](../notes/localgo.md).

## 1. Desktop binary

```bash
paru -S localgo-bin          # AUR, -bin package: no Go toolchain needed
localgo --version            # LocalGo CLI 0.6.8
```

Without a TTY (an agent shell), `paru` cannot answer sudo. Build the AUR
package and install it directly:

```bash
git clone https://aur.archlinux.org/localgo-bin.git /tmp/localgo-bin
cd /tmp/localgo-bin && makepkg -s --noconfirm
sudo pacman -U localgo-bin-*.pkg.tar.zst
```

## 2. Receiver service

`localgo serve` is a normal user service; `--ipc` is what lets the shell accept
transfers instead of a terminal prompt.

`~/.config/systemd/user/localgo.service`:

```ini
[Unit]
Description=LocalSend receiver (localgo) with the shell IPC socket
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=/usr/bin/localgo serve --ipc --no-clipboard --dir %h/Downloads
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now localgo.service
```

`--no-clipboard` keeps this file-only: incoming text is saved as a file instead
of silently replacing the clipboard. `--auto-accept` is deliberately **not**
used, so every transfer waits for the drawer's ACCEPT.

## 3. Floating file chooser

The drawer's SEND FILES opens zenity, but GTK4 dialogs are served by
`xdg-desktop-portal-gtk`: the class that maps is the portal's, not zenity's.
Without a rule the picker tiles and lands behind the card. In
`~/.config/hypr/modules/windowrules.lua`:

```lua
hl.window_rule({
    name  = "file-choosers-float",
    match = { class = "^(xdg-desktop-portal-gtk|zenity|Zenity)$" },

    float  = true,
    center = true,
})
```

The drawer also hides itself while the chooser is up: a layer surface holding
`keyboardFocus: Exclusive` would keep the dialog from being typed into.

## 4. Phone

Install **LocalSend** (v1.18.2, F-Droid / Play / GitHub release). Nothing else:
no pairing, no account. Both devices must be on the same network, and the app
must be in the foreground while it transfers.

## 5. Verify

```bash
curl -s --unix-socket ~/.cache/localgo/ipc.sock http://ipc/v1/status
# {"alias":"arch","port":53317,"protocol":"https","downloadDir":"/home/pranav/Downloads",...}

localgo devices --json        # the phone, its ip/port/protocol
qs ipc call localgo open      # the drawer: devices, SEND FILES
# or hover the bottom-left corner, or SUPER + ALT + P
```

Ports: TCP **53317** (TLS) plus multicast **224.0.0.167:53317**. There is no
firewall rule to add on this machine, but Wi-Fi client isolation would break
discovery — then use `localgo send --ip <phone>:53317` (HTTP only) or a PIN.

The shell side (module layout, IPC/SSE traps, what is verified) is in
[notes/localgo.md](../notes/localgo.md).

Last verified: 2026-11-15 — phone → desktop and desktop → phone both complete,
with the drawer's ACCEPT for the inbound file and the phone's own prompt for the
outbound one.
