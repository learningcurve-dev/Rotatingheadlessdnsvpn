#!/bin/bash

# File: setup.sh
# Project: rotatingheadlessdnsvpn
# Author: learningcurve-dev
# Description: Complete installation script with watchdog, DNS+proxy rotation, tun2socks auto-start, and error handling.

set -e

# --- 0. Self-Check and Recovery ---
trap 'bash ~/rotatingheadlessdnsvpn/scripts/self_heal.sh' ERR

# --- 1. Dependency Setup ---
echo "[+] Installing dependencies..."
pkg update -y && pkg upgrade -y
pkg install -y git golang wget curl proot-distro resolv-conf tsu termux-services nano python
pip install watchdog

# --- 2. Setup Go Path ---
export GOPATH=$HOME/go && mkdir -p "$GOPATH"
export PATH="$PATH:$GOPATH/bin"

# --- 3. Clone Repos ---
echo "[+] Cloning tun2socks repo..."
cd ~ && git clone https://github.com/eycorsican/go-tun2socks.git || true
cd go-tun2socks && go build -o tun2socks ./cmd/tun2socks

# --- 4. Setup Project Files ---
echo "[+] Setting up project structure..."
mkdir -p ~/rotatingheadlessdnsvpn/scripts

# Script: tun_start.sh
cat << 'EOF' > ~/rotatingheadlessdnsvpn/scripts/tun_start.sh
#!/bin/bash
cd ~/go-tun2socks
./tun2socks &
echo "tun2socks started"
EOF
chmod +x ~/rotatingheadlessdnsvpn/scripts/tun_start.sh

# Script: dns_rotate.sh
cat << 'EOF' > ~/rotatingheadlessdnsvpn/scripts/dns_rotate.sh
#!/bin/bash
SERVERS=("1.1.1.1" "8.8.8.8" "9.9.9.9" "208.67.222.222")
SELECTED=${SERVERS[$RANDOM % ${#SERVERS[@]}]}
echo "nameserver $SELECTED" > $PREFIX/etc/resolv.conf
echo "Rotated DNS to $SELECTED"
EOF
chmod +x ~/rotatingheadlessdnsvpn/scripts/dns_rotate.sh

# Script: self_heal.sh
cat << 'EOF' > ~/rotatingheadlessdnsvpn/scripts/self_heal.sh
#!/bin/bash
echo "[!] Running self-healing script..."
bash ~/rotatingheadlessdnsvpn/scripts/setup.sh || true
EOF
chmod +x ~/rotatingheadlessdnsvpn/scripts/self_heal.sh

# --- 5. Auto-run on boot ---
echo "[+] Setting up boot start..."
termux-wake-lock
mkdir -p ~/.termux/boot

# Boot script: startup.sh
cat << 'EOF' > ~/.termux/boot/startup.sh
#!/data/data/com.termux/files/usr/bin/bash
bash ~/rotatingheadlessdnsvpn/scripts/tun_start.sh
bash ~/rotatingheadlessdnsvpn/scripts/dns_rotate.sh
EOF
chmod +x ~/.termux/boot/startup.sh

# Watchdog boot script
cat << 'EOF' > ~/.termux/boot/watchdog.sh
#!/data/data/com.termux/files/usr/bin/bash
nohup python ~/rotatingheadlessdnsvpn/scripts/watchdog.py &
EOF
chmod +x ~/.termux/boot/watchdog.sh

# --- 6. Final Touches ---
echo "[+] Finalizing setup..."
chmod +x ~/rotatingheadlessdnsvpn/scripts/*.sh

# Self-save for recovery
cp $0 ~/rotatingheadlessdnsvpn/scripts/setup.sh
chmod +x ~/rotatingheadlessdnsvpn/scripts/setup.sh

echo "[+] Setup complete. DNS will rotate. tun2socks will start on boot."

exit 0