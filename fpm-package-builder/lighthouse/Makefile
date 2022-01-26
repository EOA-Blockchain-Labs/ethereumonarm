#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

#LIGHTHOUSE_VERSION := $(shell curl -s "https://api.github.com/repos/sigp/lighthouse/releases/latest" | jq '.tag_name' | tr -d  '"'| tr -d "v")
LIGHTHOUSE_VERSION := $(shell date +"%y%m%d")


PKG_RELEASE := 0
PKG_NAME := lighthouse-kintsugi

PKG_DESCRIPTION := "Lighthouse Kintsugi Testnet"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://github.com/sigp/lighthouse/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Apache License 2.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(LIGHTHOUSE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(LIGHTHOUSE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(LIGHTHOUSE_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/lh-geth-beacon.service\
	--deb-systemd extras/lh-geth-validator.service\
	--depends kintsugi-config

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(LIGHTHOUSE_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
#	wget  https://github.com/sigp/lighthouse/releases/download/v$(LIGHTHOUSE_VERSION)/lighthouse-v$(LIGHTHOUSE_VERSION)-aarch64-unknown-linux-gnu.tar.gz -O - | tar -xz -C sources/usr/bin/  lighthouse
	mkdir -p /tmp/lighthouse_tmp
	cd /tmp/lighthouse_tmp ; git clone -b unstable https://github.com/sigp/lighthouse.git ; cd lighthouse ; cargo install cross ; make build-aarch64
	cp /tmp/lighthouse_tmp/lighthouse/target/aarch64-unknown-linux-gnu/release/lighthouse sources/usr/bin/lighthouse-ks
	rm -rf /tmp/lighthouse_tmp	

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/lighthouse-ks

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
