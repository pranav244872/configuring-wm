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

4. mise (universal version manager - replaces nvm/rbenv/pyenv/asdf)
   ┌──────────────────────────────────────────────────────────┐
   │  Install languages:                                       │
   │    mise use -g java@latest     # Java (OpenJDK)           │
   │    mise use -g node@latest     # Node.js                  │
   │    mise use -g python@latest   # Python                   │
   │    mise use -g go@latest       # Go                       │
   │    mise use -g rust@latest     # Rust (via rustup, not    │
   │                                # recommended - use        │
   │                                # rustup directly)         │
   │                                                            │
   │  Global vs per-project:                                    │
   │    mise use -g node@18         # global default            │
   │    mise use node@20            # only in this directory    │
   │    # creates .mise.toml in current dir                    │
   │                                                            │
   │  Common commands:                                          │
   │    mise ls                     # list installed tools      │
   │    mise ls-remote java         # list available versions   │
   │    mise current                # show active versions      │
   │    mise where java             # show install path         │
   │    mise uninstall java@21      # remove a version          │
   │    mise upgrade java           # upgrade to latest         │
   │    mise trust                  # trust .mise.toml (safety) │
   │    mise doctor                 # diagnose issues           │
   │                                                            │
   │  .mise.toml example:                                        │
   │    [tools]                                                  │
   │    java = "21"                                              │
   │    node = "22"                                              │
   │    [env]                                                    │
   │    _.path = "{{ cwd }}/bin"    # add ./bin to PATH         │
   │                                                            │
   │  The magic: cd into a project with .mise.toml,             │
   │  versions auto-switch. No more nvm use / pyenv local.      │
   └──────────────────────────────────────────────────────────┘

5. SDDM login manager (pixel-skyscrapers theme)
   ┌──────────────────────────────────────────────────────────┐
   │  SDDM is enabled and will start on next boot.            │
   │                                                          │
   │  Pixel Skyscrapers theme with animated background.       │
   │                                                          │
   │  Select "Hyprland" as the session and enter password.    │
   │  Password: Shangnan                                      │
   │                                                          │
   │  If SDDM doesn't start, reboot or run:                   │
   │    sudo systemctl start sddm.service                     │
   └──────────────────────────────────────────────────────────┘

6. SwayOSD (on-screen volume/brightness/media display)
   ┌──────────────────────────────────────────────────────────┐
   │  Already enabled as a systemd user service.              │
   │  Theming updates automatically when matugen runs.        │
   │                                                          │
   │  Available hotkeys:                                      │
   │    • Vol up/down + mute     → swayosd OSD                │
   │    • Mic mute toggle        → swayosd OSD                │
   │    • Brightness up/down     → swayosd bar + percentage   │
   │    • Play/pause/next/prev   → swayosd media OSD          │
   │    • SUPER + Mute           → cycle audio sinks          │
   │    • ALT + vol/brightness   → 1% precise steps           │
   └──────────────────────────────────────────────────────────┘

6. Screen recording (gpu-screen-recorder)
   ┌──────────────────────────────────────────────────────────┐
   │  Open recording menu:                                     │
   │    SUPER + SHIFT + R          # rofi menu with status     │
   │                                                            │
   │  Recording menu shows:                                     │
   │    • 🔴 Recording (elapsed time) when active              │
   │    • ⏹ Idle when stopped                                 │
   │    • 📄 Current/last filename                             │
   │    • Start (with/without audio)                           │
   │    • Stop button                                          │
   │                                                            │
   │  Recordings saved to ~/Videos/screenrecording-*.mp4       │
   │                                                            │
   │  Post-processing:                                          │
   │    • Trims first 0.1s (warmup frames)                     │
   │    • Normalizes audio to -14 LUFS                          │
   │    • Hard-mutes 0-0.4s (PipeWire capture pop)              │
   │    • Generates preview thumbnail for notification           │
   │                                                            │
   │  Set custom output dir:                                    │
   │    export SCREENRECORD_DIR="$HOME/Videos/Screencasts"     │
   └──────────────────────────────────────────────────────────┘

MANUAL
}
