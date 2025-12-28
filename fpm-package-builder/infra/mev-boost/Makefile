# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (mev-boost)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream mev-boost binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= mev-boost
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Mev Boost is open source middleware run by validators to access a competitive block-building market
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/flashbots/mev-boost
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v2.0.2)
MEV_TAG_V := $(shell curl -s https://api.github.com/repos/flashbots/mev-boost/releases/latest | jq -r '.tag_name')
# Get the version without "v" (e.g., 2.0.2)
MEV_VERSION := $(shell echo "$(MEV_TAG_V)" | tr -d "v")

MEV_TARBALL := mev-boost_$(MEV_VERSION)_linux_$(PKG_ARCH).tar.gz
MEV_URL     := https://github.com/flashbots/mev-boost/releases/download/$(MEV_TAG_V)/$(MEV_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
MEV_RELEASE_JSON := $(shell curl -s https://api.github.com/repos/flashbots/mev-boost/releases/latest)
MEV_SHA256 := $(shell echo '$(MEV_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(MEV_TARBALL)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(MEV_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(MEV_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(MEV_VERSION) \
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
    --deb-no-default-config-files \
    $(shell test -d extras && find extras -name 'mev-boost*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'mev-boost*.service' -printf "--rpm-systemd %p ") \
    --depends merge-config

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — download & stage mev-boost binary
# ----------------------------------------------------------------------
prepare: ## Download latest mev-boost and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest mev-boost version..."
	if [[ -z "$(MEV_TAG_V)" || "$(MEV_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest mev-boost version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading mev-boost $(MEV_VERSION) ($(MEV_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(MEV_TARBALL)" "$(MEV_URL)" || { echo "❌ Download failed: $(MEV_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(MEV_SHA256)  .build/$(MEV_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(MEV_TARBALL)"; exit 1; };
	
	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(MEV_TARBALL)" -C $(SOURCESDIR)/usr/bin/ mev-boost
	chmod 0755 "$(SOURCESDIR)/usr/bin/mev-boost"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/mev-boost"

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
clean: ## Remove staged binaries and temp files
	rm -rf $(SOURCESDIR)/usr/bin/mev-boost* .build
	@echo "🧹 Clean complete (staged files and .build removed)."

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
	echo "Version resolved: $(MEV_VERSION) (Tag: $(MEV_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================