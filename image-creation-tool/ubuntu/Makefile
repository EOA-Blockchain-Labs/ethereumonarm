#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm

URL := https://cdimage.ubuntu.com/releases/20.04.1/release/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
XZ := ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
ISO := ubuntu-20.04.1-preinstalled-server-arm64+raspi.img

iso:
	mkdir /tmp/ubuntu_iso
	wget  $(URL)
	unxz $(XZ)
	sudo mount -o loop,offset=269484032 $(ISO) /tmp/ubuntu_iso
	sudo cp -a sources/* /tmp/ubuntu_iso
	sudo sed -i 's/1/0/' /tmp/ubuntu_iso/etc/apt/apt.conf.d/20auto-upgrades
	sudo umount /tmp/ubuntu_iso
	mv $(ISO) ethonarm$(ISO)
	rmdir /tmp/ubuntu_iso
