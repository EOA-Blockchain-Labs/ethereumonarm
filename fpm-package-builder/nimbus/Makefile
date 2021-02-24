#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

NIMBUS_VERSION := $(shell curl -s https://api.github.com/repos/status-im/nimbus-eth2/releases/latest | jq -r '.name' | tr -d 'v')
NIMBUS_DHASH := $(shell curl -s https://api.github.com/repos/status-im/nimbus-eth2/releases/latest | jq -r '.target_commitish' | cut -c1-8)

PKG_RELEASE := 0
PKG_NAME := nimbus

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
	--deb-systemd extras/nimbus.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(NIMBUS_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	wget https://github.com/status-im/nimbus-eth2/releases/download/v$(NIMBUS_VERSION)/nimbus-eth2_Linux_arm64v8_$(NIMBUS_VERSION)_$(NIMBUS_DHASH).tar.gz -O - | tar -xz -C sources/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 2 '*/nimbus_*'
	rm sources/usr/bin/nimbus*.sha512sum

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/nimbus*

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
