-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Reference: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
--
-- Audited 2026-10-19 against the Hyprland source (its getenv calls), the
-- installed toolkits, and the old configuring-wm / omarchy / end-4 sets.
-- Only variables something on this machine actually reads are set here; what
-- was dropped and why is recorded at the bottom (comments only, not env).

-- Cursors. Read by the compositor itself (XCursor / hyprcursor).
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- XDG session. Hyprland is started from a TTY (no display manager), so nothing
-- above it sets these; portals and toolkits read them.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit backends.
--   Qt: Wayland first, X11 as fallback. qt6ct is the platform theme that
--   applies the dark palette matugen regenerates (~/.config/qt6ct/qt6ct.conf).
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Deliberately not set (verified on 2026-10-19):
--   HYPRLAND_TRACE=1                    debug logging, costs performance
--   GDK_BACKEND                         GTK already prefers Wayland whenever
--                                       WAYLAND_DISPLAY is set
--   SDL_VIDEODRIVER                     sdl2-compat/SDL3 auto-detect Wayland;
--                                       forcing it breaks X11-only games
--   QT_AUTO_SCREEN_SCALE_FACTOR         Qt5-only; no installed Qt6 library
--                                       contains the name
--   QT_WAYLAND_DISABLE_WINDOWDECORATION Qt5-only; same, no Qt6 library has it
--   MOZ_ENABLE_WAYLAND                  Firefox >= 121 defaults to Wayland
--                                       (installed: 157.0.1)
--   ELECTRON_OZONE_PLATFORM_HINT        no Electron/Chromium app installed
--   OZONE_PLATFORM                      old Chromium variable, superseded
--   _JAVA_AWT_WM_NONREPARENTING         no Java GUI app; add it with the first
--                                       (mise installs java but nothing GUI)
--   LIBVA_DRIVER_NAME                   libva auto-selects iHD: CometLake-U +
--                                       intel-media-driver + iHD_drv_video.so
--   WLR_NO_HARDWARE_CURSORS             the fork has cursor:no_hardware_cursors
--                                       (use the option, not the env)
--   GDK_SCALE / GDK_DPI_SCALE           eDP-1 runs at scale 1
--   XCURSOR_THEME                       only Adwaita cursors installed; the
--                                       default resolves to them
--   GTK_THEME                           GTK is themed via gsettings
--                                       (adw-gtk3-dark + color-scheme
--                                       prefer-dark); an env would override
--                                       each app's own choice
--   XDG_DATA_DIRS (flatpak paths)       flatpak is not installed
--   HYPRSHOT_DIR                        hyprshot is not used (our own UI)
