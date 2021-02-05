#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

DEPOSIT_VERSION := $(shell curl -s "https://api.github.com/repos/ethereum/eth2.0-deposit-cli/tags" | jq '.[0].name' | tr -d  '"'| tr -d "v")

PKG_RELEASE := 1
PKG_NAME := eth2.0-deposit-cli

PKG_DESCRIPTION := "Ethereum Foundation eth2 deposit cli tool"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://github.com/ethereum/eth2.0-deposit-cli/

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "Creative Commons Zero v1.0 Universal"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(DEPOSIT_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(DEPOSIT_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(DEPOSIT_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(DEPOSIT_VERSION) --license $(PKG_LICENSE)\
	--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


all: prepare deb clean

prepare: ## Donwload the latest binary and compile the package files
	-sudo apt-get install python3-pip
	pip3 install pyinstaller click
	-git clone https://github.com/ethereum/eth2.0-deposit-cli.git
	-cd eth2.0-deposit-cli; git checkout v$(DEPOSIT_VERSION); sudo ./deposit.sh install
	cd eth2.0-deposit-cli/build_configs/linux ; PATH=~/.local/bin:$(PATH) pyinstaller -F build.spec
	cp eth2.0-deposit-cli/build_configs/linux/dist/deposit sources/usr/bin

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/deposit
	rm eth2.0-deposit-cli -rf

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
