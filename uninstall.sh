#!/bin/bash

# Uninstall Script for Custom 3.5" Display Driver
# Reverts changes made by install.sh and restore default HDMI behavior.

echo "Uninstalling..."

# Determine config.txt location
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
    echo "Using config: $CONFIG_FILE"
else
    CONFIG_FILE="/boot/config.txt"
    echo "Using legacy config: $CONFIG_FILE"
fi

# 1. Stop and Disable Service
if systemctl is-active --quiet fbcp.service; then
    echo "Stopping fbcp service..."
    sudo systemctl stop fbcp.service
fi
if systemctl is-enabled --quiet fbcp.service; then
    echo "Disabling fbcp service..."
    sudo systemctl disable fbcp.service
fi

if [ -f "/etc/systemd/system/fbcp.service" ]; then
    sudo rm /etc/systemd/system/fbcp.service
    sudo systemctl daemon-reload
    echo "Service removed."
fi

# 2. Remove binary
if [ -f "/usr/local/bin/fbcp" ]; then
    sudo rm /usr/local/bin/fbcp
    echo "Binary removed."
fi

# 1b. Revert Autostart Changes (if applied)
echo "Reverting Autostart configuration..."
# Remove Console Autologin override
if [ -d "/etc/systemd/system/getty@tty1.service.d" ]; then
    sudo rm -rf "/etc/systemd/system/getty@tty1.service.d"
    echo "Removed Console Autologin override."
fi

# Restore default graphical boot target
sudo systemctl set-default graphical.target
echo "Restored graphical boot target."

# Clean .bash_profile (Removing the startx block)
if [ -f "/home/rpi/.bash_profile" ]; then
    cp /home/rpi/.bash_profile /home/rpi/.bash_profile.uninstall_bak
    echo "Backed up .bash_profile to .bash_profile.uninstall_bak."
    echo "NOTE: Please manually check ~/.bash_profile and remove the 'startx' logic."
fi

# 3. Restore config.txt (This is tricky, simplistic approach: revert to backup if exists, else manual)

# Remove tft35a overlay
if grep -q "dtoverlay=tft35a" "$CONFIG_FILE"; then
    sudo sed -i '/dtoverlay=tft35a/d' "$CONFIG_FILE"
    echo "Removed tft35a overlay."
fi

# Re-enable VC4 KMS driver
# Finds #dtoverlay=vc4-kms-v3d and removes the #
if grep -q "#dtoverlay=vc4-kms-v3d" "$CONFIG_FILE"; then
    sudo sed -i 's/^#dtoverlay=vc4-kms-v3d/dtoverlay=vc4-kms-v3d/' "$CONFIG_FILE"
    # Also handle fkms if we touched it
    sudo sed -i 's/^#dtoverlay=vc4-fkms-v3d/dtoverlay=vc4-fkms-v3d/' "$CONFIG_FILE"
    echo "Re-enabled VC4 KMS driver."
fi

# Remove Custom HDMI settings block
# We look for the comment header and delete lines following it
if grep -q "# Custom HDMI settings for 3.5 inch display mirroring" "$CONFIG_FILE"; then
    # Delete the lines we added. Since we know exact lines, we can delete by pattern or block.
    # Simple approach: delete specific known lines if they match our script's output
    sudo sed -i '/# Custom HDMI settings for 3.5 inch display mirroring/d' "$CONFIG_FILE"
    sudo sed -i '/hdmi_force_hotplug=1/d' "$CONFIG_FILE"
    # hdmi_group=2 might be used by user elsewhere, be careful? 
    # Our script blindly appended. Deleting by pattern is safer.
    sudo sed -i '/hdmi_cvt=480 320/d' "$CONFIG_FILE"
    sudo sed -i '/hdmi_cvt=320 480/d' "$CONFIG_FILE"
    
    # Remove extra settings added by install.sh
    sudo sed -i '/disable_fw_kms_setup=1/d' "$CONFIG_FILE"
    sudo sed -i '/max_framebuffers=2/d' "$CONFIG_FILE"
    
    # These are generic, deleting them might affect other setups if user manually added them
    # But since we appended them, likely safe to remove generic matches found at end of file.
    # For now, let's aggressively clean what we likely added.
    sudo sed -i '/hdmi_group=2/d' "$CONFIG_FILE"
    sudo sed -i '/hdmi_mode=87/d' "$CONFIG_FILE"
    sudo sed -i '/hdmi_drive=2/d' "$CONFIG_FILE"
    
    echo "Removed custom HDMI and extra display settings."
fi

# 4. Remove Overlay file
if [ -f "/boot/overlays/tft35a.dtbo" ] || [ -f "/boot/firmware/overlays/tft35a.dtbo" ]; then
     # Check both locations just in case
     sudo rm -f /boot/overlays/tft35a.dtbo
     sudo rm -f /boot/firmware/overlays/tft35a.dtbo
     echo "Removed tft35a.dtbo."
fi

echo "Uninstallation complete."
echo "IMPORTANT: If you disabled Wayland/X11 in raspi-config, you may need to re-enable it manually."
echo "Please reboot your Raspberry Pi: sudo reboot"
