require("tiny-inline-diagnostic").setup({
  preset = "minimal",
  transparent_bg = true,
})

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  float = { border = 'rounded', source = 'if_many' },
})