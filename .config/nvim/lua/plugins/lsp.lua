return {
    'neovim/nvim-lspconfig',
    dependencies = {
        -- LSP package management
        { 'williamboman/mason.nvim', opts = {} },
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',

        -- LSP status UI
        { 'j-hui/fidget.nvim', opts = {} },

        -- Enhanced LSP capabilities
        'saghen/blink.cmp',
    },
    config = function()
        -- LSP attach keymaps and autocommands
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
            callback = function(event)
                local map = function(keys, func, desc, mode)
                    mode = mode or 'n'
                    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
                end

                -- Navigation
                map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
                map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
                map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
                map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
                map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

                -- Workspace
                map('gO', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')
                map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')
                map('gfd', require('telescope.builtin').diagnostics, '[F]ind [D]iagnostics')

                -- Actions
                map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
                map('gca', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

                -- Toggle inlay hints if supported
                local client = vim.lsp.get_client_by_id(event.data.client_id)
                if client and client.supports_method('textDocument/inlayHint') then
                    map('<leader>th', function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
                    end, '[T]oggle Inlay [H]ints')
                end
            end,
        })

        -- Diagnostic configuration
        vim.diagnostic.config {
            severity_sort = true,
            float = { border = 'rounded', source = 'if_many' },
            underline = { severity = vim.diagnostic.severity.ERROR },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '󰅚',
                    [vim.diagnostic.severity.WARN] = '󰀪',
                    [vim.diagnostic.severity.INFO] = '󰋽',
                    [vim.diagnostic.severity.HINT] = '󰌶',
                },
            },
            virtual_text = {
                source = 'if_many',
                spacing = 2,
            },
        }

        -- Enhanced capabilities from blink.cmp
        local original_capabilities = vim.lsp.protocol.make_client_capabilities()
        local capabilities = require('blink.cmp').get_lsp_capabilities(original_capabilities)

        -- Language server configurations
        local servers = {
            lua_ls = {},
        }

        -- Mason tool installer setup
        require('mason-tool-installer').setup {
            ensure_installed = vim.tbl_keys(servers or {}),
        }

        -- Setup LSP servers
        require('mason-lspconfig').setup {
            handlers = {
                function(server_name)
                    local server = servers[server_name] or {}
                    server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
                    require('lspconfig')[server_name].setup(server)
                end,
            },
        }
    end,
}
