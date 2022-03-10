#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

#TEKU_VERSION := $(shell curl -s https://api.github.com/repos/hyperledger/teku/releases/latest | jq -r '.tag_name'| tr -d 'v')
TEKU_VERSION := $(shell date +"%y%m%d")
TEKU_SNAPSHOT := $(shell curl -s https://raw.githubusercontent.com/hyperledger/teku/merge/gradle.properties | head -1 | cut -d "=" -f 2)


PKG_RELEASE := 0
PKG_NAME := teku-kiln

PKG_DESCRIPTION := "Teku Ethereum 1.0 java client"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL := https://github.com/ConsenSys/teku.git

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Apache License 2.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(TEKU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(TEKU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(TEKU_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/teku-besu.service\
	--deb-systemd extras/teku-geth.service\
	--deb-systemd extras/teku-neth.service\
	--depends kiln-config\
	--depends openjdk-11-jre-headless\
	--depends libsecp256k1-0\

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(TEKU_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir /tmp/teku_temp
	cd /tmp/teku_temp ; git clone https://github.com/ConsenSys/teku.git
	cd /tmp/teku_temp/teku/ ; ./gradlew installDist
	mkdir -p sources/usr/share/teku/kiln/lib/
	cp /tmp/teku_temp/teku/build/install/teku/bin/teku sources/usr/bin/teku-kl
	cp /tmp/teku_temp/teku/build/install/teku/lib/* sources/usr/share/teku/kiln/lib/
	sed -i 's/"$${APP_HOME:-\.\/}\.\."/"$${APP_HOME:-\.\/}\.\.\/share\/teku\/kiln"/g' sources/usr/bin/teku-kl
	rm -rf /tmp/teku_temp

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm -r sources/usr/share/
	rm sources/usr/bin/teku-kl

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
