#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

NETHERMIND_VERSION := $(shell curl -s "https://api.github.com/repos/NethermindEth/nethermind/releases/latest" | jq '.name' | tr -d  '"'| tr -d "v")
NETHERMIND_DHASH := $(shell curl -s "https://api.github.com/repos/NethermindEth/nethermind/tags" | jq -c 'map(select(.name | contains("$(NETHERMIND_VERSION)")))' | jq .[0].commit.sha | tr -d  '"' | cut -c1-7)

PKG_RELEASE := 2
PKG_NAME := nethermind

PKG_DESCRIPTION := "Ethereum 1 client written in .NET"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://nethermind.io

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := $(PKG_NAME)-$(NETHERMIND_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(NETHERMIND_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb


FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(NETHERMIND_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) -p $(OUTPUTDIR)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -x */.gitkeep\
	--deb-systemd extras/nethermind.service\
	--deb-user ethereum\
	--deb-group ethereum\
	--directories /opt/nethermind\
	--depends	libsnappy-dev\
	--depends libc6-dev\
	--depends libc6\
	--depends unzip

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(NETHERMIND_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER)\
	--description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM) --category $(CATEGORY)\
	--url $(WEB_URL) -p $(OUTPUTDIR)


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir -p /tmp/nethermind_tmp
	mkdir -p sources/opt/nethermind/logs
	wget https://nethdev.blob.core.windows.net/builds/nethermind-linux-$(PKG_ARCH_DEB)-$(NETHERMIND_VERSION)-$(NETHERMIND_DHASH).zip -P /tmp/nethermind_tmp
	unzip /tmp/nethermind_tmp/nethermind-linux-$(PKG_ARCH_DEB)-$(NETHERMIND_VERSION)-$(NETHERMIND_DHASH).zip -d sources/opt/nethermind
	rm -rf /tmp/nethermind_tmp
deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm -rf sources/opt/nethermind/*

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
