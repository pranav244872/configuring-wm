# Packages and AUR Notes

Bootstrapping paru and the Arch packaging change that breaks the documented path.

Back to [notes index](README.md) - [docs index](../README.md)

## Building paru on current Arch

- **Arch merged the `cargo` package into `rust`.** There is no `cargo` package
  upstream any more: `rust` ships `/usr/bin/cargo` and `/usr/bin/rustc` and
  declares `Provides: cargo` / `Conflicts With: cargo` / `Replaces: cargo`.
  `rust-std` is likewise gone.
- **paru's AUR PKGBUILD is stale about this** (2.1.0-2, last AUR commit
  2025-12-12): it still says `makedepends=('cargo')`, so `makepkg -s` reports
  *"Missing dependencies: cargo"* even though the toolchain is obtainable.
  Fix: install `rust` first, then build with `--nodeps`.
- **`makepkg` cannot install dependencies non-interactively**: it shells out to
  plain `sudo`, which fails with *"a terminal is required to read the password"*
  when there's no TTY. Pre-install the build deps yourself (piping the password
  to `sudo -S`) and `makepkg` won't need sudo at all.
- Verification helpers: `pacman -Si <pkg>` resolves a package, but the repo
  listing is `pacman -Sl extra` in the form `extra NAME VERSION` — *not*
  `extra/name`, so `grep '^extra/cargo'` silently finds nothing. And
  `archlinux.org/packages/search/json/?name=cargo` is the authority for "does
  this package exist upstream at all".

## Pushing to GitHub

The dotfiles repo (`~/del/configuring-wm` → `github.com/pranav244872/configuring-wm`)
is **HTTPS, and this machine had no git credentials at all** until 2026-10-19 —
which is why commits there sat local. Fixed with `extra/github-cli` (`2.102.0-1`):

```bash
gh auth login --hostname github.com --git-protocol https --web --skip-ssh-key
gh auth setup-git --hostname github.com      # plain `git push` now works
```

- The **device-code flow needs no TTY** on our side: `--web` prints a one-time
  code + `https://github.com/login/device` and polls until you approve in a
  browser. Run it with stdin from `/dev/null` and read the code from the log.
- **`ssh` is not installed** (`openssh` isn't installed, there is no `~/.ssh`), so
  an SSH remote is not an option without installing a client *and* registering a
  key. HTTPS + `gh` needs neither.
- `gh auth setup-git` writes `credential.https://github.com.helper =
  !/usr/bin/gh auth git-credential` into the **global** git config; the token
  itself is stored in plain text in `~/.config/gh/hosts.yml` (scopes `gist`,
  `read:org`, `repo`).
- GitHub no longer accepts an account password over HTTPS, so there is no
  "just type your password" fallback: `gh`, a PAT, or SSH.
- Earlier probes all came back negative, worth knowing before hunting again:
  no `credential.helper`, no `~/.git-credentials`, no `~/.netrc`, no
  `GITHUB_TOKEN` in the environment, no `~/.config/gh/`.
- The repo's history contains the **live config** (`.config/…`) plus this docs
  mirror; both are copied in by hand and committed together, so a change is not
  "done" until the copy is made (nothing syncs automatically).
