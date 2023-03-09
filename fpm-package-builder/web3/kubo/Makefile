#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

IPFS_VERSION := $(shell curl -s "https://api.github.com/repos/ipfs/kubo/releases/latest" | jq .tag_name | tr -d  '"'| tr -d "v")

PKG_RELEASE := 0
PKG_NAME := kubo

PKG_DESCRIPTION := "Ipfs Kubo: A peer-to-peer hypermedia protocol designed to make the web faster, safer, and more open."
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://ipfs.tech/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := MIT

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_RPM := $(PKG_NAME)-$(IPFS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(IPFS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb


FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(IPFS_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/ipfs.service --conflicts ipfs

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PKG_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


all: prepare deb clean test

prepare: ## Donwload the latest binary and prepare the package files
	wget https://github.com/ipfs/kubo/releases/download/v$(IPFS_VERSION)/kubo_v$(IPFS_VERSION)_linux-arm64.tar.gz -O - | tar -xz -C sources/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 1 '*/ipfs'


deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/ipfs

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
