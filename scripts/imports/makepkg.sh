#!/bin/bash

# ===================================
# Function: Optimize makepkg.conf
# ===================================
optimize_makepkg() {
    MAKEPKG_CONF="/etc/makepkg.conf"
    sudo cp "$MAKEPKG_CONF" "${MAKEPKG_CONF}.bak"

    if grep -q '^#\?MAKEFLAGS=' "$MAKEPKG_CONF"; then
        echo "MAKEFLAGS entry found. Updating to -j4..."
        sudo sed -i 's/^#\?MAKEFLAGS=.*/MAKEFLAGS="-j4"/' "$MAKEPKG_CONF"
    else
        echo "MAKEFLAGS not found. Adding..."
        echo 'MAKEFLAGS="-j4"' | sudo tee -a "$MAKEPKG_CONF" > /dev/null
    fi

    echo "Optimized makepkg.conf to use 4 cores."
}
