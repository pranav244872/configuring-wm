require("oil").setup({
    keymaps = {
        ["<Esc>"] = "actions.close",
    },
    float = {
        border = "rounded",
    },
    view_options = {
        -- Show hidden files (dotfiles like .env) by default
        show_hidden = true,
        -- What is considered a hidden file (default: dotfiles)
        is_hidden_file = function(name, bufnr)
            return vim.startswith(name, ".")
        end,
        -- Show everything - including __pycache__, node_modules, .venv
        -- Nothing is always hidden
        is_always_hidden = function(name, bufnr)
            return false
        end,
    },
})
