SHELL := /bin/bash

PROM_VERSION := $(shell curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r '.name' | awk '{print $$1}')
PROM_URL := $(shell curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest |  jq -r '.assets[] | select(.name | contains("linux-arm64")).browser_download_url')

PKG_RELEASE := 0
PKG_NAME := prometheus

PKG_DESCRIPTION := "Prometheus monitoring system and time series database"
PKG_MAINTAINER := "Fernando Collado fernando@ethereumonarm.com"

CATEGORY := science
WEB_URL :=  https://prometheus.io/

PKG_VENDOR := "ethereumonarm"
PKG_LICENSE := Apache-2.0

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages/

PKG_RPM := $(PKG_NAME)-$(PROM_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(PROM_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(PROM_VERSION) --license $(PKG_LICENSE)\
 --vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
 --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PROM_VERSION) --license $(PKG_LICENSE)\
 --vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
 --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

all: prepare deb clean test

prepare:
	wget $(PROM_URL) -O - | tar -xz -C sources/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 1 '*/prometheus' '*/promtool'

deb:
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm:
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean:
	rm sources/usr/bin/prometheus
	rm sources/usr/bin/promtool
test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        	printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    	else \
        	printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        	exit 1; \
    	fi

help:
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
