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
    override_vim_notify = true,
    window = {
      border = "rounded",
      winblend = 0,
      align = "bottom",
      normal_hl = "NormalFloat",
    },
  },
})
