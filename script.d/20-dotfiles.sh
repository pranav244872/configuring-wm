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
  ln -sf ~/del/configuring-wm/.config/gtk/gtk.css ~/.config/gtk-4.0/gtk.css
  cp ~/del/configuring-wm/.config/gtk/settings.ini ~/.config/gtk-3.0/settings.ini
  mkdir -p ~/.config/btop/themes ~/.config/qt6ct/colors
  cp ~/del/configuring-wm/.config/btop/themes/matugen.theme ~/.config/btop/themes/
  cp ~/del/configuring-wm/.config/qt6ct/colors/matugen.conf ~/.config/qt6ct/colors/
  cp ~/del/configuring-wm/.config/qt6ct/qt6ct.conf ~/.config/qt6ct/qt6ct.conf
  cp -r ~/del/configuring-wm/.config/systemd ~/.config
  cp -r ~/del/configuring-wm/.config/fastfetch ~/.config
  mkdir -p ~/.config/opencode/themes
  cp ~/del/configuring-wm/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc
  cp -r ~/del/configuring-wm/.config/swayosd ~/.config/swayosd
  ok "Configs deployed"
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
