#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

EME_VERSION := $(shell curl -s https://api.github.com/repos/ethpandaops/ethereum-metrics-exporter/releases/latest | jq -r '.tag_name' | tr -d "v")

PKG_RELEASE := 3
PKG_NAME := ethereum-metrics-exporter

PKG_DESCRIPTION := "Provides a client-agnostic set of metrics for monitoring the health and performance of Ethereum nodes across multiple client implementations, by relying on well-defined APIs"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/ethpandaops/ethereum-metrics-exporter

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_AFTER_INSTALL := extras/ethereum-metrics-exporter.postinst
PKG_AFTER_REMOVE := extras/ethereum-metrics-exporter.postrm
PKG_BEFPRE_REMOVE := extras/ethereum-metrics-exporter.prerm

PKG_RPM := $(PKG_NAME)-$(EME_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(EME_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(EME_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--after-install $(PKG_AFTER_INSTALL) --before-remove $(PKG_BEFPRE_REMOVE)\
--after-remove $(PKG_AFTER_REMOVE) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/ethereum-metrics-exporter.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(EME_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean test

prepare: ## Download the latest binary and prepare the package files
	wget https://github.com/ethpandaops/ethereum-metrics-exporter/releases/download/v$(EME_VERSION)/ethereum-metrics-exporter_$(EME_VERSION)_linux_arm64.tar.gz -O - | tar -xz  -C sources/usr/bin/ --wildcards --absolute-names --no-anchored  '*ethereum-metrics-exporter*' --transform='s/ethereum-metrics-exporter-$(EME_VERSION)/ethereum-metrics-exporter/' 


deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/ethereum-metrics-exporter

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi

help:  ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
