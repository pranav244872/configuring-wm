----------------
----  MISC  ----
----------------

hl.config({
    debug = {
        -- VFR (variable frame rate): only render when something changes.
        -- Official recommendation for battery life; on by default.
        -- Do not turn off unless debugging.
        vfr = true,
    },

    misc = {
        force_default_wallpaper = 0,    -- no anime mascot wallpapers
        disable_hyprland_logo   = true, -- no Hyprland logo on empty workspaces
    },
})
