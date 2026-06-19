#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for f in "$SCRIPT_DIR/script.d"/*.sh; do
  source "$f"
done

# ── Tweaks ────────────────────────────────────────────────

sudo sed -i '/^ILoveCandy$/d' /etc/pacman.conf
sudo sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf

# ── Main ──────────────────────────────────────────────────

install_packages
clone_dotfiles
setup_paru
setup_rofi
deploy_configs
setup_gtk
setup_intel_gpu
enable_services
install_aur_packages
setup_docker
setup_mise
setup_git
setup_sddm

chsh -s "$(which fish)"

rm -f ~/.bashrc

post_install_manual_steps

echo
printf "\033[1;32m━━━ Done ━━━\033[0m\n"
