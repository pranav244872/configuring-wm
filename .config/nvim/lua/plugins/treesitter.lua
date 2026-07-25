require('nvim-treesitter').setup({})

require('nvim-treesitter').install({ 'c', 'cpp' })

local ts_filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' }
vim.api.nvim_create_autocmd('FileType', {
  pattern = ts_filetypes,
  callback = function()
    vim.treesitter.start()
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo.foldlevel = 99
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

vim.opt.viewoptions:append('folds')
vim.api.nvim_create_autocmd('BufWinLeave', {
  callback = function()
    if vim.fn.expand('%') ~= '' then
      vim.cmd('silent! mkview')
    end
  end,
})
vim.api.nvim_create_autocmd('BufWinEnter', {
  callback = function()
    if vim.fn.expand('%') ~= '' then
      pcall(vim.cmd, 'silent! loadview')
    end
  end,
})
