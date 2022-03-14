#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

NIMBUS_DHASH := $(shell curl -s https://api.github.com/repos/status-im/nimbus-eth2/commits?sha=kiln-dev-auth | jq -r '. [0] |  .sha' | cut -c1-8)
NIMBUS_VERSION_MAIN="1.7.0"
#NIMBUS_VERSION_MAIN := $(shell curl -s https://api.github.com/repos/status-im/nimbus-eth2/releases/latest | jq -r '.name' | tr -d 'v')
#NIMBUS_DHASH := $(shell curl -s https://api.github.com/repos/status-im/nimbus-eth2/releases/latest | jq -r '.target_commitish' | cut -c1-8)
#DOWNLOAD_NAME := $(shell curl -s https://api.github.com/repos/status-im/nimbus-eth2/releases/latest | jq -r '.assets[2].name')
#NIMBUS_URL := $(shell curl -s https://api.github.com/repos/status-im/nimbus-eth2/releases/latest | jq -r '.assets[2].browser_download_url')
NIMBUS_VERSION := $(shell date +"%y%m%d")


PKG_RELEASE := 0
PKG_NAME := nimbus-kiln

PKG_DESCRIPTION := "Ethereum 2.0 Nimbus implementation"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://nimbus.team/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := MIT

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(NIMBUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(NIMBUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(NIMBUS_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/nim-geth.service\
	--deb-systemd extras/nim-neth.service\
	--deb-systemd extras/nim-besu.service\
	--depends kiln-config\

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(NIMBUS_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir -p /tmp/nimbus_tmp
	cd /tmp/nimbus_tmp ; git clone -b kiln-dev-auth https://github.com/status-im/nimbus-eth2.git ; cd nimbus-eth2 ; make dist-arm64
	cd /tmp/nimbus_tmp/nimbus-eth2/dist ; tar zxvf nimbus-eth2_Linux_arm64v8_$(NIMBUS_VERSION_MAIN)_$(NIMBUS_DHASH).tar.gz	
	cp /tmp/nimbus_tmp/nimbus-eth2/dist/nimbus-eth2_Linux_arm64v8_$(NIMBUS_VERSION_MAIN)_$(NIMBUS_DHASH)/build/nimbus_beacon_node sources/usr/bin/nimbus_beacon_node-kl
	rm -rf /tmp/nimbus_tmp

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/nimbus*

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

