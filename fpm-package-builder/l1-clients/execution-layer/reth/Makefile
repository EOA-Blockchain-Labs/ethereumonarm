# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Reth)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Reth binary from GitHub
# - Stages files into ./sources/usr/bin and ./sources/etc
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Docker enforcement: Auto-invoke inside eoa-builder if not already there
# ----------------------------------------------------------------------
ifndef EOA_BUILDER
# Find project root (where Dockerfile lives)
PROJECT_ROOT := $(shell d=$$(pwd); while [ "$$d" != "/" ]; do [ -f "$$d/Dockerfile" ] && echo "$$d" && break; d=$$(dirname "$$d"); done)
RELATIVE_DIR := $(shell pwd | sed "s|^$(PROJECT_ROOT)/||")
DOCKER_IMAGE := eoa-builder
DOCKER_PLATFORM := linux/arm64

.PHONY: all clean test release deb rpm prepare help
all clean test release deb rpm prepare help:
	@cd $(PROJECT_ROOT) && \
	if [ -z "$$(docker images -q $(DOCKER_IMAGE) 2>/dev/null)" ]; then \
	    echo "🐳 Building Docker image $(DOCKER_IMAGE)..."; \
	    docker build --platform $(DOCKER_PLATFORM) -t $(DOCKER_IMAGE) . ; \
	fi && \
	echo "🐳 Running build inside Docker container..." && \
	docker run --rm --platform $(DOCKER_PLATFORM) \
	    -v "$(PROJECT_ROOT)":/workspace -w /workspace \
	    $(DOCKER_IMAGE) \
	    make -C "$(RELATIVE_DIR)" $@

else
# Running inside Docker container - proceed with actual build



# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= reth
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Rust implementation of the Ethereum protocol by Paradigm team
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://paradigmxyz.github.io/reth/
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag once (e.g., "v0.1.0-alpha.10")
LATEST_TAG   := $(shell curl -s "https://api.github.com/repos/paradigmxyz/reth/releases/latest" | jq -r '.tag_name')

# RETH_TAG is used for the download URL (e.g., "v0.1.0-alpha.10")
RETH_TAG     := $(LATEST_TAG)
# RETH_VERSION is for the package version (e.g., "0.1.0-alpha10")
RETH_VERSION := $(shell echo "$(LATEST_TAG)" | tr -d "v" | sed -E 's/([a-z]+)\.([0-9]+)/\1\2/')

RETH_TARBALL := reth-$(RETH_TAG)-$(PKG_ARCH_RPM)-unknown-linux-gnu.tar.gz
RETH_URL     := https://github.com/paradigmxyz/reth/releases/download/$(RETH_TAG)/$(RETH_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
# RETH_RELEASE_JSON := $(shell curl -s "https://api.github.com/repos/paradigmxyz/reth/releases/latest")
# RETH_SHA256 := $(shell echo '$(RETH_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(RETH_TARBALL)") | .digest' | sed 's/sha256://')

# GPG Signature Verification
RETH_GPG_KEY := 50FB7CC55B2E8AFA59FE03B7AA5ED56A7FBF253E
RETH_ASC     := $(RETH_TARBALL).asc
RETH_ASC_URL := https://github.com/paradigmxyz/reth/releases/download/$(RETH_TAG)/$(RETH_ASC)

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(RETH_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(RETH_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(RETH_VERSION) \
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
# prepare — download & stage Reth binary
# ----------------------------------------------------------------------
prepare: ## Download latest Reth and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Reth version..."
	if [[ -z "$(RETH_TAG)" || "$(RETH_TAG)" == "null" ]]; then \
	    echo "❌ Could not determine latest Reth version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Reth $(RETH_VERSION) ($(RETH_TAG))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(RETH_TARBALL)" "$(RETH_URL)" || { echo "❌ Download failed: $(RETH_URL)"; exit 1; };
	wget -q -O ".build/$(RETH_ASC)" "$(RETH_ASC_URL)" || { echo "❌ Signature download failed: $(RETH_ASC_URL)"; exit 1; };
	@echo "🔐 Verifying GPG Signature..."
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys $(RETH_GPG_KEY) 2>/dev/null || \
		gpg --batch --keyserver keyserver.ubuntu.com --recv-keys $(RETH_GPG_KEY) || \
		{ echo "❌ Failed to import GPG key"; exit 1; };
	gpg --verify ".build/$(RETH_ASC)" ".build/$(RETH_TARBALL)" || { echo "❌ GPG signature verification FAILED!"; rm -f ".build/$(RETH_TARBALL)"; exit 1; };

	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(RETH_TARBALL)" -C $(SOURCESDIR)/usr/bin/ reth
	chmod 0755 "$(SOURCESDIR)/usr/bin/reth"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/reth"

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
# help — show all available targets
# ----------------------------------------------------------------------
help: ## Show available targets
	echo ""
	echo "EOA Packaging — $(PKG_NAME)"
	echo ""
	awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	echo ""
	echo "Version resolved: $(RETH_VERSION) (Tag: $(RETH_TAG))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
