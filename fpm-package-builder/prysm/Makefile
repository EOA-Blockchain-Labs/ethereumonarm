#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

PRYSM_VERSION := $(shell curl -s "https://api.github.com/repos/prysmaticlabs/prysm/tags" | jq '.[0].name' | tr -d  '"'| tr -d "v")
PRYSM_DHASH :=$(shell curl -s "https://api.github.com/repos/prysmaticlabs/prysm/tags" | jq '.[0].commit.sha' | tr -d  '"' | cut -c1-8)

PKG_RELEASE := 2
PKG_NAME := prysm

PKG_DESCRIPTION := "Ethereum 2.0 Prysmatic Labs implementation"
PKG_MAINTAINER := "diego losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/prysmaticlabs/prysm

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := ${pkg_name}-${prysm_version}-${pkg_release}_${pkg_arch_rpm}.rpm
PKG_DEB := ${pkg_name}_${prysm_version}-${pkg_release}_${pkg_arch_deb}.deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(PRYSM_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/prysm-slasher.service\
	--deb-systemd extras/prysm-beacon.service\
	--deb-systemd extras/prysm-validator.service\
	--conflicts prysm-beacon\
	--conflicts prysm-slasher\
	--conflicts prysm-validator\
	--provides prysm-beacon\
	--provides prysm-slasher\
	--provides prysm-validator\
	--replaces prysm-beacon\
	--replaces prysm-slasher\
	--replaces prysm-validator

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PRYSM_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	wget https://github.com/prysmaticlabs/prysm/releases/download/v$(PRYSM_VERSION)/beacon-chain-v$(PRYSM_VERSION)-linux-arm64 -O sources/usr/bin/beacon-chain
	wget https://github.com/prysmaticlabs/prysm/releases/download/v$(PRYSM_VERSION)/validator-v$(PRYSM_VERSION)-linux-arm64 -O sources/usr/bin/validator
	wget https://github.com/prysmaticlabs/prysm/releases/download/v$(PRYSM_VERSION)/slasher-v$(PRYSM_VERSION)-linux-arm64 -O sources/usr/bin/slasher
	chmod +x sources/usr/bin/beacon-chain sources/usr/bin/validator sources/usr/bin/slasher
deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/*
