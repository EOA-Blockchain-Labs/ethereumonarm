# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Ethrex)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Ethrex binary from GitHub
# - Stages files into ./sources/usr/bin and ./sources/etc
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= ethrex
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Ethrex is a minimalist, stable, modular and fast implementation of the Ethereum protocol
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/lambdaclass/ethrex
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
ETHREX_VERSION := $(shell curl -sL "https://api.github.com/repos/lambdaclass/ethrex/releases/latest" | jq -r '.tag_name' | tr -d 'v')
ETHREX_BINARY  := ethrex-linux-$(PKG_ARCH_RPM)
ETHREX_URL     := https://github.com/lambdaclass/ethrex/releases/download/v$(ETHREX_VERSION)/$(ETHREX_BINARY)

# SHA256 checksum extracted from GitHub API asset digest field
ETHREX_RELEASE_JSON := $(shell curl -sL "https://api.github.com/repos/lambdaclass/ethrex/releases/latest")
ETHREX_SHA256  := $(shell echo '$(ETHREX_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(ETHREX_BINARY)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(ETHREX_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(ETHREX_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(ETHREX_VERSION) \
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
# Includes dynamic systemd unit detection and dynamic config-file tracking
FPM_DEB_OPTS = $(FPM_COMMON_OPTS) \
    -t deb \
    --architecture $(PKG_ARCH) \
    --deb-no-default-config-files \
    $(shell test -d extras && find extras -name '$(PKG_NAME)*.service' -printf "--deb-systemd %p " || true) \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name '$(PKG_NAME)*.service' -printf "--rpm-systemd %p " || true)

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — download & stage Ethrex binary
# ----------------------------------------------------------------------
prepare: ## Download latest Ethrex and stage directly into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Ethrex version..."
	if [[ -z "$(ETHREX_VERSION)" || "$(ETHREX_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest Ethrex version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Ethrex $(ETHREX_VERSION)..."
	mkdir -p $(SOURCESDIR)/usr/bin
	wget -q -O "$(SOURCESDIR)/usr/bin/$(PKG_NAME)" "$(ETHREX_URL)" || { echo "❌ Download failed: $(ETHREX_URL)"; exit 1; }; \
	@echo "🔐 Verifying SHA256..."
	@echo "$(ETHREX_SHA256)  $(SOURCESDIR)/usr/bin/$(PKG_NAME)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f "$(SOURCESDIR)/usr/bin/$(PKG_NAME)"; exit 1; };
	chmod 0755 "$(SOURCESDIR)/usr/bin/$(PKG_NAME)"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/$(PKG_NAME)"

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
	rm -rf $(SOURCESDIR)/usr/bin/$(PKG_NAME)*
	@echo "🧹 Clean complete (staged binaries removed)."

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
# help — show all available targets
# ----------------------------------------------------------------------
help: ## Show available targets
	echo ""
	echo "EOA Packaging — $(PKG_NAME)"
	echo ""
	awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	echo ""
	echo "Version resolved: $(ETHREX_VERSION)"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================