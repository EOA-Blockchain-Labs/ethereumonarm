#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm

DATE := $(shell date +"%y.%m")
RELEASE:= 00

# Raspberry Pi 4 image
RPI_URL := https://cdimage.ubuntu.com/releases/20.04.4/release/ubuntu-20.04.5-preinstalled-server-arm64+raspi.img.xz
RPI_XZ := ubuntu-20.04.5-preinstalled-server-arm64+raspi.img.xz
RPI_ISO := ubuntu-20.04.5-preinstalled-server-arm64+raspi.img
rpi_iso:
	mkdir /tmp/ubuntu_iso
	wget  $(RPI_URL)
	unxz $(RPI_XZ)
	sudo mount -o loop,offset=269484032 $(RPI_ISO) /tmp/ubuntu_iso
	sudo cp -a sources/etc/rc.local.rpi /tmp/ubuntu_iso/etc/rc.local
	sudo sed -i 's/1/0/' /tmp/ubuntu_iso/etc/apt/apt.conf.d/20auto-upgrades
	sudo umount /tmp/ubuntu_iso
	mv $(RPI_ISO) ethonarm_rpi_$(DATE).$(RELEASE).img
	rmdir /tmp/ubuntu_iso

# Odroid M1 image
ODROID_URL := https://dn.odroid.com/RK3568/ODROID-M1/Ubuntu/ubuntu-20.04-server-odroidm1-20220531.img.xz
ODROID_XZ := ubuntu-20.04-server-odroidm1-20220531.img.xz
ODROID_ISO := ubuntu-20.04-server-odroidm1-20220531.img
odroid_iso:
	mkdir /tmp/ubuntu_iso
	wget  $(ODROID_URL)
	unxz $(ODROID_XZ)
	sudo mount -o loop,offset=269484032 $(ODROID_ISO) /tmp/ubuntu_iso
	sudo cp -a sources/etc/rc.local.odroid /tmp/ubuntu_iso/etc/rc.local
	sudo umount /tmp/ubuntu_iso
	mv $(ODROID_ISO) ethonarm_odroid_$(DATE).$(RELEASE).img
	rmdir /tmp/ubuntu_iso

# Radxa Rock 5B image
ROCK5B_URL := https://github.com/radxa/debos-radxa/releases/download/20221111-1029/rock-5b-ubuntu-focal-server-arm64-20221111-1242-gpt.img.xz  
ROCK5B_XZ := rock-5b-ubuntu-focal-server-arm64-20221111-1242-gpt.img.xz
ROCK5B_ISO := Armbian_23.02.0-trunk_Rock-5b_focal_legacy_5.10.110.img
rock5b_iso:
	mkdir /tmp/ubuntu_iso
	#wget  $(ROCK5B_URL)
	#unxz $(ROCK5B_XZ)
	sudo mount -o loop,offset=285212672 $(ROCK5B_ISO) /tmp/ubuntu_iso
	sudo cp -a sources/etc/rc.local.rock5b /tmp/ubuntu_iso/etc/rc.local
	#sudo cp -a sources/etc/sysfs.d/tk-optimize-rk3588.conf /tmp/ubuntu_iso/etc/sysfs.d/
	sudo umount /tmp/ubuntu_iso
	mv $(ROCK5B_ISO) ethonarm_rock5b_$(DATE).$(RELEASE).img
	rmdir /tmp/ubuntu_iso
