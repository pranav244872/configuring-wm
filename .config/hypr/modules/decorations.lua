-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Speed-first preset: blur OFF, shadows OFF, fully opaque windows.
-- Chaldea geometry: square windows (no rounding), tight gaps, teal 2px borders.

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 12,

        border_size = 2,

        col = {
            active_border   = colors.primary,
            inactive_border = colors.surface_container_high,
        },

        -- Set to true to enable resizing windows by dragging borders/gaps
        resize_on_border = false,

        -- Games: flip to true only if you want tearing support (see wiki: Tearing)
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 0, -- straight edges to match the shell frames
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false, -- speed: off
        },

        blur = {
            enabled = false, -- speed: off (the official "lowest power" tip)
        },
    },

    animations = {
        enabled = true,
    },
})

-- Curves
hl.curve("linear",     { type = "bezier", points = { {0, 0},     {1, 1}     } })
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1},  {0.32, 1} } })

-- UNITS (verified against installed hyprutils 0.14.2):
--   duration_ms = speed * 100  ->  speed 1 = 100ms, speed 2 = 200ms
--   So LOWER speed = FASTER. Anything not set here inherits "global".
--   Springs (old config) ignore speed: stiffness/damping decide, and they
--   settled in 470-690ms when measured -> slower, so beziers only.
hl.animation({ leaf = "global",     enabled = true, speed = 2,   bezier = "default" })
hl.animation({ leaf = "windows",    enabled = true, speed = 2,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 1.8, bezier = "easeOutQuint", style = "popin 93%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "popin 93%" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 1.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 1.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.2, bezier = "easeOutQuint", style = "fade" }) -- fast ~120ms fade
hl.animation({ leaf = "layers",     enabled = true, speed = 2,   bezier = "easeOutQuint" })
hl.animation({ leaf = "border",     enabled = true, speed = 2,   bezier = "easeOutQuint" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 2,   bezier = "easeOutQuint" })
