# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Armbian Extras)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - This is a meta-package that ships config files and scripts
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= ethereumonarm-armbian-extras
PKG_RELEASE     ?= 0
PKG_ARCH        ?= all
PKG_ARCH_RPM    ?= noarch
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU General Public License v3.0
PKG_DESCRIPTION ?= Armbian script to config zram, ramlog, and tmpdir for Ethereum on ARM images
PKG_MAINTAINER  ?= Fernando Collado <fcollado@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ethereumonarm/armbian-files
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Install/Remove Scripts
# ----------------------------------------------------------------------
PKG_AFTER_INSTALL ?= extras/ethereumonarm-armbian-extras.postinst
PKG_AFTER_REMOVE  ?= extras/ethereumonarm-armbian-extras.postrm
PKG_BEFPRE_REMOVE ?= extras/ethereumonarm-armbian-extras.prerm

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
PKG_VERSION ?= 1.2.3

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(PKG_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
  -s dir \
  -n $(PKG_NAME) \
  -v $(PKG_VERSION) \
  --iteration $(PKG_RELEASE) \
  --vendor "$(PKG_VENDOR)" \
  --license "$(PKG_LICENSE)" \
  --description "$(PKG_DESCRIPTION)" \
  --maintainer "$(PKG_MAINTAINER)" \
  --category "$(CATEGORY)" \
  --url "$(WEB_URL)" \
  -C $(SOURCESDIR) \
  -x '*/.gitkeep'

# ----------------------------------------------------------------------
# Debian-specific options
# ----------------------------------------------------------------------
FPM_DEB_OPTS = $(FPM_COMMON_OPTS) \
  -t deb \
  --architecture $(PKG_ARCH) \
  --after-install $(PKG_AFTER_INSTALL) \
  --before-remove $(PKG_BEFPRE_REMOVE) \
  --after-remove $(PKG_AFTER_REMOVE) \
  --deb-no-default-config-files \
  $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
  --depends dphys-swapfile \
  --depends dc

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
  -t rpm \
  --architecture $(PKG_ARCH_RPM) \
  --after-install $(PKG_AFTER_INSTALL) \
  --before-remove $(PKG_BEFPRE_REMOVE) \
  --after-remove $(PKG_AFTER_REMOVE) \
  --depends dphys-swapfile \
  --depends dc

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — Prepare source files
# ----------------------------------------------------------------------
prepare: ## Set permissions on config files
	@echo "🌱 This is a configuration-only package. Setting file permissions..."
	mkdir -p $(SOURCESDIR)
	if [ -f $(SOURCESDIR)/etc/cron.d/armbian-truncate-logs ]; then \
	  chmod 644 $(SOURCESDIR)/etc/cron.d/armbian-truncate-logs; \
	  echo "✅ File permissions set."; \
	else \
	  echo "ℹ️ No cron file found to set permissions on. Skipping."; \
	fi

# ----------------------------------------------------------------------
# deb — build Debian package
# ----------------------------------------------------------------------
deb: prepare ## Build .deb package
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building DEB package..."
	fpm $(FPM_DEB_OPTS) -p "$(PKG_DEB)" .
	if [[ -f "$(PKG_DEB)" ]]; then \
	  echo "✅ DEB package created at $(PKG_DEB)"; \
	else \
	  echo "❌ DEB package creation failed."; exit 1; \
	fi

# ----------------------------------------------------------------------
# rpm — build RPM package
# ----------------------------------------------------------------------
rpm: prepare ## Build .rpm package
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building RPM package..."
	fpm $(FPM_RPM_OPTS) -p "$(PKG_RPM)" .
	if [[ -f "$(PKG_RPM)" ]]; then \
	  echo "✅ RPM package created at $(PKG_RPM)"; \
	else \
	  echo "❌ RPM package creation failed."; exit 1; \
	fi

# ----------------------------------------------------------------------
# clean — remove build artifacts
# ----------------------------------------------------------------------
clean: ## No binaries to clean
	@echo "🧹 No binaries to clean for this package."

# ----------------------------------------------------------------------
# test — verify build success
# ----------------------------------------------------------------------
test: ## Check that .deb exists
	if [[ -f "$(PKG_DEB)" ]]; then \
	  echo "🧪 Test: .deb exists — OK ✅"; \
	else \
	  echo "🧪 Test: .deb missing — ❌"; exit 1; \
	fi

# ----------------------------------------------------------------------
# release — full CI build (includes RPM)
# ----------------------------------------------------------------------
release: clean prepare deb rpm test ## Clean + Prepare + Build + Test (all)
	@echo "🎉 All packages built successfully for $(PKG_ARCH)"

# ----------------------------------------------------------------------
# help — show all available targets
# ----------------------------------------------------------------------
help: ## Show available targets
	echo ""
	echo "EOA Packaging — $(PKG_NAME)"
	echo ""
	awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	echo ""
	echo "Version resolved: $(PKG_VERSION)"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================