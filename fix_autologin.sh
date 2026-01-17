#!/bin/bash

# Script to FORCE enable desktop autologin for user 'rpi'
# Usage: sudo ./fix_autologin.sh

echo "Configuring LightDM Autologin..."

# Ensure lightdm is installed
if ! command -v lightdm &> /dev/null; then
    echo "LightDM not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y lightdm
fi

# Configuration file path
LIGHTDM_CONF="/etc/lightdm/lightdm.conf"

# Backup existing config
if [ -f "$LIGHTDM_CONF" ]; then
    sudo cp "$LIGHTDM_CONF" "$LIGHTDM_CONF.bak"
    echo "Backed up existing config to $LIGHTDM_CONF.bak"
else
    # Create dir if missing
    sudo mkdir -p /etc/lightdm
fi

# Create/Overwrite config with specific autologin settings
# We write a clean config block for [Seat:*] to ensure no conflicts
cat <<EOF | sudo tee "$LIGHTDM_CONF"
[Seat:*]
autologin-user=rpi
autologin-user-timeout=0
user-session=startx
display-setup-script=/usr/bin/xset s off && /usr/bin/xset -dpms
greeter-session=pi-greeter
xserver-command=X -s 0 -dpms
EOF

echo "Autologin configuration written."

# Ensure graphical target is default
sudo systemctl set-default graphical.target

echo "Done. Please reboot to test: sudo reboot"
