require("fzf-lua").setup({
  -- Clean code actions menu configuration
  lsp_code_actions = {
    prompt = '<Code Actions>',
    previewer = "codeaction",  -- Clean built-in previewer
    async_or_timeout = 5000,
  },
  -- fzf-lua nullifies the ambient rg config unless given explicitly,
  -- so point it at our shared ignore rules (__pycache__, venvs, ...)
  RIPGREP_CONFIG_PATH = "~/.config/ripgrep/config",
})

require("fzf-lua").register_ui_select()
