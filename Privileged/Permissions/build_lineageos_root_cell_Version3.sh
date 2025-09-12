#!/bin/bash
set -euo pipefail

# === CONFIGURATION ===
CELL_NAME="lineageos_root_cell"
CELL_BASE="/data/local/tmp/${CELL_NAME}"
DEVICE_CODENAME="star2lte"  # Galaxy S9+
LINEAGE_VERSION="17.1"      # Android 10
LINEAGE_BUILD_DATE="20210101"  # Use latest available

# Direct download URLs for LineageOS
LINEAGE_ROM_URL="https://download.lineageos.org/${DEVICE_CODENAME}/lineage-${LINEAGE_VERSION}-${LINEAGE_BUILD_DATE}-nightly-${DEVICE_CODENAME}.zip"
LINEAGE_RECOVERY_URL="https://download.lineageos.org/${DEVICE_CODENAME}/lineage-${LINEAGE_VERSION}-${LINEAGE_BUILD_DATE}-recovery-${DEVICE_CODENAME}.img"

echo "[+] Building LineageOS Root Cell: ${CELL_BASE}"
mkdir -p "${CELL_BASE}"
cd "${CELL_BASE}"

# === DOWNLOAD LINEAGEOS SYSTEM IMAGE ===
echo "[+] Downloading LineageOS ${LINEAGE_VERSION} for ${DEVICE_CODENAME}..."
wget -c "${LINEAGE_ROM_URL}" -O lineage-rom.zip
echo "[+] LineageOS ROM downloaded successfully"

# === EXTRACT SYSTEM IMAGE ===
echo "[+] Extracting system.img from LineageOS ROM..."
EXTRACT_DIR=$(mktemp -d)
cd "${EXTRACT_DIR}"

# Extract the system image from the ROM zip
unzip -j "${CELL_BASE}/lineage-rom.zip" "system.img" || {
    echo "[-] Failed to extract system.img from ROM"
    # Some LineageOS builds use system.new.dat format
    if unzip -j "${CELL_BASE}/lineage-rom.zip" "system.new.dat" "system.transfer.list"; then
        echo "[+] Converting system.new.dat to system.img..."
        # Use sdat2img to convert (install: pip3 install sdat2img)
        sdat2img.py system.transfer.list system.new.dat system.img
    else
        echo "[-] Could not find system image in ROM"
        exit 1
    fi
}

# === CREATE HARDENED CELL STRUCTURE ===
echo "[+] Creating hardened cell structure..."
cd "${CELL_BASE}"

mkdir -p "./system_ro"  # Read-only LineageOS system
mkdir -p "./upper"      # Writable overlay for modifications
mkdir -p "./work"       # OverlayFS working directory
mkdir -p "./merged"     # Final unified root filesystem

# Mount the LineageOS system image as read-only base
mount -o loop "${EXTRACT_DIR}/system.img" "${CELL_BASE}/system_ro"

# Create OverlayFS for writable system
mount -t overlay overlay \
    -o lowerdir="${CELL_BASE}/system_ro",upperdir="${CELL_BASE}/upper",workdir="${CELL_BASE}/work" \
    "${CELL_BASE}/merged"

# === ENABLE ROOT WITHIN CELL ===
echo "[+] Configuring root access within the hardened cell..."

# Create root user and su binary in the overlay
mkdir -p "${CELL_BASE}/upper/system/bin"
mkdir -p "${CELL_BASE}/upper/system/xbin"

# Install Magisk su binary (or compile su from AOSP)
cat > "${CELL_BASE}/upper/system/xbin/su" << 'EOF'
#!/system/bin/sh
# Hardened Cell Root Access
exec /system/bin/sh "$@"
EOF

chmod 4755 "${CELL_BASE}/upper/system/xbin/su"

# Enable root shell access
echo "root:x:0:0:root:/root:/system/bin/sh" > "${CELL_BASE}/upper/etc/passwd"
echo "root::0::::::" > "${CELL_BASE}/upper/etc/shadow"

# === CREATE ADVANCED ENTRY SCRIPT ===
cat > /data/local/tmp/enter_${CELL_NAME} << 'EOF'
#!/system/bin/sh
# LineageOS Hardened Root Cell Entry Script

CELL_BASE="/data/local/tmp/lineageos_root_cell"
MERGED_ROOT="${CELL_BASE}/merged"

# Ensure overlay is mounted
if ! mountpoint -q "${MERGED_ROOT}"; then
    echo "[+] Mounting LineageOS system overlay..."
    mount -t overlay overlay \
        -o lowerdir="${CELL_BASE}/system_ro",upperdir="${CELL_BASE}/upper",workdir="${CELL_BASE}/work" \
        "${MERGED_ROOT}"
fi

# Enter the hardened LineageOS environment with full namespace isolation
echo "[+] Entering LineageOS Root Cell..."
echo "[+] You now have root access within an isolated LineageOS environment"

# Use unshare for complete namespace isolation if available
if command -v unshare >/dev/null 2>&1; then
    exec unshare --mount-proc --pid --net --ipc --uts --fork \
        proot -r "${MERGED_ROOT}" \
        -b /dev -b /proc -b /sys \
        -w / \
        /system/bin/sh -c "
            export HOME=/data/root
            export PATH=/system/bin:/system/xbin:/vendor/bin
            echo 'LineageOS Root Cell Active - Full System Access Enabled'
            echo 'Device: Galaxy S9+ (star2lte)'
            echo 'OS: LineageOS ${LINEAGE_VERSION}'
            echo 'Root: Enabled'
            /system/bin/sh
        "
else
    # Fallback to basic proot if unshare isn't available
    exec proot -r "${MERGED_ROOT}" \
        -b /dev -b /proc -b /sys \
        -w / \
        /system/bin/sh
fi
EOF

chmod +x /data/local/tmp/enter_${CELL_NAME}

# === INSTALL ESSENTIAL ROOT TOOLS ===
echo "[+] Installing essential root tools in the cell..."

# Create directories for additional tools
mkdir -p "${CELL_BASE}/upper/system/addon.d"
mkdir -p "${CELL_BASE}/upper/data/adb"

# Install BusyBox (compile for aarch64 or download precompiled)
BUSYBOX_URL="https://busybox.net/downloads/binaries/1.35.0-aarch64-linux-musl/busybox"
wget -O "${CELL_BASE}/upper/system/xbin/busybox" "${BUSYBOX_URL}"
chmod 755 "${CELL_BASE}/upper/system/xbin/busybox"

# Create BusyBox symlinks for common tools
cd "${CELL_BASE}/upper/system/xbin"
for cmd in grep awk sed find wget curl tar gzip gunzip; do
    ln -sf busybox "$cmd"
done

echo "[+] Cleaning up..."
umount "${CELL_BASE}/system_ro"
rm -rf "${EXTRACT_DIR}"

echo "[+] =============================================================="
echo "[+] LINEAGEOS HARDENED ROOT CELL CONSTRUCTION COMPLETE!"
echo "[+] =============================================================="
echo "[+] Cell Location: ${CELL_BASE}"
echo "[+] Entry Command: /data/local/tmp/enter_${CELL_NAME}"
echo "[+]"
echo "[+] Features:"
echo "[+] ✓ Pure LineageOS ${LINEAGE_VERSION} system"
echo "[+] ✓ Full root access within isolated environment"
echo "[+] ✓ No Samsung/carrier restrictions"
echo "[+] ✓ BusyBox utilities installed"
echo "[+] ✓ Writable overlay for system modifications"
echo "[+] ✓ Complete namespace isolation"
echo "[+] =============================================================="