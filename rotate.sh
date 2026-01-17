#!/bin/bash

# Script to rotate the 3.5" display and update HDMI resolution accordingly
# Usage: sudo ./rotate.sh [0|90|180|270]

if [ -z "$1" ]; then
    echo "Usage: sudo ./rotate.sh [0|90|180|270]"
    exit 1
fi

ROTATION=$1

# Determine config.txt location
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi

echo "Updating configuration in $CONFIG_FILE..."

# Update Rotation in dtoverlay
# Regex matches dtoverlay=tft35a:rotate=* and replaces it
if grep -q "dtoverlay=tft35a" "$CONFIG_FILE"; then
    sudo sed -i "s/dtoverlay=tft35a:rotate=[0-9]*/dtoverlay=tft35a:rotate=$ROTATION/" "$CONFIG_FILE"
else
    echo "Error: tft35a overlay not found in config.txt"
    exit 1
fi

# Update HDMI resolution based on orientation
if [ "$ROTATION" == "0" ] || [ "$ROTATION" == "180" ]; then
    echo "Setting Portrait mode (320x480)..."
    WIDTH=320
    HEIGHT=480
elif [ "$ROTATION" == "90" ] || [ "$ROTATION" == "270" ]; then
    echo "Setting Landscape mode (480x320)..."
    WIDTH=480
    HEIGHT=320
else
    echo "Invalid rotation value. Use 0, 90, 180, or 270."
    exit 1
fi

# Update hdmi_cvt line
# hdmi_cvt=width height 60 6 0 0 0
sudo sed -i "s/^hdmi_cvt=.*/hdmi_cvt=$WIDTH $HEIGHT 60 6 0 0 0/" "$CONFIG_FILE"

echo "Rotation set to $ROTATION degrees."
echo "Resolution set to ${WIDTH}x${HEIGHT}."
echo "Please reboot to apply changes: sudo reboot"
