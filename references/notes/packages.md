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
