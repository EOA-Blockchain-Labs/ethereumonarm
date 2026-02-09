# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Geth)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Geth binary from GitHub
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
PKG_NAME        ?= geth
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Official Go implementation of the Ethereum protocol
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://geth.ethereum.org
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
GETH_VERSION := $(shell curl -s https://api.github.com/repos/ethereum/go-ethereum/releases/latest | jq -r '.tag_name' | tr -d 'v')
GETH_DHASH   := $(shell curl -s https://api.github.com/repos/ethereum/go-ethereum/tags | jq -r '.[0].commit.sha' | cut -c1-8)
GETH_TARBALL := geth-linux-$(PKG_ARCH)-$(GETH_VERSION)-$(GETH_DHASH).tar.gz
GETH_URL     := https://gethstore.blob.core.windows.net/builds/$(GETH_TARBALL)
GETH_SIG_URL := $(GETH_URL).asc

# Go Ethereum Linux Builder PGP key ID (from https://geth.ethereum.org/downloads#pgpsignatures)
GETH_PGP_KEY := 9BA28146

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(GETH_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(GETH_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(GETH_VERSION) \
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
    $(shell test -d extras && find extras -name '$(PKG_NAME)*.service' -printf "--rpm-systemd %p " || true) \
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
# prepare — download & stage Geth binary
# ----------------------------------------------------------------------
prepare: ## Download latest Geth and verify PGP signature
	@echo "🔎 Resolving latest Geth version..."
	@if [[ -z "$(GETH_VERSION)" || "$(GETH_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest Geth version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Geth $(GETH_VERSION) ($(GETH_DHASH))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	
	# Download tarball and signature
	wget -q -O ".build/$(GETH_TARBALL)" "$(GETH_URL)" || { echo "❌ Download failed: $(GETH_URL)"; exit 1; };
	wget -q -O ".build/$(GETH_TARBALL).asc" "$(GETH_SIG_URL)" || { echo "❌ Signature download failed: $(GETH_SIG_URL)"; exit 1; };
	
	@echo "🔐 Verifying PGP signature..."
	# Import Geth Linux Builder key if not present (key ID: 9BA28146)
	gpg --list-keys $(GETH_PGP_KEY) >/dev/null 2>&1 || \
		gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys $(GETH_PGP_KEY) 2>/dev/null || \
		gpg --batch --keyserver keyserver.ubuntu.com --recv-keys $(GETH_PGP_KEY) || \
		{ echo "❌ Failed to import GPG key $(GETH_PGP_KEY)"; exit 1; };
	# Verify signature
	gpg --verify ".build/$(GETH_TARBALL).asc" ".build/$(GETH_TARBALL)" || { echo "❌ PGP signature verification FAILED!"; rm -f ".build/$(GETH_TARBALL)"*; exit 1; };

	
	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(GETH_TARBALL)" -C $(SOURCESDIR)/usr/bin --strip-components=1 --wildcards '*/geth'
	chmod 0755 "$(SOURCESDIR)/usr/bin/geth"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/geth"

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
	echo "Version resolved: $(GETH_VERSION) ($(GETH_DHASH))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
