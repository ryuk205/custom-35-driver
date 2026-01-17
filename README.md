# Custom 3.5" RPi Display Driver

This directory contains custom drivers and scripts to enable a generic 3.5-inch SPI Touch Screen (MPI3508/ILI9486) on Raspberry Pi 4 (specifically configured for Debian Trixie / Raspberry Pi OS Bookworm+).

## Configuration Note (Stability)
The scripts are optimized for hardware stability on the Raspberry Pi 4:
- **SPI Speed**: Default is **16MHz**. While the screen supports up to 64MHz, higher speeds often cause the console to freeze or the display to hang.
- **Orientation**: Default is **Portrait (0°)** with a resolution of **320x480**.

## Features
- **Primary Display**: Makes the SPI screen the main output using `rpi-fbcp`.
- **64-bit Compatible**: Compiles necessary `bcm_host` libraries from source for modern OS compatibility (Debian Trixie/Bookworm).
- **Stability Focused**: Automatically configures `disable_fw_kms_setup` and `max_framebuffers` to prevent driver hangs.
- **Rotation Support**: Easy script to rotate screen and resolution.
- **Clean Uninstall**: Script to revert all changes safely.
  
## Original Drivers:
- Vendor repo: https://github.com/ryuk205/custom-35-driver
- Docs for display: https://www.lcdwiki.com/3.5inch_RPi_Display


## Prerequisites
- Raspberry Pi 4/5 running Raspberry Pi OS (Debian Trixie/Bookworm).

## Installation

1.  Navigate to this directory:
    ```bash
    cd ~/Documents/AntiGravity/drivers/custom-35-driver
    ```

2.  Make scripts executable:
    ```bash
    chmod +x install.sh rotate.sh uninstall.sh enable_console_autostart.sh
    ```

3.  Run the installer:
    ```bash
    sudo ./install.sh
    ```
    *This will compile Userland and fbcp from source.*

4.  **Configure Autostart** (Crucial for 3.5" screen):
    The standard Desktop login manager often fails with this display. Use this script to set up "Console Autologin + Auto-Startx":
    ```bash
    sudo ./enable_console_autostart.sh
    ```
    *This ensures the desktop appears on the 3.5" screen on every boot.*

5.  **Reboot** when prompted.

## Usage

### Rotating the Screen
To rotate the display (0, 90, 180, 270 degrees):
```bash
# Example: Landscape
sudo ./rotate.sh 90

# Example: Portrait (Default)
sudo ./rotate.sh 0
```
*Reboot required after rotation.*

## Uninstallation
To revert all changes and restore default HDMI output:

```bash
sudo ./uninstall.sh
```
This will:
- Stop and remove the `fbcp` service.
- Revert Autostart changes (restores standard graphical boot).
- Re-enable the default KMS video driver (`vc4-kms-v3d`).
- Restore `config.txt` to default HDMI and clean up display specific settings.
 
## 📜 Acknowledgments
These drivers and overlays are adapted from various sources for legacy 3.5" SPI displays. Since this package utilizes a modified/stable set of configurations, you may want to refer to the **[Official Raspberry Pi Firmware (Specific Version)](https://github.com/raspberrypi/firmware/tree/2ba11f2a07760588546821aed578010252c9ecb3)** which matches the environment used during development.
This code was made with Google AntiGravity IDE, it is AI Generated. Used AI to recode the drivers because I did not trust the vedor code, AI was effective to research about the hardware.
