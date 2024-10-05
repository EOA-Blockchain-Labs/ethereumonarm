#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

#CHARON_VERSION := $(shell date +"%y%m%d")
CHARON_VERSION := $(shell curl -s "https://api.github.com/repos/ObolNetwork/charon/releases/latest" | jq -r '.tag_name' | tr -d "v")
PKG_RELEASE := 0
PKG_NAME := obol-charon

PKG_DESCRIPTION := "Obol DVT client"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/ObolNetwork/charon

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := $(PKG_NAME)-$(CHARON_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(CHARON_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(CHARON_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/charon.service \

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(CHARON_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean

prepare: ## Download the latest binary and prepare the package files
	mkdir -p /tmp/charon_tmp
	cd /tmp/charon_tmp/ ; git clone https://github.com/ObolNetwork/charon ; cd charon ; git checkout v$(CHARON_VERSION);  env GO111MODULE=on CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 go build -o charon
	cp /tmp/charon_tmp/charon/charon sources/usr/bin/charon

deb: ## Create deb package
	echo $(PKG_DEB) $(FPM_DEB_OPTS)
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/charon
	rm -rf /tmp/charon_tmp/

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi
	
help:  ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
