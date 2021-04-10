#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

ROCKETPOOL_VERSION := "1.0.0-beta.1"

PKG_RELEASE := 0
PKG_NAME := rocketpool

PKG_DESCRIPTION := "Rocket Pool is a next generation Ethereum proof of stake (PoS) infrastructure service "
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://github.com/rocketpool/go-rocketpool

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := GPL3

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(rocketpool_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(rocketpool_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb


FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(ROCKETPOOL_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/rocketpool.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PKG_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir -p /tmp/rocketpool_tmp
	cd /tmp/rocketpool_tmp ; git clone https://github.com/rocket-pool/smartnode.git ; cd smartnode ; git checkout v$(ROCKETPOOL_VERSION); \
	cd rocketpool-cli ; env GOOS=linux GOARCH=arm64 go build rocketpool-cli.go ; cd ../rocketpool ; env GOOS=linux GOARCH=arm64 go build rocketpool.go
	cp /tmp/rocketpool_tmp/smartnode/rocketpool/rocketpool sources/usr/bin/rocketpoold
	cp /tmp/rocketpool_tmp/smartnode/rocketpool-cli/rocketpool-cli sources/usr/bin/rocketpool
	rm -rf /tmp/rocketpool_tmp


deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/rocketpool

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
