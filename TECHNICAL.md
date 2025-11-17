# Technical Documentation

This document provides technical details about the SMI USB Display driver installation process and the modifications required for kernel 6.14+ compatibility.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [The EVDI Problem](#the-evdi-problem)
3. [Solution Design](#solution-design)
4. [Installation Process](#installation-process)
5. [Code Analysis](#code-analysis)
6. [Kernel Module Details](#kernel-module-details)

---

## Architecture Overview

### Component Stack

```
┌─────────────────────────────────────┐
│   Display Applications (X.org)      │
├─────────────────────────────────────┤
│   SMIUSBDisplayManager (Userspace)  │
├─────────────────────────────────────┤
│   libevdi.so (EVDI Library)        │
├─────────────────────────────────────┤
│   evdi.ko (Kernel Module)          │
├─────────────────────────────────────┤
│   DRM/KMS (Kernel Subsystem)       │
├─────────────────────────────────────┤
│   USB Subsystem                     │
├─────────────────────────────────────┤
│   SMI USB Display Hardware         │
└─────────────────────────────────────┘
```

### Components

1. **SMI USB Display Hardware:**
   - Physical USB display device
   - Uses Silicon Motion chipset (vendor ID: 090c)
   - Connects via USB 2.0/3.0

2. **EVDI Kernel Module (evdi.ko):**
   - Creates virtual DRM devices
   - Bridges between userspace and kernel graphics
   - Version: 1.14.11 (required for kernel 6.14+)

3. **EVDI Library (libevdi.so):**
   - Userspace library for communicating with kernel module
   - Provides API for display management
   - Built from EVDI source

4. **SMIUSBDisplayManager:**
   - Proprietary daemon by Silicon Motion
   - Manages USB display devices
   - Communicates with EVDI library
   - Handles firmware loading and display configuration

5. **X.org/Display Manager:**
   - Uses modesetting driver
   - Sees EVDI devices as standard displays
   - Configured via `/usr/share/X11/xorg.conf.d/20-smi.conf`

---

## The EVDI Problem

### Kernel 6.14 API Changes

Linux kernel 6.14 introduced breaking changes to the DRM subsystem:

**Affected APIs:**

1. **drm_plane structure changes:**
   - Removed: `drm_plane.format_default`
   - Changed: `drm_plane_create()` signature
   - Impact: EVDI's plane initialization code breaks

2. **drm_framebuffer handling:**
   - Modified reference counting
   - Changed validation functions
   - Impact: Buffer management code needs updates

3. **DRM modeset locking:**
   - New locking requirements
   - Changed: `drm_modeset_lock_all()` behavior
   - Impact: Need to update locking patterns

### EVDI Version Compatibility

| EVDI Version | Kernel Support | Notes |
|--------------|----------------|-------|
| 1.14.7 | Up to 6.13 | Bundled with SMI driver |
| 1.14.8 | 6.14 partial | Some fixes |
| 1.14.9 | 6.14 partial | Additional patches |
| 1.14.10 | 6.14 better | Improved compatibility |
| 1.14.11+ | 6.14+ full | Full kernel 6.14+ support |

### Why SMI Driver Fails

The SMI driver v2.22.1.0 bundles EVDI 1.14.7:

```bash
# Extraction shows:
$ tar -tzf evdi.tar.gz | head
evdi-1.14.7/
evdi-1.14.7/module/
evdi-1.14.7/module/evdi_drm_drv.c
...
```

When the installer tries to build this on kernel 6.14:

```
make -j16 KERNELRELEASE=6.14.0-35-generic all ...
error: 'struct drm_plane' has no member named 'format_default'
error: too many arguments to function 'drm_plane_create'
ERROR: Failed to install evdi to the kernel tree.
```

---

## Solution Design

### Strategy

Instead of waiting for SMI to update their driver, we:

1. Install compatible EVDI (1.14.11) from upstream source
2. Patch the SMI installer to use the system EVDI
3. Preserve all other SMI functionality

### Key Insight

The EVDI kernel module and library are **separate** from the SMI driver logic. The SMI driver only needs:
- A working EVDI kernel module
- The libevdi.so library
- Configuration files

We can replace just the EVDI components while keeping SMI's proprietary code intact.

---

## Installation Process

### Phase 1: EVDI Installation

```bash
# Clone latest EVDI
git clone https://github.com/DisplayLink/evdi.git

# Build library
cd evdi/library
make
sudo make install

# Install kernel module via DKMS
cd ../module
sudo dkms add .
sudo dkms build evdi/1.14.11
sudo dkms install evdi/1.14.11
```

**DKMS Benefits:**
- Automatic rebuild on kernel updates
- Proper module signing for Secure Boot
- Version management
- Clean uninstallation

### Phase 2: Secure Boot Handling

If Secure Boot is enabled:

```bash
# Sign the module
sudo /usr/bin/kmodsign sha512 \
    /var/lib/shim-signed/mok/MOK.priv \
    /var/lib/shim-signed/mok/MOK.der \
    /lib/modules/$(uname -r)/updates/dkms/evdi.ko

# Enroll MOK (requires reboot and user interaction)
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
```

### Phase 3: Installer Patching

The script modifies three parts of the SMI installer:

**1. Disable pre-check modprobe:**
```bash
# Line 621: modprobe evdi
# Changed to: # modprobe evdi (using pre-installed)
```

**2. Bypass running module check:**
```bash
# Lines 623-641: Check for /sys/devices/evdi/count
# Modified condition to always false
```

**3. Replace install_evdi() function:**

Original function (lines 14-78):
- Extracts evdi.tar.gz
- Runs DKMS install (fails on kernel 6.14)
- Builds library
- Copies files

Replacement function:
- Extracts evdi.tar.gz (for library source only)
- Skips DKMS install (already done)
- Builds library from extracted source
- Copies library and configuration
- Uses system EVDI module

**Critical code section:**

```bash
install_evdi()
{
  # Skip kernel module installation
  echo "[[ Using pre-installed EVDI 1.14.11 ]]"
  
  # Still need to build library
  local EVDI
  EVDI=$(mktemp -d)
  tar xf "$TARGZ" -C "$EVDI"
  
  # Build libevdi.so from SMI's bundled source
  cd "${EVDI}/library"
  make
  cp -f libevdi.so* "$COREDIR"
  
  # Backup system EVDI for SMI to use
  cp -rf /usr/src/evdi-1.14.11 $COREDIR/module/
  
  # Configuration
  printf 'evdi\n' > /etc/modules-load.d/evdi.conf
  printf 'options evdi initial_device_count=4\n' > /etc/modprobe.d/evdi.conf
}
```

### Phase 4: Service Installation

The patched installer then proceeds normally:

1. Installs SMIUSBDisplayManager binary
2. Copies firmware files
3. Creates udev rules
4. Configures systemd service
5. Sets up X.org configuration

---

## Code Analysis

### Critical Files Modified

**Original SMI install.sh:**
```bash
├── install_evdi() [Lines 14-78]
│   ├── Extract evdi.tar.gz
│   ├── dkms install (FAILS on 6.14)
│   └── Build library
├── check_preconditions() [Lines 607-642]
│   ├── modprobe evdi
│   └── Check /sys/devices/evdi/count
└── install() [Lines 316-413]
    └── Call install_evdi()
```

**Patched version:**
```bash
├── install_evdi() [REPLACED]
│   ├── Extract evdi.tar.gz
│   ├── Use system EVDI (pre-installed)
│   └── Build library only
├── check_preconditions() [MODIFIED]
│   ├── # modprobe evdi (disabled)
│   └── if false; then (bypass check)
└── install() [UNCHANGED]
    └── Call install_evdi()
```

### Library Compatibility

The EVDI library (libevdi.so) from the SMI tarball is built against the installed kernel module. Key points:

1. **API Compatibility:** Library version must match module version
2. **ABI Stability:** EVDI maintains backward compatibility
3. **Build Process:** Library is kernel-independent (no kernel headers needed)

This means we can build libevdi.so from the SMI bundle even though the kernel module is different, because:
- Library version in SMI bundle: 1.14.7
- System kernel module: 1.14.11
- EVDI maintains ABI compatibility between minor versions

---

## Kernel Module Details

### DKMS Configuration

Located at `/usr/src/evdi-1.14.11/dkms.conf`:

```ini
PACKAGE_NAME="evdi"
PACKAGE_VERSION="1.14.11"
MAKE="make all KVER=$kernelver"
CLEAN="make clean"
BUILT_MODULE_NAME="evdi"
DEST_MODULE_LOCATION="/updates/dkms"
AUTOINSTALL="yes"
```

### Module Parameters

```bash
# View current parameters
cat /sys/module/evdi/parameters/initial_device_count

# Set at load time
modprobe evdi initial_device_count=4

# Set permanently
echo "options evdi initial_device_count=4" > /etc/modprobe.d/evdi.conf
```

### Module Dependencies

```bash
$ modinfo evdi
...
depends:        drm,drm_kms_helper
...
```

The module depends on:
- `drm`: Direct Rendering Manager core
- `drm_kms_helper`: Kernel Mode Setting helpers

These are provided by the kernel and don't need separate installation.

---

## Systemd Service

### Service Unit File

Located at `/lib/systemd/system/smiusbdisplay.service`:

```ini
[Unit]
Description=SiliconMotion Driver Service
After=display-manager.service
Conflicts=getty@tty7.service

[Service]
ExecStartPre=/bin/bash -c "modprobe evdi || (dkms install ...)"
ExecStart=/opt/siliconmotion/SMIUSBDisplayManager
Restart=always
WorkingDirectory=/opt/siliconmotion
RestartSec=5
```

### Service Behavior

1. **Start Trigger:** After display manager (gdm, lightdm, etc.)
2. **Pre-Start:** Ensures EVDI is loaded, reinstalls if needed
3. **Main Process:** SMIUSBDisplayManager daemon
4. **Auto-Restart:** Restarts on crash with 5-second delay

---

## X.org Configuration

### Modesetting Driver

Located at `/usr/share/X11/xorg.conf.d/20-smi.conf`:

```xorg
Section "Device"
    Identifier "SiliconMotion"
    Driver "modesetting"
    Option "PageFlip" "false"
EndSection
```

**Why modesetting?**
- Generic driver for any KMS device
- Works with EVDI virtual displays
- No need for SMI-specific X.org driver

**Why PageFlip disabled?**
- Improves compatibility with EVDI
- Reduces tearing in some configurations
- Slight performance trade-off for stability

---

## USB Device Detection

### Udev Rules

Located at `/etc/udev/rules.d/99-smiusbdisplay.rules`:

```udev
# Silicon Motion USB Display devices (vendor ID: 090c)
ACTION=="add", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="090c", \
    RUN+="/opt/siliconmotion/smi-udev.sh START"

ACTION=="remove", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="090c", \
    RUN+="/opt/siliconmotion/smi-udev.sh STOP"
```

### Device Enumeration

```bash
# List SMI devices
lsusb | grep 090c

# Device details
sudo udevadm info --query=all --name=/dev/bus/usb/002/005

# Trigger udev event
sudo udevadm trigger --action=add /sys/bus/usb/devices/2-1
```

---

## Debugging Tools

### Module Debugging

```bash
# Enable debug output
echo 8 > /sys/devices/evdi/loglevel

# Watch kernel messages
sudo dmesg -w | grep evdi

# Module information
modinfo evdi
lsmod | grep evdi
```

### EVDI Debugging

```bash
# EVDI device count
cat /sys/devices/evdi/count

# Add virtual device
echo 1 > /sys/devices/evdi/add

# Remove all devices
echo 1 > /sys/devices/evdi/remove_all

# Version
cat /sys/devices/evdi/version
```

### Service Debugging

```bash
# Real-time logs
sudo journalctl -u smiusbdisplay.service -f

# Full logs
sudo journalctl -u smiusbdisplay.service --no-pager

# Run manually
sudo systemctl stop smiusbdisplay.service
sudo /opt/siliconmotion/SMIUSBDisplayManager
```

---

## Future Considerations

### Kernel Updates

When Ubuntu updates the kernel:
- DKMS automatically rebuilds EVDI
- Module is re-signed if Secure Boot is enabled
- No manual intervention needed (usually)

If issues arise:
```bash
# Rebuild for new kernel
sudo dkms install evdi/1.14.11 -k $(uname -r)
```

### SMI Driver Updates

If Silicon Motion releases a new driver:
1. Check bundled EVDI version
2. If still < 1.14.11, use this patching method
3. If >= 1.14.11, direct installation may work

### EVDI Updates

To update EVDI to newer version:
```bash
cd ~/Downloads/evdi
git pull
cd library
make clean && make && sudo make install
cd ../module
sudo dkms remove evdi/1.14.11 --all
sudo dkms add .
VERSION=$(grep PACKAGE_VERSION dkms.conf | cut -d'"' -f2)
sudo dkms build evdi/$VERSION
sudo dkms install evdi/$VERSION
```

---

## References

- [EVDI GitHub Repository](https://github.com/DisplayLink/evdi)
- [Linux DRM Subsystem Documentation](https://www.kernel.org/doc/html/latest/gpu/index.html)
- [DKMS Documentation](https://github.com/dell/dkms)
- [Secure Boot and MOK](https://wiki.ubuntu.com/UEFI/SecureBoot)

---

**Document Version:** 1.0  
**Last Updated:** November 2024
