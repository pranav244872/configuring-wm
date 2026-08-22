local mason_bin = vim.fn.stdpath('data') .. '/mason/bin/pyrefly'

vim.lsp.config('pyrefly', {
    cmd = (vim.fn.executable(mason_bin) == 1) and { mason_bin, 'lsp' } or nil,
})

-- Defaults (root_markers incl. pyrefly.toml) come from nvim-lspconfig's lsp/pyrefly.lua
vim.lsp.enable('pyrefly')
