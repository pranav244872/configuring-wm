#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/rofi/wallpaper"
WALLPAPER_DIRS_FILE="$CONFIG_DIR/dirs"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

mkdir -p "$CONFIG_DIR"

if ! pgrep -x "awww-daemon" >/dev/null; then
    awww-daemon &
fi

pick_dir() {
    "$SCRIPT_DIR/dir_picker.sh" "$HOME"
}

ensure_dir() {
    if [ ! -f "$WALLPAPER_DIRS_FILE" ]; then
        DIR=$(pick_dir)
        if [ -n "$DIR" ]; then
            mkdir -p "$DIR"
            echo "$DIR" > "$WALLPAPER_DIRS_FILE"
        else
            exit 1
        fi
    fi
}

ensure_dir || exit
WALL_DIR=$(head -1 "$WALLPAPER_DIRS_FILE")

mapfile -t IMAGES < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.bmp" \) -printf "%f\n" | sort)

if [ ${#IMAGES[@]} -eq 0 ]; then
    notify-send "Wallpaper" "No images found in $WALL_DIR"
    DIR=$(pick_dir)
    if [ -n "$DIR" ]; then
        echo "$DIR" > "$WALLPAPER_DIRS_FILE"
        exec "$0"
    fi
    exit
fi

CHOSEN=$(
    for img in "${IMAGES[@]}"; do
        echo -en "$img\0icon\x1f$WALL_DIR/$img\n"
    done | rofi -dmenu -i -p "Wallpaper" -theme "$SCRIPT_DIR/wallpaper.rasi"
)

if [ -z "$CHOSEN" ]; then
    exit
fi

FULL_PATH="$WALL_DIR/$CHOSEN"
notify-send "Wallpaper" "Setting..."
awww img "$FULL_PATH" --transition-type random --transition-step 90 --transition-fps 60 --transition-duration 2
matugen image "$FULL_PATH" --prefer darkness
notify-send "Wallpaper" "Done"
