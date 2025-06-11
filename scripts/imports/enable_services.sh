#!/bin/bash

# =============================
# Function: Enable Services
# =============================
enable_services() {
    sudo systemctl enable bluetooth.service
    sudo systemctl enable sddm
    sudo usermod -a -G input pranav
    sudo systemctl start power-profiles-daemon.service
}
