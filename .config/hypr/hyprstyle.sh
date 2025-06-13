#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/"
SUPPORTED_FORMATS=("jpg" "jpeg" "png" "gif")
MONITOR="eDP-1"

is_image() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"
    for format in "${SUPPORTED_FORMATS[@]}"; do
        if [[ "$ext" == "$format" ]]; then
            return 0
        fi
    done
    return 1
}

get_wallpapers() {
    local images=()
    [[ ! -d "$WALLPAPER_DIR" ]] && echo "Error: No wallpaper dir" >&2 && exit 1

    while IFS= read -r -d '' file; do
        is_image "$file" && images+=("$file")
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f -print0)

    [[ ${#images[@]} -eq 0 ]] && echo "Error: No images found" >&2 && exit 1
    printf '%s\n' "${images[@]}"
}

# Wait for hyprpaper to be ready (up to 5s)
for i in {1..10}; do
    hyprctl monitors &>/dev/null && break
    sleep 0.5
done

selected=$(get_wallpapers | shuf -n 1)
[[ ! -r "$selected" ]] && echo "Error: Cannot read $selected" >&2 && exit 1

hyprctl hyprpaper preload "$selected"
sleep 0.2
hyprctl hyprpaper wallpaper "$MONITOR,$selected"
if [[ $? -eq 0 ]]; then
    wal -i "$selected"
    pkill waybar
    waybar &
    echo "Wallpaper set: $(basename "$selected")"
else
    echo "Error: Failed to set wallpaper" >&2
    exit 1
fi
