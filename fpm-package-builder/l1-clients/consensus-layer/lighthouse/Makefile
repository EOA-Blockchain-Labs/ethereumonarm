#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

LIGHTHOUSE_VERSION := $(shell curl -sL "https://api.github.com/repos/sigp/lighthouse/releases/latest" | jq '.tag_name' | tr -d  '"'| tr -d "v")

PKG_RELEASE := 0
PKG_NAME := lighthouse

PKG_DESCRIPTION := "Ethereum 2.0 Sigma Prime implementation"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://github.com/sigp/lighthouse/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Apache License 2.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := $(PKG_NAME)-$(LIGHTHOUSE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(LIGHTHOUSE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(LIGHTHOUSE_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/lighthouse-beacon.service --deb-systemd extras/lighthouse-validator.service\
	--deb-systemd extras/lighthouse-beacon-mev.service --deb-systemd extras/lighthouse-validator-mev.service\
	--deb-systemd extras/lighthouse-beacon-holesky.service --deb-systemd extras/lighthouse-validator-holesky.service\
	--deb-systemd extras/lighthouse-beacon-sepolia.service --deb-systemd extras/lighthouse-validator-sepolia.service\
	--deb-systemd extras/lighthouse-beacon-sepolia-mev.service --deb-systemd extras/lighthouse-validator-sepolia-mev.service\
	--deb-systemd extras/lighthouse-beacon-hoodi.service --deb-systemd extras/lighthouse-validator-hoodi.service\
	--deb-systemd extras/lighthouse-beacon-hoodi-mev.service --deb-systemd extras/lighthouse-validator-hoodi-mev.service\
	--depends merge-config

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(LIGHTHOUSE_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep
https://preply.com/edu/english/classroom-v2/5934186?source=learner-home-next-lesson-card
all: prepare deb clean test

prepare: ## Download the latest binary and prepare the package files
	wget  https://github.com/sigp/lighthouse/releases/download/v$(LIGHTHOUSE_VERSION)/lighthouse-v$(LIGHTHOUSE_VERSION)-aarch64-unknown-linux-gnu.tar.gz -O - | tar -xz -C sources/usr/bin/  lighthouse

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/lighthouse

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
