return {
  "romgrk/barbar.nvim",
  dependencies = {
    "lewis6991/gitsigns.nvim",   -- OPTIONAL: for git status
    "nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
  },
  config = function()
    local map = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }
    -- Move to previous/next
    vim.keymap.set("n", "<A-,>", "<Cmd>BufferPrevious<CR>", opts)
    vim.keymap.set("n", "<A-.>", "<Cmd>BufferNext<CR>", opts)
    -- Re-order to previous/next
    vim.keymap.set("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", opts)
    vim.keymap.set("n", "<A-<>", "<Cmd>BufferMoveNext<CR>", opts)
    -- Goto buffer in position
    vim.keymap.set("n", "<A-1>", "<Cmd>BufferGoto 1<CR>", opts)
    vim.keymap.set("n", "<A-2>", "<Cmd>BufferGoto 2<CR>", opts)
    vim.keymap.set("n", "<A-3>", "<Cmd>BufferGoto 3<CR>", opts)
    vim.keymap.set("n", "<A-4>", "<Cmd>BufferGoto 4<CR>", opts)
    -- Close Buffer
    vim.keymap.set("n", "<A-c>", "<Cmd>BufferClose<CR>", opts)
  end,
}
