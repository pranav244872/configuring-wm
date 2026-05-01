-- mini.pairs configuration (autopairs)
local ok = pcall(require, 'mini.pairs')
if not ok then return end

require('mini.pairs').setup({
  -- Default pairs: (, [, {, ', ", `
  -- Set `cr = true` to enable <CR> inside pair to add blank line
  mappings = {
    ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].', register = { cr = false } },
    [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].', register = { cr = false } },
    ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].', register = { cr = false } },
    [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].', register = { cr = false } },
    ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].', register = { cr = false } },
    ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].', register = { cr = false } },

    ['"'] = { action = 'open', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
    ["'"] = { action = 'open', pair = "''", neigh_pattern = '[^\\].', register = { cr = false } },
    ['`'] = { action = 'open', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
  },
})
