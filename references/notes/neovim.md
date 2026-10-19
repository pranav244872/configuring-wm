# Neovim Notes

How the editor is installed and bootstrapped, and the traps in its config
(deployed verbatim from `~/del/configuring-wm/.config/nvim`).

Back to [notes index](README.md) - [docs index](../README.md)

## What runs it

`neovim 0.12.6` (official `extra`) — the **0.12** part matters: the config is
built on `vim.pack` and `vim.lsp.config`/`vim.lsp.enable`, none of which exist
in 0.11.

Four packages it needs, all `extra`:

| Package | Why |
|---|---|
| `fzf` | `fzf-lua`'s picker binary (> 0.36); every finder keymap goes through it |
| `tree-sitter-cli` | `nvim-treesitter` **main** requires the CLI >= 0.26.1 (**not** the npm one) |
| `unzip` | mason unpacks `.zip` releases (clangd is a `.zip`, lua-language-server a `.tar.gz`) |
| `fd` | the config passes explicit `fd_opts`; without `fd` fzf-lua silently falls back to rg/find |

Already present, so nothing to install: `ripgrep`, `gcc` + `make`, `git`,
`curl`, `tar`, `gzip`, `python3`, `nodejs`, `wl-clipboard`,
`ttf-jetbrains-mono-nerd`.

## Bootstrapping it headless (fresh machine)

```bash
# 1. plugins — vim.pack.add() installs the declared set on first start
nvim --headless "+qa"
# 2. LSP servers (lua_ls, clangd, pyrefly) — the Sync variant blocks until done
nvim --headless -c "MasonToolsInstallSync" -c "qa"
# 3. treesitter parsers (compiled here, not downloaded prebuilt)
nvim --headless -c "lua require('nvim-treesitter').install({'c','cpp','markdown','markdown_inline'}):wait(600000)" -c "qa"
```

Expect **26 plugin clones + 3 mason downloads + 4 parser compiles**, all under
`~/.local/share/nvim`. On this spinning disk that is minutes, so run it with
neovim headless rather than on first interactive open.

## Traps

- **`vim.pack` installs the lockfile's set, but only `vim.pack.add` puts a
  plugin on the runtimepath.** `nvim-pack-lock.json` lists 26 plugins and the
  config's `vim.pack.add` declares 24; the two extras (`focus.nvim`,
  `mini.pairs`) are installed into `site/pack/core/opt/` yet never
  `packadd`ed, so `require("mini.pairs")` fails and
  `lua/plugins/mini-pairs.lua`'s `pcall` guard skips it silently — verified
  2026-10-19 (`module 'mini.pairs' not found`). Practical impact is nil
  (`autoclose.nvim` is declared and does the same job: typing `(` gives `()`,
  verified live), but that file is dead code until its URL is added to
  `vim.pack.add`.
- **A `pcall(require, …)` guard hides a missing plugin instead of erroring** —
  mini-pairs, mini-ai, blink and luasnip all use one. When something feels off,
  check the plugin list; startup being quiet proves nothing.
- **`nvim-treesitter` `main` is a different API from the frozen `master`.**
  `master` is `require('nvim-treesitter.configs')` + `:TSInstall`; `main` is
  `require('nvim-treesitter').install()` + `vim.treesitter.start()`, wants
  Neovim 0.12 and `tree-sitter` on PATH, and **compiles** each parser (so it
  needs a C compiler, and there is no prebuilt download to fail quietly).
  Parsers land in `~/.local/share/nvim/site/parser/*.so`.
- **mason's pypi packages need no `python-pip`.** mason builds its own venv —
  `pyrefly` is `pkg:pypi/pyrefly@1.4.0` — and Arch's `python` with `ensurepip`
  is enough. `clangd` and `lua-language-server` are prebuilt GitHub releases.
- **`matugen` the binary is not installed and not needed.** The config watches
  a *committed* JSON (`~/.config/nvim/matugen-colors.json`), and
  `daedlock/matugen.nvim` ships `colors/matugen.lua`, so the config's
  `vim.cmd.colorscheme("matugen")` is the plugin's own documented usage — do
  **not** "fix" it to `require("matugen").load()`. Install `extra/matugen` only
  if colours should track the wallpaper.
- `matugen.lua` at the config root (a generated base16 colorscheme requiring
  `base16-colorscheme`, which is in no pack list) is required from nowhere —
  dead file, deliberately left as-is.

## Verifying it (never trust startup silence)

```bash
# 1. every module the config requires, and whether it really loads
nvim --headless -c 'lua for _,m in ipairs({"mini.pairs","fzf-lua","mason","blink.cmp","oil","lualine","markview","nvim-treesitter"}) do local ok,err=pcall(require,m) print(m,ok,err) end' -c qa
# 2. an LSP client actually attaches (clangd on a .c buffer, lua_ls on .lua)
nvim --headless a.c -c 'lua vim.wait(20000, function() return #vim.lsp.get_clients({bufnr=0})>0 end)' -c 'lua print(vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({bufnr=0}))))' -c qa
```

For the UI, `--remote-send` drives a *running* neovim over its own socket, no
uinput needed:

```bash
kitty -e nvim --listen /tmp/opencode/nvim.sock file.c
nvim --server /tmp/opencode/nvim.sock --remote-send '<Space>ff'   # leader ff
grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" shot.png
```

That is how 2026-10-19 was verified end to end: treesitter highlighting and
lualine themed live, `<leader>ff` rendering fzf with a treesitter-highlighted
preview pane, `(` auto-closing, and `clangd`/`lua_ls` attaching.
