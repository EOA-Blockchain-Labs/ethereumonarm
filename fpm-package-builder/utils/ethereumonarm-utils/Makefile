#Install FPM
#apt-get install ruby ruby-dev rubygems build-essential
#gem install --no-document fpm
SHELL := /bin/bash

PKG_NAME := ethereumonarm-utils
PKG_DESCRIPTION := "Ethereum on ARM utils"

PKG_VERSION := 1.0.6
PKG_RELEASE := 2

PKG_MAINTAINER := "Fernando Collado <fcollado@ethereumonarm.com>"
PKG_ARCH := all

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_DEB := ${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}_${PKG_ARCH}.deb

FPM_OPTS := -s dir -n $(PKG_NAME) -v $(PKG_VERSION) --iteration $(PKG_RELEASE)\
	-C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH) -p $(OUTPUTDIR) -x */.gitkeep\

all: deb test

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_OPTS)

.PHONY: test
test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
        printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
    else \
        printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
        exit 1; \
    fi

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
