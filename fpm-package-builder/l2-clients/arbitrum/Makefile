#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

NITRO_VERSION := $(shell curl -s "https://api.github.com/repos/OffchainLabs/nitro/releases/latest" | jq -r '.tag_name' | tr -d "v")
#NITRO_DHASH :=$(shell curl -s "https://api.github.com/repos/ethereum/go-ethereum/tags" | jq -c 'map(select(.name | contains("$(NITRO_VERSION)")))' | jq -r '.[0].commit.sha' | cut -c1-8)
#DOCKER_CONTAINER := "offchainlabs/nitro-node:v3.6.6-a1deae2"
#DOCKER_CONTAINER := $(shell curl -s "https://api.github.com/repos/OffchainLabs/nitro/releases/latest" | jq -r '.body' | sed -n 's/.*Docker Hub at \([^[:space:]]*\).*/\1/p')
DOCKER_CONTAINER := $(shell curl -s "https://api.github.com/repos/OffchainLabs/nitro/releases/latest" | jq -r '.body' | grep -oP 'offchainlabs\/nitro-node:v\d+\.\d+\.\d+(?:-[0-9a-f]+)?' | head -n 1)

PKG_RELEASE := 0
PKG_NAME := arbitrum-nitro

PKG_DESCRIPTION := "Arbitrum nitro node"
PKG_MAINTAINER := "Diego Losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://nitro.ethereum.org

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_RPM := $(PKG_NAME)-$(NITRO_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_RPM).rpm
PKG_DEB := $(PKG_NAME)_$(NITRO_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(NITRO_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/nitro.service\
--depends merge-config

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(NITRO_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_RPM)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\

all: prepare deb clean test

prepare: ## Download the latest binary and prepare the package files
	set -e ;\
	docker pull --platform linux/arm64 $(DOCKER_CONTAINER) ;\
	docker run --entrypoint /bin/bash --platform linux/arm64 -it -d $(DOCKER_CONTAINER) ;\
	DOCKER_CONTAINER_ID=$$(docker ps -q | head -n 1) ;\
	docker cp $$DOCKER_CONTAINER_ID:/usr/local/bin/nitro sources/usr/bin/nitro ;\

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean test
clean: ## Clean up
	set -e ;\
	rm sources/usr/bin/nitro ;\
	docker stop $$(docker ps -aq) && docker rm $$(docker ps -aq) ;\

##DOCKER_CONTAINER_ID=$$(docker ps -qa | head -n 1) ;\	
##docker stop $$DOCKER_CONTAINER_ID && docker rm $$DOCKER_CONTAINER_ID ;\
test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi

help:  ## List targets.
	"$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
