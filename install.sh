#!/bin/bash

# Custom Installation Script for 3.5" RPi Touch Screen (MPI3508/ILI9486)
# Acts as a secondary display using fbcp.

set -e

echo "Starting installation..."

# Determine config.txt location
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
    OVERLAYS_DIR="/boot/firmware/overlays"
    echo "Detected newer OS structure. Using config: $CONFIG_FILE"
else
    CONFIG_FILE="/boot/config.txt"
    OVERLAYS_DIR="/boot/overlays"
    echo "Using legacy config: $CONFIG_FILE"
fi

# 1. Install Dependencies
echo "Installing dependencies..."
sudo apt-get update
# Check for header files and install if missing
# Check for header files and install if missing
if [ ! -d "/opt/vc/include" ] || [ ! -f "/opt/vc/lib/libbcm_host.so" ]; then
    echo "Headers/Libraries not found or incompatible. Compiling Userland from source..."
    
    # Install dependencies for userland
    sudo apt-get install -y build-essential

    echo "Cloning raspberrypi/userland..."
    rm -rf userland
    git clone --depth 1 https://github.com/raspberrypi/userland.git
    cd userland
    
    echo "Building Userland (this may take a few minutes)..."
    ./buildme --aarch64
    
    cd ..
    # buildme installs to /opt/vc automatically
    
    # Add library path
    echo "/opt/vc/lib" | sudo tee /etc/ld.so.conf.d/00-vmcs.conf
    sudo ldconfig
fi

sudo apt-get install -y cmake git

# 2. Enable SPI in config.txt if not already enabled
if ! grep -q "dtparam=spi=on" "$CONFIG_FILE"; then
    echo "Enabling SPI..."
    echo "dtparam=spi=on" | sudo tee -a "$CONFIG_FILE"
fi

# 3. Install Device Tree Overlay
echo "Installing Device Tree Overlay..."
if [ -f "tft35a.dtbo" ]; then
    # Ensure overlays dir exists
    if [ ! -d "$OVERLAYS_DIR" ]; then
         # Fallback if detection was weird or dir missing
         OVERLAYS_DIR="/boot/overlays"
    fi
    sudo cp tft35a.dtbo "$OVERLAYS_DIR/"
else
    echo "Error: tft35a.dtbo not found in current directory!"
    exit 1
fi

# Disable KMS driver (incompatible with rpi-fbcp)
echo "Disabling VC4 KMS driver..."
# Match line starting with optional whitespace, then dtoverlay=vc4-kms-v3d
sudo sed -i 's/^\s*dtoverlay=vc4-kms-v3d/#dtoverlay=vc4-kms-v3d/' "$CONFIG_FILE"
# Also disable fkms if present, just in case
sudo sed -i 's/^\s*dtoverlay=vc4-fkms-v3d/#dtoverlay=vc4-fkms-v3d/' "$CONFIG_FILE"

# Add extra settings for framebuffers and KMS bypass
if ! grep -q "disable_fw_kms_setup=1" "$CONFIG_FILE"; then
    echo "disable_fw_kms_setup=1" | sudo tee -a "$CONFIG_FILE"
fi
if ! grep -q "max_framebuffers=2" "$CONFIG_FILE"; then
    echo "max_framebuffers=2" | sudo tee -a "$CONFIG_FILE"
fi

# Configure config.txt for the display overlay
# Remove old configuration if exists (basic check)
sudo sed -i '/dtoverlay=tft35a/d' "$CONFIG_FILE"
echo "dtoverlay=tft35a:rotate=0,speed=16000000,fps=60" | sudo tee -a "$CONFIG_FILE"

# 4. Configure HDMI for 320x480
echo "Configuring HDMI resolution..."
# Backup config.txt
sudo cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# Append HDMI settings
cat <<EOF | sudo tee -a "$CONFIG_FILE"
# Custom HDMI settings for 3.5 inch display mirroring
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 480 60 6 0 0 0
hdmi_drive=2
EOF

# 5. Compile and Install rpi-fbcp
echo "Compiling rpi-fbcp..."
if [ -d "rpi-fbcp" ]; then
    rm -rf rpi-fbcp
fi
git clone https://github.com/tasanakorn/rpi-fbcp
cd rpi-fbcp
mkdir build
cd build
cmake ..
make
sudo install fbcp /usr/local/bin/fbcp
cd ../..

# 6. Install Systemd Service
echo "Installing fbcp service..."
if [ -f "fbcp.service" ]; then
    sudo cp fbcp.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable fbcp.service
    sudo systemctl start fbcp.service
else
    echo "Error: fbcp.service not found!"
    exit 1
fi

echo "Installation complete! Please reboot your Raspberry Pi."
echo "Usage: sudo reboot"
