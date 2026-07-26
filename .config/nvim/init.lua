vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Pack declarations
vim.pack.add({
    'https://github.com/stevearc/oil.nvim',
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/daedlock/matugen.nvim',
    'https://github.com/ibhagwan/fzf-lua',
    'https://github.com/nmac427/guess-indent.nvim',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
    'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
    'https://github.com/j-hui/fidget.nvim',
    'https://github.com/saghen/blink.lib',
    'https://github.com/saghen/blink.cmp',
    'https://github.com/L3MON4D3/LuaSnip',
    'https://github.com/rafamadriz/friendly-snippets',
    -- Autopairs 
    'https://github.com/nvim-mini/mini.pairs',
    -- Enhanced textobjects (a/i)
    'https://github.com/nvim-mini/mini.ai',
    -- Treesitter parser management + queries
    'https://github.com/nvim-treesitter/nvim-treesitter',
    -- Smart paste with correct indentation
    'https://github.com/nemanjamalesija/smart-paste.nvim',
    -- Floating UI for vim.pack
    'https://github.com/jtprogru/pack-ui.nvim',
    -- Pretty LSP hover documentation
    'https://github.com/Fildo7525/pretty_hover',
})

-- Plugin setups (auto-require all plugins in lua/plugins/)
local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"
local plugin_files = vim.fn.glob(plugins_dir .. "/*.lua", true, true)

for _, plugin_file in ipairs(plugin_files) do
  local plugin_name = vim.fn.fnamemodify(plugin_file, ":t:r")
  -- Skip non-plugin files if needed
  require("plugins." .. plugin_name)
end
