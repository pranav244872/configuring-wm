install_gaming() {
  section "Gaming packages"

  local packages=(
    heroic-games-launcher-bin
    gamescope
    mangohud lib32-mangohud
    gamemode lib32-gamemode
    winetricks
    goverlay
    vkbasalt lib32-vkbasalt
  )

  local aur=()
  for pkg in "${packages[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null 2>&1; then
      ok "$pkg already installed"
    else
      if pacman -Si "$pkg" &>/dev/null 2>&1; then
        aur+=("$pkg")
      else
        aur+=("$pkg")
      fi
    fi
  done

  if [[ ${#aur[@]} -gt 0 ]]; then
    for pkg in "${aur[@]}"; do
      if pacman -Qi "$pkg" &>/dev/null 2>&1; then
        continue
      fi
      if pacman -Si "$pkg" &>/dev/null 2>&1; then
        sudo pacman -Sy --needed --noconfirm "$pkg" 2>&1 | tail -1
      else
        if [[ ! -d /tmp/build-"$pkg" ]]; then
          git clone --depth 1 "https://aur.archlinux.org/$pkg.git" "/tmp/build-$pkg" 2>&1 | tail -1
          (cd "/tmp/build-$pkg" && makepkg -si --noconfirm) 2>&1 | tail -1
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

  echo Shangnan | sudo -S tee /etc/modules-load.d/ntsync.conf >/dev/null <<< "ntsync"
  echo Shangnan | sudo -S modprobe ntsync 2>/dev/null || true
  ok "ntsync module enabled"

  echo Shangnan | sudo -S tee /etc/sysctl.d/99-gaming.conf >/dev/null <<< "kernel.split_lock_mitigate=0"
  ok "split_lock_mitigate disabled"

  ok "Performance tweaks applied"
}
