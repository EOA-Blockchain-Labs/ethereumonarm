# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Prysm)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Prysm binaries from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= prysm
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU General Public License v3.0
PKG_DESCRIPTION ?= Ethereum 2.0 Prysmatic Labs implementation
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/prysmaticlabs/prysm
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v5.0.0)
PRYSM_TAG_V := $(shell curl -Ls "https://api.github.com/repos/prysmaticlabs/prysm/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 5.0.0)
PRYSM_VERSION := $(shell echo "$(PRYSM_TAG_V)" | tr -d "v")

# Binary names for this architecture
BEACON_CHAIN_BINARY := beacon-chain-$(PRYSM_TAG_V)-linux-$(PKG_ARCH)
VALIDATOR_BINARY    := validator-$(PRYSM_TAG_V)-linux-$(PKG_ARCH)

BEACON_CHAIN_URL := https://github.com/prysmaticlabs/prysm/releases/download/$(PRYSM_TAG_V)/$(BEACON_CHAIN_BINARY)
VALIDATOR_URL    := https://github.com/prysmaticlabs/prysm/releases/download/$(PRYSM_TAG_V)/$(VALIDATOR_BINARY)

# SHA256 checksums extracted from GitHub API asset digest field
# PRYSM_RELEASE_JSON := $(shell curl -Ls "https://api.github.com/repos/prysmaticlabs/prysm/releases/latest")
# BEACON_CHAIN_SHA256 := $(shell echo '$(PRYSM_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(BEACON_CHAIN_BINARY)") | .digest' | sed 's/sha256://')
# VALIDATOR_SHA256    := $(shell echo '$(PRYSM_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(VALIDATOR_BINARY)") | .digest' | sed 's/sha256://')

# GPG Signature Verification
# Key from prysm.sh: 0AE0051D647BA3C1A917AF4072E33E4DF1A5036E
PRYSM_GPG_KEY := 0AE0051D647BA3C1A917AF4072E33E4DF1A5036E
BEACON_CHAIN_SIG_URL := https://prysmaticlabs.com/releases/$(BEACON_CHAIN_BINARY).sig
VALIDATOR_SIG_URL    := https://prysmaticlabs.com/releases/$(VALIDATOR_BINARY).sig

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(PRYSM_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(PRYSM_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(PRYSM_VERSION) \
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
    $(shell test -d extras && find extras -name 'prysm-*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'prysm-*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Prysm binaries
# ----------------------------------------------------------------------
prepare: ## Download latest Prysm binaries and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Prysm version..."
	if [[ -z "$(PRYSM_TAG_V)" || "$(PRYSM_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest Prysm version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Prysm $(PRYSM_VERSION) ($(PRYSM_TAG_V))..."
	mkdir -p $(SOURCESDIR)/usr/bin

	@echo "🔐 Importing GPG Key..."
	gpg --keyserver keyserver.ubuntu.com --recv-keys $(PRYSM_GPG_KEY) || { echo "❌ Failed to import GPG key from keyserver"; \
		curl --silent https://prysmaticlabs.com/releases/pgp_keys.asc | gpg --import || { echo "❌ Failed to import GPG key from URL"; exit 1; }; \
	}
	
	@echo "Downloading beacon-chain..."
	wget -q -O "$(SOURCESDIR)/usr/bin/beacon-chain" "$(BEACON_CHAIN_URL)" || { echo "❌ beacon-chain download failed: $(BEACON_CHAIN_URL)"; exit 1; };
	wget -q -O "$(SOURCESDIR)/usr/bin/beacon-chain.sig" "$(BEACON_CHAIN_SIG_URL)" || { echo "❌ beacon-chain signature download failed: $(BEACON_CHAIN_SIG_URL)"; exit 1; };
	
	@echo "ℹ️  Note: You may see a 'WARNING: This key is not certified with a trusted signature!' message."
	@echo "ℹ️  This is expected. Ensure the key belongs to 'Preston Van Loon <preston@pvl.dev>'."
	@echo "🔐 Verifying beacon-chain GPG Signature..."
	gpg --verify "$(SOURCESDIR)/usr/bin/beacon-chain.sig" "$(SOURCESDIR)/usr/bin/beacon-chain" || { echo "❌ beacon-chain GPG signature verification FAILED!"; rm -f "$(SOURCESDIR)/usr/bin/beacon-chain"; exit 1; };
	
	@echo "Downloading validator..."
	wget -q -O "$(SOURCESDIR)/usr/bin/validator" "$(VALIDATOR_URL)" || { echo "❌ validator download failed: $(VALIDATOR_URL)"; exit 1; };
	wget -q -O "$(SOURCESDIR)/usr/bin/validator.sig" "$(VALIDATOR_SIG_URL)" || { echo "❌ validator signature download failed: $(VALIDATOR_SIG_URL)"; exit 1; };
	@echo "🔐 Verifying validator GPG Signature..."
	gpg --verify "$(SOURCESDIR)/usr/bin/validator.sig" "$(SOURCESDIR)/usr/bin/validator" || { echo "❌ validator GPG signature verification FAILED!"; rm -f "$(SOURCESDIR)/usr/bin/validator"; exit 1; };
	
	@echo "🧹 Cleaning up signature files..."
	rm -f "$(SOURCESDIR)/usr/bin/beacon-chain.sig" "$(SOURCESDIR)/usr/bin/validator.sig"
	
	chmod 0755 $(SOURCESDIR)/usr/bin/beacon-chain $(SOURCESDIR)/usr/bin/validator
	@echo "✅ Binaries downloaded and verified in $(SOURCESDIR)/usr/bin"

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
	rm -rf $(SOURCESDIR)/usr/bin/beacon-chain $(SOURCESDIR)/usr/bin/validator
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
	echo "Version resolved: $(PRYSM_VERSION) (Tag: $(PRYSM_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================