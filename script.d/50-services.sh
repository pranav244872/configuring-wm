enable_services() {
  section "Systemd services"
  systemctl --user daemon-reload
  sudo systemctl enable --now bluetooth
  systemctl --user enable swayosd-server 2>&1 | tail -1
}
