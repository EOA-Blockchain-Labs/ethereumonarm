# Makefile for building custom Armbian images
# Version: 2.1
#
# This script automates the download, customization, and packaging
# of Armbian images for various single-board computers (SBCs).

# --- Configuration ---

# Get current date (e.g., 25.10) for versioning
DATE := $(shell date +"%y.%m")
# Manual release number for the current date
RELEASE := 00

# Function to generate the final standardized image name
ETHONARM_IMAGE = ethonarm_$(1)_$(DATE).$(RELEASE).img

# --- Device Definitions ---
# List of all target devices. Add new device names here.
DEVICES = rpi5 rock5b rock5t orangepi5-plus nanopct6

# NOTE: Armbian uses the rpi4b image for Raspberry Pi 4 & 5
rpi5_url := https://es.sbcmirror.org/dl/rpi4b/archive/Armbian_25.11.1_Rpi4b_noble_current_6.12.58_minimal.img.xz
rpi5_iso := Armbian_25.11.1_Rpi4b_noble_current_6.12.58_minimal.img

rock5b_url := https://es.sbcmirror.org/dl/rock-5b/archive/Armbian_25.11.1_Rock-5b_noble_vendor_6.1.115_minimal.img.xz
rock5b_iso := Armbian_25.11.1_Rock-5b_noble_vendor_6.1.115_minimal.img

rock5t_url := https://es.sbcmirror.org/dl/rock-5t/archive/Armbian_25.11.1_Rock-5t_noble_vendor_6.1.115_minimal.img.xz
rock5t_iso := Armbian_25.11.1_Rock-5t_noble_vendor_6.1.115_minimal.img

orangepi5-plus_url := https://es.sbcmirror.org/dl/orangepi5-plus/archive/Armbian_25.11.1_Orangepi5-plus_noble_vendor_6.1.115_minimal.img.xz 
orangepi5-plus_iso := Armbian_25.11.1_Orangepi5-plus_noble_vendor_6.1.115_minimal.img

nanopct6_url := https://es.sbcmirror.org/dl/nanopct6-lts/archive/Armbian_25.11.1_Nanopct6-lts_noble_vendor_6.1.115_minimal.img.xz
nanopct6_iso := Armbian_25.11.1_Nanopct6-lts_noble_vendor_6.1.115_minimal.img

# --- End Device Definitions ---

# --- Canned Recipes (Functions) ---

# Defines the process for downloading, verifying, and decompressing an image.
# Downloads the .sha file from the Armbian mirror for checksum verification.
# Skips steps if the required files already exist.
# Argument $1: URL of the compressed image.
define download_image
	@if [ -f $(notdir $1) ]; then \
	    echo "🔎 $(notdir $1) already exists. Skipping download."; \
	else \
	    echo "🔽 Downloading $1..."; \
	    wget -q --show-progress -O $(notdir $1) $1 || { echo "❌ Download failed for $1"; exit 1; }; \
	fi
	@echo "🔐 Downloading and verifying SHA256 checksum..."
	@EXPECTED_SHA=$$(wget -qO- "$1.sha" 2>/dev/null | awk '{print $$1}'); \
	if [ -n "$$EXPECTED_SHA" ]; then \
	    echo "$$EXPECTED_SHA  $(notdir $1)" | sha256sum -c - || { echo "❌ Checksum verification FAILED!"; rm -f $(notdir $1); exit 1; }; \
	    echo "✅ Checksum verified."; \
	else \
	    echo "⚠️  Could not fetch .sha file. Skipping verification."; \
	fi
	@if [ -f $(basename $(notdir $1)) ]; then \
	    echo "📦 $(basename $(notdir $1)) already exists. Skipping decompression."; \
	else \
	    echo "📦 Decompressing $(notdir $1)..."; \
	    unxz -k $(notdir $1) || { echo "❌ Failed to decompress $1"; exit 1; }; \
	fi
endef

# Defines the process for modifying the decompressed image.
# Mounts the image, copies/removes files, then unmounts and renames it.
# Automatically detects the start sector of the second partition (assumed root).
# Argument $1: Name of the raw .img file.
# Argument $2: Device name (e.g., 'rpi5').
define modify_image
	@sudo -v || { echo "Error: Sudo privileges are required to modify the image."; exit 1; }
	@echo "--> Modifying image $(notdir $1) for device '$2'..."
	@echo "🔍 Detecting partition offset..."
	@START_SECTOR=$$(fdisk -l $(notdir $1) | grep "$(notdir $1)p2" | awk '{print $$2}'); \
	if [ -z "$$START_SECTOR" ]; then \
		echo "❌ Could not detect start sector for partition 2."; exit 1; \
	fi; \
	OFFSET=$$(( $$START_SECTOR * 512 )); \
	echo "✅ Detected start sector: $$START_SECTOR (Offset: $$OFFSET bytes)"; \
	mount_dir=$$(mktemp -d); \
	trap 'echo "--> Caught signal, cleaning up..."; sudo umount $$mount_dir 2>/dev/null; rm -rf $$mount_dir;' INT TERM EXIT; \
	set -e; \
	sudo mount -o loop,offset=$$OFFSET $(notdir $1) $$mount_dir || { echo "Mount failed"; exit 1; }; \
	sudo mkdir -p $$mount_dir/opt/ethereumonarm; \
	sudo cp -a sources/opt/ethereumonarm/ansible $$mount_dir/opt/ethereumonarm/; \
	sudo cp -a sources/usr/local/bin/ethereum-first-boot $$mount_dir/usr/local/bin/ethereum-first-boot; \
	sudo chmod +x $$mount_dir/usr/local/bin/ethereum-first-boot; \
	sudo cp -a sources/etc/systemd/system/ethereum-first-boot.service $$mount_dir/etc/systemd/system/; \
	sudo ln -sf /etc/systemd/system/ethereum-first-boot.service $$mount_dir/etc/systemd/system/multi-user.target.wants/ethereum-first-boot.service; \
	sudo cp -a sources/usr/local/sbin/check_install $$mount_dir/usr/local/sbin/; \
	sudo rm -f $$mount_dir/etc/systemd/system/getty@.service.d/override.conf || true; \
	sudo rm -f $$mount_dir/etc/systemd/system/serial-getty@.service.d/override.conf || true; \
	sudo rm -f $$mount_dir/root/.not_logged_in_yet || true; \
	sudo ln -sf /dev/null $$mount_dir/etc/systemd/system/systemd-networkd-wait-online.service; \
	sudo ln -sf /dev/null $$mount_dir/etc/systemd/system/NetworkManager-wait-online.service; \
	sync; \
	sudo umount $$mount_dir; \
	trap - INT TERM EXIT; \
	rmdir $$mount_dir;
	@mv $(notdir $1) $(call ETHONARM_IMAGE,$2)
	@sha256sum $(call ETHONARM_IMAGE,$2) >> manifest.txt
	@echo "✅ Created image: $(call ETHONARM_IMAGE,$2)"
endef
# --- End Canned Recipes ---

# Generate the list of all final target image filenames.
TARGET_IMAGES := $(foreach dev,$(DEVICES),$(call ETHONARM_IMAGE,$(dev)))

# Set the default goal to 'help' so that running 'make' without arguments shows usage.
.DEFAULT_GOAL := help
# Declare targets that are not files to prevent conflicts.
.PHONY: all $(TARGET_IMAGES) clean build help lint

# --- Main Targets ---

# Target to build all device images defined in the DEVICES list.
all: $(TARGET_IMAGES)

# Convenience target to build a single device image.
# Usage: make build DEVICE=rock5b
build:
ifndef DEVICE
	$(error Please specify a DEVICE. Available devices: $(DEVICES))
endif
	$(MAKE) $(call ETHONARM_IMAGE,$(DEVICE))

# Static Pattern Rule to build any device image. This single rule
# replaces the need for separate rules for each device.
# The '*' (stem) captures the device name from the target filename.
$(TARGET_IMAGES): ethonarm_%_$(DATE).$(RELEASE).img:
	$(eval DEVICE_NAME := $*)
	@echo "--- Building for $(DEVICE_NAME) ---"
	$(call download_image,$(value $(DEVICE_NAME)_url))
	$(call modify_image,$(value $(DEVICE_NAME)_iso),$(DEVICE_NAME))

# Target to remove all generated and downloaded files.
clean:
	@echo "Cleaning generated images and downloads..."
	rm -f $(TARGET_IMAGES)
	rm -f *_minimal.img.xz *.img manifest.txt
	@echo "Clean complete."

# Target to display help information.
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  all                  Builds all device images."
	@echo "  build DEVICE=<name>  Builds a single image for the specified device."
	@echo "  clean                Removes all downloaded and generated files."
	@echo "  lint                 Runs shellcheck on shell scripts."
	@echo "  help                 Shows this help message."
	@echo ""
	@echo "Available devices: $(DEVICES)"

# Target to lint shell scripts using shellcheck.
lint:
	@echo "🔎 Running shellcheck on shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
	    find sources -type f -name '*.sh' -o -name 'ethereum-first-boot' -o -name 'check_install' | \
	    xargs -r shellcheck -x -S warning && echo "✅ All scripts passed lint." || echo "❌ Lint issues found."; \
	else \
	    echo "❌ shellcheck not installed. Install with: apt install shellcheck"; \
	    exit 1; \
	fi