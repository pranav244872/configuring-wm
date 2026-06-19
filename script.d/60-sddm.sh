setup_sddm() {
  section "SDDM login manager"
  sudo pacman -Sy --needed --noconfirm sddm qt6-declarative qt6-5compat qt6-svg qt6-multimedia qt6-multimedia-ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly 2>&1 | tail -1

  sudo mkdir -p /usr/share/sddm/themes/pixel-skyscrapers
  sudo cp -r "$SCRIPT_DIR/sddm/themes/pixel-skyscrapers/"* /usr/share/sddm/themes/pixel-skyscrapers/
  sudo rm -f /usr/share/sddm/hyprland.conf
  sudo cp "$SCRIPT_DIR/sddm/hyprland.lua" /usr/share/sddm/hyprland.lua

  sudo mkdir -p /etc/sddm.conf.d
  sudo cp "$SCRIPT_DIR/sddm/10-wayland.conf" /etc/sddm.conf.d/10-wayland.conf
  sudo cp "$SCRIPT_DIR/sddm/theme.conf" /etc/sddm.conf.d/theme.conf

  sudo systemctl enable sddm.service 2>&1 | tail -1
  ok "SDDM enabled with pixel-skyscrapers theme"
}
