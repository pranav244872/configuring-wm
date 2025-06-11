#!/bin/bash

# =============================
# Function: Set Console Font
# =============================
set_console_font() {
    # Ensure sudo privileges early
    sudo true || { echo "Sudo authentication failed."; exit 1; }

    # Update system packages
    sudo pacman -Syu --noconfirm
    if [ $? -ne 0 ]; then
        echo "System update failed. Exiting."
        exit 1
    fi

    # Install terminus-font
    sudo pacman -S --noconfirm terminus-font
    if [ $? -ne 0 ]; then
        echo "Failed to install terminus-font. Exiting."
        exit 1
    fi

    CONF_FILE="/etc/vconsole.conf"
    NEW_FONT="ter-v28b"

    # Backup and update font setting
    sudo cp "$CONF_FILE" "$CONF_FILE.bak"
    echo "Created backup of $CONF_FILE as $CONF_FILE.bak"

    if grep -q "^FONT=" "$CONF_FILE"; then
        echo "FONT entry found. Updating..."
        sudo sed -i "s/^FONT=.*/FONT=$NEW_FONT/" "$CONF_FILE"
    else
        echo "FONT entry not found. Adding..."
        echo "FONT=$NEW_FONT" | sudo tee -a "$CONF_FILE" > /dev/null
    fi

    echo "Done. You may need to reboot or run 'setfont $NEW_FONT' to apply it immediately."
}
