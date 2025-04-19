#!/bin/bash
# File: init.sh
# Usage: bash init.sh
# Description: Bootstraps the full rotatingheadlessdnsvpn system locally

set -e
echo "[+] Bootstrapping rotatingheadlessdnsvpn..."

mkdir -p rotatingheadlessdnsvpn/{logs,configs,scripts}
cd rotatingheadlessdnsvpn

echo "[+] Creating config files..."

cat <<EOF > configs/dns.conf
# Example DNS list
1.1.1.1
8.8.8.8
9.9.9.9
EOF

cat <<EOF > configs/proxylist.txt
# Example proxies
http://proxy1.example.com:8080
http://proxy2.example.com:8080
EOF

cat <<EOF > configs/vpn.conf
# Placeholder for VPN configs
# Format depends on your VPN type (e.g. OpenVPN, WireGuard)
EOF

echo "[+] Creating main scripts..."

cat <<'EOF' > setup.sh
#!/data/data/com.termux/files/usr/bin/bash
set -e
pkg update -y && pkg upgrade -y
pkg install -y git curl wget tsu proot net-tools resolv-conf dnsutils \
    python openssh golang nodejs termux-services openssl
pip install --upgrade pip
pip install speedtest-cli
npm install -g localtunnel
chmod +x run.sh watchdog.sh scripts/*.sh
echo "[✓] Setup complete."
EOF

cat <<'EOF' > run.sh
#!/data/data/com.termux/files/usr/bin/bash
cd ~/rotatingheadlessdnsvpn
bash scripts/rotate_dns.sh &
bash scripts/rotate_proxies.sh &
bash scripts/tunnel_start.sh &
bash watchdog.sh &
echo "[✓] VPN/DNS/Proxy rotation started."
EOF

cat <<'EOF' > watchdog.sh
#!/data/data/com.termux/files/usr/bin/bash
LOGFILE=~/rotatingheadlessdnsvpn/logs/watchdog.log
while true; do
  echo "[*] Watchdog ping at $(date)" >> "$LOGFILE"
  pgrep -f rotate_dns.sh > /dev/null || bash scripts/rotate_dns.sh &
  pgrep -f rotate_proxies.sh > /dev/null || bash scripts/rotate_proxies.sh &
  pgrep -f tunnel_start.sh > /dev/null || bash scripts/tunnel_start.sh &
  sleep 60
done
EOF

echo "[+] Adding script files..."

cat <<'EOF' > scripts/rotate_dns.sh
#!/data/data/com.termux/files/usr/bin/bash
DNS_SERVERS=("1.1.1.1" "8.8.8.8" "9.9.9.9")
while true; do
  for dns in "${DNS_SERVERS[@]}"; do
    echo "nameserver $dns" > $PREFIX/etc/resolv.conf
    echo "[+] DNS set to $dns"
    sleep 120
  done
done
EOF

cat <<'EOF' > scripts/rotate_proxies.sh
#!/data/data/com.termux/files/usr/bin/bash
PROXIES=("http://proxy1.example.com:8080" "http://proxy2.example.com:8080")
while true; do
  for proxy in "${PROXIES[@]}"; do
    export http_proxy=$proxy
    export https_proxy=$proxy
    echo "[+] Proxy set to $proxy"
    sleep 120
  done
done
EOF

cat <<'EOF' > scripts/tunnel_start.sh
#!/data/data/com.termux/files/usr/bin/bash
cd ~/go/go-tun2socks
./tun2socks
EOF

chmod +x setup.sh run.sh watchdog.sh scripts/*.sh

echo "[✓] Project structure created."
echo "[*] To finish setup, run:"
echo "     cd rotatingheadlessdnsvpn && bash setup.sh"
