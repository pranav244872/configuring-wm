-- ~/.config/nvim/lua/plugins/java.lua

-- Java development setup with nvim-java (Neovim 0.12)
local ok = pcall(require, 'java')
if not ok then return end

-- Configure JDTLS to use system Java 21
vim.lsp.config('jdtls', {
  settings = {
    java = {
      configuration = {
        runtimes = {
          {
            name = "JavaSE-21",
            path = "/usr/lib/jvm/java-21-openjdk",
            default = true,
          }
        }
      }
    }
  }
})

-- Setup nvim-java with system JDK (no auto-install)
require('java').setup({ jdk = { auto_install = false } })

-- Enable JDTLS LSP (required for nvim-java to work)
-- Uses new Neovim 0.11+ LSP API instead of deprecated lspconfig
vim.lsp.enable('jdtls')


-- ==============================================================
-- Java Command Palette (Fzf-Lua)
-- ==============================================================
local ok_fzf, fzf = pcall(require, 'fzf-lua')
if ok_fzf then
  local java_commands = {
    -- Workspace & Build
    { cmd = "JavaBuildBuildWorkspace", desc = "Build Workspace (Maven/Gradle)" },
    { cmd = "JavaBuildCleanWorkspace", desc = "Clear Workspace Cache (Restart Neovim to apply)" },

    -- Core Runner
    { cmd = "JavaRunnerRunMain",       desc = "Run Main Class / Application" },
    { cmd = "JavaRunnerStopMain",      desc = "Stop Running Application" },
    { cmd = "JavaRunnerToggleLogs",    desc = "Toggle Runner Log Window" },

    -- Testing
    { cmd = "JavaTestRunCurrentClass",    desc = "Test: Run Current Class" },
    { cmd = "JavaTestDebugCurrentClass",  desc = "Test: Debug Current Class" },
    { cmd = "JavaTestRunCurrentMethod",   desc = "Test: Run Method Under Cursor" },
    { cmd = "JavaTestDebugCurrentMethod", desc = "Test: Debug Method Under Cursor" },
    { cmd = "JavaTestRunAllTests",        desc = "Test: Run All Workspace Tests" },
    { cmd = "JavaTestDebugAllTests",      desc = "Test: Debug All Workspace Tests" },
    { cmd = "JavaTestViewLastReport",     desc = "Test: View Last Report Popup" },

    -- Refactoring
    { cmd = "JavaRefactorExtractVariable",              desc = "Refactor: Extract Variable" },
    { cmd = "JavaRefactorExtractVariableAllOccurrence", desc = "Refactor: Extract Variable (All Occurrences)" },
    { cmd = "JavaRefactorExtractConstant",              desc = "Refactor: Extract Constant" },
    { cmd = "JavaRefactorExtractMethod",                desc = "Refactor: Extract Method" },
    { cmd = "JavaRefactorExtractField",                 desc = "Refactor: Extract Field" },

    -- DAP & Config
    { cmd = "JavaDapConfig",             desc = "Force Reconfigure DAP" },
    { cmd = "JavaProfile",               desc = "Open Profiles Management UI" },
    { cmd = "JavaSettingsChangeRuntime", desc = "Change Active JDK Runtime" },
  }

  local function show_java_commands()
    local items = {}
    for _, item in ipairs(java_commands) do
      -- Format nicely: Pad the command to 45 characters so descriptions align
      table.insert(items, string.format("%-45s %s", item.cmd, item.desc))
    end

    fzf.fzf_exec(items, {
      prompt = "Java > ",
      winopts = {
        width = 0.8,
        height = 0.6,
        title = " Java Command Palette ",
        title_pos = "center"
      },
      actions = {
        ["default"] = function(selected)
          if not selected or #selected == 0 then return end
          -- Extract just the command part (everything before the first space)
          local cmd = selected[1]:match("^(%S+)")
          if cmd then
             vim.cmd(cmd)
          end
        end
      }
    })
  end

  -- Expose function for keymaps.lua (do not set keymap here)
  _G.JavaShowCommands = show_java_commands
end
