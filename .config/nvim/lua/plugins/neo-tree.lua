return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local neotree_open_left = false -- Flag to track open/closed state

    vim.keymap.set("n", "<C-n>", function()
      if neotree_open_left then
        -- Close NeoTree if it's open
        vim.api.nvim_command(":Neotree close")
        neotree_open_left = false
      else
        -- Open NeoTree towards the left
        vim.api.nvim_command(":Neotree filesystem reveal left")
        neotree_open_left = true
      end
    end, {})

    -- Optional: Change the leader key behavior if needed
    vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", {})
  end,
}
