-- Helper to make keymap definitions cleaner
local map = vim.keymap.set

-- ==============================================================
-- Oil Keymaps
-- ==============================================================

-- <leader>rd: Open Oil in a floating window at the Root Directory (Current Working Directory)
map("n", "<leader>rd", function()
    require("oil").open_float(vim.fn.getcwd())
end, { desc = "Open Oil (Float) in Root Directory" })

-- <leader>cw: Open Oil in a floating window at the Current Directory of the active file
map("n", "<leader>cw", function()
    -- vim.fn.expand("%:p:h") gets the full path (%) to the current file, and extracts the head/directory (h)
    require("oil").open_float(vim.fn.expand("%:p:h"))
end, { desc = "Open Oil (Float) in Current File Directory" })

-- ==============================================================
-- Fzf-Lua Keymaps
-- ==============================================================

-- <leader>ff: Find Files. Searches for file names in your root directory.
map("n", "<leader>ff", function()
    require("fzf-lua").files()
end, { desc = "Fuzzy find files in root" })

-- <leader>fg: Find Grep. Live text search throughout your entire project.
map("n", "<leader>fg", function()
    require("fzf-lua").live_grep()
end, { desc = "Fuzzy find text (live grep)" })

-- <leader>fb: Find Buffers. Quickly switch between files you already have open.
map("n", "<leader>fb", function()
    require("fzf-lua").buffers()
end, { desc = "Fuzzy find open buffers" })

-- <leader>fh: Find Help. Searches through Neovim's documentation.
map("n", "<leader>fh", function()
    require("fzf-lua").help_tags()
end, { desc = "Fuzzy find help tags" })

-- <leader>fk: Find Keymaps. Search through all Neovim keybindings.
map("n", "<leader>fk", function()
    require("fzf-lua").keymaps()
end, { desc = "Search keymaps" })

-- <leader>en: Find files in Neovim config directory (~/.config/nvim)
map("n", "<leader>en", function()
    require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find files in [N]eovim [C]onfig" })

-- ==============================================================
-- Native Package Manager Dashboard
-- ==============================================================
-- <leader>p: Open the custom package manager UI
map("n", "<leader>p", function()
    require("pack_ui").update()
end, { desc = "Open [P]ackage Manager UI" })



-- ==============================================================
-- Fold Keymaps
-- ==============================================================
map("n", "<leader>zj", "zj", { desc = "Next [F]old" })
map("n", "<leader>zk", "zk", { desc = "Previous [F]old" })
map("n", "<leader>za", "za", { desc = "Toggle [F]old" })
map("n", "<leader>zA", "zA", { desc = "Toggle [F]old Recursive" })
map("n", "<leader>zR", "zR", { desc = "Open All [F]olds" })
map("n", "<leader>zM", "zM", { desc = "Close All [F]olds" })

-- Search folds via fzf-lua (lists all fold regions in the buffer)
map("n", "<leader>zf", function()
  local folds = {}
  local i = 1
  while true do
    local ok, lnum = pcall(vim.fn.foldclosed, i)
    if not ok then break end
    if lnum ~= -1 then
      local end_lnum = vim.fn.foldclosedend(i)
      local text = vim.fn.getline(lnum)
      table.insert(folds, { lnum = lnum, end_lnum = end_lnum, text = text })
      i = end_lnum + 1
    else
      i = i + 1
    end
    if i > vim.fn.line('$') then break end
  end
  if #folds == 0 then
    vim.notify("No folds in buffer", vim.log.levels.INFO)
    return
  end
  local items = vim.tbl_map(function(f)
    return string.format("%4d │ %s", f.lnum, f.text)
  end, folds)
  require("fzf-lua").fzf_exec(items, {
    prompt = "Folds > ",
    actions = {
      ["default"] = function(selected)
        if not selected or #selected == 0 then return end
        local lnum = tonumber(selected[1]:match("%s*(%d+)"))
        if lnum then
          vim.api.nvim_win_set_cursor(0, { lnum, 0 })
          vim.cmd.normal({ "zxzv", bang = true })
        end
      end,
    },
  })
end, { desc = "[F]ind [F]olds (fzf)" })

-- ==============================================================
-- Diagnostics Keymaps
-- ==============================================================
-- gl: Show full diagnostic in floating window (for copy-paste)
map("n", "gl", function()
    vim.diagnostic.open_float({ focus = true })
end, { desc = "Show full diagnostic in float (focused)" })

-- <leader>q: Open diagnostic quickfix list
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- ==============================================================
-- Split Management (smart-splits.nvim)
-- ==============================================================

-- Move between splits; creates new split when at edge
map('n', '<C-h>', require('smart-splits').move_cursor_left, { desc = 'Split: move left / create left' })
map('n', '<C-j>', require('smart-splits').move_cursor_down, { desc = 'Split: move down / create down' })
map('n', '<C-k>', require('smart-splits').move_cursor_up, { desc = 'Split: move up / create up' })
map('n', '<C-l>', require('smart-splits').move_cursor_right, { desc = 'Split: move right / create right' })

-- Resize splits
map('n', '<A-h>', require('smart-splits').resize_left, { desc = 'Split: resize left' })
map('n', '<A-j>', require('smart-splits').resize_down, { desc = 'Split: resize down' })
map('n', '<A-k>', require('smart-splits').resize_up, { desc = 'Split: resize up' })
map('n', '<A-l>', require('smart-splits').resize_right, { desc = 'Split: resize right' })

-- ==============================================================
-- mini.ai Textobjects
-- ==============================================================
-- mini.ai enhances a/i textobjects. Type a/i + character to select.
-- Examples: a( = around parentheses, i" = inside quotes, af = around function
-- a+char: around textobject (a(, a", a{, af, aa=argument, at=tag)
-- i+char: inside textobject (i(, i", i{, if, ia, it)
-- an+char: around next, in+char: inside next
-- al+char: around last, il+char: inside last
-- g[: move to left edge, g]: move to right edge

-- ==============================================================
-- LSP Keymaps (set on LspAttach)
-- ==============================================================
-- These keybindings are set when a language server attaches to the buffer.
-- They allow you to navigate code, rename variables, and access LSP features.

--[[
LSP Keybindings Explanation:

  Inlay Hints:
    Small, greyed-out text hints shown inline in your code.
    Examples: parameter names ("name:" before argument), type annotations (": string"),
    or chaining hints. Toggle with <leader>th.

  Document Symbols:
    Fuzzy-searchable list of all symbols (functions, variables, classes) in the CURRENT file.
    Useful for quick navigation within a file. Access with gO.

  Workspace Symbols:
    Fuzzy-searchable list of all symbols across your ENTIRE project/workspace.
    Useful for jumping to definitions in other files. Access with gW.

  References:
    Find all places where a symbol (function, variable, etc.) is used. Access with grr.

  Implementation:
    Jump to the implementation of an interface or abstract type. Access with gri.

  Definition vs Declaration:
    - Definition (grd): Where a function/variable is defined (where it gets its value).
    - Declaration (grD): Where something is declared (e.g., in C headers, header files).
--]]

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    -- Helper to set buffer-local keymaps with descriptions
    local bufmap = function(mode, keys, func, desc)
      vim.keymap.set(mode, keys, func, { buffer = buf, desc = 'LSP: ' .. desc })
    end

    -- grn: [R]e[n]ame variable under cursor (refactors across files if supported)
    bufmap('n', 'grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- <leader>ca: Code [A]ction (quick fixes, refactors; works in normal & visual mode)
    -- Uses fzf-lua for a clean, fuzzy-searchable code actions menu
    bufmap({ 'n', 'x' }, '<leader>ca', function()
      require('fzf-lua').lsp_code_actions()
    end, 'Code [A]ction (fzf)')

    -- grD: [G]oto [D]eclaration (where something is declared, e.g., C headers)
    bufmap('n', 'grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- grr: [G]oto [R]eferences (find all usages of the symbol under cursor)
    bufmap('n', 'grr', require('fzf-lua').lsp_references, '[G]oto [R]eferences')

    -- gri: [G]oto [I]mplementation (jump to implementation of interfaces/abstract types)
    bufmap('n', 'gri', require('fzf-lua').lsp_implementations, '[G]oto [I]mplementation')

    -- grd: [G]oto [D]efinition (where function/variable is defined; press <C-t> to jump back)
    bufmap('n', 'grd', require('fzf-lua').lsp_definitions, '[G]oto [D]efinition')

    -- gO: Open Document Symbols (fuzzy find functions, variables in current file)
    bufmap('n', 'gO', require('fzf-lua').lsp_document_symbols, 'Open Document Symbols')

    -- gW: Open Workspace Symbols (fuzzy find symbols across entire project)
    bufmap('n', 'gW', require('fzf-lua').lsp_workspace_symbols, 'Open Workspace Symbols')

    -- grt: [G]oto [T]ype Definition (jump to the type, not the variable definition)
    bufmap('n', 'grt', require('fzf-lua').lsp_typedefs, '[G]oto [T]ype Definition')

    -- K: Show pretty hover documentation
    bufmap('n', 'K', function()
      require("pretty_hover").hover()
    end, 'Hover Documentation')

    -- <leader>th: [T]oggle Inlay [H]ints (show/hide inline type and parameter hints)
    bufmap('n', '<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = buf })
    end, '[T]oggle Inlay [H]ints')

    -- C/C++: Switch between source/header file
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == 'clangd' then
      bufmap('n', '<leader>h', function()
        client:request('textDocument/switchSourceHeader', vim.lsp.util.make_text_document_params(buf), function(err, result)
          if err then return end
          if result then vim.cmd.edit(vim.uri_to_fname(result)) end
        end)
      end, 'Toggle Source/Header')
    end
  end,
})
