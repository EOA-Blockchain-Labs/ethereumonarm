# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Fuel)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Fuel binary from GitHub
# - Stages files into ./sources/usr/bin
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
PKG_NAME        ?= fuel-network
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Fuel Network node
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://fuel.network
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v0.22.0)
FUEL_TAG_V := $(shell curl -s "https://api.github.com/repos/FuelLabs/fuel-core/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 0.22.0)
FUEL_VERSION := $(shell echo "$(FUEL_TAG_V)" | tr -d "v")

FUEL_TARBALL := fuel-core-$(FUEL_VERSION)-$(PKG_ARCH_RPM)-unknown-linux-gnu.tar.gz
FUEL_URL     := https://github.com/FuelLabs/fuel-core/releases/download/$(FUEL_TAG_V)/$(FUEL_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
FUEL_RELEASE_JSON := $(shell curl -s "https://api.github.com/repos/FuelLabs/fuel-core/releases/latest")
FUEL_SHA256 := $(shell echo '$(FUEL_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(FUEL_TARBALL)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(FUEL_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(FUEL_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(FUEL_VERSION) \
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
    $(shell test -d extras && find extras -name 'fuel*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'fuel*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Fuel binaries
# ----------------------------------------------------------------------
prepare: ## Download latest Fuel and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Fuel version..."
	if [[ -z "$(FUEL_TAG_V)" || "$(FUEL_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest Fuel version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Fuel $(FUEL_VERSION) ($(FUEL_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(FUEL_TARBALL)" "$(FUEL_URL)" || { echo "❌ Download failed: $(FUEL_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(FUEL_SHA256)  .build/$(FUEL_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(FUEL_TARBALL)"; exit 1; };
	
	@echo "📦 Extracting binaries..."
	tar -xzf ".build/$(FUEL_TARBALL)" -C $(SOURCESDIR)/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 1 '*/fuel*'
	
	@echo "📂 Staging helper scripts..."
	cp extras/fuel-core-pre.sh $(SOURCESDIR)/usr/bin
	
	chmod 0755 $(SOURCESDIR)/usr/bin/fuel-core $(SOURCESDIR)/usr/bin/fuel-core-pre.sh
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
	rm -rf $(SOURCESDIR)/usr/bin/fuel* .build
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
	echo "Version resolved: $(FUEL_VERSION) (Tag: $(FUEL_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
