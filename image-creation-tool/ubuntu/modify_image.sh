#!/bin/bash
# Script to modify Armbian images for Ethereum on ARM
# usage: ./modify_image.sh <image_file> <device_name>

set -e

[ -z "$1" ] || [ -z "$2" ] && { echo "Usage: $0 <image_file> <device_name>"; exit 1; }
[ "$EUID" -ne 0 ] && { echo "Please run as root (sudo)"; exit 1; }

IMAGE=$1
DEVICE=$2

echo "--> Working on $IMAGE for '$DEVICE'..."

# Capture fdisk output to variable
FDISK_OUT=$(fdisk -l "$IMAGE" 2>&1 || true)

# Try finding partition 2, then partition 1
PART_LINE=$(echo "$FDISK_OUT" | grep -E "^${IMAGE}p?2[[:space:]]" || echo "$FDISK_OUT" | grep -E "^${IMAGE}p?1[[:space:]]" || true)

if [ -z "$PART_LINE" ]; then
    echo "❌ Cannot find partition 1 or 2."
    echo "$FDISK_OUT"
    exit 1
fi

# Extract start sector (handle boot flag '*' in 2nd column)
START_SECTOR=$(echo "$PART_LINE" | awk '{ if ($2 == "*") print $3; else print $2 }')

# Mount
OFFSET=$(( START_SECTOR * 512 ))
echo "✅ Partition starts at sector $START_SECTOR"

MOUNT_DIR=$(mktemp -d)
trap 'umount "$MOUNT_DIR" 2>/dev/null || true; rmdir "$MOUNT_DIR" || true' EXIT INT TERM

mount -o loop,offset=$OFFSET "$IMAGE" "$MOUNT_DIR"

echo "📂 Copying files..."
mkdir -p "$MOUNT_DIR/opt/ethereumonarm"
cp -a sources/opt/ethereumonarm/ansible "$MOUNT_DIR/opt/ethereumonarm/"
cp -a sources/usr/local/bin/ethereum-first-boot "$MOUNT_DIR/usr/local/bin/ethereum-first-boot"
chmod +x "$MOUNT_DIR/usr/local/bin/ethereum-first-boot"
cp -a sources/etc/systemd/system/ethereum-first-boot.service "$MOUNT_DIR/etc/systemd/system/"
ln -sf /etc/systemd/system/ethereum-first-boot.service "$MOUNT_DIR/etc/systemd/system/multi-user.target.wants/ethereum-first-boot.service"
cp -a sources/usr/local/sbin/check_install "$MOUNT_DIR/usr/local/sbin/"

# Clean up settings
rm -f "$MOUNT_DIR/etc/systemd/system/getty@.service.d/override.conf" 2>/dev/null || true
rm -f "$MOUNT_DIR/etc/systemd/system/serial-getty@.service.d/override.conf" 2>/dev/null || true
rm -f "$MOUNT_DIR/root/.not_logged_in_yet" 2>/dev/null || true
ln -sf /dev/null "$MOUNT_DIR/etc/systemd/system/systemd-networkd-wait-online.service"
ln -sf /dev/null "$MOUNT_DIR/etc/systemd/system/NetworkManager-wait-online.service"

echo "💾 Finalizing..."
sync

# Trap will handle unmount
# Rename and checksum
FINAL_NAME="ethonarm_${DEVICE}_$(date +%y.%m).00.img"
mv "$IMAGE" "$FINAL_NAME"
sha256sum "$FINAL_NAME" >> manifest.txt
echo "✅ Done: $FINAL_NAME"
