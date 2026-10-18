# System and Workflow Traps

The environment traps that waste time: sudo, /tmp, aborted runs.

Back to [notes index](README.md) - [docs index](../README.md)

## System / workflow traps

- **Aborted `pacman` runs leave `/var/lib/pacman/db.lck`.** Check no pacman is
  running (`ps aux | grep [p]acman`), then
  `echo '<sudo pw>' | sudo -S rm -f /var/lib/pacman/db.lck` and retry.
- They can also leave a **`/var/cache/pacman/pkg/download-XXXXXX`** partial
  download dir (owned by `alpm`), which `paccache` doesn't touch and `du`
  can't read without root. Found one on 2026-10-15 and removed it; harmless
  but it makes `du -sh /var/cache/pacman/pkg` fail with "Permission denied".
- **`/tmp` is wiped on reboot** — anything cloned there (wiki, benchmarks) is
  gone after a restart; re-clone into `/tmp/opencode/`.
- Sessions start on **tty1**; launch with `start-hyprland`, leave with
  `SUPER + M`. If the config breaks before binds register, Hyprland installs
  emergency binds: `SUPER+Q` terminal, `SUPER+R` launcher, `SUPER+M` exit.
- The source build lives at `~/del/Hyprland` with its `build/` dir kept, so
  updates are incremental: `git pull` → `cmake --build ./build --config Release -j4`
  → `sudo cmake --install ./build`.

## Measuring speed

- **`systemd-analyze time` / `blame` only measure up to `graphical.target`.**
  They will happily report a clean 42.8 s while a service eats a core between
  login and a usable desktop. The user's definition of boot speed is
  **power-on → login → Hyprland responsive** (see
  [preferences.md](../preferences.md)), so session-time costs have to be
  measured separately — don't argue from `systemd-analyze`.
- Baseline on this machine: 4.1 s firmware + 7.6 s loader + 4.5 s kernel +
  26.6 s userspace; the single worst unit is `dev-sda2.device` at **8.2 s**,
  i.e. the disk dominates, not userspace daemons.
- **User units don't gate the boot target** — they start in parallel with the
  session rather than in the boot path, so they never appear in `blame`.

## Docker

- **The `docker` group is root-equivalent.** `docker run -v /:/host … chroot
  /host` writes the host filesystem as root with no password. We are
  deliberately **not** in it (`id -nG` shows only `pranav wheel`), so Docker
  needs `sudo`. Adding yourself is one command but hands over root.
- Arch's `docker` package leaves **`docker.service` disabled** after install —
  nothing Docker-related runs at boot. Start it deliberately with
  `sudo systemctl start docker`.
- Rootless Docker on Arch needs the AUR package `docker-rootless-extras`
  (the ArchWiki says so explicitly); it provides user `docker.service` /
  `docker.socket` units plus `dockerd-rootless-setuptool.sh`. Prerequisites we
  already satisfy: `/etc/subuid` + `/etc/subgid` entries
  (`pranav:100000:65536`), `newuidmap`/`newgidmap`, user namespaces enabled,
  `/dev/fuse` present. Revisit only if root-equivalent access becomes a problem.
- Socket activation (`docker.socket`) is the cheap way to have the daemon
  available on demand without paying for it at login — that's what the old
  `~/del/configuring-wm` setup did at system level.
