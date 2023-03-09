#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

PAPYRUS_VERSION := $(shell date +"%y%m%d")

PKG_RELEASE := 0
PKG_NAME := papyrus

PKG_DESCRIPTION := "StarkNet Papyrus node"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL :=  https://github.com/starkware-libs/papyrus

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_RPM := $(PKG_NAME)-$(PAPYRUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(PAPYRUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(PAPYRUS_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
  --deb-systemd extras/papyrus.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PAPYRUS_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

all: prepare deb clean test

prepare: ## Donwload the latest binary and compile the package files
	mkdir -p /tmp/papyrus_tmp
	cd /tmp/papyrus_tmp ; git clone https://github.com/starkware-libs/papyrus.git
	cd /tmp/papyrus_tmp/papyrus ; PKG_CONFIG=/usr/bin/aarch64-linux-gnu-pkg-config PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig/ cargo build --release --package papyrus_node --bin papyrus_node --target aarch64-unknown-linux-gnu 
	cp /tmp/papyrus_tmp/papyrus/target/aarch64-unknown-linux-gnu/release/papyrus_node sources/usr/bin/

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/papyrus_node
	rm -rf /tmp/papyrus_tmp

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
