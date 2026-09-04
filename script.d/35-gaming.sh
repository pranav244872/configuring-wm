enable_multilib() {
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    section "Enabling multilib repository"
    sudo sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/#//' /etc/pacman.conf
    sudo pacman -Sy
    ok "Multilib repository enabled"
  fi
}

install_gaming() {
  enable_multilib

  section "Gaming packages"

  local packages=(
    heroic-games-launcher-bin
    gamescope
    mangohud lib32-mangohud
    gamemode lib32-gamemode
    winetricks
    goverlay
    vkbasalt lib32-vkbasalt
    openal lib32-openal
    lib32-alsa-plugins
  )

  local gpu
  gpu=$(lspci | grep -iE 'vga|3d|display' | grep -i 'intel') || true
  if [[ -n $gpu ]]; then
    packages+=(lib32-vulkan-intel lib32-ocl-icd)
  fi

  if command -v paru &>/dev/null; then
    paru -S --needed --noconfirm "${packages[@]}" 2>&1 | tail -1
  else
    for pkg in "${packages[@]}"; do
      if pacman -Qi "$pkg" &>/dev/null 2>&1; then
        ok "$pkg already installed"
        continue
      fi
      if pacman -Si "$pkg" &>/dev/null 2>&1; then
        sudo pacman -Sy --needed --noconfirm "$pkg" 2>&1 | tail -1
      else
        if [[ ! -d /tmp/build-"$pkg" ]]; then
          git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "/tmp/build-$pkg" 2>&1 | tail -1
          (cd "/tmp/build-$pkg" && makepkg -si --noconfirm) 2>&1 | tail -1
          rm -rf "/tmp/build-$pkg"
        fi
      fi
      ok "$pkg installed"
    done
  fi

  performance_tweaks
  ok "Gaming packages installed"
}

performance_tweaks() {
  section "Gaming performance tweaks"

  echo "ntsync" | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null
  sudo modprobe ntsync 2>/dev/null || true
  ok "ntsync module enabled"

  echo "kernel.split_lock_mitigate=0" | sudo tee /etc/sysctl.d/99-gaming.conf >/dev/null
  ok "split_lock_mitigate disabled"

  ok "Performance tweaks applied"
}
