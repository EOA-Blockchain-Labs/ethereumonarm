#!/bin/bash
# Script to modify Armbian images for Ethereum on ARM
# usage: ./modify_image.sh <image_file> <device_name>

set -e

IMAGE=$1
DEVICE=$2

if [ -z "$IMAGE" ] || [ -z "$DEVICE" ]; then
    echo "Usage: $0 <image_file> <device_name>"
    exit 1
fi

# Ensure sudo
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo)"
  exit 1
fi

echo "--> Working on $IMAGE for '$DEVICE'..."
echo "🔍 Looking for the main partition..."

# Detect partition
fdisk -l "$IMAGE" > fdisk.log 2>&1 || true

# Try partition 2 first, then 1
PART_LINE=$(grep -E "^${IMAGE}p?2[[:space:]]" fdisk.log || true)
if [ -n "$PART_LINE" ]; then
    echo "ℹ️  Found partition 2."
else
    PART_LINE=$(grep -E "^${IMAGE}p?1[[:space:]]" fdisk.log || true)
    if [ -n "$PART_LINE" ]; then
        echo "ℹ️  Found partition 1."
    else
        echo "❌ Cannot find partition 1 or 2."
        cat fdisk.log
        rm -f fdisk.log
        exit 1
    fi
fi
rm -f fdisk.log

# Extract start sector
START_SECTOR=$(echo "$PART_LINE" | awk '{ if ($2 == "*") print $3; else print $2 }')
if [ -z "$START_SECTOR" ]; then
    echo "❌ Failed to read Start Sector from: $PART_LINE"
    exit 1
fi

OFFSET=$(( START_SECTOR * 512 ))
echo "✅ Partition starts at: $START_SECTOR (Offset: $OFFSET bytes)"

MOUNT_DIR=$(mktemp -d)

cleanup() {
    if [ -d "$MOUNT_DIR" ]; then
        umount "$MOUNT_DIR" 2>/dev/null || true
        rmdir "$MOUNT_DIR" || true
    fi
}
trap cleanup EXIT INT TERM

# Mount
mount -o loop,offset=$OFFSET "$IMAGE" "$MOUNT_DIR"

# Copy files
echo "📂 Copying files..."
mkdir -p "$MOUNT_DIR/opt/ethereumonarm"
cp -a sources/opt/ethereumonarm/ansible "$MOUNT_DIR/opt/ethereumonarm/"
cp -a sources/usr/local/bin/ethereum-first-boot "$MOUNT_DIR/usr/local/bin/ethereum-first-boot"
chmod +x "$MOUNT_DIR/usr/local/bin/ethereum-first-boot"
cp -a sources/etc/systemd/system/ethereum-first-boot.service "$MOUNT_DIR/etc/systemd/system/"
ln -sf /etc/systemd/system/ethereum-first-boot.service "$MOUNT_DIR/etc/systemd/system/multi-user.target.wants/ethereum-first-boot.service"
cp -a sources/usr/local/sbin/check_install "$MOUNT_DIR/usr/local/sbin/"

# Clean up old files in image
rm -f "$MOUNT_DIR/etc/systemd/system/getty@.service.d/override.conf" || true
rm -f "$MOUNT_DIR/etc/systemd/system/serial-getty@.service.d/override.conf" || true
rm -f "$MOUNT_DIR/root/.not_logged_in_yet" || true
ln -sf /dev/null "$MOUNT_DIR/etc/systemd/system/systemd-networkd-wait-online.service"
ln -sf /dev/null "$MOUNT_DIR/etc/systemd/system/NetworkManager-wait-online.service"

echo "💾 Syncing and unmounting..."
sync
umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"
trap - EXIT INT TERM

# Rename
FINAL_NAME="ethonarm_${DEVICE}_$(date +%y.%m).00.img"
mv "$IMAGE" "$FINAL_NAME"
sha256sum "$FINAL_NAME" >> manifest.txt
echo "✅ Done: $FINAL_NAME"
