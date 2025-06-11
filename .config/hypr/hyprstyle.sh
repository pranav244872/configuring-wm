#!/bin/bash

# Configuration variables
WALLPAPER_DIR="$HOME/Pictures/Wallpapers/"
SUPPORTED_FORMATS=("jpg" "jpeg" "png" "gif")
MONITOR="eDP-1"

# Function to check if a file is an image based on extension
is_image() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # Convert to lowercase

    for format in "${SUPPORTED_FORMATS[@]}"; do
        if [[ "$ext" == "$format" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to get all images from the wallpaper directory
get_wallpapers() {
    local images=()

    # Check if directory exists
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        echo "Error: Wallpaper directory not found: $WALLPAPER_DIR" >&2
        exit 1
    fi

    # Find all image files
    while IFS= read -r -d '' file; do
        if is_image "$file"; then
            images+=("$file")
        fi
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f -print0)

    # Check if any images were found
    if [[ ${#images[@]} -eq 0 ]]; then
        echo "Error: No supported images found in $WALLPAPER_DIR" >&2
        exit 1
    fi

    printf '%s\n' "${images[@]}"
}

# Get all wallpapers and choose one at random
selected=$(get_wallpapers | shuf -n 1)

# Check if the file is readable
if [[ ! -r "$selected" ]]; then
    echo "Error: Cannot read selected wallpaper: $selected" >&2
    exit 1
fi

# Set the wallpaper using hyprctl
hyprctl hyprpaper preload "$selected"
if [[ $? -eq 0 ]]; then
    hyprctl hyprpaper wallpaper "$MONITOR,$selected"
    if [[ $? -eq 0 ]]; then
        wal -i "$selected"
        exec fish
        pkill waybar
        waybar &
        echo "Successfully set random wallpaper: $(basename "$selected")"
        exit 0
    fi
fi

echo "Error: Failed to set wallpaper" >&2
exit 1
