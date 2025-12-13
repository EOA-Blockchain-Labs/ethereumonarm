# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (ethereum-metrics-exporter)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= ethereum-metrics-exporter
PKG_RELEASE     ?= 4
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Provides a client-agnostic set of metrics for monitoring Ethereum nodes
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ethpandaops/ethereum-metrics-exporter
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Install/Remove Scripts
# ----------------------------------------------------------------------
PKG_AFTER_INSTALL ?= extras/postinst
PKG_AFTER_REMOVE  ?= extras/postrm
PKG_BEFPRE_REMOVE ?= extras/prerm

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v1.2.0)
EME_TAG_V := $(shell curl -s https://api.github.com/repos/ethpandaops/ethereum-metrics-exporter/releases/latest | jq -r '.tag_name')
# Get the version without "v" (e.g., 1.2.0)
EME_VERSION := $(shell echo "$(EME_TAG_V)" | tr -d "v")

EME_TARBALL := ethereum-metrics-exporter_$(EME_VERSION)_linux_$(PKG_ARCH).tar.gz
EME_URL     := https://github.com/ethpandaops/ethereum-metrics-exporter/releases/download/$(EME_TAG_V)/$(EME_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
EME_RELEASE_JSON := $(shell curl -s https://api.github.com/repos/ethpandaops/ethereum-metrics-exporter/releases/latest)
EME_SHA256 := $(shell echo '$(EME_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(EME_TARBALL)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(EME_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(EME_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(EME_VERSION) \
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
    $(shell test -d extras && find extras -name 'ethereum-metrics-exporter*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    --after-install $(PKG_AFTER_INSTALL) \
    --before-remove $(PKG_BEFPRE_REMOVE) \
    --after-remove $(PKG_AFTER_REMOVE) \
    $(shell test -d extras && find extras -name 'ethereum-metrics-exporter*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage binary
# ----------------------------------------------------------------------
prepare: ## Download latest ethereum-metrics-exporter and stage
	@echo "🔎 Resolving latest EME version..."
	if [[ -z "$(EME_TAG_V)" || "$(EME_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest EME version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading EME $(EME_VERSION) ($(EME_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(EME_TARBALL)" "$(EME_URL)" || { echo "❌ Download failed: $(EME_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(EME_SHA256)  .build/$(EME_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(EME_TARBALL)"; exit 1; };
	
	@echo "📦 Extracting binary..."
	# Find the versioned binary and rename it to the unversioned name on extraction
	tar -xzf ".build/$(EME_TARBALL)" -C $(SOURCESDIR)/usr/bin/ \
	    --transform='s/ethereum-metrics-exporter-$(EME_VERSION)/ethereum-metrics-exporter/' \
	    "ethereum-metrics-exporter-$(EME_VERSION)"
	
	chmod 0755 "$(SOURCESDIR)/usr/bin/ethereum-metrics-exporter"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/ethereum-metrics-exporter"

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
	rm -rf $(SOURCESDIR)/usr/bin/ethereum-metrics-exporter* .build
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
	echo "Version resolved: $(EME_VERSION) (Tag: $(EME_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================