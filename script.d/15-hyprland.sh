setup_hyprland() {
  section "Building Hyprland from source (pranav244872/Hyprland)"

  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone --depth 1 https://github.com/pranav244872/Hyprland.git "$tmpdir"

  pushd "$tmpdir" > /dev/null
  make release PREFIX=/usr
  sudo make install PREFIX=/usr
  popd > /dev/null

  rm -rf "$tmpdir"
  ok "Hyprland built and installed"
}
