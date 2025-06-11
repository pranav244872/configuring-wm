#!/bin/bash

# ====================================
# Function: Install and Configure Paru
# ====================================

install_paru() {
    # Clone paru
    git clone https://aur.archlinux.org/paru.git || { echo "Failed to clone paru repo."; exit 1; }

    cd paru || { echo "Failed to enter paru directory."; exit 1; }

    # Build and install paru
    makepkg -si --noconfirm || { echo "Failed to build/install paru."; exit 1; }

    # Optionally remove Rust (paru installs it temporarily)
    sudo pacman -Rns --noconfirm rust || { echo "Failed to remove rust."; exit 1; }

    # Move to cleanup directory
    mkdir -p ~/del
    cd ~/del || { echo "Failed to switch to ~/del directory."; exit 1; }

    rm -rf ~/paru || { echo "Failed to clean up paru directory."; exit 1; }

    echo "Installed paru"

    # Configure paru
    PARU_CONF="/etc/paru.conf"
    sudo cp "$PARU_CONF" "${PARU_CONF}.bak" || { echo "Failed to back up paru.conf"; exit 1; }

    # Uncomment RemoveMake and CleanAfter
    sudo sed -i \
        -e 's/^#\s*\(RemoveMake\)/\1/' \
        -e 's/^#\s*\(CleanAfter\)/\1/' \
        "$PARU_CONF" || { echo "Failed to update paru.conf"; exit 1; }

    echo "RemoveMake and CleanAfter have been uncommented in $PARU_CONF."
}
