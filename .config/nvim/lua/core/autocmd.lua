-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Disable automatic comment continuation on new lines
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})


-- Remove underscore from 'iskeyword' to treat it as a word boundary
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt_local.iskeyword:remove("_")
    end,
})

local autocmd = vim.api.nvim_create_autocmd

-- Remove padding when entering Neovim
autocmd("VimEnter", {
  callback = function()
    vim.fn.jobstart({ "kitty", "@", "set-spacing", "padding=0", "margin=0" })
  end,
})

-- Restore padding when leaving Neovim
autocmd("VimLeavePre", {
  callback = function()
    vim.fn.jobstart({ "kitty", "@", "set-spacing", "padding=20", "margin=10" })
  end,
})
