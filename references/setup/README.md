# Setup Steps

The rebuild path, in order. Each step lists only explicit `pacman -S`
arguments; transitive dependencies are pacman's business.

Back to [docs index](../README.md)

| # | Step | File | Status |
|---|---|---|---|
| 1 | Minimal bare install | [01-minimal-bare-install.md](01-minimal-bare-install.md) | ✅ done (2026-10-15) |
| 2 | Runtime packages | [02-runtime-packages.md](02-runtime-packages.md) | ✅ done |
| 3 | Fork build dependencies | [03-fork-build-deps.md](03-fork-build-deps.md) | ✅ done |
| 4 | Hyprland fork build (source) | [04-hyprland-fork-build.md](04-hyprland-fork-build.md) | ✅ done (2026-10-15) |
| 5 | Hyprland config (speed-first, modular) | [05-hyprland-config.md](05-hyprland-config.md) | ✅ done (2026-10-15) |
| 6 | Rice layer | [06-rice.md](06-rice.md) | ⬜ planned |

Package installs that happen *later* (icon font, cache tooling, AUR helper)
live in [package-management.md](../package-management.md).

Status legend: ✅ done · 🔄 in progress · ⬜ planned · ⏸ deferred
