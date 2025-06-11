#!/bin/bash

source ./imports/network.sh
source ./imports/terminal_font.sh
source ./imports/install_base.sh
source ./imports/makepkg.sh
source ./imports/install_paru.sh
source ./imports/install_paru_packages.sh
source ./imports/install_fish.sh
source ./imports/enable_services.sh
source ./imports/git_config.sh

# =============================
# Main Script Execution
# =============================

connect_wifi
set_console_font
install_base_packages
optimize_makepkg
install_paru
install_paru_packages
set_fish_as_default
enable_services
git_config


echo "All tasks completed successfully."
