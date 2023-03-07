#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

STATUS_VERSION := $(shell curl -s "https://api.github.com/repos/status-im/status-go/releases/latest" | jq -r .tag_name | tr -d "v")

PKG_RELEASE := 1
PKG_NAME := statusd

PKG_DESCRIPTION := "Description: Status is a messenger, crypto wallet, and Web3 browser built with state of the art technology. This is a Status Node, an Ethereum client for supporting the Status network"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"

CATEGORY := science
WEB_URL :=  https://status.im

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := MIT

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_RPM := $(PKG_NAME)-$(STATUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(STATUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb


FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(STATUS_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/statusd.service

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PKG_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep


BUILD_ARCH := $(shell uname -p)

#ifneq ($(BUILD_ARCH),aarch64)
#  $(error You need to use this script in a aarch64 system)
#endif


all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files

	sudo apt install ruby ruby-dev rubygems build-essential
	sudo gem install --no-document fpm
	mkdir -p /tmp/status_tmp
	cd /tmp/status_tmp ; git clone https://github.com/status-im/status-go.git ; cd status-go ; git checkout v$(STATUS_VERSION); sed -i 's/\(go build -mod=vendor -i\)/go build -mod=vendor/g' Makefile; sed -i 's/\(go \)/env CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 \1/' Makefile; make statusgo;
	cp /tmp/status_tmp/status-go/build/bin/statusd sources/usr/bin/
	#git lone https://github.com/status-im/status-go ~/go/src/github.com/status-im/status-go ; cd ~/go/src/github.com/status-im/status-go ; sed -i 's/\(go build -mod=vendor -i\)/go build -mod=vendor/g' Makefile; sed -i 's/\(go \)/env CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 \1/' Makefile; make statusgo
	#cp ~/go/src/github.com/status-im/status-go/build/bin/statusd sources/usr/bin/
	rm -rf /tmp/status_tmp

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/statusd

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
