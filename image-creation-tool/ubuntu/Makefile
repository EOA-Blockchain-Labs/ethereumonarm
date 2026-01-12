# Makefile for building custom Armbian images
# Version: 2.0
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
rpi5_offset := 272629760 # Partition start offset in bytes

rock5b_url := https://es.sbcmirror.org/dl/rock-5b/archive/Armbian_25.11.1_Rock-5b_noble_vendor_6.1.115_minimal.img.xz
rock5b_iso := Armbian_25.11.1_Rock-5b_noble_vendor_6.1.115_minimal.img
rock5b_offset := 16777216

rock5t_url := https://es.sbcmirror.org/dl/rock-5t/archive/Armbian_25.11.1_Rock-5t_noble_vendor_6.1.115_minimal.img.xz
rock5t_iso := Armbian_25.11.1_Rock-5t_noble_vendor_6.1.115_minimal.img
rock5t_offset := 16777216

orangepi5-plus_url := https://es.sbcmirror.org/dl/orangepi5-plus/archive/Armbian_25.11.1_Orangepi5-plus_noble_vendor_6.1.115_minimal.img.xz 
orangepi5-plus_iso := Armbian_25.11.1_Orangepi5-plus_noble_vendor_6.1.115_minimal.img
orangepi5-plus_offset := 16777216

nanopct6_url := https://es.sbcmirror.org/dl/nanopct6-lts/archive/Armbian_25.11.1_Nanopct6-lts_noble_vendor_6.1.115_minimal.img.xz
nanopct6_iso := Armbian_25.11.1_Nanopct6-lts_noble_vendor_6.1.115_minimal.img
nanopct6_offset := 16777216
# --- End Device Definitions ---

# --- Canned Recipes (Functions) ---

# Defines the process for downloading and decompressing an image.
# Skips steps if the required files already exist.
# Argument $1: URL of the compressed image.
define download_image
	@if [ -f $(notdir $1) ]; then \
	    echo "--> $(notdir $1) already exists. Skipping download."; \
	else \
	    echo "--> Downloading $1..."; \
	    wget -q --show-progress -O $(notdir $1) $1 || { echo "Download failed for $1"; exit 1; }; \
	fi
	@if [ -f $(basename $(notdir $1)) ]; then \
	    echo "--> $(basename $(notdir $1)) already exists. Skipping decompression."; \
	else \
	    echo "--> Decompressing $(notdir $1)..."; \
	    unxz -k $(notdir $1) || { echo "Failed to decompress $1"; exit 1; }; \
	fi
endef

# Defines the process for modifying the decompressed image.
# Mounts the image, copies/removes files, then unmounts and renames it.
# Argument $1: Name of the raw .img file.
# Argument $2: Partition offset.
# Argument $3: Device name (e.g., 'rpi5').
define modify_image
	@sudo -v || { echo "Error: Sudo privileges are required to modify the image."; exit 1; }
	@echo "--> Modifying image $(notdir $1) for device '$3'..."
	@mount_dir=$$(mktemp -d); \
	trap 'echo "--> Caught signal, cleaning up..."; sudo umount $$mount_dir 2>/dev/null; rm -rf $$mount_dir;' INT TERM EXIT; \
	sudo mount -o loop,offset=$(2) $(notdir $1) $$mount_dir || { echo "Mount failed"; exit 1; }; \
	sudo cp -a sources/usr/local/bin/ethereum-first-boot $$mount_dir/usr/local/bin/ethereum-first-boot; \
	sudo chmod +x $$mount_dir/usr/local/bin/ethereum-first-boot; \
	sudo cp -a sources/etc/systemd/system/ethereum-first-boot.service $$mount_dir/etc/systemd/system/; \
	sudo ln -sf /etc/systemd/system/ethereum-first-boot.service $$mount_dir/etc/systemd/system/multi-user.target.wants/ethereum-first-boot.service; \
	sudo cp -a sources/usr/local/sbin/check_install $$mount_dir/usr/local/sbin/; \
	sudo rm -f $$mount_dir/etc/systemd/system/getty@.service.d/override.conf || true; \
	sudo rm -f $$mount_dir/etc/systemd/system/serial-getty@.service.d/override.conf || true; \
	sudo rm -f $$mount_dir/root/.not_logged_in_yet || true; \
	sync; \
	sudo umount $$mount_dir; \
	trap - INT TERM EXIT; \
	rmdir $$mount_dir;
	@mv $(notdir $1) $(call ETHONARM_IMAGE,$3)
	@sha256sum $(call ETHONARM_IMAGE,$3) >> manifest.txt
	@echo "✅ Created image: $(call ETHONARM_IMAGE,$3)"
endef
# --- End Canned Recipes ---

# Generate the list of all final target image filenames.
TARGET_IMAGES := $(foreach dev,$(DEVICES),$(call ETHONARM_IMAGE,$(dev)))

# Set the default goal to 'help' so that running 'make' without arguments shows usage.
.DEFAULT_GOAL := help
# Declare targets that are not files to prevent conflicts.
.PHONY: all $(TARGET_IMAGES) clean build help

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
	$(call modify_image,$(value $(DEVICE_NAME)_iso),$(value $(DEVICE_NAME)_offset),$(DEVICE_NAME))

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
	@echo "  help                 Shows this help message."
	@echo ""
	@echo "Available devices: $(DEVICES)"