#Install FPM
#apt-get install ruby ruby-dev rubygems build-essential
#gem install --no-document fpm
SHELL := /bin/bash

PKG_NAME := ethereumonarm-monitoring-extras
PKG_DESCRIPTION := "Ethereum on ARM monitoring config"
PKG_VERSION := 1.0.5
PKG_RELEASE := 0
PKG_MAINTAINER := "Fernando Collado <fcollado@ethereumonarm.com>"
PKG_ARCH := all
SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_DEB := ${pkg_name}_${pkg_version}-${pkg_release}_${pkg_arch}.deb
FPM_OPTS := -s dir -n $(PKG_NAME) -v $(PKG_VERSION) --iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)  -a $(PKG_ARCH) -p $(OUTPUTDIR) -x */.gitkeep

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_OPTS) --depends grafana --depends prometheus --depends prometheus-node-exporter --depends ufw

help:  ## List targets.
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
