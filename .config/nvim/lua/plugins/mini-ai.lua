-- mini.ai configuration (enhanced textobjects)
local ok = pcall(require, 'mini.ai')
if not ok then return end

require('mini.ai').setup({
  -- Custom textobjects (add your own here)
  custom_textobjects = nil,

  -- Module mappings
  mappings = {
    -- Main textobject prefixes (used with operators: d, c, y, v + a/i + char)
    around = 'a',
    inside = 'i',

    -- Next/last variants
    around_next = 'an',
    inside_next = 'in',
    around_last = 'al',
    inside_last = 'il',
  },

  -- Search method: 'cover', 'cover_or_next', 'cover_or_prev'
  search_method = 'cover',

  -- Use treesitter for supported textobjects (requires nvim-treesitter)
  use_treesitter = false,  -- Set to true if you have nvim-treesitter
})
