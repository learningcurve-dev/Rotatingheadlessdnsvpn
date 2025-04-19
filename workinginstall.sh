mkdir -p ~/bin && cd ~/bin

cat > setup_vpn.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

echo "[+] Updating Termux and installing core packages..."
pkg update -y && pkg upgrade -y
pkg install -y git golang wget curl proot-distro resolv-conf tsu termux-services nano python clang make termux-boot

echo "[+] Installing Python modules..."
pip install --upgrade pip
pip install psutil

echo "[+] Setting up Go environment..."
export GOPATH=$HOME/go
mkdir -p "$GOPATH"
export PATH="$PATH:$GOPATH/bin"

echo "[+] Cloning and building go-tun2socks..."
rm -rf ~/go-tun2socks
git clone https://github.com/eycorsican/go-tun2socks.git ~/go-tun2socks
cd ~/go-tun2socks || exit 1
go build -o tun2socks ./cmd/tun2socks

echo "[+] Cloning and building microsocks SOCKS5 proxy..."
cd ~
rm -rf microsocks
git clone https://github.com/rofl0r/microsocks.git
cd microsocks || exit 1
make

echo "[+] Creating project structure..."
mkdir -p ~/headlessdnsvpn/scripts

echo "[+] Setup complete. Run your VPN logic from ~/headlessdnsvpn/scripts"
EOF

chmod +x setup_vpn.sh
./setup_vpn.sh