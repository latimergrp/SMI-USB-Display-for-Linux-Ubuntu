# SMI USB Display Driver for Ubuntu 24.04 (Kernel 6.14+)

A solution for installing Silicon Motion USB Display drivers on Ubuntu 24.04 with newer kernels (6.14+) that are incompatible with the bundled EVDI 1.14.7 module.

## Problem

The official SMI USB Display driver (v2.22.1.0) bundles EVDI kernel module version 1.14.7, which fails to build on Linux kernel 6.14+ due to kernel API changes. This results in installation failure:

```
ERROR: Failed to install evdi to the kernel tree.
```

## Solution

This repository provides a patched installation script that:

1. Installs the latest EVDI (1.14.11+) from source, which is compatible with kernel 6.14+
2. Patches the SMI installer to use the system-installed EVDI instead of the bundled version
3. Completes the SMI driver installation successfully

## Compatibility

- **Tested on:** Ubuntu 24.04.3 LTS
- **Kernel:** 6.14.0-35-generic (should work on 6.14+)
- **HDMI Device:** WAVLINK WL-UG7602H-FBA USB 3.0 to Dual HDMI
- **SMI Driver:** v2.22.1.0
- **Architecture:** x86_64

## Prerequisites

- Ubuntu 24.04 (or similar Debian-based distribution)
- Kernel 6.14 or newer
- Secure Boot (optional - script handles MOK enrollment)
- Root/sudo access

## Installation

### Step 1: Download the Official SMI Driver

Download the Silicon Motion USB Display driver from the official source:
- Driver version: 2.22.1.0
- Extract to a directory (e.g., `~/Downloads/SMI-USB-Display-for-Linux-v2.22.1.0/`)

### Step 2: Clone This Repository

```bash
cd ~/Downloads/SMI-USB-Display-for-Linux-v2.22.1.0/
git clone https://github.com/latimergrp/smi-usb-display-ubuntu
cd smi-usb-display-ubuntu
```

### Step 3: Run the Installation Script

```bash
sudo bash install_smi_usb_display.sh
```

The script will:
1. Install required dependencies
2. Build and install EVDI 1.14.11 from source
3. Handle Secure Boot MOK enrollment (if needed)
4. Patch and run the SMI installer
5. Configure the systemd service

### Step 4: Reboot and Connect Display

```bash
sudo reboot
```

After reboot, connect your SMI USB display device. It should be automatically detected.

## Secure Boot Note

If Secure Boot is enabled, the script will:
1. Generate a Machine Owner Key (MOK)
2. Prompt you to create a password
3. Reboot to the MOK enrollment screen

**During the blue MOK Management screen:**
1. Select "Enroll MOK"
2. Select "Continue"
3. Select "Yes"
4. Enter the password you created
5. Reboot

After rebooting, run the installation script again to complete the installation.

## Verification

Check if the installation was successful:

```bash
# Check if EVDI module is loaded
lsmod | grep evdi

# Check if SMI service is running
systemctl status smiusbdisplay.service

# Check driver installation
ls -la /opt/siliconmotion/

# Monitor service logs
sudo journalctl -u smiusbdisplay.service -f
```

## Troubleshooting

### EVDI Module Not Loading

If the EVDI module fails to load:

```bash
# Check DKMS status
dkms status

# Try rebuilding
sudo dkms remove evdi/1.14.11 --all
cd ~/Downloads/evdi
cd module
sudo dkms add .
sudo dkms build evdi/1.14.11
sudo dkms install evdi/1.14.11

# Load module
sudo modprobe evdi
```

### Secure Boot Key Rejected

If you see "Key was rejected by service":

```bash
# Check MOK status
mokutil --sb-state

# Re-enroll the key
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
sudo reboot
```

### Display Not Detected

1. Check if USB device is recognized:
```bash
lsusb | grep 090c
```

2. Check kernel messages:
```bash
sudo dmesg | tail -50
```

3. Restart the service:
```bash
sudo systemctl restart smiusbdisplay.service
```

### Build Dependencies Missing

If you get build errors, ensure all dependencies are installed:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r) libdrm-dev pkg-config git
```

## Technical Details

### Why This is Needed

The official SMI driver includes EVDI 1.14.7, which has compatibility issues with kernel 6.14+ due to changes in the DRM (Direct Rendering Manager) subsystem. Specifically:

- Kernel 6.14 introduced breaking changes to `drm_plane` and `drm_framebuffer` APIs
- EVDI 1.14.7 uses deprecated kernel functions
- EVDI 1.14.11+ includes patches for kernel 6.14+ compatibility

### What the Script Does

1. **EVDI Installation:**
   - Clones the latest EVDI from GitHub (DisplayLink/evdi)
   - Builds the userspace library
   - Installs the kernel module via DKMS
   - Signs the module for Secure Boot compatibility

2. **Installer Patching:**
   - Extracts the SMI installer
   - Replaces the `install_evdi()` function to use system EVDI
   - Disables conflicting module checks
   - Preserves all other SMI driver functionality

3. **Service Configuration:**
   - Installs SMI binaries to `/opt/siliconmotion/`
   - Creates systemd service for automatic startup
   - Configures udev rules for device detection
   - Sets up X.org configuration

## File Structure

```
.
├── README.md                    # This file
├── install_smi_usb_display.sh         # Main installation script
├── TROUBLESHOOTING.md          # Detailed troubleshooting guide
├── LICENSE                      # License information
└── docs/
    └── TECHNICAL.md            # Technical details and architecture
```

## Uninstallation

To remove the SMI driver:

```bash
cd /opt/siliconmotion
sudo bash SMIUSBDisplay-driver.2.22.1.0.run uninstall
```

To also remove EVDI:

```bash
sudo dkms remove evdi/1.14.11 --all
sudo rm -rf /usr/src/evdi-1.14.11
sudo rm -rf ~/Downloads/evdi
```

## Known Issues

- **Wayland compatibility:** The driver works best with X.org. Wayland support is limited.
- **Multi-monitor:** Some configurations may require manual X.org configuration.
- **Performance:** USB display performance is inherently limited by USB bandwidth.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with a clear description

## Related Projects

- [DisplayLink/evdi](https://github.com/DisplayLink/evdi) - The EVDI kernel module
- [AdnanHodzic/displaylink-debian](https://github.com/AdnanHodzic/displaylink-debian) - DisplayLink driver installer

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The SMI USB Display driver is proprietary software owned by Silicon Motion, Inc.

## Credits

- Solution developed for Ubuntu 24.04 with kernel 6.14+ compatibility
- EVDI module by DisplayLink
- Original SMI driver by Silicon Motion, Inc.

## Disclaimer

This is an unofficial installation method. Use at your own risk. The author is not affiliated with Silicon Motion, Inc. or DisplayLink.

## Support

For issues and questions:
- Open an issue on GitHub
- Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide
- Review closed issues for similar problems

---

**Last Updated:** November 2025  
**Version:** 1.0.0
