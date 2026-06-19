setup_docker() {
  section "Docker"
  sudo mkdir -p /etc/docker /etc/systemd/resolved.conf.d /etc/systemd/system/docker.service.d
  sudo tee /etc/docker/daemon.json >/dev/null <<'DOCKER_EOF'
{
    "log-driver": "json-file",
    "log-opts": { "max-size": "10m", "max-file": "5" },
    "dns": ["172.17.0.1"],
    "bip": "172.17.0.1/16"
}
DOCKER_EOF
  sudo tee /etc/systemd/resolved.conf.d/20-docker-dns.conf >/dev/null <<'DNS_EOF'
[Resolve]
DNSStubListenerExtra=172.17.0.1
DNS_EOF
  sudo systemctl restart systemd-resolved
  sudo systemctl enable docker.socket
  sudo usermod -aG docker "$USER"
  sudo tee /etc/systemd/system/docker.service.d/no-block-boot.conf >/dev/null <<'BOOT_EOF'
[Unit]
DefaultDependencies=no
BOOT_EOF
  sudo systemctl daemon-reload
  ok "Docker configured (log out/in for group)"
}
