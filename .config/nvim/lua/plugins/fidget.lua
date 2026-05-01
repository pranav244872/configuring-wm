require("fidget").setup({
  progress = {
    display = {
      progress_icon = { "dots" },
      done_icon = "✔",
      done_style = "Constant",
      progress_style = "WarningMsg",
      group_style = "Title",
    },
  },
  notification = {
    window = {
      border = "rounded",  -- Rounded border for notification window
      winblend = 0,           -- No transparency (set to 100 for fully transparent)
      align = "bottom",        -- Show at bottom of screen
      normal_hl = "NormalFloat",
    },
  },
})
