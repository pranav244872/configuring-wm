--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Ignore maximize requests from all apps.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Inhibit idle/sleep while any window is fullscreen (videos, games, ...)
hl.window_rule({
    name  = "idle-inhibit-fullscreen",
    match = { class = ".*" },

    idle_inhibit = "fullscreen",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

------------------------------------------
---- SCREENSHARE HIDING (fork feature) ----
------------------------------------------

-- This fork's feature: any window or layer with no_screen_share = true is
-- skipped while the screen is being captured (Discord / Zoom / OBS shares).
-- Copy either rule and change the match to hide anything else:
--   window rules match on class/title, layer rules match on namespace.

hl.layer_rule({
    name  = "cheatsheet-layer-noscreenshare",
    match = { namespace = "cheatsheet" },

    no_screen_share = true,
})

hl.window_rule({
    name  = "cheatsheet-window-noscreenshare",
    match = { class = "cheatsheet" },

    no_screen_share = true,
})
