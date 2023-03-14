DATE := $(shell date +"%y.%m")
RELEASE := 00

define download_image
	mkdir -p /tmp/ubuntu_iso
	wget $1
	unxz $(notdir $1)
endef

define modify_image
	sudo mount -o loop,offset=$(2) $(notdir $1) /tmp/ubuntu_iso
	sudo cp -a sources/etc/rc.local.$(3) /tmp/ubuntu_iso/etc/rc.local
	sudo sed -i 's/1/0/' /tmp/ubuntu_iso/etc/apt/apt.conf.d/20auto-upgrades
	sync
	sudo umount /tmp/ubuntu_iso
	mv $(notdir $1) ethonarm_$(3)_$(DATE).$(RELEASE).img
	rmdir /tmp/ubuntu_iso
endef

rpi_url := https://cdimage.ubuntu.com/releases/20.04.4/release/ubuntu-20.04.5-preinstalled-server-arm64+raspi.img.xz
rpi_iso := ubuntu-20.04.5-preinstalled-server-arm64+raspi.img
rpi_offset := 269484032
rpi_rclocal := rpi

rock5b_url := https://es-mirror.bret.dk/armbian/dl/rock-5b/archive/Armbian_23.02.2_Rock-5b_jammy_legacy_5.10.110.img.xz
rock5b_iso := Armbian_23.02.2_Rock-5b_jammy_legacy_5.10.110.img
rock5b_offset := 285212672
rock5b_rclocal := rock5b

all: rpi rock5b

rpi:
	$(call download_image,$(rpi_url))
	$(call modify_image,$(rpi_iso),$(rpi_offset),$(rpi_rclocal))

rock5b:
	$(call download_image,$(rock5b_url))
	$(call modify_image,$(rock5b_iso),$(rock5b_offset),$(rock5b_rclocal))
