install_packages() {
  section "System packages"
  sudo pacman -Sy --needed --noconfirm \
    hyprland kitty gtk4 hyprpolkitagent pipewire xdg-desktop-portal-hyprland \
    qt6-wayland qt5-wayland neovim git mpv firefox which base-devel fzf grep tree ripgrep vim \
    devtools unzip wl-clipboard qt6ct awww hyprshot waybar ttf-jetbrains-mono-nerd \
    brightnessctl playerctl btop fastfetch hypridle matugen hyprtoolkit hyprlock hyprsunset rofi mako gvfs fish starship adw-gtk-theme papirus-icon-theme zoxide eza bat docker docker-compose docker-buildx mise gpu-screen-recorder jq ffmpeg intel-media-driver hyprpicker \
    bluez bluez-utils pavucontrol less 2>&1 | tail -1
  ok "Packages installed"
}

setup_paru() {
  section "AUR helper (paru)"
  if command -v paru &>/dev/null; then
    ok "paru already installed"
    return
  fi
  git clone --depth 1 https://aur.archlinux.org/paru.git ~/del/paru
  cd ~/del/paru
  makepkg -si --noconfirm 2>&1 | tail -1
  cd ~
  rm -rf ~/del/paru
  sudo pacman -Rns --noconfirm rust 2>&1 | tail -1
  ok "paru installed"

  mkdir -p ~/.config/paru
  cp /etc/paru.conf ~/.config/paru/paru.conf
  sed -i \
    -e 's/^#\s*\(BottomUp\)/\1/' \
    -e 's/^#\s*\(RemoveMake\)/\1/' \
    -e 's/^#\s*\(SudoLoop\)/\1/' \
    -e 's/^#\s*\(UseAsk\)/\1/' \
    -e 's/^#\s*\(CombinedUpgrade\)/\1/' \
    -e 's/^#\s*\(CleanAfter\)/\1/' \
    -e 's/^#\s*\(UpgradeMenu\)/\1/' \
    -e 's/^#\s*\(NewsOnUpgrade\)/\1/' \
    -e 's/^#\s*\(Chroot\)/\1/' \
    ~/.config/paru/paru.conf
  ok "paru configured"
}

install_aur_packages() {
  section "AUR packages"
  paru -Sy vscodium antigravity-cli opencode git-credential-manager otf-rubik nmrs blueberry swayosd 2>&1 | tail -1
  ok "AUR packages installed"
}
