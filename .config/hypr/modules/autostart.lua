-------------------
---- AUTOSTART ----
-------------------

-- Keep this list as small as possible. Everything else belongs to the rice step.

hl.on("hyprland.start", function()
    -- Polkit authentication agent (GUI password prompts for privileged actions)
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    -- Own shell (bar, OSD, launcher, lock): warm at login, instant toggles
    hl.exec_cmd("setsid qs -n >/dev/null 2>&1 &")
end)
