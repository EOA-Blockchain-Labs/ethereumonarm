#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

TEKU_VERSION := $(shell curl -s https://api.github.com/repos/ConsenSys/teku/releases/latest | jq -r '.name' | tr -d 'v')

PKG_RELEASE := 1
PKG_NAME := teku

PKG_DESCRIPTION := "Consensys Quorum Teku Eth2 java client"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://consensys.net/knowledge-base/ethereum-2/teku/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Apache License 2.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(TEKU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(TEKU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(TEKU_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/teku.service\
	--depends openjdk-11-jre-headless

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(TEKU_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir /tmp/teku_temp
	wget https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/$(TEKU_VERSION)/teku-$(TEKU_VERSION).tar.gz -O - | tar -xz -C  /tmp/teku_temp --wildcards --absolute-names --no-anchored --strip-components 1
	cp /tmp/teku_temp/bin/teku sources/usr/bin/
	cp /tmp/teku_temp/lib/*  sources/usr/share/teku/lib/
	sed -i 's/"$${APP_HOME:-\.\/}\.\."/"$${APP_HOME:-\.\/}\.\.\/share\/teku"/g' sources/usr/bin/teku
	rm -rf /tmp/teku_temp
deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/share/teku/lib/*
	rm sources/usr/bin/teku
