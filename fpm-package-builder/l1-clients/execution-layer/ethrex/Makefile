
SHELL := /bin/bash

# Using 'lambdaclass/ethrex' instead of 'erigontech/erigon'.
ETHREX_VERSION := $(shell curl -sL "https://api.github.com/repos/lambdaclass/ethrex/releases/latest" | jq -r '.tag_name' | tr -d 'v')

PKG_RELEASE := 1
PKG_NAME := ethrex

PKG_DESCRIPTION := "Ethrex Go implementation of the Ethereum protocol (execution client)"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/lambdaclass/ethrex

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := $(PKG_NAME)-$(ETHREX_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(ETHREX_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(ETHREX_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/ethrex.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(ETHREX_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean test

prepare: ## Download the latest binary and prepare the package files
	# WARNING: This DOWNLOAD URL is an assumption.
	# Please verify the actual file name format on the Ethrex releases page.
	wget https://github.com/lambdaclass/ethrex/releases/download/v$(ETHREX_VERSION)/ethrex-linux_aarch64 -O sources/usr/bin/ethrex
	chmod +x sources/usr/bin/ethrex

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/ethrex

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
		printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
	else \
		printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
		exit 1; \
	fi

help: ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"