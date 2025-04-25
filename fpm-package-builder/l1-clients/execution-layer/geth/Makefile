#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

GETH_VERSION := $(shell curl -s "https://api.github.com/repos/ethereum/go-ethereum/releases/latest" | jq -r '.tag_name' | tr -d "v")
GETH_DHASH :=$(shell curl -s "https://api.github.com/repos/ethereum/go-ethereum/tags" | jq -c 'map(select(.name | contains("$(GETH_VERSION)")))' | jq -r '.[0].commit.sha' | cut -c1-8)

PKG_RELEASE := 0
PKG_NAME := geth

PKG_DESCRIPTION := "Official Go implementation of the Ethereum protocol"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://geth.ethereum.org

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := $(PKG_NAME)-$(GETH_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(GETH_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(GETH_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/geth.service --deb-systemd extras/geth-hoodi.service\
--deb-systemd extras/geth-holesky.service --deb-systemd extras/geth-gnosis.service\
--depends merge-config

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(GETH_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean test

prepare: ## Download the latest binary and prepare the package files
	wget https://gethstore.blob.core.windows.net/builds/geth-linux-$(PKG_ARCH_DEB)-$(GETH_VERSION)-$(GETH_DHASH).tar.gz -O - | tar -xz -C sources/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 1 '*/geth'

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/geth

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi	

help:  ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
