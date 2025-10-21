SHELL := /bin/bash

# ------------------------------------------------------------------------------
# Package Metadata
# ------------------------------------------------------------------------------

ETHREX_L2_VERSION := 5.0.0
PKG_RELEASE := 0
PKG_NAME := ethrex-l2

PKG_DESCRIPTION := "Ethrex L2 is a minimalist, modular, and fast rollup implementation built by LambdaClass, enabling L2 sequencers and provers to run efficiently on ARM devices."
PKG_MAINTAINER := 'Diego Losada <dlosada@ethereumonarm.com>'
CATEGORY := science
WEB_URL := https://github.com/lambdaclass/ethrex
PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU Lesser General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../../packages

PKG_DEB := $(PKG_NAME)_$(ETHREX_L2_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH_DEB).deb

# ------------------------------------------------------------------------------
# FPM Options
# ------------------------------------------------------------------------------


FPM_DEB_OPTS = $(COMMON_FPM_OPTS) \
--deb-systemd extras/ethrex-l2.service \
--deb-systemd extras/ethrex-l2-prover.service \
-C $(SOURCESDIR)

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(ETHREX_L2_VERSION) --license $(PKG_LICENSE)\
--vendor $(PKG_VENDOR) --iteration $(PKG_RELEASE) -C $(SOURCESDIR)\
--maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION) -a $(PKG_ARCH_DEB)\
--category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
--deb-systemd extras/ethrex-l2.service \
--deb-systemd extras/ethrex-l2-prover.service 


# ------------------------------------------------------------------------------
# Targets
# ------------------------------------------------------------------------------

all: prepare deb clean test

prepare: ## Download ethrex-l2 binary and prepare package files
	@echo "Downloading Ethrex L2 v$(ETHREX_L2_VERSION)..."
	mkdir -p sources/usr/bin
	wget -q https://github.com/lambdaclass/ethrex/releases/download/v$(ETHREX_L2_VERSION)/ethrex-l2-linux-aarch64 -O sources/usr/bin/ethrex-l2
	chmod +x sources/usr/bin/ethrex-l2
	@echo "✓ ethrex-l2 binary ready"

deb: ## Create Debian package
	fpm $(FPM_DEB_OPTS) -t deb -p $(OUTPUTDIR)/$(PKG_DEB)
	@echo "✓ Debian package built: $(PKG_DEB)"

.PHONY: clean test
clean: ## Clean up temporary binaries
	rm -f sources/usr/bin/ethrex-l2

test:
	@if [ -f $(OUTPUTDIR)/$(PKG_DEB) ]; then \
		printf "\033[32mPackage $(PKG_DEB) successfully created\033[0m\n"; \
	else \
		printf "\033[31mError: Package $(PKG_DEB) not found\033[0m\n"; \
		exit 1; \
	fi

help: ## List all available targets
	@grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' \
	-e 's/^\(.\+\):\(.*\)/\x1b[36m\1\x1b[m:\2/' | column -c2 -t -s :