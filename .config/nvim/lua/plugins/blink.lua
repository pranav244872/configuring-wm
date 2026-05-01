-- Configure blink.cmp for autocompletion (only if available)
local ok, cmp = pcall(require, 'blink.cmp')
if not ok then
  -- blink.cmp not yet installed, skip setup
  return
end

-- Skip build if using Lua implementation (no cargo needed)
-- cmp.build():wait(60000)  -- Only needed for Rust fuzzy matcher

cmp.setup({
  -- Key mappings (default: C-y to accept, C-space for docs, etc.)
  -- Default preset includes:
  --   C-n: select_next, C-p: select_prev, C-y: select_and_accept
  --   C-k: show/hide signature, C-b/C-f: scroll documentation
  keymap = { preset = 'default' },

  -- Enable signature help (experimental, opt-in)
  signature = { enabled = true },

  -- Completion sources
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' }
  },

  -- Fuzzy matching (lua = pure Lua, no Rust/cargo needed)
  fuzzy = { implementation = 'lua' },

  -- Completion menu appearance with source info
  completion = {
    menu = {
      border = 'rounded',
      -- Custom columns: show source name (LSP, Path, Buffer, Snippet) + kind icon + label
      draw = {
        columns = {
          { 'kind_icon' },           -- Column 1: Kind icon (function, variable, etc.)
          { 'label', 'label_description', gap = 1 },  -- Column 2: Completion text
          { 'source_name' },          -- Column 3: Source name (lsp, path, buffer, snippets)
        },
        components = {
          -- Custom source_name component: show source with brackets
          source_name = {
            text = function(ctx)
              local source = ctx.source_name or ""
              return "[" .. source .. "]"
            end,
            highlight = 'Comment',  -- Dim the source name
          },
          -- Keep kind_icon as-is
          kind_icon = {
            text = function(ctx) return ctx.kind_icon or "" end,
            highlight = function(ctx) return ctx.kind_hl or "Normal" end,
          },
        },
      },
    },
    documentation = { auto_show = true, auto_show_delay_ms = 500 },
  },

  -- Snippet support (LuaSnip as primary, with friendly-snippets collection)
  snippets = { preset = 'luasnip' },
})
