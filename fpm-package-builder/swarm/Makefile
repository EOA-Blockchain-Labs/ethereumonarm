#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

BEE_VERSION := $(shell curl -s "https://api.github.com/repos/ethersphere/bee/releases/latest" | jq .name | tr -d  '"'| tr -d "v")

PKG_RELEASE := 1
PKG_NAME := bee

PKG_DESCRIPTION := "Bee is a Swarm client implemented in Go."
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://swarm.ethereum.org/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "BSD 3-Clause License"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(BEE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(BEE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb


FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(BEE_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/bee.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(BEE_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	wget https://github.com/ethersphere/bee/releases/download/v$(BEE_VERSION)/bee-linux-arm64 -O $(SOURCESDIR)/usr/bin/bee
	chmod 755  $(SOURCESDIR)/usr/bin/bee

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/bee

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
