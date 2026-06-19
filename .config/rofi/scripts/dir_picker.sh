#!/usr/bin/env bash

current_dir="${1:-$HOME}"

while true; do
    dirs=$(find "$current_dir" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf "%f\n" | sort)
    options="Use This Folder\n..\n$dirs"
    options=$(echo "$options" | sed '/^$/d')

    chosen=$(echo -e "$options" | rofi -dmenu -i -p "$current_dir")

    if [ -z "$chosen" ]; then
        exit 1
    elif [ "$chosen" == "Use This Folder" ]; then
        echo "$current_dir"
        exit 0
    elif [ "$chosen" == ".." ]; then
        current_dir=$(dirname "$current_dir")
    else
        current_dir="$current_dir/$chosen"
    fi
done
