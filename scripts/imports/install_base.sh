#!/bin/bash

# ====================================
# Function: Install Base Packages
# ====================================
install_base_packages() {
    # Ensure sudo access first
    sudo true || { echo "Sudo authentication failed."; exit 1; }

    # System update
    echo "Updating system..."
    sudo pacman -Syu --noconfirm
    if [ $? -ne 0 ]; then
        echo "System update failed. Exiting."
        exit 1
    fi

    echo "Installing base packages..."
    sudo pacman -Sy --noconfirm fzf udiskie fastfetch neovim
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm kitty hyprland dunst hyprpolkitagent fuzzel
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm pipewire wireplumber xdg-desktop-portal-hyprland qt6-wayland gtk4
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm firefox git tree brightnessctl
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm bluez bluez-utils fd ripgrep 
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm pacman-contrib btop less sddm
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm alsa-utils noto-fonts noto-fonts-emoji noto-fonts-cjk
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm qt6-declarative qt6-5compat qt6-svg fish gvfs gvfs-mtp
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm ttf-jetbrains-mono-nerd eza playerctl unzip
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm socat jq python awk grep
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm wireless_tools wlsunset p7zip waybar
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi
    sudo pacman -Sy --noconfirm power-profiles-daemon expac
    if [ $? -ne 0 ]; then
        echo "One or more packages failed to install. Exiting."
        exit 1
    fi

    echo "All packages installed successfully."
}
