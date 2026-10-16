-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Reference: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Cursors
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")

-- XDG session (needed for portals when starting from a bare TTY)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

-- Deliberately dropped from the old config:
--   HYPRLAND_TRACE=1     -> debug logging, costs performance
--   QT_QPA_PLATFORMTHEME -> qt6ct not installed (rice step)
--   GTK_THEME            -> adw-gtk3 not installed (rice step)
--   HYPRSHOT_DIR         -> hyprshot not installed (rice step)
