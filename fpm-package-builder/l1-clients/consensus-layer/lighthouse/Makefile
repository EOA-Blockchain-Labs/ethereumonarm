# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Lighthouse)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Lighthouse binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= lighthouse
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Apache License 2.0
PKG_DESCRIPTION ?= Ethereum 2.0 Sigma Prime implementation
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/sigp/lighthouse/
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v5.1.3) for the download URL
LIGHTHOUSE_TAG := $(shell curl -sL "https://api.github.com/repos/sigp/lighthouse/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 5.1.3) for the package version
LIGHTHOUSE_VERSION := $(shell echo "$(LIGHTHOUSE_TAG)" | tr -d "v")

LIGHTHOUSE_TARBALL := lighthouse-$(LIGHTHOUSE_TAG)-$(PKG_ARCH_RPM)-unknown-linux-gnu.tar.gz
LIGHTHOUSE_URL     := https://github.com/sigp/lighthouse/releases/download/$(LIGHTHOUSE_TAG)/$(LIGHTHOUSE_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
# LIGHTHOUSE_RELEASE_JSON := $(shell curl -sL "https://api.github.com/repos/sigp/lighthouse/releases/latest")
# LIGHTHOUSE_SHA256 := $(shell echo '$(LIGHTHOUSE_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(LIGHTHOUSE_TARBALL)") | .digest' | sed 's/sha256://')

# GPG Signature Verification
LIGHTHOUSE_GPG_KEY := 15E66D941F697E28F49381F426416DC3F30674B0
LIGHTHOUSE_ASC     := $(LIGHTHOUSE_TARBALL).asc
LIGHTHOUSE_ASC_URL := https://github.com/sigp/lighthouse/releases/download/$(LIGHTHOUSE_TAG)/$(LIGHTHOUSE_ASC)

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(LIGHTHOUSE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(LIGHTHOUSE_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(LIGHTHOUSE_VERSION) \
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
    $(shell test -d extras && find extras -name 'lighthouse-*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'lighthouse-*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Lighthouse binary
# ----------------------------------------------------------------------
prepare: ## Download latest Lighthouse and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Lighthouse version..."
	if [[ -z "$(LIGHTHOUSE_TAG)" || "$(LIGHTHOUSE_TAG)" == "null" ]]; then \
	    echo "❌ Could not determine latest Lighthouse version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Lighthouse $(LIGHTHOUSE_VERSION) ($(LIGHTHOUSE_TAG))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(LIGHTHOUSE_TARBALL)" "$(LIGHTHOUSE_URL)" || { echo "❌ Download failed: $(LIGHTHOUSE_URL)"; exit 1; };
	wget -q -O ".build/$(LIGHTHOUSE_ASC)" "$(LIGHTHOUSE_ASC_URL)" || { echo "❌ Signature download failed: $(LIGHTHOUSE_ASC_URL)"; exit 1; };
	@echo "🔐 Verifying GPG Signature..."
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys $(LIGHTHOUSE_GPG_KEY) 2>/dev/null || \
		gpg --batch --keyserver keyserver.ubuntu.com --recv-keys $(LIGHTHOUSE_GPG_KEY) || \
		{ echo "❌ Failed to import GPG key"; exit 1; };
	gpg --verify ".build/$(LIGHTHOUSE_ASC)" ".build/$(LIGHTHOUSE_TARBALL)" || { echo "❌ GPG signature verification FAILED!"; rm -f ".build/$(LIGHTHOUSE_TARBALL)"; exit 1; };

	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(LIGHTHOUSE_TARBALL)" -C $(SOURCESDIR)/usr/bin/ lighthouse
	chmod 0755 "$(SOURCESDIR)/usr/bin/lighthouse"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/lighthouse"

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
	rm -rf $(SOURCESDIR)/usr/bin/$(PKG_NAME)* .build
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
	echo "Version resolved: $(LIGHTHOUSE_VERSION) (Tag: $(LIGHTHOUSE_TAG))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================