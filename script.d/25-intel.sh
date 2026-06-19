setup_intel_gpu() {
  section "Intel GPU drivers"

  local gpu
  gpu=$(lspci | grep -iE 'vga|3d|display' | grep -i 'intel') || true

  if [[ -z $gpu ]]; then
    ok "No Intel GPU detected, skipping"
    return
  fi

  local packages=()

  if [[ ${gpu,,} =~ (hd\ graphics|uhd\ graphics|iris|xe|arc) ]]; then
    packages+=(intel-media-driver libvpl vpl-gpu-rt)
  elif [[ ${gpu,,} =~ gma ]]; then
    packages+=(libva-intel-driver)
  fi

  packages+=(vulkan-intel)

  if [[ ${#packages[@]} -gt 0 ]]; then
    sudo pacman -Sy --needed --noconfirm "${packages[@]}" 2>&1 | tail -1
    ok "Intel GPU drivers installed: ${packages[*]}"
  fi

  local cpu_model
  cpu_model=$(grep -m1 "^model" /proc/cpuinfo | awk '{print $3}')

  if [[ -n $cpu_model ]] && ((cpu_model >= 42)) && ls /sys/class/power_supply | grep -q "^BAT"; then
    if ! pacman -Q thermald &>/dev/null; then
      sudo pacman -Sy --noconfirm thermald 2>&1 | tail -1
      sudo systemctl enable --now thermald 2>/dev/null
      ok "thermald installed (Intel Sandy Bridge+ laptop)"
    else
      ok "thermald already installed"
    fi
  fi
}
