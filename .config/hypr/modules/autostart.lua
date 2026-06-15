-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hyprsunset --identity >/dev/null 2>&1")
    hl.exec_cmd("sleep 2 && ~/.config/hypr/scripts/hyprsunsetctl reset && ~/.config/hypr/scripts/hyprsunsetctl auto")
end)
