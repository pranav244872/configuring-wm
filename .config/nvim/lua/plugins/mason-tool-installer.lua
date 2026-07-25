require('mason-tool-installer').setup({
  ensure_installed = {
    'lua_ls',
    'clangd',
  },
  run_on_start = true,
  start_delay = 3000,
})
