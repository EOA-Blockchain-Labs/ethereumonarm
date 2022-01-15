#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

ETHVAL_VERSION := $(shell date +"%y%m%d")

PKG_RELEASE := 0
PKG_NAME := eth2-val-tools

PKG_DESCRIPTION := "eth2-val-tool cli tool"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://github.com/protolambda/eth2-val-tools

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Creative Commons Zero v1.0 Universal"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(ETHVAL_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(ETHVAL_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(ETHVAL_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(ETHVAL_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

BUILD_ARCH := $(shell uname -p)

all: prepare deb clean

prepare: ## Donwload the latest binary and compile the package files
	mkdir -p /tmp/eth2-val-tools_tmp
	cd /tmp/eth2-val-tools_tmp/ ; git clone https://github.com/protolambda/eth2-val-tools.git ; cd eth2-val-tools/ ; env CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 GO111MODULE=on go build
	cp /tmp/eth2-val-tools_tmp/eth2-val-tools/eth2-val-tools sources/usr/bin/
	rm -rf /tmp/eth2-val-tools_tmp

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/eth2-val-tools

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
