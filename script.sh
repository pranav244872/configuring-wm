#!/bin/bash
set -euo pipefail

log()  { printf "\033[1;34m[%s]\033[0m %s\n" "$(date +%H:%M:%S)" "$*"; }
ok()   { printf "\033[1;32m  ✓\033[0m %s\n" "$*"; }
fail() { printf "\033[1;31m  ✗\033[0m %s\n" "$*" >&2; }

section() {
  printf "\n\033[1;36m━━━ %s ━━━\033[0m\n" "$1"
}

install_packages() {
  section "System packages"
  sudo pacman -Sy --needed --noconfirm \
    hyprland kitty gtk4 hyprpolkitagent pipewire xdg-desktop-portal-hyprland \
    qt6-wayland qt5-wayland neovim git mpv firefox which base-devel fzf grep tree ripgrep vim \
    devtools unzip wl-clipboard qt6ct awww hyprshot waybar ttf-jetbrains-mono-nerd \
    brightnessctl playerctl btop hypridle matugen hyprtoolkit hyprlock hyprsunset rofi mako fastfetch gvfs fish starship adw-gtk-theme 2>&1 | tail -1
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

clone_dotfiles() {
  section "Dotfiles"
  if [ -d ~/del/configuring-wm ]; then
    ok "Dotfiles already cloned"
    return
  fi
  git clone https://github.com/pranav244872/configuring-wm ~/del/configuring-wm
  ok "Dotfiles cloned"
}

setup_rofi() {
  section "Rofi launcher themes"
  if [ -d ~/.config/rofi/launchers ]; then
    ok "Rofi themes already installed"
    return
  fi
  git clone --depth 1 https://github.com/adi1090x/rofi.git /tmp/adi1090x-rofi
  (cd /tmp/adi1090x-rofi && bash setup.sh)
  rm -rf /tmp/adi1090x-rofi
  ok "Rofi themes installed"
}

deploy_configs() {
  section "Configs & wallpapers"
  mkdir -p ~/Pictures/{Wallpapers,Screenshots}
  cp ~/del/configuring-wm/Wallpapers/* ~/Pictures/Wallpapers/
  cp -r ~/del/configuring-wm/.config/nvim ~/del/configuring-wm/.config/mpv ~/.config/
  cp -r ~/del/configuring-wm/.config/waybar ~/.config
  cp -r ~/del/configuring-wm/.config/kitty ~/.config
  cp -r ~/del/configuring-wm/.config/hypr ~/.config
  cp -r ~/del/configuring-wm/.config/matugen ~/.config
  cp -r ~/del/configuring-wm/.config/rofi ~/.config
  cp -r ~/del/configuring-wm/.config/mako ~/.config
  cp ~/del/configuring-wm/.config/starship.toml ~/.config/
  cp -r ~/del/configuring-wm/.config/gtk ~/.config
  mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
  cp ~/del/configuring-wm/.config/gtk/gtk.css ~/.config/gtk-3.0/gtk.css
  cp ~/del/configuring-wm/.config/gtk/gtk.css ~/.config/gtk-4.0/gtk.css
  cp ~/del/configuring-wm/.config/gtk/settings.ini ~/.config/gtk-3.0/settings.ini
  mkdir -p ~/.config/btop/themes ~/.config/qt6ct/colors
  cp ~/del/configuring-wm/.config/btop/themes/matugen.theme ~/.config/btop/themes/
  cp ~/del/configuring-wm/.config/qt6ct/colors/matugen.conf ~/.config/qt6ct/colors/
  cp ~/del/configuring-wm/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/qt6ct.conf
  cp -r ~/del/configuring-wm/.config/systemd ~/.config
  cp -r ~/del/configuring-wm/.config/fastfetch ~/.config
  mkdir -p ~/.config/opencode/themes
  cp ~/del/configuring-wm/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc
  ok "Configs deployed"
}

setup_gtk() {
  section "GTK theme"
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
  gsettings set org.gnome.desktop.interface font-name "Rubik 11"
  ok "GTK theme set to adw-gtk3-dark, font set to Rubik 11"
}

enable_services() {
  section "Systemd services"
  systemctl --user daemon-reload
  systemctl --user enable --now hyprsunset-auto.timer 2>&1 | tail -1
  ok "hyprsunset auto-timer enabled"
}

install_aur_packages() {
  section "AUR packages"
  paru -Sy --noconfirm vscodium antigravity-cli opencode git-credential-manager otf-rubik 2>&1 | tail -1
  ok "AUR packages installed"
}

setup_git() {
  section "Git configuration"
  git config --global credential.credentialStore plaintext
  git-credential-manager configure

  read -rp "Enter your GitHub Email: " git_email
  read -rp "Enter your GitHub Username: " git_username

  git config --global user.email "$git_email"
  git config --global user.name "$git_username"

  echo
  ok "Email: $(git config --global user.email)"
  ok "Name:  $(git config --global user.name)"
}

post_install_manual_steps() {
  section "Manual steps required"

  cat <<'MANUAL'

┌─────────────────────────────────────────────────────────────┐
│  These apps need manual setup to use matugen colors         │
└─────────────────────────────────────────────────────────────┘

1. btop
   - Open btop → press Escape → Options → Themes
   - Select "matugen"

2. Qt apps (qt6ct)
   - Open qt6ct:
       qt6ct
   - Go to Appearance tab → check "Use custom palette"
   - Select "matugen" from the color scheme dropdown
   - Click Apply

3. Neovim
   - Install the base16-colorscheme plugin (e.g. via lazy.nvim):
       { "RRethy/base16-nvim" }
   - Add to your init.lua:
       dofile(vim.fn.expand("~/.config/nvim/matugen.lua"))
   - The theme auto-updates when matugen runs (SIGUSR1)

MANUAL
}

### ── Main ────────────────────────────────────────────────

sudo sed -i '/^ILoveCandy$/d' /etc/pacman.conf
sudo sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf

install_packages
clone_dotfiles
setup_paru
setup_rofi
deploy_configs
setup_gtk
enable_services
install_aur_packages
setup_git

chsh -s $(which fish)

# Remove .bashrc since we use fish
rm -f ~/.bashrc

post_install_manual_steps

echo
printf "\033[1;32m━━━ Done ━━━\033[0m\n"
