require("fzf-lua").setup({
  -- Clean code actions menu configuration
  lsp_code_actions = {
    prompt = '<Code Actions>',
    previewer = "codeaction",
    async_or_timeout = 5000,
  },
  -- fzf-lua nullifies the ambient rg config unless given explicitly,
  -- so point it at our shared ignore rules (__pycache__, venvs, ...)
  RIPGREP_CONFIG_PATH = "~/.config/ripgrep/config",
  -- Files picker: show hidden files (.env) but exclude venvs/__pycache__
  -- Per fzf-lua/docs + defaults.lua:528-535 hidden=true auto-adds --hidden via toggle_hidden_flag
  files = {
    hidden = true,
    -- Respect .gitignore by default (toggle with <A-i>), show hidden with <A-h>
    -- Permanent excludes mirror oil.nvim's is_always_hidden
    fd_opts = [[--color=never --type f --type l --exclude .git --exclude .jj --exclude .venv --exclude venv --exclude env --exclude __pycache__ --exclude .pytest_cache --exclude .mypy_cache --exclude .ruff_cache --exclude node_modules]],
    rg_opts = [[--color=never --files -g "!.git" -g "!.jj" -g "!.venv" -g "!venv" -g "!env" -g "!__pycache__" -g "!.pytest_cache" -g "!.mypy_cache" -g "!.ruff_cache" -g "!node_modules"]],
    find_opts = [[-type f \! -path '*/.git/*' \! -path '*/.jj/*' \! -path '*/.venv/*' \! -path '*/venv/*' \! -path '*/env/*' \! -path '*/__pycache__/*' \! -path '*/.pytest_cache/*' \! -path '*/.mypy_cache/*' \! -path '*/.ruff_cache/*' \! -path '*/node_modules/*']],
    -- fallback filtering for any provider (fd/rg/find): never return these paths
    file_ignore_patterns = { "%.venv/", "venv/", "env/", "__pycache__/", "%.pytest_cache/", "%.mypy_cache/", "%.ruff_cache/", "node_modules/" },
  },
  -- Grep / live_grep: also include hidden files so .env is searchable,
  -- but keep RIPGREP_CONFIG_PATH excludes for venvs/__pycache__
  grep = {
    hidden = true,
  },
  live_grep = {
    hidden = true,
  },
})

require("fzf-lua").register_ui_select()
