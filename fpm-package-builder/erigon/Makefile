#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

ERIGON_VERSION := $(shell curl -s "https://api.github.com/repos/ledgerwatch/erigon/releases/latest" | jq -r '.tag_name' | tr -d "v")
ERIGON_DHASH :=$(shell curl -s "https://api.github.com/repos/ledgerwatch/erigon/tags" | jq -c 'map(select(.name | contains("$(ERIGON_VERSION)")))' | jq -r '.[0].commit.sha' | cut -c1-8)

PKG_RELEASE := 0
PKG_NAME := erigon

PKG_DESCRIPTION := "Erigon Go implementation of the Ethereum protocol"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/ledgerwatch/erigon

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(ERIGON_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(ERIGON_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(ERIGON_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/erigon.service --deb-systemd extras/erigon-rpc.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(ERIGON_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean

prepare: ## Download the latest binary and prepare the package files
	sudo gem install --no-document fpm
	mkdir -p /tmp/erigon_tmp
	 ## Clone GIT repo, add flags for crosscompilation and compile 
	cd /tmp/erigon_tmp ; git clone --recurse-submodules -j8 https://github.com/ledgerwatch/erigon.git ; cd erigon ; git checkout v$(ERIGON_VERSION); sed -i 's/\(env\)/\1 CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64/' Makefile ; make erigon ; make rpcdaemon
	cp /tmp/erigon_tmp/erigon/build/bin/erigon sources/usr/bin/ ; cp /tmp/erigon_tmp/erigon/build/bin/rpcdaemon sources/usr/bin/
	rm -rf /tmp/erigon_tmp

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/erigon

help:  ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
