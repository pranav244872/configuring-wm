#!/bin/bash

# =============================
# Function: Install Paru packages
# =============================

install_paru_packages() {
    paru -Sy --noconfirm hyprshot || { echo "Failed to install hyprshot"; exit 1; }
    paru -Sy --noconfirm hyprpaper || { echo "Failed to install hyprpaper"; exit 1; }
    paru -Sy --noconfirm hyprlock || { echo "Failed to install hyprlock"; exit 1; }
    paru -Sy --noconfirm hypridle || { echo "Failed to install hypridle"; exit 1; }
    paru -Sy --noconfirm python-pywal16 || { echo "Failed to install python-pywal16"; exit 1; }

    echo "All paru packages installed successfully."
}
