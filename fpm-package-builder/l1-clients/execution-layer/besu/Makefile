#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

BESU_VERSION := $(shell curl -s https://api.github.com/repos/hyperledger/besu/releases/latest | jq -r '.tag_name'| tr -d 'v')
PKG_RELEASE := 0
PKG_NAME := besu

PKG_DESCRIPTION := "Hyperledger Ethereum 1.0 java client"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL := https://www.hyperledger.org/use/besu

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Apache License 2.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := $(PKG_NAME)-$(BESU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(BESU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(BESU_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/besu.service --deb-systemd extras/besu-goerli.service\
	--depends openjdk-17-jre-headless\
	--depends libsecp256k1-0\
	--depends merge-config\
	--depends libjemalloc-dev\
	--replaces hyperledger-besu\
	--conflicts hyperledger-besu\
	--provides hyperledger-besu

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(BESU_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir /tmp/besu_temp
	wget  https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/$(BESU_VERSION)/besu-$(BESU_VERSION).zip -P /tmp/besu_temp
	unzip /tmp/besu_temp/besu-$(BESU_VERSION).zip -d /tmp/besu_temp
	cp /tmp/besu_temp/besu-$(BESU_VERSION)/bin/besu sources/usr/bin/
	cp /tmp/besu_temp/besu-$(BESU_VERSION)/lib/*  sources/usr/share/besu/lib/
	sed -i 's/`pwd -P`/\/usr\/share\/besu\//' sources/usr/bin/besu
	rm -rf /tmp/besu_temp
deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/share/besu/lib/*
	rm sources/usr/bin/besu

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
