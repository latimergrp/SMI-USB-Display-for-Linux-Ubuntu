# Command Reference

Quick reference for common commands used with SMI USB Display drivers.

## Installation

```bash
# Run installer
sudo bash install_smi_fixed.sh

# Check installation
systemctl status smiusbdisplay.service
lsmod | grep evdi
```

## EVDI Module

```bash
# Load module
sudo modprobe evdi

# Unload module
sudo modprobe -r evdi

# Check if loaded
lsmod | grep evdi

# Module info
modinfo evdi

# DKMS status
dkms status | grep evdi

# Rebuild module
sudo dkms build evdi/1.14.11
sudo dkms install evdi/1.14.11
```

## Service Management

```bash
# Start service
sudo systemctl start smiusbdisplay.service

# Stop service
sudo systemctl stop smiusbdisplay.service

# Restart service
sudo systemctl restart smiusbdisplay.service

# Enable auto-start
sudo systemctl enable smiusbdisplay.service

# Disable auto-start
sudo systemctl disable smiusbdisplay.service

# Check status
systemctl status smiusbdisplay.service

# View logs (real-time)
sudo journalctl -u smiusbdisplay.service -f

# View logs (last 50 lines)
sudo journalctl -u smiusbdisplay.service -n 50

# View logs (since boot)
sudo journalctl -u smiusbdisplay.service -b
```

## Display Management

```bash
# List displays
xrandr

# Get display info
xrandr --verbose

# Configure display
xrandr --output VIRTUAL-1 --mode 1920x1080

# Detect displays
xrandr --auto
```

## USB Device

```bash
# List USB devices
lsusb

# Find SMI devices (vendor ID: 090c)
lsusb | grep 090c

# Detailed USB info
lsusb -v -d 090c:

# Check USB device in dmesg
sudo dmesg | grep -i usb

# Trigger udev for device
sudo udevadm trigger --action=add
```

## EVDI Debugging

```bash
# Check EVDI device count
cat /sys/devices/evdi/count

# Get EVDI version
cat /sys/devices/evdi/version

# Add virtual display
echo 1 | sudo tee /sys/devices/evdi/add

# Remove all displays
echo 1 | sudo tee /sys/devices/evdi/remove_all

# Set log level (0-8, higher = more verbose)
echo 8 | sudo tee /sys/devices/evdi/loglevel

# View EVDI kernel messages
sudo dmesg | grep evdi
```

## Kernel Messages

```bash
# Watch kernel messages in real-time
sudo dmesg -w

# Filter for EVDI
sudo dmesg | grep -i evdi

# Filter for SMI
sudo dmesg | grep -i smi

# Filter for USB
sudo dmesg | grep -i usb

# Last 20 messages
sudo dmesg | tail -20
```

## Configuration Files

```bash
# View EVDI module config
cat /etc/modprobe.d/evdi.conf

# View EVDI auto-load config
cat /etc/modules-load.d/evdi.conf

# View udev rules
cat /etc/udev/rules.d/99-smiusbdisplay.rules

# View X.org config
cat /usr/share/X11/xorg.conf.d/20-smi.conf

# View systemd service
cat /lib/systemd/system/smiusbdisplay.service
```

## System Information

```bash
# Kernel version
uname -r

# Ubuntu version
lsb_release -a

# System architecture
uname -m

# Check Secure Boot status
mokutil --sb-state

# List kernel headers
ls /usr/src/linux-headers-*
```

## Secure Boot / MOK

```bash
# Check Secure Boot status
mokutil --sb-state

# List enrolled keys
mokutil --list-enrolled

# Test if key is enrolled
mokutil --test-key /var/lib/shim-signed/mok/MOK.der

# Import MOK key
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der

# List pending MOK requests
mokutil --list-new
```

## Troubleshooting

```bash
# Check for errors
sudo journalctl -p err -b

# Check all SMI files
ls -la /opt/siliconmotion/

# Run manager manually (for debugging)
sudo systemctl stop smiusbdisplay.service
sudo /opt/siliconmotion/SMIUSBDisplayManager

# Check X.org logs
grep -i evdi /var/log/Xorg.0.log
grep -i smi /var/log/Xorg.0.log

# Verify all dependencies
sudo apt install build-essential dkms linux-headers-$(uname -r) libdrm-dev pkg-config
```

## Uninstallation

```bash
# Uninstall SMI driver
cd /opt/siliconmotion
sudo bash SMIUSBDisplay-driver.*.run uninstall

# Remove EVDI
sudo modprobe -r evdi
sudo dkms remove evdi/1.14.11 --all
sudo rm -rf /usr/src/evdi-1.14.11

# Clean up
sudo rm -rf /opt/siliconmotion
sudo rm -f /etc/udev/rules.d/99-smiusbdisplay.rules
sudo rm -f /etc/modprobe.d/evdi.conf
sudo rm -f /etc/modules-load.d/evdi.conf
```

## Performance Tuning

```bash
# Check current resolution
xrandr | grep '*'

# Lower resolution for better performance
xrandr --output VIRTUAL-1 --mode 1600x900

# Check USB speed
lsusb -t

# Monitor CPU usage
top
htop  # If installed
```

## Backup / Export

```bash
# Backup SMI installation
sudo tar czf smi_backup.tar.gz /opt/siliconmotion/

# Backup EVDI configuration
sudo tar czf evdi_config.tar.gz \
    /etc/modprobe.d/evdi.conf \
    /etc/modules-load.d/evdi.conf \
    /usr/src/evdi-1.14.11
```

## Quick Diagnostics

Run this to collect info for bug reports:

```bash
# Create diagnostic report
{
    echo "=== System Info ==="
    uname -a
    lsb_release -a
    echo
    echo "=== EVDI Status ==="
    dkms status | grep evdi
    lsmod | grep evdi
    cat /sys/devices/evdi/count 2>/dev/null || echo "EVDI not loaded"
    echo
    echo "=== USB Devices ==="
    lsusb | grep 090c
    echo
    echo "=== Service Status ==="
    systemctl status smiusbdisplay.service --no-pager
    echo
    echo "=== Recent Logs ==="
    sudo journalctl -u smiusbdisplay.service -n 20 --no-pager
    echo
    echo "=== Kernel Messages ==="
    sudo dmesg | grep -i evdi | tail -10
} > diagnostic_report.txt

cat diagnostic_report.txt
```

---

**Tip:** Bookmark this page for quick reference!
