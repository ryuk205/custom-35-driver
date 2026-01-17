#!/bin/bash

# Script to enable Console Autologin + Auto-Startx
# This bypasses LightDM issues by booting to console and launching X11 manually.

USER_NAME="rpi"

echo "Configuring Console Autologin for user '$USER_NAME'..."

# 1. Enable Console Autologin via systemd override
# Create drop-in directory for getty@tty1
DIR="/etc/systemd/system/getty@tty1.service.d"
if [ ! -d "$DIR" ]; then
    sudo mkdir -p "$DIR"
fi

# Write the autologin configuration
cat <<EOF | sudo tee "$DIR/autologin.conf"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo "Console autologin configured."

# 2. Set default boot target to multi-user (console) instead of graphical
sudo systemctl set-default multi-user.target
echo "Boot target set to Console (multi-user.target)."

# 3. Add startx to .bash_profile
PROFILE="/home/$USER_NAME/.bash_profile"

# Create .bash_profile if it doesn't exist
if [ ! -f "$PROFILE" ]; then
    touch "$PROFILE"
    chown $USER_NAME:$USER_NAME "$PROFILE"
fi

# specific magic check to only startx on tty1 (the main screen) and if not already running
# We must source .profile manually because bash_profile overrides it
STARTX_CMD='
if [ -f ~/.profile ]; then
    . ~/.profile
fi

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    echo "Starting X11..."
    startx
fi
'

if grep -q "Starting X11" "$PROFILE"; then
    echo ".bash_profile already configured."
else
    echo "$STARTX_CMD" >> "$PROFILE"
    echo "Added autostart logic to $PROFILE"
fi

echo "Configuration complete."
echo "The system will now boot to console, log in automatically, and type 'startx' for you."
echo "Please reboot: sudo reboot"
