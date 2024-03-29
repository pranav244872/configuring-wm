#!/bin/bash

# Set the path to your wallpaper directory
WALLPAPER_DIR=/home/pranav/Pictures/Wallpapers

# Choose a random wallpaper
WALLPAPER=$(ls $WALLPAPER_DIR/* | shuf -n 1)

# Use pywal to set the wallpaper and generate color scheme
swaybg -i "$WALLPAPER" &
wal -i "$WALLPAPER"
sed -i 's/#//g' ~/.cache/wal/colors-hyprland.conf
rm -rf ~/scripts/Pywal/
/home/pranav/scripts/generate-theme.sh
