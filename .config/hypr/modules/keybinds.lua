---------------------
---- MY PROGRAMS ----
---------------------

-- Reuse the running kitty instead of cold-starting (no SSD; a cold start
-- re-reads the font from disk). CLI flag only: "single_instance" is not a
-- valid kitty.conf key and kitty ignores it.
local terminal = "kitty --single-instance --instance-group shell"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Windows key

-- Basics
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",      hl.dsp.exit())
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + W",      hl.dsp.window.fullscreen({ action = "toggle" }))

-- Fake fullscreen: tell the app it's fullscreen, keep it a normal window.
-- (Used from Moonlight sessions where the SUPER key isn't available.)
hl.bind(
    "CTRL + SHIFT + F",
    hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" })
)

-- Layout
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- Move focus with mainMod + arrows
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces: mainMod + key to switch, mainMod + SHIFT + key to move a window there
for i = 1, 10 do
    local key = i % 10 -- workspace 10 sits on key 0

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i })
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i })
    )
end

-- Scratchpad (special workspace "magic")
hl.bind(
    mainMod .. " + S",
    hl.dsp.workspace.toggle_special("magic")
)

hl.bind(
    mainMod .. " + SHIFT + S",
    hl.dsp.window.move({ workspace = "special:magic" })
)

-- Scroll through existing workspaces
hl.bind(
    mainMod .. " + mouse_down",
    hl.dsp.focus({ workspace = "e+1" })
)

hl.bind(
    mainMod .. " + mouse_up",
    hl.dsp.focus({ workspace = "e-1" })
)

-- Move/resize windows with the mouse
hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)

-- Laptop multimedia keys: volume / brightness / mic.
-- Volume needs no call-out: our quickshell OSD watches the default PipeWire
-- sink and shows itself on any change (see modules/osd/OsdHost.qml).
-- Brightness has no such service, so the bind pings the OSD over IPC after the
-- change. `2>/dev/null` keeps Hyprland's log clean when quickshell isn't running.
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 ; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 ; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("sh /home/pranav/.config/hypr/scripts/brightness.sh up 5 ; qs ipc call osd brightness 2>/dev/null"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("sh /home/pranav/.config/hypr/scripts/brightness.sh down 5 ; qs ipc call osd brightness 2>/dev/null"),
    { locked = true, repeating = true }
)

-- ALT + key: precise ±1% steps
hl.bind(
    "ALT + XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 ; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "ALT + XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 ; wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),
    { locked = true, repeating = true }
)

hl.bind(
    "ALT + XF86MonBrightnessUp",
    hl.dsp.exec_cmd("sh /home/pranav/.config/hypr/scripts/brightness.sh up 1 ; qs ipc call osd brightness 2>/dev/null"),
    { locked = true, repeating = true }
)

hl.bind(
    "ALT + XF86MonBrightnessDown",
    hl.dsp.exec_cmd("sh /home/pranav/.config/hypr/scripts/brightness.sh down 1 ; qs ipc call osd brightness 2>/dev/null"),
    { locked = true, repeating = true }
)

-- Media player control (playerctl)
hl.bind(
    "XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true }
)

hl.bind(
    "XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true }
)

-- Own shell (autostarted): bind restarts it if ever killed.
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("qs -n"))
hl.bind(
    mainMod .. " + F",
    hl.dsp.exec_cmd("sh -c 'pgrep -x qs >/dev/null || (setsid qs -n >/dev/null 2>&1 & sleep 1); qs ipc call launcher toggle'")
)

-- Session lock (own quickshell UI + PAM, replaces hyprlock).
-- Reached with Fn+F9: plain F9 is the firmware "lock screen" hotkey and emits
-- nothing Linux can see (no evdev keycode, no ACPI); Fn+F9 sends the real F9.
local lockCmd = "sh -c 'pgrep -x qs >/dev/null || (setsid qs -n >/dev/null 2>&1 & sleep 1); qs ipc call lock lock'"
hl.bind("F9", hl.dsp.exec_cmd(lockCmd))

-- Screenshot utility (own quickshell UI): Print captures, annotate in-shell.
hl.bind(
    "Print",
    hl.dsp.exec_cmd("sh -c 'pgrep -x qs >/dev/null || (setsid qs -n >/dev/null 2>&1 & sleep 1); qs ipc call screenshot toggle'")
)

-- Wallpaper picker (own quickshell UI): the sheet the bottom-right corner
-- opens. The dashboard is closed first: two bottom sheets stacked is a bug.
hl.bind(
    mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd("sh -c 'pgrep -x qs >/dev/null || (setsid qs -n >/dev/null 2>&1 & sleep 1); qs ipc call dashboard close; qs ipc call wallpaper toggle'")
)

-- Manual step of the wallpaper cycle: next image in the library, no sheet.
hl.bind(
    mainMod .. " + ALT + W",
    hl.dsp.exec_cmd("sh -c 'pgrep -x qs >/dev/null || (setsid qs -n >/dev/null 2>&1 & sleep 1); qs ipc call wallpaper cycleNext'")
)

-- Deferred to the rice step (old binds that need tools we are not installing yet):
--   SUPER + ESCAPE          -> rofi powermenu
--   SUPER + K               -> keybinds menu
--   SUPER + E               -> dolphin file manager
--   SUPER + XF86AudioMute   -> audio output switch script
--   SUPER + SHIFT + R       -> screen recording
