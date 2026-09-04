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
  cp "$SCRIPT_DIR/Wallpapers/"* ~/Pictures/Wallpapers/
  cp -r "$SCRIPT_DIR/.config/nvim" "$SCRIPT_DIR/.config/mpv" ~/.config/
  cp -r "$SCRIPT_DIR/.config/waybar" ~/.config/
  cp -r "$SCRIPT_DIR/.config/kitty" ~/.config/
  cp -r "$SCRIPT_DIR/.config/hypr" ~/.config/
  cp -r "$SCRIPT_DIR/.config/matugen" ~/.config/
  cp -r "$SCRIPT_DIR/.config/rofi" ~/.config/
  cp -r "$SCRIPT_DIR/.config/mako" ~/.config/
  cp -r "$SCRIPT_DIR/.config/fish" ~/.config/
  cp -r "$SCRIPT_DIR/.config/ripgrep" ~/.config/
  cp "$SCRIPT_DIR/.config/starship.toml" ~/.config/
  cp -r "$SCRIPT_DIR/.config/gtk" ~/.config/
  mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
  ln -sf "$SCRIPT_DIR/.config/gtk/gtk.css" ~/.config/gtk-4.0/gtk.css
  cp "$SCRIPT_DIR/.config/gtk/settings.ini" ~/.config/gtk-3.0/settings.ini
  mkdir -p ~/.config/btop/themes ~/.config/qt6ct/colors
  cp "$SCRIPT_DIR/.config/btop/themes/matugen.theme" ~/.config/btop/themes/
  cp "$SCRIPT_DIR/.config/qt6ct/colors/matugen.conf" ~/.config/qt6ct/colors/
  cp "$SCRIPT_DIR/.config/qt6ct/qt6ct.conf" ~/.config/qt6ct/qt6ct.conf
  cp -r "$SCRIPT_DIR/.config/systemd" ~/.config/
  cp -r "$SCRIPT_DIR/.config/fastfetch" ~/.config/
  mkdir -p ~/.config/opencode/themes
  cp "$SCRIPT_DIR/.config/opencode/opencode.jsonc" ~/.config/opencode/opencode.jsonc
  mkdir -p ~/.config/imv
  cp "$SCRIPT_DIR/.config/imv/config" ~/.config/imv/config
  cp -r "$SCRIPT_DIR/.config/swayosd" ~/.config/swayosd
  if [[ -f "$SCRIPT_DIR/.bashrc" ]]; then
    cp "$SCRIPT_DIR/.bashrc" ~/.bashrc
  fi
  ok "Configs deployed"
}

setup_imv() {
  section "Default image viewer (imv)"
  xdg-mime default imv.desktop image/png
  xdg-mime default imv.desktop image/jpeg
  xdg-mime default imv.desktop image/gif
  xdg-mime default imv.desktop image/webp
  xdg-mime default imv.desktop image/bmp
  xdg-mime default imv.desktop image/tiff
  xdg-mime default imv.desktop image/svg+xml
  ok "imv set as default image viewer"
}

setup_gtk() {
  section "GTK theme"
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
  gsettings set org.gnome.desktop.interface icon-theme "Papirus"
  gsettings set org.gnome.desktop.interface font-name "Rubik 11"
  gsettings set org.gnome.desktop.interface font-antialiasing "rgba"
  gsettings set org.gnome.desktop.interface font-rgba-order "rgb"
  ok "GTK theme set to adw-gtk3-dark, font set to Rubik 11"
}
