#!/bin/bash

rofi -dmenu -p "Keybindings" -i -no-custom -theme ~/.config/rofi/keybinds/style.rasi \
  < <(
cat <<'BINDS' | while IFS= read -r line; do
SUPER + K|Show this keybinding browser
SUPER + RETURN|Open terminal (kitty)
SUPER + Q|Close window
SUPER + M|Exit Hyprland
SUPER + E|Open file manager (dolphin)
SUPER + V|Toggle window float
SUPER + F|App launcher (rofi)
SUPER + ESCAPE|Power menu (rofi)
SUPER + P|Toggle pseudo-tiling
SUPER + J|Toggle split layout
SUPER + arrows|Focus window in direction
SUPER + [0-9]|Switch to workspace
SUPER + SHIFT + [0-9]|Move window to workspace
SUPER + S|Toggle scratchpad
SUPER + SHIFT + S|Move window to scratchpad
SUPER + scroll|Cycle workspaces
SUPER + mouse:272|Drag window
SUPER + mouse:273|Resize window
Vol up/down|Raise/lower volume
Mute|Toggle mute
Mic mute|Toggle microphone
Brightness up/down|Adjust brightness
ALT + vol or br|Precise 1% adjustment
SUPER + Mute|Cycle audio output
Play/Pause/Next/Prev|Media playback controls
SUPER + SHIFT + W|Wallpaper picker (rofi)
SUPER + PRINT|Screenshot active window
PRINT|Screenshot monitor
SHIFT + PRINT|Screenshot region
SUPER + SHIFT + R|Screen recording menu (rofi)
BINDS
  key="${line%%|*}"
  desc="${line#*|}"
  printf "%-30s %s\n" "$key" "$desc"
done
)
