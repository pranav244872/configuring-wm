#!/bin/bash

install_paru_packages() {
    paru -S --noconfirm hyprshot || { echo "Failed to install hyprshot"; exit 1; }
    paru -S --noconfirm hyprpaper || { echo "Failed to install hyprpaper"; exit 1; }
    paru -S --noconfirm hyprlock || { echo "Failed to install hyprlock"; exit 1; }
    paru -S --noconfirm hypridle || { echo "Failed to install hypridle"; exit 1; }

    echo "All paru packages installed successfully."
}
