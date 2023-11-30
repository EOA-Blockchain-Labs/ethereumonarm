#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

LODESTAR_VERSION := $(shell curl -s "https://api.github.com/repos/ChainSafe/lodestar/releases/latest" | jq '.tag_name' | tr -d  '"'| tr -d "v")
LODESTAR_BIN_PATH := "lodestar.bin" # Update this to the path where your lodestarbin is located

PKG_RELEASE := 0
PKG_NAME := lodestar

PKG_DESCRIPTION := "Ethereum 2.0 Lodestar implementation"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://github.com/ChainSafe/lodestar

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := Apache License 2.0

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := .

PKG_DEB := $(PKG_NAME)_$(LODESTAR_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(LODESTAR_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/lodestar.service


all: prepare deb clean test

prepare: ## Replace Lodestar binary with Lodestar binary

	cp $(LODESTAR_BIN_PATH) $(SOURCESDIR)/usr/bin/lodestar

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm $(SOURCESDIR)/usr/bin/lodestar

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

