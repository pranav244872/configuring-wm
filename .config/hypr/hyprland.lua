-- ~/.config/hypr/hyprland.lua
-- Entry point of the Hyprland config (Lua).
-- Split into modules/ the same way the old configuring-wm repo did.
--
-- Main file is intentionally tiny: colours + require() list only.
-- Order: colours first (used by modules.decorations), then the rest.

-- Shared colour palette (Material/teal) used by modules.decorations
colors = require("modules.colors")

require("modules.monitors")
require("modules.keybinds")
require("modules.autostart")
require("modules.env")
require("modules.decorations")
require("modules.windowrules")
require("modules.layouts")
require("modules.misc")
require("modules.input")
