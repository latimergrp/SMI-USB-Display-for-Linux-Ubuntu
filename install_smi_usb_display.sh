#!/bin/bash

# SMI USB Display Driver Installation Script - Fixed Version
# Handles kernel 6.14+ compatibility by using pre-installed EVDI

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[*]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SMI USB Display Driver Installer${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run with sudo"
    exit 1
fi

# Verify EVDI 1.14.11 is installed
print_status "Checking for EVDI 1.14.11..."
if ! dkms status | grep -q "evdi.*1.14.11"; then
    print_error "EVDI 1.14.11 not found!"
    print_error "Please install it first using the previous script or manually"
    exit 1
fi

print_status "EVDI 1.14.11 found in DKMS"

# Find the SMI installer in current directory
SMI_INSTALLER="./SMIUSBDisplay-driver.2.22.1.0.run"

if [ ! -f "$SMI_INSTALLER" ]; then
    print_error "SMI installer not found: $SMI_INSTALLER"
    print_error "Please run this script from the SMI driver directory"
    exit 1
fi

# Extract installer
print_status "Extracting SMI installer..."
WORK_DIR="/tmp/smi_install_$$"
bash "$SMI_INSTALLER" --noexec --target "$WORK_DIR"

cd "$WORK_DIR"

# Backup original
cp install.sh install.sh.original

print_status "Patching installer..."

# Strategy: Modify install_evdi function to use system EVDI instead of installing
# Replace the install_evdi function body (lines 14-78) with a stub that succeeds

# First, disable the modprobe check in check_preconditions
sed -i '621s/^  modprobe evdi/  # modprobe evdi (using pre-installed)/' install.sh

# Second, bypass the /sys/devices/evdi/count check
sed -i '623,641s/if \[ -f \/sys\/devices\/evdi\/count \]/if false/' install.sh

# Third, replace the install_evdi function to use system EVDI
# We'll replace the function content but keep the structure
cat > install_evdi_replacement.txt << 'EOFFUNCTION'
install_evdi()
{
  TARGZ="$1"
  ERRORS="$2"
  
  echo "[[ Using pre-installed EVDI 1.14.11 from system DKMS ]]"
  
  # Extract just to get the library source for building
  local EVDI
  EVDI=$(mktemp -d)
  if ! tar xf "$TARGZ" -C "$EVDI"; then
    echo "Unable to extract $TARGZ to $EVDI" > "$ERRORS"
    return 1
  fi

  echo "[[ Installing module configuration files ]]"
  printf '%s\n' 'evdi' > /etc/modules-load.d/evdi.conf
  printf '%s\n' 'options evdi initial_device_count=4' > /etc/modprobe.d/evdi.conf
  
  local EVDI_DRM_DEPS
  EVDI_DRM_DEPS=$(sed -n -e '/^drm_kms_helper/p' /proc/modules | awk '{print $4}' | tr ',' ' ')
  EVDI_DRM_DEPS=${EVDI_DRM_DEPS/evdi/}
  [[ "${EVDI_DRM_DEPS}" ]] && printf 'softdep %s pre: %s\n' 'evdi' "${EVDI_DRM_DEPS}" >> /etc/modprobe.d/evdi.conf

  echo "[[ Backing up system EVDI (1.14.11) to SMI directory ]]"
  # Use the system-installed EVDI 1.14.11
  local EVDI_VERSION="evdi-1.14.11"
  mkdir -p $COREDIR/module
  cp -rf /usr/src/$EVDI_VERSION/* $COREDIR/module/ 2>/dev/null || cp -rf /var/lib/dkms/evdi/1.14.11/source/* $COREDIR/module/
  cp /etc/modprobe.d/evdi.conf $COREDIR 2>/dev/null || true

  echo "[[ Building EVDI library from extracted source ]]"
  (
    cd "${EVDI}/library" || return 1
    if ! make; then
      echo "Failed to build evdi library." > "$ERRORS"
      return 1
    fi
    if ! cp -f libevdi.so* "$COREDIR"; then
      echo "Failed to copy evdi library to $COREDIR." > "$ERRORS"
      return 1
    fi
    chmod 0755 "$COREDIR"/libevdi.so*
    # Create symlinks for compatibility
    ln -sf "$COREDIR/libevdi.so.1.14.7" /usr/lib/libevdi.so.0 2>/dev/null || ln -sf "$COREDIR"/libevdi.so.* /usr/lib/libevdi.so.0
    ln -sf "$COREDIR/libevdi.so.1.14.7" /usr/lib/libevdi.so.1 2>/dev/null || ln -sf "$COREDIR"/libevdi.so.* /usr/lib/libevdi.so.1
  ) || return 1
  
  rm -rf "$EVDI"
  echo "[[ EVDI setup complete using system kernel module ]]"
  return 0
}
EOFFUNCTION

# Now replace the install_evdi function in install.sh (lines 14-78)
# Extract everything before install_evdi
sed -n '1,13p' install.sh > install.sh.new

# Add our replacement function
cat install_evdi_replacement.txt >> install.sh.new

# Extract everything after the original install_evdi function (line 79 onwards)
sed -n '79,$p' install.sh >> install.sh.new

# Replace the file
mv install.sh.new install.sh
chmod +x install.sh

rm -f install_evdi_replacement.txt

print_status "Patches applied. Running installer..."
echo ""

# Run the patched installer
bash install.sh install

RESULT=$?

# Cleanup
cd /
rm -rf "$WORK_DIR"

if [ $RESULT -eq 0 ]; then
    echo ""
    print_status "${GREEN}Installation completed successfully!${NC}"
    echo ""
    print_status "Verifying installation..."
    
    # Check if evdi is loaded
    if lsmod | grep -q evdi; then
        echo -e "${GREEN}✓${NC} EVDI module is loaded"
    else
        print_warning "EVDI module not loaded, loading now..."
        modprobe evdi
    fi
    
    # Check if SMI driver is installed
    if [ -d /opt/siliconmotion ]; then
        echo -e "${GREEN}✓${NC} SMI driver installed to /opt/siliconmotion"
    fi
    
    # Check if systemd service exists
    if [ -f /lib/systemd/system/smiusbdisplay.service ]; then
        echo -e "${GREEN}✓${NC} Systemd service installed"
        systemctl enable smiusbdisplay.service
        systemctl start smiusbdisplay.service
        echo -e "${GREEN}✓${NC} Service enabled and started"
    fi
    
    echo ""
    print_status "Installation complete!"
    print_status "Please connect your SMI USB display device"
    print_status "Monitor with: sudo journalctl -u smiusbdisplay.service -f"
    echo ""
else
    print_error "Installation failed with exit code: $RESULT"
    print_error "Check /var/log/SMIUSBDisplay for details"
    exit 1
fi
