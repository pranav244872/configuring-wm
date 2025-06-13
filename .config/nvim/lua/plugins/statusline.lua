return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local lazy_status = require("lazy.status")
        local lualine = require("lualine")
        lualine.setup({
            options = {
                icons_enabled = true,
                theme = "cyberdream",
            }
        })
    end
}

