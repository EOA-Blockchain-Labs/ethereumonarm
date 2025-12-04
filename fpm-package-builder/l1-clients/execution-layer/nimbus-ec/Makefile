# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Nimbus-EC)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Nimbus binaries from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= nimbus-ec
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= Ethereum 1.0 Nimbus implementation
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://nimbus.team/
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# NOTE: The "latest" release on this repo is a "nightly" build.
# We must hardcode the desired version tag to get a stable release.
# This can be overridden from CI/CLI (e.g., make NIMBUS_VERSION=0.2.3)
NIMBUS_VERSION      ?= 0.2.2

# Make one API call to the specific version tag to get all assets
NIMBUS_ASSETS_JSON  := $(shell curl -sL https://api.github.com/repos/status-im/nimbus-eth1/releases/tags/v$(NIMBUS_VERSION) | jq -r '.assets[]')
NIMBUS_CLIENT_URL   := $(shell echo '$(NIMBUS_ASSETS_JSON)' | jq -r 'select(.name | contains("client-linux-arm64")).browser_download_url')
NIMBUS_PROXY_URL    := $(shell echo '$(NIMBUS_ASSETS_JSON)' | jq -r 'select(.name | contains("proxy-linux-arm64")).browser_download_url')
NIMBUS_DOWNLOADER_URL := https://raw.githubusercontent.com/status-im/nimbus-eth1/refs/heads/master/scripts/era_downloader.sh

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(NIMBUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(NIMBUS_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(NIMBUS_VERSION) \
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
    $(shell test -d extras && find extras -name 'nimbus-execution*.service' -printf "--deb-systemd %p " || true) \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config \
    --depends aria2

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'nimbus-execution*.service' -printf "--rpm-systemd %p " || true) \
    --depends aria2

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — download & stage Nimbus binaries
# ----------------------------------------------------------------------
prepare: ## Download latest Nimbus and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Nimbus version..."
	if [[ -z "$(NIMBUS_VERSION)" || "$(NIMBUS_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest Nimbus version via GitHub API."; exit 1; \
	fi
	if [[ -z "$(NIMBUS_CLIENT_URL)" || -z "$(NIMBUS_PROXY_URL)" ]]; then \
	    echo "❌ Could not resolve download URLs from GitHub API assets."; exit 1; \
	fi
	@echo "🔽 Downloading Nimbus $(NIMBUS_VERSION) binaries..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	
	@echo "Downloading downloader script..."
	wget -q -O "$(SOURCESDIR)/usr/bin/era_downloader.sh" "$(NIMBUS_DOWNLOADER_URL)" || { echo "❌ Downloader script download failed"; exit 1; }
	
	@echo "Downloading client..."
	wget -q -O ".build/client.tar.gz" "$(NIMBUS_CLIENT_URL)" || { echo "❌ Client download failed: $(NIMBUS_CLIENT_URL)"; exit 1; }
	@echo "Downloading proxy..."
	wget -q -O ".build/proxy.tar.gz" "$(NIMBUS_PROXY_URL)" || { echo "❌ Proxy download failed: $(NIMBUS_PROXY_URL)"; exit 1; }
	
	@echo "Extracting binaries..."
	tar -xzf ".build/client.tar.gz" -C $(SOURCESDIR)/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 2 '*/nimbus_*'
	tar -xzf ".build/proxy.tar.gz" -C $(SOURCESDIR)/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 2 '*/nimbus_*'
	
	chmod 0755 $(SOURCESDIR)/usr/bin/era_downloader.sh
	rm -f $(SOURCESDIR)/usr/bin/nimbus*.sha512sum
	@echo "✅ Binaries ready in $(SOURCESDIR)/usr/bin"

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
	rm -rf $(SOURCESDIR)/usr/bin/nimbus* $(SOURCESDIR)/usr/bin/era_downloader.sh .build
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
	echo "Version resolved: $(NIMBUS_VERSION)"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================