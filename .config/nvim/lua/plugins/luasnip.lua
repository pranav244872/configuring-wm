-- LuaSnip configuration
local ok, luasnip = pcall(require, 'luasnip')
if not ok then return end

luasnip.setup({
  -- Enable autotriggered snippets (snippets that expand without tab)
  enable_autosnippets = true,
  -- Use extbase snippets directory if it exists
  -- This allows you to add custom snippets in ~/.config/nvim/snippets/
})

-- Load VSCode-style snippets (friendly-snippets)
require('luasnip.loaders.from_vscode').lazy_load()

-- Optionally load custom snippets from ~/.config/nvim/snippets/
local custom_snippets_path = vim.fn.stdpath('config') .. '/snippets'
if vim.fn.isdirectory(custom_snippets_path) == 1 then
  require('luasnip.loaders.from_vscode').lazy_load({ paths = { custom_snippets_path } })
end
