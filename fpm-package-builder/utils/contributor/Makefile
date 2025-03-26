#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

CONTRIBUTOOR_VERSION := $(shell curl -s "https://api.github.com/repos/ethpandaops/contributoor/releases/latest" | jq -r '.tag_name | sub("^v"; "")')

PKG_RELEASE := 0
PKG_NAME := contributoor

PKG_DESCRIPTION := "Xatu Contributoor Service"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL	:= https://github.com/ethpandaops/contributoor
PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Apache License 2.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_RPM := $(PKG_NAME)-$(CONTRIBUTOOR_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(CONTRIBUTOOR_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(CONTRIBUTOOR_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/contributoor.service \
	--config-files /etc/ethereum/contributoor/config.yaml

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(CONTRIBUTOOR_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

all: prepare deb clean test

prepare: ## Download the latest binary and prepare the package files
	wget -qO- https://github.com/ethpandaops/contributoor/releases/download/v$(CONTRIBUTOOR_VERSION)/contributoor_$(CONTRIBUTOOR_VERSION)_linux_arm64.tar.gz | tar --no-same-owner -xz -C $(SOURCESDIR)/usr/bin/ sentry
	wget -qO- https://github.com/ethpandaops/contributoor-installer/releases/download/v$(CONTRIBUTOOR_VERSION)/contributoor-installer_$(CONTRIBUTOOR_VERSION)_linux_arm64.tar.gz | tar --no-same-owner -xz -C $(SOURCESDIR)/usr/bin/ contributoor

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/contributoor
	rm sources/usr/bin/sentry

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
		printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
	else \
		printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
		exit 1; \
	fi

help: ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
