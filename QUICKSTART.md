# Quick Start Guide

**TL;DR:** Install SMI USB Display driver on Ubuntu 24.04 with kernel 6.14+ in under 10 minutes.

## Prerequisites

- Ubuntu 24.04 LTS
- Kernel 6.14 or newer
- Internet connection
- Sudo access

## Installation (5 Steps)

### 1. Download SMI Driver

Download the official Silicon Motion USB Display driver v2.22.1.0 and extract it to a folder.

### 2. Clone This Repository

```bash
cd ~/Downloads/SMI-USB-Display-for-Linux-v2.22.1.0/
git clone https://github.com/YOUR_USERNAME/smi-usb-display-ubuntu.git
cd smi-usb-display-ubuntu
```

### 3. Run the Installer

```bash
sudo bash install_smi_usb_display.sh
```

### 4. Handle Secure Boot (if prompted)

If you see a MOK enrollment prompt:
- Create a password when asked
- Reboot
- In the blue MOK screen: **Enroll MOK → Continue → Yes → Enter password → Reboot**
- Run the installer again after reboot

### 5. Connect Display

```bash
sudo reboot
```

After reboot, connect your SMI USB display. It should work automatically!

## Verify Installation

```bash
# Check EVDI module
lsmod | grep evdi

# Check service
systemctl status smiusbdisplay.service

# Check display
xrandr  # Should show SMI display
```

## Troubleshooting

**Display not detected?**
```bash
sudo systemctl restart smiusbdisplay.service
sudo journalctl -u smiusbdisplay.service -f
```

**Build errors?**
```bash
sudo apt update
sudo apt install build-essential dkms linux-headers-$(uname -r)
```

**More help?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Common Commands

```bash
# Restart service
sudo systemctl restart smiusbdisplay.service

# View logs
sudo journalctl -u smiusbdisplay.service -f

# Check USB device
lsusb | grep 090c

# Uninstall
cd /opt/siliconmotion
sudo bash SMIUSBDisplay-driver.*.run uninstall
```

---

**Need more details?** See the full [README.md](README.md)
