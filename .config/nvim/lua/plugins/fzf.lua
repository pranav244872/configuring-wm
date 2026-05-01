require("fzf-lua").setup({
  -- Clean code actions menu configuration
  lsp_code_actions = {
    prompt = '<Code Actions>',
    previewer = "codeaction",  -- Clean built-in previewer
    async_or_timeout = 5000,
  },
})
