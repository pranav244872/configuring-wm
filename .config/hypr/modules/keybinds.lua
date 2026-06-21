---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "~/.config/rofi/launcher/launcher.sh"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

-- Toggle fullscreen
hl.bind(mainMod .. " + W", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Original: SUPER + F (launcher)
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(menu))

-- Fake fullscreen toggle: tell app it's fullscreen, keep it as normal window
-- Used via Moonlight from Windows (avoid Super key)
hl.bind(
    "CTRL + SHIFT + F",
    hl.dsp.window.fullscreen_state({ internal = 0, client = 2, action = "toggle" })
)

-- Powermenu
hl.bind(
    mainMod .. " + ESCAPE",
    hl.dsp.exec_cmd("~/.config/rofi/powermenu/powermenu.sh")
)

-- Keybinding search
hl.bind(
    mainMod .. " + K",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds-menu.sh")
)

hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- workspace 10 uses key 0

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i })
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i })
    )
end

-- Special workspace (scratchpad)
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

-- Move/resize windows with mouse
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

-- Laptop multimedia keys for volume and brightness
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("swayosd-client --output-volume raise"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/mic-mute-toggle"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/swayosd-brightness +5%"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/swayosd-brightness 5%-"),
    { locked = true, repeating = true }
)

-- Requires playerctl
hl.bind(
    "XF86AudioNext",
    hl.dsp.exec_cmd("swayosd-client --playerctl next"),
    { locked = true }
)

hl.bind(
    "XF86AudioPause",
    hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPlay",
    hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"),
    { locked = true }
)

hl.bind(
    "XF86AudioPrev",
    hl.dsp.exec_cmd("swayosd-client --playerctl previous"),
    { locked = true }
)

-- Audio output switching
hl.bind(
    mainMod .. " + XF86AudioMute",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/audio-output-switch"),
    { locked = true }
)

-- Precise volume and brightness controls
hl.bind(
    "ALT + XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("swayosd-client --output-volume +1"),
    { locked = true, repeating = true }
)

hl.bind(
    "ALT + XF86AudioLowerVolume",
    hl.dsp.exec_cmd("swayosd-client --output-volume -1"),
    { locked = true, repeating = true }
)

hl.bind(
    "ALT + XF86MonBrightnessUp",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/swayosd-brightness +1%"),
    { locked = true, repeating = true }
)

hl.bind(
    "ALT + XF86MonBrightnessDown",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/swayosd-brightness 1%-"),
    { locked = true, repeating = true }
)

-- Hyprshot

-- Wallpaper picker
hl.bind(
    mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd("~/.config/rofi/scripts/wallpaper_menu.sh")
)

-- Screenshot active window
hl.bind(
    mainMod .. " + PRINT",
    hl.dsp.exec_cmd("hyprshot -m window")
)

-- Screenshot monitor
hl.bind(
    "PRINT",
    hl.dsp.exec_cmd("hyprshot -m output")
)

-- Screenshot region
hl.bind(
    "SHIFT + PRINT",
    hl.dsp.exec_cmd("hyprshot -m region")
)

-- Screen recording menu (rofi-based)
hl.bind(
    mainMod .. " + SHIFT + R",
    hl.dsp.exec_cmd("~/.config/rofi/recording/recording.sh")
)