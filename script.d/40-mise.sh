setup_mise() {
  section "mise (version manager)"
  mkdir -p ~/Work
  cat > ~/Work/.mise.toml <<'EOF'
[env]
_.path = "{{ cwd }}/bin"
EOF
  mise trust ~/Work/.mise.toml
  mise use -g java@latest 2>&1 | tail -1
  ok "mise configured with java $(java -version 2>&1 | head -1)"
}
