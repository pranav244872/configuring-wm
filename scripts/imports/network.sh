#!/bin/bash
# =============================================
# ARCH WIFI MIGRATION: nmcli → iwd (Auto-Reconnect)
# =============================================

set -e  # Exit on any error

connect_wifi() {
    # Phase 1: Temporary nmcli connection
    echo "📶 [Phase 1/3] Temporary nmcli connection..."
    nmcli device wifi list || {
        echo "❌ Error: Network scan failed"
        exit 1
    }

    read -p "🔹 Enter WiFi SSID: " SSID
    read -sp "🔹 Enter Password: " PASSWORD
    echo

    echo "🔄 Connecting via nmcli..."
    if ! nmcli device wifi connect "$SSID" password "$PASSWORD"; then
        echo "❌ nmcli connection failed"
        exit 1
    fi
    echo "✅ nmcli connected successfully!"

    # Phase 2: Migrate to iwd
    echo "🔧 [Phase 2/3] Migrating to iwd..."
    sudo pacman -S --noconfirm iwd || {
        echo "❌ iwd installation failed"
        exit 1
    }

    sudo systemctl stop NetworkManager
    sudo systemctl disable NetworkManager
    sudo systemctl enable --now iwd

    sudo mkdir -p /etc/iwd
    echo -e "[General]\nEnableNetworkConfiguration=true" | sudo tee /etc/iwd/main.conf >/dev/null

    # Phase 3: Reconnect with iwd
    echo "🔁 [Phase 3/3] Reconnecting via iwd..."
    DEVICE=$(iwctl device list | awk '/station/{print $2; exit}')
    if [ -z "$DEVICE" ]; then
        echo "❌ No WiFi device detected"
        exit 1
    fi

    echo "🔄 Scanning networks with iwd..."
    iwctl station "$DEVICE" scan || {
        echo "❌ iwd scan failed"
        exit 1
    }

    if ! iwctl --passphrase="$PASSWORD" station "$DEVICE" connect "$SSID"; then
        echo "❌ iwd connection failed"
        echo "⚠️  You may need to manually connect with:"
        echo "    iwctl station $DEVICE connect \"$SSID\" --passphrase=\"$PASSWORD\""
        exit 1
    fi

    echo "✅ iwd connected successfully!"
    echo "🧹 Cleaning up NetworkManager..."
    sudo pacman -Rns --noconfirm networkmanager 2>/dev/null || true

    echo "🎉 Migration complete!"
    echo "➡️  Your system is now using iwd with:"
    echo "    SSID: $SSID"
    echo "    Device: $DEVICE"
}
