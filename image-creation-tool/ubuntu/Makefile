DATE := $(shell date +"%y.%m")
RELEASE := 00

define download_image
	wget $1
	unxz $(notdir $1)
endef

define modify_image
	# Copy device rc.local
	mkdir -p /tmp/ubuntu_iso
	sudo mount -o loop,offset=$(2) $(notdir $1) /tmp/ubuntu_iso
	sudo cp -a sources/etc/rc.local.$(3) /tmp/ubuntu_iso/etc/rc.local
	sudo cp -a sources/usr/local/sbin/check_install /tmp/ubuntu_iso/usr/local/sbin
	# Disable Armbian autologin
	sudo rm -f /tmp/ubuntu_iso/etc/systemd/system/getty@.service.d/override.conf
	sudo rm -f /tmp/ubuntu_iso/etc/systemd/system/serial-getty@.service.d/override.conf
	sudo test -f "/tmp/ubuntu_iso/root/.not_logged_in_yet" && sudo rm -f /tmp/ubuntu_iso/root/.not_logged_in_yet || echo no armbian release detected
	sync
	sudo umount /tmp/ubuntu_iso
	mv $(notdir $1) ethonarm_$(3)_$(DATE).$(RELEASE).img
	rmdir /tmp/ubuntu_iso
endef

rpi5_url := 
rpi5_iso := Armbian-unofficial_25.02.0-trunk_Rpi5b_jammy_current_6.6.73.img
rpi5_offset := 272629760
rpi5_rclocal := rpi5

rock5b_url := https://armbian.nardol.ovh/dl/rock-5b/archive/Armbian_24.8.1_Rock-5b_jammy_vendor_6.1.75.img.xz
rock5b_iso := Armbian_24.8.1_Rock-5b_jammy_vendor_6.1.75.img
rock5b_offset := 16777216
rock5b_rclocal := rock5b

rock5b32_url := https://github.com/radxa-build/rock-5b/releases/download/b39/rock-5b_ubuntu_jammy_cli_b39.img.xz
rock5b32_iso := rock-5b_ubuntu_jammy_cli_b39.img
rock5b32_offset := 348127232
rock5b32_rclocal := rock5b32

orangepi5_url := https://fi.mirror.armbian.de/archive/orangepi5/archive/Armbian_23.8.1_Orangepi5_jammy_legacy_5.10.160.img.xz
orangepi5_iso := Armbian_23.8.1_Orangepi5_jammy_legacy_5.10.160.img
orangepi5_offset := 285212672
orangepi5_rclocal := orangepi5

orangepi5-plus_url := https://dl.armbian.com/orangepi5-plus/archive/Armbian_24.5.1_Orangepi5-plus_jammy_vendor_6.1.43.img.xz
orangepi5-plus_iso := Armbian_24.5.1_Orangepi5-plus_jammy_vendor_6.1.43.img
orangepi5-plus_offset := 16777216
orangepi5-plus_rclocal := orangepi5-plus

# There is not an Armbian image for downloading yet
nanopct6_url := Armbian-unofficial_24.8.2_Nanopct6_jammy_current_6.10.6.img
nanopct6_iso := Armbian-unofficial_24.8.2_Nanopct6_jammy_current_6.10.6.img
nanopct6_offset := 16777216
nanopct6_rclocal := nanopct6

all: rpi5 rock5b orangepi5 orangepi5-plus nanopct6

rpi5:
#	$(call download_image,$(rpi5_url))
	$(call modify_image,$(rpi5_iso),$(rpi5_offset),$(rpi5_rclocal))

rock5b:
	$(call download_image,$(rock5b_url))
	$(call modify_image,$(rock5b_iso),$(rock5b_offset),$(rock5b_rclocal))

rock5b32:
	$(call download_image,$(rock5b32_url))ubuntu-22.04.2-preinstalled-server-arm64+raspi.img
	$(call modify_image,$(rock5b32_iso),$(rock5b32_offset),$(rock5b32_rclocal))

orangepi5:
	$(call download_image,$(orangepi5_url))
	$(call modify_image,$(orangepi5_iso),$(orangepi5_offset),$(orangepi5_rclocal))

orangepi5-plus:
	$(call download_image,$(orangepi5-plus_url))
	$(call modify_image,$(orangepi5-plus_iso),$(orangepi5-plus_offset),$(orangepi5-plus_rclocal))

nanopct6:
#	$(call download_image,$(nanopct6_url))
	$(call modify_image,$(nanopct6_iso),$(nanopct6_offset),$(nanopct6_rclocal))
