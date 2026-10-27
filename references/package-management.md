# Package Management

How this machine gets and keeps its packages: pacman settings and the AUR
helper. The `paccache` trim timer is documented separately in
[notes/cache.md](notes/cache.md).

Last updated: 2026-10-20

## Packages installed for this setup (explicit `pacman -S` args only)

Full per-step lists live in the step files. This is the consolidated view —
transitive dependencies are **not** listed (pacman resolves them).

Removed after the fact: `mingw-w64-gcc` (2026-10-16 — built once for the
abandoned Steam-emulator shim, removed with `pacman -Rns mingw-w64-gcc`
together with the whole `~/Games` experiment, transitive chain included).

| Package | Why | When |
|---|---|---|
| `ttf-material-symbols-variable` | icon font for quickshell UI glyphs | 2026-10-15 |
| `papirus-icon-theme` | system application icons for launcher and desktop apps | 2026-10-15 |
| `pacman-contrib` | provides `paccache` + `paccache.timer` for weekly cache trim | 2026-10-15 |
| `docker` | container runtime (service disabled at boot; run with `sudo`) | 2026-10-15 |
| `docker-compose` | v2 compose CLI, `docker compose …` | 2026-10-15 |
| `steam` | game runtime (The Spike Cross); replaces the standalone Proton experiment | 2026-10-16 |
| `vulkan-intel` | Vulkan driver for the UHD 620 — DXVK needs an ICD | 2026-10-16 |
| `jq` | JSON CLI for `hyprctl -j` one-liners (screenshot workspace-filter verification, future scripts) | 2026-10-16 |
| `eza` | modern `ls` (fish `ls` / `lt`) — the last piece of the old repo's shell aliases | 2026-10-18 |
| `neovim` | the editor, with the `configuring-wm` config deployed verbatim (`vim.pack`, mason LSP, compiled treesitter) — the config needs **0.12+** | 2026-10-19 |
| `fzf` | `fzf-lua`'s picker binary (> 0.36) **and** the shell's fuzzy finder: `fzf --fish` bindings in `config.fish` (Ctrl+R history, Ctrl+T files, Alt+C cd) and zoxide's `cdi` | 2026-10-19 (shell bindings 2026-10-27) |
| `tree-sitter-cli` | `nvim-treesitter` **main** compiles parsers with it (>= 0.26.1, not the npm one) | 2026-10-19 |
| `unzip` | mason requirement — clangd ships as a `.zip`, lua-language-server as `.tar.gz` | 2026-10-19 |
| `fd` | the config passes `fd_opts` for the file picker; without it fzf-lua falls back to rg/find silently | 2026-10-19 |
| `matugen` | wallpaper-derived Material 3 palette for the shell, Hyprland, kitty, nvim, GTK and qt6ct — see [notes/matugen.md](notes/matugen.md) | 2026-10-19 |
| `adw-gtk-theme` | `adw-gtk3-dark`: the GTK3 theme that consumes the named colours matugen writes | 2026-10-19 |
| `qt6ct` | Qt6 platform theme (`QT_QPA_PLATFORMTHEME=qt6ct`) applying the dark matugen palette | 2026-10-19 |
| `btop` | system monitor, `color_theme = "matugen"` | 2026-10-19 |
| `starship` | shell prompt; its palette is generated into `~/.config/starship.toml` | 2026-10-19 |

```bash
# quickshell UI fonts and application icons
sudo pacman -S --needed --noconfirm ttf-material-symbols-variable papirus-icon-theme

# cache trimming
sudo pacman -S --needed --noconfirm pacman-contrib

# containers (installed, deliberately not enabled at boot and not rootless)
sudo pacman -S --needed --noconfirm docker docker-compose

# games: Steam client (pulls the lib32-* chain)
sudo pacman -S --needed --noconfirm steam

# JSON CLI for hyprctl scripting/debugging
sudo pacman -S --needed --noconfirm jq

# modern ls replacement (already in extra; --git needs libgit2, pulled as a dep)
sudo pacman -S --needed --noconfirm eza

# editor + the four packages its config needs (fzf-lua, nvim-treesitter main,
# mason, fd pickers). fzf also serves the shell (Ctrl+R/T, Alt+C, `cdi`).
# Already present: ripgrep, gcc/make, git, curl, tar, gzip, python3, nodejs,
# wl-clipboard, the Nerd font.
sudo pacman -S --needed --noconfirm neovim fzf tree-sitter-cli unzip fd
```

The editor's bootstrap (headless, before the first interactive open) and the
config's traps are in [notes/neovim.md](notes/neovim.md).

### Docker

Rootful install, defaults everywhere, and two deliberate choices:

- **`docker.service` is left disabled**, so nothing Docker-related runs at boot.
  Start it when needed: `sudo systemctl start docker`.
- **We are not in the `docker` group.** That group is *root-equivalent*
  (`docker run -v /:/host chroot /host` writes the host as root, no password),
  and the user asked not to have that. Consequence: Docker needs `sudo`, e.g.
  `sudo docker run …`. Adding yourself later is one command:
  `sudo usermod -aG docker "$USER"` (then re-login) — but it grants root.
- No `/etc/docker/daemon.json` tweaks: the old setup's `dns`/`bip` +
  systemd-resolved hack existed for its bridge config and isn't needed now.

A **rootless** setup (daemon as the user, socket in `/run/user/1000/`) was
researched and declined as unnecessary complexity — on Arch it needs the AUR
package `docker-rootless-extras`. See
[notes/system.md](notes/system.md) if it's ever worth revisiting.

## AUR

**Rule (2026-10-15): official repos first. AUR only through `paru`, only when a
package genuinely isn't in the official repos, and only after asking.**

`paru` itself is **not** in `extra`, so it is bootstrapped from its AUR repo
(this is what `~/del/configuring-wm` did too). It is listed here as an AUR package,
not as a `pacman -S` argument:

| AUR package | Version | Why |
|---|---|---|
| `paru` | 2.1.0-2 | AUR helper; the user wanted one (2026-10-15). Built with makepkg from the AUR repo, owned by pacman afterwards (`paru v2.1.0 - libalpm v16.0.1`) |
| `ttf-rubik-vf` | 2.3.0-3 | GTK UI font `Rubik 11` (2026-10-20). Rubik has no official package; the variable build replaces the installer's old `otf-rubik` entry. Built with `makepkg -f` and installed with `sudo pacman -U`, no paru needed — see [notes/packages.md](notes/packages.md#gtk-font-rubik-aur) |

```bash
# AUR helper (see "Building it" below)
git clone --depth 1 https://aur.archlinux.org/paru.git ~/del/paru
cd ~/del/paru && makepkg -si --noconfirm
cd ~ && rm -rf ~/del/paru
```

### Building it (deviation from configuring-wm)

Arch **merged `cargo` into `rust`** (rust ships `/usr/bin/cargo` and
`Provides: cargo`; there is no separate `cargo` or `rust-std` package upstream
any more). paru's PKGBUILD (2.1.0-2, AUR commit 2025-12-12) still lists
`makedepends=('cargo')`, so `makepkg -s` fails with *"Missing dependencies:
cargo"*. Install `rust` first and build with `--nodeps`:

```bash
sudo pacman -S --needed --asdeps --noconfirm rust
cd ~/del/paru && makepkg --nodeps --noconfirm
sudo pacman -U --noconfirm paru-*.pkg.tar.zst
```

`makepkg` also can't install dependencies without a TTY (it calls plain `sudo`,
which errors with *"a terminal is required to read the password"*), so the build
deps have to be installed up front.

### Transient build dependency

`rust` is pulled in only to build `paru`, then removed again so the toolchain
doesn't linger (`base-devel` does not include it):

```bash
sudo pacman -Rns --noconfirm rust
```

A future AUR package that needs Rust re-downloads the toolchain once.

## paru configuration

`~/.config/paru/paru.conf` (user-level, seeded from `/etc/paru.conf`) with the
same options `~/del/configuring-wm` enabled — all eight verified to still exist in
**paru 2.1.0**, using paru's own descriptions:

| Option | paru's description | Why we want it |
|---|---|---|
| `CleanAfter` | *Remove package sources after install* | **the no-accumulation one** — sources/build dir are deleted after installing |
| `RemoveMake` | *Remove makedepends after install* | drops build-only deps again (pairs with `UseAsk` to do it unattended) |
| `UseAsk` | *Automatically resolve conflicts using pacman's ask flag* | lets the above run without prompts |
| `CombinedUpgrade` | *Refresh then perform the repo and AUR upgrade together* | one transaction, fewer prompts, no partial states |
| `SudoLoop` | *Loop sudo calls in the background to avoid timeout* | type the password once per `-Syu`, not per package |
| `UpgradeMenu` | *Show interactive menu to skip upgrades* | choose what to hold back |
| `NewsOnUpgrade` | *Print new news during sysupgrade* | catch Arch news before an upgrade bites |
| `BottomUp` | (dependency tree order) | matches how we read the tree |

**Deliberately left off:** `KeepRepoCache` (keeps cloned AUR repos — exactly the
accumulation we don't want), `Chroot`, `Sign`, `AurOnly`.

Check them with `paru --help 2>&1 | grep '\[no\]'` — the CLI toggles are spelled
`--[no]<option>`, **not** `--[no-]<option>`.

## pacman.conf

Already set on this machine: `Color` (no `ILoveCandy`), `ParallelDownloads = 5`.
`ILoveCandy` isn't needed — `Color` gives the same output with fewer colours.

## Not set up (and why)

- **reflector / mirror ranking** — was in the old setup's package list but isn't
  installed here. Mirror choice is a network/region question; Arch's
  `mirrorlist` plus `archlinux-keyring-wkd-sync.timer` (which does run) is enough.
- No other new timers: `shadow`, `fstrim`, `systemd-tmpfiles-clean` and
  `archlinux-keyring-wkd-sync` are the distro's and stay untouched.
