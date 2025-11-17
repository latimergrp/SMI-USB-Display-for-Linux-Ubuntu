# Troubleshooting Guide

This guide covers common issues and their solutions when installing SMI USB Display drivers on Ubuntu 24.04 with kernel 6.14+.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [EVDI Module Issues](#evdi-module-issues)
3. [Secure Boot Issues](#secure-boot-issues)
4. [Display Detection Issues](#display-detection-issues)
5. [Performance Issues](#performance-issues)
6. [Service Issues](#service-issues)

---

## Installation Issues

### Error: "Unable to locate package libdrm-dev"

**Cause:** Package repositories not updated or universe repository not enabled.

**Solution:**
```bash
sudo apt update
sudo add-apt-repository universe
sudo apt install libdrm-dev
```

### Error: "Linux headers not found"

**Cause:** Kernel headers for your running kernel are not installed.

**Solution:**
```bash
sudo apt update
sudo apt install linux-headers-$(uname -r)

# Verify installation
ls /lib/modules/$(uname -r)/build
```

### Error: "DKMS build failed"

**Cause:** Missing build tools or incompatible kernel version.

**Solution:**
```bash
# Install all build dependencies
sudo apt install build-essential dkms linux-headers-$(uname -r) libdrm-dev pkg-config

# Check DKMS build log
cat /var/lib/dkms/evdi/1.14.11/build/make.log

# Try rebuilding
sudo dkms remove evdi/1.14.11 --all
cd ~/Downloads/evdi/module
sudo dkms add .
sudo dkms build evdi/1.14.11
sudo dkms install evdi/1.14.11
```

---

## EVDI Module Issues

### Error: "Module evdi not found"

**Cause:** EVDI module not properly installed or not loaded.

**Solution:**
```bash
# Check DKMS status
dkms status | grep evdi

# If not installed, install it
cd ~/Downloads/evdi/module
sudo dkms add .
sudo dkms build evdi/1.14.11
sudo dkms install evdi/1.14.11

# Load the module
sudo modprobe evdi

# Verify
lsmod | grep evdi
```

### Error: "Key was rejected by service"

**Cause:** Secure Boot is enabled and the module signature is not trusted.

**Solution:** See [Secure Boot Issues](#secure-boot-issues) section.

### EVDI Module Loads but No Display

**Diagnostic Steps:**
```bash
# Check if EVDI is creating devices
cat /sys/devices/evdi/count

# Check module info
modinfo evdi

# Check kernel messages
sudo dmesg | grep evdi

# Check module parameters
cat /sys/module/evdi/parameters/*
```

**Solution:**
```bash
# Try unloading and reloading with debug enabled
sudo modprobe -r evdi
sudo modprobe evdi initial_device_count=4

# Check if SMI service is using it
systemctl status smiusbdisplay.service
```

---

## Secure Boot Issues

### Understanding MOK Enrollment

MOK (Machine Owner Key) enrollment is required when Secure Boot is enabled because custom kernel modules must be signed with a trusted key.

### Error: "Key was rejected by service"

**Step-by-step solution:**

1. **Generate and import MOK:**
```bash
# Import the MOK key
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der

# You'll be prompted to create a password - remember it!
```

2. **Reboot:**
```bash
sudo reboot
```

3. **During boot, you'll see a blue "MOK Management" screen:**
   - Select "Enroll MOK"
   - Select "Continue"
   - Select "Yes"
   - Enter the password you created
   - Select "Reboot"

4. **After reboot, verify:**
```bash
# Check if key is enrolled
mokutil --test-key /var/lib/shim-signed/mok/MOK.der

# Try loading the module
sudo modprobe evdi
lsmod | grep evdi
```

### MOK Enrollment Screen Not Appearing

**Cause:** System may have rebooted too quickly or MOK request was not registered.

**Solution:**
```bash
# Check pending MOK requests
mokutil --list-new

# If empty, re-import
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
sudo reboot
```

### Alternative: Disable Secure Boot

If you don't require Secure Boot:

1. Reboot and enter BIOS/UEFI (usually F2, F10, F12, or Del during boot)
2. Find Security settings
3. Disable Secure Boot
4. Save and exit
5. Boot Ubuntu and try loading EVDI:
```bash
sudo modprobe evdi
lsmod | grep evdi
```

---

## Display Detection Issues

### USB Device Not Recognized

**Check USB connection:**
```bash
# List all USB devices
lsusb

# Look for Silicon Motion device (vendor ID 090c)
lsusb | grep 090c

# If not found, try different USB ports
# Prefer USB 3.0 ports for better performance
```

### Device Recognized but No Display

**Diagnostic steps:**

1. **Check if EVDI module is loaded:**
```bash
lsmod | grep evdi
```

2. **Check SMI service status:**
```bash
systemctl status smiusbdisplay.service
sudo journalctl -u smiusbdisplay.service -n 50
```

3. **Check EVDI device count:**
```bash
cat /sys/devices/evdi/count
# Should show number of virtual displays available
```

4. **Check for SMI processes:**
```bash
ps aux | grep SMI
```

5. **Check X.org logs:**
```bash
grep -i smi /var/log/Xorg.0.log
grep -i evdi /var/log/Xorg.0.log
```

**Solutions:**

```bash
# Restart the SMI service
sudo systemctl restart smiusbdisplay.service

# Manually trigger EVDI device creation
echo 1 | sudo tee /sys/devices/evdi/add

# Check kernel messages
sudo dmesg | tail -50

# Try running the manager manually for debugging
sudo /opt/siliconmotion/SMIUSBDisplayManager
```

### Display Detected but Not Showing in Settings

**For X.org:**
```bash
# Check display detection
xrandr

# If SMI display not listed, try rescanning
xrandr --output HDMI-1 --auto  # Adjust output name
```

**For Wayland:**
```bash
# Switch to X.org session (recommended for SMI displays)
# Log out and select "Ubuntu on Xorg" at login screen
```

---

## Performance Issues

### Slow/Laggy Display

**Causes and Solutions:**

1. **USB bandwidth limitation:**
   - Use USB 3.0 ports (blue ports)
   - Disconnect other high-bandwidth USB devices
   - Avoid USB hubs if possible

2. **Resolution too high:**
   - Lower resolution in display settings
   - Reduce refresh rate if adjustable

3. **Video playback issues:**
   - Hardware acceleration may not work well with USB displays
   - Disable compositing effects

4. **Driver optimization:**
```bash
# Check current driver settings
cat /usr/share/X11/xorg.conf.d/20-smi.conf

# Try disabling PageFlip (already done by installer)
# If still having issues, consult X.org configuration guides
```

### Choppy Video Playback

```bash
# Try different video players
# VLC often works better than browser-based players

# Disable hardware acceleration in browsers:
# Chrome: chrome://flags/#ignore-gpu-blocklist
# Firefox: about:preferences - uncheck "Use hardware acceleration"
```

---

## Service Issues

### Service Fails to Start

**Check service status:**
```bash
systemctl status smiusbdisplay.service
sudo journalctl -u smiusbdisplay.service -xe
```

**Common issues:**

1. **EVDI module not loaded:**
```bash
sudo modprobe evdi
sudo systemctl restart smiusbdisplay.service
```

2. **Missing dependencies:**
```bash
# Check if all files are present
ls -la /opt/siliconmotion/
```

3. **Permission issues:**
```bash
sudo chmod +x /opt/siliconmotion/SMIUSBDisplayManager
sudo systemctl restart smiusbdisplay.service
```

### Service Starts but Doesn't Work

**Debug by running manually:**
```bash
# Stop the service
sudo systemctl stop smiusbdisplay.service

# Run manually to see output
sudo /opt/siliconmotion/SMIUSBDisplayManager

# Check for error messages
```

### Service Doesn't Auto-Start on Boot

**Enable the service:**
```bash
sudo systemctl enable smiusbdisplay.service
sudo systemctl is-enabled smiusbdisplay.service  # Should show "enabled"

# Check for dependency issues
systemctl list-dependencies smiusbdisplay.service
```

---

## Advanced Diagnostics

### Collecting Debug Information

When reporting issues, please collect this information:

```bash
# System information
uname -a
lsb_release -a

# Kernel version
uname -r

# EVDI status
dkms status | grep evdi
lsmod | grep evdi
modinfo evdi

# SMI installation
ls -la /opt/siliconmotion/
systemctl status smiusbdisplay.service

# USB devices
lsusb | grep 090c

# Kernel messages
sudo dmesg | grep -i evdi
sudo dmesg | grep -i smi

# Service logs
sudo journalctl -u smiusbdisplay.service -n 100

# X.org logs (if using Xorg)
grep -i evdi /var/log/Xorg.0.log
```

### Completely Removing and Reinstalling

If all else fails:

```bash
# 1. Uninstall SMI driver
cd /opt/siliconmotion
sudo bash SMIUSBDisplay-driver.*.run uninstall

# 2. Remove EVDI
sudo modprobe -r evdi
sudo dkms remove evdi/1.14.11 --all
sudo rm -rf /usr/src/evdi-1.14.11
sudo rm -rf /var/lib/dkms/evdi

# 3. Clean up
sudo rm -rf /opt/siliconmotion
sudo rm -rf ~/Downloads/evdi

# 4. Reboot
sudo reboot

# 5. Start fresh installation
cd ~/Downloads/SMI-USB-Display-for-Linux-v2.22.1.0
sudo bash install_smi_usb_display.sh
```

---

## Getting Help

If none of these solutions work:

1. **Check the GitHub Issues:** Someone may have encountered the same problem
2. **Collect debug information** using the commands above
3. **Open a new issue** with:
   - Your kernel version (`uname -r`)
   - Ubuntu version (`lsb_release -a`)
   - Complete error messages
   - Output from diagnostic commands
   - Steps to reproduce

---

**Note:** This is an unofficial guide. For official support, contact Silicon Motion, Inc.
