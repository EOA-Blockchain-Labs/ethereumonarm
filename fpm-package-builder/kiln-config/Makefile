
#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

MERGE_CONFIG_VERSION := $(shell date +"%y%m%d")
MERGE_CONFIG_URL := https://github.com/eth-clients/merge-testnets.git


PKG_RELEASE := 0
PKG_NAME := kiln-config

PKG_DESCRIPTION := "A repository to host the various Ethereum testnet configuration files"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/eth-clients/merge-testnets

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages/

PKG_RPM := $(PKG_NAME)-$(MERGE_CONFIG_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(MERGE_CONFIG_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb


FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(MERGE_CONFIG_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) -p $(OUTPUTDIR)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -x */.gitkeep\
	--deb-systemd extras/kiln-config.service --after-install extras/postinst\
	--depends git\
	--depends jq\
	--conflicts kintsugi-config

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(MERGE_CONFIG_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY)\
	--url $(WEB_URL) -p $(OUTPUTDIR)


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir -p sources/etc/ethereum/kiln
	git  -C sources/etc/ethereum/kiln clone https://github.com/eth-clients/merge-testnets.git 

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm -rf  sources/etc/ethereum/kiln/

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
