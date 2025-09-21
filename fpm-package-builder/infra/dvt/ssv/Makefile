#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

#SSV_VERSION := $(shell date +"%y%m%d")
SSV_VERSION := $(shell curl -s "https://api.github.com/repos/ssvlabs/ssv/releases/latest" | jq -r '.tag_name' | tr -d "v")
SSV_KEYS_VERSION := $(shell curl -s "https://api.github.com/repos/ssvlabs/ssv-keys/releases/latest" | jq -r '.tag_name' | tr -d "v")
PKG_RELEASE := 0
PKG_NAME := dvt-ssv

PKG_DESCRIPTION := "SSV DVT client"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/ObolNetwork/ssv

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

PKG_AFTER_INSTALL := extras/postinstall

SOURCESDIR := sources/
OUTPUTDIR := ../../../packages

PKG_RPM := $(PKG_NAME)-$(SSV_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(SSV_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(SSV_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--after-install $(PKG_AFTER_INSTALL) --deb-systemd extras/ssv.service \

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(SSV_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean

prepare: ## Download the latest binary and prepare the package files
	mkdir -p /tmp/ssv_tmp
	cd /tmp/ssv_tmp/ ; git clone https://github.com/ssvlabs/ssv.git ; cd ssv ; git checkout v$(SSV_VERSION);  env GO111MODULE=on CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 go build -o ./bin/ssvnode -ldflags "-X main.Commit=`git rev-parse HEAD` -X main.Version=`git describe --tags $(git rev-list --tags --max-count=1)`" ./cmd/ssvnode/
	cp /tmp/ssv_tmp/ssv/bin/ssvnode sources/usr/bin/
	# install ssv-keys
	mkdir -p /tmp/ssv_keys_tmp
	cd /tmp/ssv_keys_tmp/ ; git clone https://github.com/ssvlabs/ssv-keys.git ; cd ssv-keys ; git checkout v$(SSV_KEYS_VERSION);
	cd /tmp/ssv_keys_tmp/ssv-keys ; sed -i '/"package-linux": "pkg dist\/cli-interactive.js --targets node22-linux-x64 --output bin\/linux\/ssv-keys-lin --compress GZip",/a \ \ "package-linux-arm64": "pkg dist/cli-interactive.js --targets node22-linux-arm64 --output bin/linux/ssv-keys-lin-arm64 --compress GZip",' package.json
	cd /tmp/ssv_keys_tmp/ssv-keys ; pnpm install --fetch-timeout 1000000 && pnpm package-linux-arm64
	cp /tmp/ssv_keys_tmp/ssv-keys/bin/linux/ssv-keys-lin-arm64 sources/usr/bin/ssv-keys

deb: ## Create deb package
	echo $(PKG_DEB) $(FPM_DEB_OPTS)
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	rm sources/usr/bin/ssv*
	rm -rf /tmp/ssv_tmp/

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi
	
help:  ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
