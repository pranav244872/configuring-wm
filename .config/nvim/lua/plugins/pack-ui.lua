-- ~/.config/nvim/lua/plugins/pack-ui.lua
local M = {}
local api = vim.api

-- Create a namespace for our custom highlight colors
local UI_NS = api.nvim_create_namespace("pack_ui_colors")
local state = { packages = {} }

function M.open()
  -- 1. Create a clean, unlisted scratch buffer
  local buf = api.nvim_create_buf(false, true)
  api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  api.nvim_set_option_value("filetype", "pack-ui", { buf = buf })

  -- 2. Calculate window size (80% of your screen)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  -- 3. Open the floating window (It will inherit your Matugen rounded borders!)
  local win = api.nvim_open_win(buf, true, {
    relative = "editor", width = width, height = height,
    col = col, row = row, style = "minimal", border = "rounded",
    title = " 📦 Native Pack Manager ", title_pos = "center"
  })
  
  -- Turn on the cursorline so it feels like a menu
  api.nvim_set_option_value("cursorline", true, { win = win })

  -- 4. The Render Function (Draws text and colors to the buffer)
  local function render()
    api.nvim_set_option_value("modifiable", true, { buf = buf })
    
    -- Get and sort all packages natively
    state.packages = vim.pack.get()
    table.sort(state.packages, function(a, b) return a.spec.name < b.spec.name end)

    -- Define the header
    local lines = {
      "  Manage your native vim.pack plugins.",
      "  [U] Update All  |  [x] Delete  |  [<CR>] Info  |  [q] Close",
      "",
    }
    local offset = #lines

    -- Build the plugin list
    for _, pkg in ipairs(state.packages) do
      local icon = pkg.active and "🟢" or "🔴"
      table.insert(lines, string.format("  %s  %-30s %s", icon, pkg.spec.name, pkg.spec.src))
    end

    -- Write the lines to the buffer
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Apply Colors (These use standard groups that Matugen already themes)
    api.nvim_buf_clear_namespace(buf, UI_NS, 0, -1)
    api.nvim_buf_add_highlight(buf, UI_NS, "Comment", 0, 0, -1)
    api.nvim_buf_add_highlight(buf, UI_NS, "String", 1, 0, -1)

    for i, pkg in ipairs(state.packages) do
      local line_idx = offset + i - 1
      api.nvim_buf_add_highlight(buf, UI_NS, "Title", line_idx, 6, 36)
      api.nvim_buf_add_highlight(buf, UI_NS, "Comment", line_idx, 36, -1)
    end

    api.nvim_set_option_value("modifiable", false, { buf = buf })
  end

  -- Initial draw
  render()

  -- 5. Set up the local Keymaps
  local function map(key, func, desc)
    vim.keymap.set("n", key, func, { buffer = buf, nowait = true, silent = true, desc = desc })
  end

  -- Quit
  map("q", function() api.nvim_win_close(win, true) end, "Close UI")
  map("<Esc>", function() api.nvim_win_close(win, true) end, "Close UI")

  -- Update All
  map("U", function()
    api.nvim_win_close(win, true)
    vim.pack.update() -- Triggers Neovim's native parallel update window
  end, "Update All")

  -- Delete Plugin under cursor
  map("x", function()
    local cursor = api.nvim_win_get_cursor(win)
    local line_idx = cursor[1]
    local pkg_idx = line_idx - 3 -- Offset by 3 header lines

    if pkg_idx > 0 and pkg_idx <= #state.packages then
      local pkg = state.packages[pkg_idx]
      -- Ask for confirmation
      vim.ui.select({"Yes", "No"}, { prompt = "Delete " .. pkg.spec.name .. "? " }, function(choice)
        if choice == "Yes" then
          vim.pack.del({ pkg.spec.name })
          vim.notify("Deleted: " .. pkg.spec.name, vim.log.levels.INFO)
          render() -- Redraw the UI
        end
      end)
    end
  end, "Delete Plugin")

  -- Show Plugin Info
  map("<CR>", function()
    local cursor = api.nvim_win_get_cursor(win)
    local pkg_idx = cursor[1] - 3
    if pkg_idx > 0 and pkg_idx <= #state.packages then
      local pkg = state.packages[pkg_idx]
      local info = string.format("Name: %s\nURL: %s\nRev: %s\nActive: %s", 
                                 pkg.spec.name, pkg.spec.src, string.sub(pkg.rev or "N/A", 1, 7), tostring(pkg.active))
      vim.notify(info, vim.log.levels.INFO, { title = "📦 " .. pkg.spec.name })
    end
  end, "Show Info")
end

return M
