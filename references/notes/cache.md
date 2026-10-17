# Cache Policy

How `/var/cache/pacman/pkg` is trimmed: the timer, why it exists, what it does
to boot time, and its measured state.

Back to [notes index](README.md) - [package management](../package-management.md) - [docs index](../README.md)

## Cache policy — keep 1 version, drop orphans

`pacman-contrib` ships `paccache.timer` (**weekly**, `Persistent=true`) which
runs `paccache.service`, a `Type=oneshot` unit that does
`paccache -r $PACCACHE_ARGS` with the args from `/etc/conf.d/pacman-contrib`.

Two changes make it match the policy:

```bash
# /etc/conf.d/pacman-contrib
PACCACHE_ARGS="-rk1"
```

`paccache` refuses two operations in one invocation (*"only one operation may
be used at a time"*), so purging orphans needs a second `ExecStart`. That is a
drop-in, which survives package upgrades (the shipped unit would not):

```ini
# /etc/systemd/system/paccache.service.d/paccache.conf
[Service]
ExecStart=
ExecStart=/usr/bin/paccache -rk1
ExecStart=/usr/bin/paccache -ruk0
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now paccache.timer
systemctl list-timers | grep paccache
```

### Does the timer slow boot?

No. A timer is a calendar entry, not a boot-time service — enabling one adds no
service to the boot sequence. The only nuance is `Persistent=true` (left as
shipped): if the weekly slot passed while the machine was powered off, the job
runs **once** at the next boot. Measured here:

| Thing | Cost |
|---|---|
| `paccache` scan of 1048 cache files | **21 ms** (76 ms cold) |
| `dev-sda2.device` at boot, for scale | **8.224 s** |

Boot is 42.8 s total (4.1 firmware + 7.6 loader + 4.5 kernel + 26.6 userspace),
and the distro already runs three `Persistent=true` timers of its own —
`fstrim.timer` (weekly, TRIMs the whole SSD) is far heavier than paccache.

Verified after setup:

```
$ systemctl list-timers paccache.timer
Mon 2026-10-19 00:00:00 IST  3 days  -  paccache.timer  paccache.service

$ systemctl show paccache.timer -p Persistent
Persistent=yes
```

Manual equivalent: `sudo paccache -rk1 && sudo paccache -ruk0`.
Always check first with `--dryrun`.

### Current state (2026-10-15)

Set up and verified:

- `paccache.timer` enabled, weekly, `Persistent=yes`, both `-rk1` and `-ruk0`
  confirmed in the merged unit; a manual `systemctl start` returned
  `Result=success` and pruned the one orphan package.
- `paru` 2.1.0-2 installed, `~/.config/paru/paru.conf` in place, `rust` removed
  again, the AUR clone deleted (`~/del` now holds only `Hyprland`,
  `references`, `mpv-legacy-config`).

The cache was already tidy before any of this: **524 packages cached for 523
installed — one version each, zero orphans** (`paccache --keep 1 --remove
--dryrun` and `--uninstalled --remove --dryrun` both return nothing). The
~1.6 GB is simply what 524 packages weigh, so the timer is insurance against
growth, not a one-off saving. A stale `download-0GQ92D` dir (from an aborted
pacman run earlier that day) was removed.
