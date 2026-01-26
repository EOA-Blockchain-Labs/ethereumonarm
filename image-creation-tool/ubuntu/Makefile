# Makefile for building custom Armbian images
# Version: 2.2
#
# This script helps to download and change Armbian images for small computers (SBCs).

# --- Configuration ---

# Get current date (example: 25.01)
DATE := $(shell date +"%y.%m")
# Release number for today
RELEASE := 00

# Function to make the final image name
ETHONARM_IMAGE = ethonarm_$(1)_$(DATE).$(RELEASE).img

# --- Device List ---
# List of devices we support. Add new ones here.
DEVICES = rpi5 rock5b rock5t orangepi5-plus nanopct6

# Raspberry Pi 5 uses the RPi4 image from Armbian
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

# --- End Device List ---

# --- Functions ---

# Function to download the image if we don't have it.
# It also checks if the file is correct using SHA256.
# Argument $1: URL of the image file.
define download_image
	@if [ -f $(notdir $1) ]; then \
	    echo "🔎 $(notdir $1) exists. No need to download."; \
	else \
	    echo "🔽 Downloading $1..."; \
	    wget -q --show-progress -O $(notdir $1) $1 || { echo "❌ Download failed"; exit 1; }; \
	fi
	@echo "🔐 Checking file integrity..."
	@EXPECTED_SHA=$$(wget -qO- "$1.sha" 2>/dev/null | awk '{print $$1}'); \
	if [ -n "$$EXPECTED_SHA" ]; then \
	    echo "$$EXPECTED_SHA  $(notdir $1)" | sha256sum -c - || { echo "❌ Bad file!"; rm -f $(notdir $1); exit 1; }; \
	    echo "✅ File is good."; \
	else \
	    echo "⚠️  Cannot check file integrity because .sha file is missing."; \
	fi
	@if [ -f $(basename $(notdir $1)) ]; then \
	    echo "📦 Image already unzipped."; \
	else \
	    echo "📦 Unzipping $(notdir $1)..."; \
	    unxz -k $(notdir $1) || { echo "❌ Unzip failed"; exit 1; }; \
	fi
endef

# Function to change the image.
# It calls an external script to do the hard work.
# Argument $1: Name of the .img file.
# Argument $2: Name of the device (like 'rpi5').
define modify_image
	@sudo ./modify_image.sh $(notdir $1) $2
endef
# --- End Functions ---

# List of all images we want to build
TARGET_IMAGES := $(foreach dev,$(DEVICES),$(call ETHONARM_IMAGE,$(dev)))

.DEFAULT_GOAL := help
.PHONY: all $(TARGET_IMAGES) clean build help lint

# --- Main Commands ---

# Build all images
all: $(TARGET_IMAGES)

# Build only one image
# Example: make build DEVICE=rock5b
build:
ifndef DEVICE
	$(error Please choose a DEVICE. Example: make build DEVICE=rock5b)
endif
	$(MAKE) $(call ETHONARM_IMAGE,$(DEVICE))

# Rule to build any image
$(TARGET_IMAGES): ethonarm_%_$(DATE).$(RELEASE).img:
	$(eval DEVICE_NAME := $*)
	@echo "--- Building for $(DEVICE_NAME) ---"
	$(call download_image,$(value $(DEVICE_NAME)_url))
	$(call modify_image,$(value $(DEVICE_NAME)_iso),$(DEVICE_NAME))

# Clean up files
clean:
	@echo "Cleaning up..."
	rm -f $(TARGET_IMAGES)
	rm -f *_minimal.img.xz *.img manifest.txt
	@echo "Done."

# Show help
help:
	@echo "Usage: make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  all                  Build all images."
	@echo "  build DEVICE=<name>  Build one image."
	@echo "  clean                Remove all files."
	@echo "  lint                 Check scripts for errors."
	@echo "  help                 Show this help."
	@echo ""
	@echo "Devices: $(DEVICES)"

# Check scripts
lint:
	@echo "🔎 Checking scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
	    find sources -type f -name '*.sh' -o -name 'ethereum-first-boot' -o -name 'check_install' | \
	    xargs -r shellcheck -x -S warning && echo "✅ Scripts are good." || echo "❌ Found errors."; \
	else \
	    echo "❌ shellcheck is missing. Install it with: apt install shellcheck"; \
	    exit 1; \
	fi