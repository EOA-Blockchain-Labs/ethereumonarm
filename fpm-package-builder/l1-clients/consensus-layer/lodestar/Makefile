# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Lodestar)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Lodestar binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= lodestar
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Ethereum 2.0 Lodestar implementation
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ChainSafe/lodestar
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages


# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v1.17.0)
LODESTAR_TAG := $(shell curl -s "https://api.github.com/repos/ChainSafe/lodestar/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 1.17.0)
LODESTAR_VERSION := $(shell echo "$(LODESTAR_TAG)" | tr -d "v")

LODESTAR_TARBALL := lodestar-$(LODESTAR_TAG)-linux-$(PKG_ARCH).tar.gz
LODESTAR_URL     := https://github.com/ChainSafe/lodestar/releases/download/$(LODESTAR_TAG)/$(LODESTAR_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
LODESTAR_SHA256 := $(shell curl -s "https://api.github.com/repos/ChainSafe/lodestar/releases/latest" | jq -r '.assets[] | select(.name == "$(LODESTAR_TARBALL)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(LODESTAR_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(LODESTAR_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(LODESTAR_VERSION) \
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
    $(shell test -d extras && find extras -name 'lodestar-*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'lodestar-*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Lodestar binary
# ----------------------------------------------------------------------
prepare: ## Download latest Lodestar and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Lodestar version..."
	if [[ -z "$(LODESTAR_TAG)" || "$(LODESTAR_TAG)" == "null" ]]; then \
	    echo "❌ Could not determine latest Lodestar version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Lodestar $(LODESTAR_VERSION) ($(LODESTAR_TAG))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(LODESTAR_TARBALL)" "$(LODESTAR_URL)" || { echo "❌ Download failed: $(LODESTAR_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(LODESTAR_SHA256)  .build/$(LODESTAR_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(LODESTAR_TARBALL)"; exit 1; };
	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(LODESTAR_TARBALL)" -C $(SOURCESDIR)/usr/bin/
	chmod 0755 "$(SOURCESDIR)/usr/bin/lodestar"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/lodestar"

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
	echo "Version resolved: $(LODESTAR_VERSION) (Tag: $(LODESTAR_TAG))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ----------------------------------------------------------------------
# docker-build — build inside a Docker container
# ----------------------------------------------------------------------
docker-build: check-qemu ## Run the build inside a Docker container
	# Uses the shared builder image defined in fpm-package-builder/Dockerfile
	docker run --rm -v $(PWD):/workspace -w /workspace \
	    -e PKG_NAME=$(PKG_NAME) \
	    -e PKG_RELEASE=$(PKG_RELEASE) \
	    eoa-builder \
	    /bin/bash -c "make release"

# ----------------------------------------------------------------------
# QEMU check
# ----------------------------------------------------------------------
check-qemu:
	@if [ "$$(uname -m)" = "x86_64" ]; then \
		if [ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ] && [ ! -f /proc/sys/fs/binfmt_misc/aarch64 ]; then \
			echo "⚠️  Warning: Host is x86_64 but qemu-aarch64 binfmt seems missing."; \
			echo "   Installing QEMU binfmt for ARM64 emulation..."; \
			docker run --privileged --rm tonistiigi/binfmt --install all || true; \
		fi \
	fi

# ======================================================================
# End of file
# ======================================================================
