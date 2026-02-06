# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Grandine)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Grandine binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= grandine
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Apache License 2.0
PKG_DESCRIPTION ?= Ethereum Consensus Layer Grandine Tech implementation
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://grandine.io
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v0.1.0) for the download URL
GRANDINE_TAG := $(shell curl -sL "https://api.github.com/repos/grandinetech/grandine/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 0.1.0) for the package version
GRANDINE_VERSION := $(shell echo "$(GRANDINE_TAG)" | tr -d "v")

# The binary name for this architecture
GRANDINE_BINARY := grandine-$(GRANDINE_VERSION)-$(PKG_ARCH)
GRANDINE_URL := https://github.com/grandinetech/grandine/releases/download/$(GRANDINE_TAG)/$(GRANDINE_BINARY)

# SHA256 checksum extracted from GitHub API asset digest field
GRANDINE_SHA256 := $(shell curl -sL "https://api.github.com/repos/grandinetech/grandine/releases/latest" | jq -r '.assets[] | select(.name == "$(GRANDINE_BINARY)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(GRANDINE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(GRANDINE_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(GRANDINE_VERSION) \
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
    $(shell test -d extras && find extras -name 'grandine-*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'grandine-*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Grandine binary
# ----------------------------------------------------------------------
prepare: ## Download latest Grandine and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Grandine version..."
	if [[ -z "$(GRANDINE_TAG)" || "$(GRANDINE_TAG)" == "null" ]]; then \
	    echo "❌ Could not determine latest Grandine version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Grandine $(GRANDINE_VERSION) ($(GRANDINE_TAG))..."
	mkdir -p $(SOURCESDIR)/usr/bin
	wget -q -O "$(SOURCESDIR)/usr/bin/$(PKG_NAME)" "$(GRANDINE_URL)" || { echo "❌ Download failed: $(GRANDINE_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(GRANDINE_SHA256)  $(SOURCESDIR)/usr/bin/$(PKG_NAME)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f "$(SOURCESDIR)/usr/bin/$(PKG_NAME)"; exit 1; };
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
	echo "Version resolved: $(GRANDINE_VERSION) (Tag: $(GRANDINE_TAG))"
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
