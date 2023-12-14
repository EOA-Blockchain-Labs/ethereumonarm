DATE := $(shell date +"%y.%m")
RELEASE := 00

define download_image
	mkdir -p /tmp/ubuntu_iso
	wget $1
	unxz $(notdir $1)
endef

define modify_image
	# Copy device rc.local
	sudo mount -o loop,offset=$(2) $(notdir $1) /tmp/ubuntu_iso
	sudo cp -a sources/etc/rc.local.$(3) /tmp/ubuntu_iso/etc/rc.local
	sudo cp -a sources/usr/local/sbin/check_install /tmp/ubuntu_iso/usr/local/sbin
	# Disable Armbian autologin
	sudo rm -f /tmp/ubuntu_iso/etc/systemd/system/getty@.service.d/override.conf
	sudo rm -f /tmp/ubuntu_iso/etc/systemd/system/serial-getty@.service.d/override.conf

	sudo test -f "/tmp/ubuntu_iso/root/.not_logged_in_yet" && sudo rm -f /tmp/ubuntu_iso/root/.not_logged_in_yet
	sync
	sudo umount /tmp/ubuntu_iso
	mv $(notdir $1) ethonarm_$(3)_$(DATE).$(RELEASE).img
	rmdir /tmp/ubuntu_iso
endef

rpi_url := https://cdimage.ubuntu.com/releases/22.04.2/release/ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz
rpi_iso := ubuntu-22.04.2-preinstalled-server-arm64+raspi.img
rpi_offset := 269484032
rpi_rclocal := rpi

rock5b_url := https://fi.mirror.armbian.de/archive/rock-5b/archive/Armbian_23.8.1_Rock-5b_jammy_legacy_5.10.160.img.xz
rock5b_iso := Armbian_23.8.1_Rock-5b_jammy_legacy_5.10.160.img
rock5b_offset := 285212672
rock5b_rclocal := rock5b

orangepi5_url := https://fi.mirror.armbian.de/archive/orangepi5/archive/Armbian_23.8.1_Orangepi5_jammy_legacy_5.10.160.img.xz
orangepi5_iso := Armbian_23.8.1_Orangepi5_jammy_legacy_5.10.160.img
orangepi5_offset := 285212672
orangepi5_rclocal := orangepi5

orangepi5-plus_url := https://fi.mirror.armbian.de/archive/orangepi5-plus/archive/Armbian_23.8.2_Orangepi5-plus_jammy_legacy_5.10.160.img.xz
orangepi5-plus_iso := Armbian_23.8.2_Orangepi5-plus_jammy_legacy_5.10.160.img
orangepi5-plus_offset := 285212672
orangepi5-plus_rclocal := orangepi5-plus

# There is not an Armbian image for downloading yet
#nanopct6_url := 
nanopct6_iso := Armbian_23.08.0-trunk_Nanopct6_jammy_legacy_5.10.160.img
nanopct6_offset := 285212672
nanopct6_rclocal := nanopct6

all: rpi rock5b orangepi5 orangepi5-plus nanopct6

rpi:
	$(call download_image,$(rpi_url))
	$(call modify_image,$(rpi_iso),$(rpi_offset),$(rpi_rclocal))

rock5b:
	$(call download_image,$(rock5b_url))
	$(call modify_image,$(rock5b_iso),$(rock5b_offset),$(rock5b_rclocal))

orangepi5:
	$(call download_image,$(orangepi5_url))
	$(call modify_image,$(orangepi5_iso),$(orangepi5_offset),$(orangepi5_rclocal))

orangepi5-plus:
	$(call download_image,$(orangepi5-plus_url))
	$(call modify_image,$(orangepi5-plus_iso),$(orangepi5-plus_offset),$(orangepi5-plus_rclocal))

nanopct6:
#	$(call download_image,$(nanopct6_url))
	$(call modify_image,$(nanopct6_iso),$(nanopct6_offset),$(nanopct6_rclocal))
