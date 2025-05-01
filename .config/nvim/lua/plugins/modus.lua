return {
  "miikanissi/modus-themes.nvim",
  priority = 1000, -- Load before other plugins
  config = function()
    -- Choose one of these
    vim.cmd.colorscheme("modus")
  end,
}
