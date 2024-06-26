--- Uncomment the two plugins below if you want to manage the language servers from neovim

return {
  { 'VonHeikemen/lsp-zero.nvim', branch = 'v3.x' },
  { 'williamboman/mason.nvim' },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", -- source for text in buffer
      "hrsh7th/cmp-path",   -- source for file system paths
      {
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        build = "make install_jsregexp",
      },
      "saadparwaiz1/cmp_luasnip",     -- for autocompletion
      "rafamadriz/friendly-snippets", -- useful snippets
      "onsails/lspkind.nvim",         -- vs-code like pictograms
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
      require("luasnip.loaders.from_vscode").lazy_load()


      cmp.setup({
        preselect = 'item',
        completion = {
          completeopt = "menu,menuone,preview,noselect",
        },
        snippet = { -- configure how nvim-cmp interacts with snippet engine
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
          ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
          ["<C-e>"] = cmp.mapping.abort(),        -- close completion window
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
        }),
        -- sources for autocompletion
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" }, -- snippets
          { name = "buffer" },  -- text within current buffer
          { name = "path" },    -- file system paths
        },

        -- configure lspkind for vs-code like pictograms in completion menu
        formatting = {
          format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', "BufNewFile" },
    dependencies = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'williamboman/mason-lspconfig.nvim' },
    },
    config = function()
      --This is where all the LSP stuff will live
      local lsp_zero = require('lsp-zero')
      lsp_zero.extend_lspconfig()

      lsp_zero.on_attach(function(client, bufnr)
        lsp_zero.default_keymaps({ buffer = bufnr })
      end)

      -- Symbols for warning if something wrong
      lsp_zero.set_sign_icons({
        error = '✘',
        warn = '▲',
        hint = '⚑',
        info = '»'
      })
      -- Enabling format on save
      lsp_zero.format_on_save({
        format_opts = {
          async = false,
          timeout_ms = 10000,
        },
        -- Mention language servers to use for languages to format
        servers = {
          ['tsserver'] = { 'javascript', 'typescript' },
          ['bashls'] = { 'bash' },
          ['biome'] = { 'json' },
          ['clangd'] = { 'c', 'c++' },
          ['lua_ls'] = { 'lua' },
          ['html'] = { 'html', 'ejs' },

          ['jedi_language_server'] = { 'python' },
          ['cssls'] = { 'css' },
        }
      })

      require('mason').setup({})
      require('mason-lspconfig').setup({

        -- Check here to get all the language servers https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers
        ensure_installed = { 'bashls', 'clangd', 'cssls', 'html', 'biome', 'tsserver', 'lua_ls', 'jedi_language_server' },
        handlers = {
          lsp_zero.default_setup,
        },
      })
    end
  }
}
