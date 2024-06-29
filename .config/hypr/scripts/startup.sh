#!/bin/bash

hyprpaper &

cache_dir="/home/pranav/.cache"
dir_to_remove="$cache_dir/cur_wallpaper"

# Check if the cur_wallpaper directory exists and remove it if it does
if [ -d "$dir_to_remove" ]; then
    echo "Directory $dir_to_remove exists. Removing..."
    rm -rf "$dir_to_remove"
    echo "Directory $dir_to_remove removed successfully."
fi

# Create the directory cur_wallpaper
mkdir -p "$cache_dir/cur_wallpaper"

# Set path to the wallpaper directory
WALLPAPER_DIR=/home/pranav/Pictures/Wallpapers
# Choose a Random Wallpaper
WALLPAPER=$(ls $WALLPAPER_DIR/* | shuf -n 1)
echo "$WALLPAPER"
# Copy the selected wallpaper to cur_wallpaper directory and rename it
cp "$WALLPAPER" "$cache_dir/cur_wallpaper/cur_wallpaper.png"
echo "Wallpaper copied to $cache_dir/cur_wallpaper/cur_wallpaper.png"

# Now set the wallpaper using the appropriate commands
swaybg -i "$WALLPAPER" &

wal -i "$WALLPAPER"

