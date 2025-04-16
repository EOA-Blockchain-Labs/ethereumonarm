#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

PRYSM_VERSION := $(shell curl -Ls "https://api.github.com/repos/prysmaticlabs/prysm/releases/latest" | jq -r '.tag_name' | tr -d "v")
PRYSM_DHASH :=$(shell curl -Ls "https://api.github.com/repos/prysmaticlabs/prysm/tags" | jq -c 'map(select(.name | contains("$(PRYSM_VERSION)")))' | jq -r '.[0].commit.sha' | cut -c1-8)

PKG_RELEASE := 1
PKG_NAME := prysm

PKG_DESCRIPTION := "Ethereum 2.0 Prysmatic Labs implementation"
PKG_MAINTAINER := "diego losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/prysmaticlabs/prysm

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := ${PKG_NAME}-${PRYSM_VERSION}-${PKG_RELEASE}_${PKG_ARCH_RPM}.rpm
PKG_DEB := ${PKG_NAME}_${PRYSM_VERSION}-${PKG_RELEASE}_${PKG_ARCH_DEB}.deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(PRYSM_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/prysm-beacon.service --deb-systemd extras/prysm-validator.service\
	--deb-systemd extras/prysm-beacon-mev.service --deb-systemd extras/prysm-validator-mev.service\
	--deb-systemd extras/prysm-beacon-hoodi.service --deb-systemd extras/prysm-validator-hoodi.service\
	--deb-systemd extras/prysm-beacon-hoodi-mev.service --deb-systemd extras/prysm-validator-hoodi-mev.service\
	--deb-systemd extras/prysm-beacon-holesky.service --deb-systemd extras/prysm-validator-holesky.service\
	--conflicts prysm-beacon\
	--conflicts prysm-validator\
	--provides prysm-beacon\
	--provides prysm-validator\
	--replaces prysm-beacon\
	--replaces prysm-validator\
	--depends merge-config

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PRYSM_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

all: prepare deb clean test

prepare: ## Download the latest binary and prepare the package files
	wget https://github.com/prysmaticlabs/prysm/releases/download/v$(PRYSM_VERSION)/beacon-chain-v$(PRYSM_VERSION)-linux-arm64 -O sources/usr/bin/beacon-chain
	wget https://github.com/prysmaticlabs/prysm/releases/download/v$(PRYSM_VERSION)/validator-v$(PRYSM_VERSION)-linux-arm64 -O sources/usr/bin/validator
	chmod +x sources/usr/bin/beacon-chain sources/usr/bin/validator 
deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/*

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi
