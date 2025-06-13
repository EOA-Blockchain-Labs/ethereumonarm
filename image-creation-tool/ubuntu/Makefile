DATE := $(shell date +"%y.%m")
RELEASE := 00

ETHONARM_IMAGE = ethonarm_$(1)_$(DATE).$(RELEASE).img

define download_image
	@if [ -f $(notdir $1) ]; then \
		echo "$(notdir $1) already exists. Skipping download."; \
	else \
		echo "Downloading $1..."; \
		wget -O $(notdir $1) $1 || { echo "Download failed for $1"; exit 1; }; \
	fi
	@if [ ! -f $(basename $(notdir $1)) ]; then \
		echo "Decompressing $(notdir $1)..."; \
		unxz -k $(notdir $1) || { echo "Failed to decompress $1"; exit 1; }; \
	else \
		echo "$(basename $(notdir $1)) already exists. Skipping decompression."; \
	fi
endef

define modify_image
	@echo "Modifying image $(notdir $1) for device $3..."
	@mount_dir=$$(mktemp -d); \
	sudo mount -o loop,offset=$(2) $(notdir $1) $$mount_dir || { echo "Mount failed"; exit 1; }; \
	sudo cp -a sources/etc/rc.local $$mount_dir/etc/rc.local; \
	sudo cp -a sources/usr/local/sbin/check_install $$mount_dir/usr/local/sbin/; \
	sudo rm -f $$mount_dir/etc/systemd/system/getty@.service.d/override.conf || true; \
	sudo rm -f $$mount_dir/etc/systemd/system/serial-getty@.service.d/override.conf || true; \
	sudo test -f "$$mount_dir/root/.not_logged_in_yet" && sudo rm -f $$mount_dir/root/.not_logged_in_yet || echo "no armbian release detected (no .not_logged_in_yet file)"; \
	sync; \
	sudo umount $$mount_dir; \
	rmdir $$mount_dir
	@mv $(notdir $1) $(call ETHONARM_IMAGE,$3)
	@sha256sum $(call ETHONARM_IMAGE,$3) >> manifest.txt
	@echo "Created image: $(call ETHONARM_IMAGE,$3)"
endef

# Device definitions
rpi5_url := https://es.sbcmirror.org/dl/rpi4b/archive/Armbian_25.2.4_Rpi4b_noble_current_6.12.28_minimal.img.xz
rpi5_iso := Armbian_25.2.4_Rpi4b_noble_current_6.12.28_minimal.img
rpi5_offset := 272629760

rock5b_url := https://es.sbcmirror.org/dl/rock-5b/archive/Armbian_25.2.2_Rock-5b_noble_vendor_6.1.115_minimal.img.xz
rock5b_iso := Armbian_25.2.2_Rock-5b_noble_vendor_6.1.115_minimal.img
rock5b_offset := 16777216

orangepi5-plus_url := https://es.sbcmirror.org/dl/orangepi5-plus/archive/Armbian_25.2.1_Orangepi5-plus_noble_vendor_6.1.115_minimal.img.xz
orangepi5-plus_iso := Armbian_25.2.1_Orangepi5-plus_noble_vendor_6.1.115_minimal.img
orangepi5-plus_offset := 16777216

nanopct6_url := https://es.sbcmirror.org/dl/nanopct6/archive/Armbian_25.2.1_Nanopct6_noble_vendor_6.1.115_minimal.img.xz
nanopct6_iso := Armbian_25.2.1_Nanopct6_noble_vendor_6.1.115_minimal.img
nanopct6_offset := 16777216

DEVICES = rpi5 rock5b orangepi5-plus nanopct6

.PHONY: all $(foreach dev,$(DEVICES),$(call ETHONARM_IMAGE,$(dev))) clean build

# Build all images
all: $(foreach dev,$(DEVICES),$(call ETHONARM_IMAGE,$(dev)))

# Build individual device
build:
ifndef DEVICE
	$(error Please specify a DEVICE, e.g. make build DEVICE=rock5b)
endif
	$(MAKE) $(call ETHONARM_IMAGE,$(DEVICE))

# Per-device rules
$(call ETHONARM_IMAGE,rpi5):
	$(call download_image,$(rpi5_url))
	$(call modify_image,$(rpi5_iso),$(rpi5_offset),rpi5)

$(call ETHONARM_IMAGE,rock5b):
	$(call download_image,$(rock5b_url))
	$(call modify_image,$(rock5b_iso),$(rock5b_offset),rock5b)

$(call ETHONARM_IMAGE,orangepi5-plus):
	$(call download_image,$(orangepi5-plus_url))
	$(call modify_image,$(orangepi5-plus_iso),$(orangepi5-plus_offset),orangepi5-plus)

$(call ETHONARM_IMAGE,nanopct6):
	$(call download_image,$(nanopct6_url))
	$(call modify_image,$(nanopct6_iso),$(nanopct6_offset),nanopct6)

# Clean target
clean:
	@echo "Cleaning generated images and downloads..."
	rm -f $(foreach dev,$(DEVICES),$(call ETHONARM_IMAGE,$(dev)))
	rm -f *_minimal.img.xz *.img manifest.txt
	@echo "Clean complete."
