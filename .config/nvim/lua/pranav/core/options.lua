local opt = vim.opt

opt.relativenumber = true
opt.number = true

--tabs & identation
opt.tabstop = 2       --2 spaces for tabs
opt.shiftwidth = 2    --2 spaces for indent width
opt.expandtab = true  --expand tab to spaces
opt.autoindent = true --copy indent from current line when starting new one

--search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true  -- if you include mixed case in your search, assumes you want case-sensitive

--setting colors
--opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

--clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

--split windows
opt.splitright = true
opt.splitbelow = true
