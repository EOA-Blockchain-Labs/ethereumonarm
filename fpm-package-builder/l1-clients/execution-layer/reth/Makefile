#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

RETH_VERSION_GIT := $(shell curl -s "https://api.github.com/repos/paradigmxyz/reth/releases/latest" | jq -r '.tag_name')
RETH_VERSION := $(shell curl -s "https://api.github.com/repos/paradigmxyz/reth/releases/latest" | jq -r '.tag_name' | tr -d "v" | sed -E 's/([a-z]+)\.([0-9]+)/\1\2/')

PKG_RELEASE := 0
PKG_NAME := reth

PKG_DESCRIPTION := "Rust implementation of the Ethereum protocol by Paradigm team"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://paradigmxyz.github.io/reth/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := $(PKG_NAME)-$(RETH_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(RETH_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(RETH_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/reth.service \
--depends merge-config

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(RETH_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean test

prepare: ## Donwload the latest binary and prepare the package files
	mkdir -p /tmp/reth_tmp
	cd /tmp/reth_tmp ; git clone https://github.com/paradigmxyz/reth.git ; cd reth ; git checkout $(RETH_VERSION_GIT) 
	cd /tmp/reth_tmp/reth ; PKG_CONFIG=/usr/bin/aarch64-linux-gnu-pkg-config PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig/ cargo build --profile maxperf --target aarch64-unknown-linux-gnu 
	cp /tmp/reth_tmp/reth/target/aarch64-unknown-linux-gnu/maxperf/reth sources/usr/bin/
	rm -rf /tmp/reth_tmp

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/reth

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi	

help:  ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
