local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local ok, clone_status = pcall(vim.fn.system, {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.runtimepath:prepend(lazypath)
require("vim-options")
require("lazy").setup("plugins")
local opts = {}
