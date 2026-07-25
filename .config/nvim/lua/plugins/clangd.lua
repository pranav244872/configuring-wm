vim.lsp.config('clangd', {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = { '.clangd', 'compile_commands.json', 'compile_flags.txt', '.git' },
  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      },
    },
  },
})
vim.lsp.enable('clangd')
