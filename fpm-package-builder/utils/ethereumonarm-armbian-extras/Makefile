#Install FPM
#apt-get install ruby ruby-dev rubygems build-essential
#gem install --no-document fpm
SHELL := /bin/bash

PKG_NAME := ethereumonarm-armbian-extras
PKG_DESCRIPTION := "Armbian script to config zram, ramlog, and tmpdir for Ethereum on ARM images"

PKG_VERSION := 1.2.2
PKG_RELEASE := 0

PKG_MAINTAINER := "Fernando Collado <fcollado@ethereumonarm.com>"
PKG_ARCH := all

PKG_AFTER_INSTALL := extras/ethereumonarm-armbian-extras.postinst
PKG_AFTER_REMOVE := extras/ethereumonarm-armbian-extras.postrm
PKG_BEFPRE_REMOVE := extras/ethereumonarm-armbian-extras.prerm

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_DEB := ${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}_${PKG_ARCH}.deb

FPM_OPTS := -s dir -n $(PKG_NAME) -v $(PKG_VERSION) --iteration $(PKG_RELEASE)\
	-C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	--after-install $(PKG_AFTER_INSTALL) --before-remove $(PKG_BEFPRE_REMOVE)\
	--after-remove $(PKG_AFTER_REMOVE) -a $(PKG_ARCH) -p $(OUTPUTDIR) -x */.gitkeep\
	--depends	dphys-swapfile\
	--depends dc
all: deb test

deb: ## Create deb package
	chmod 644 $(SOURCESDIR)etc/cron.d/armbian-truncate-logs
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
