#Install FPM
#apt-get install ruby ruby-dev rubygems build-essential
#gem install --no-document fpm


PKG_NAME=armbian-extras
PKG_DESCRIPTION="Armbian script to config zram, ramlog, and tmpdir"
PKG_VERSION=1
PKG_RELEASE=0
PKG_MAINTAINER="Diego Losada <diego@ethereumonarm.com>"
PKG_ARCH=all
PKG_AFTER_INSTALL=extras/armbian-extras.postinst
PKG_AFTER_REMOVE=extras/armbian-extras.postrm
PKG_BEFORE_REMOVE=extras/armbian-extras.prerm

PKG_DEB=${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}_${PKG_ARCH}.deb
FPM_OPTS=-s dir -n $(PKG_NAME) -v $(PKG_VERSION) --iteration $(PKG_RELEASE) -C $(TMPINSTALLDIR) --maintainer ${PKG_MAINTAINER} --description $(PKG_DESCRIPTION) --after-install $(PKG_AFTER_INSTALL) --before-remove $(PKG_BEFORE_REMOVE)  --after-remove $(PKG_AFTER_REMOVE) -a $(PKG_ARCH) 
TMPINSTALLDIR=sources/

deb:
	fpm -t deb -p $(PKG_DEB) $(FPM_OPTS) 

