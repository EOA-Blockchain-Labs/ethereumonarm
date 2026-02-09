# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (zkSync Era)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Clones zkSync Era source from GitHub
# - Compiles zksync_server binary using Rust/Cargo
# - Includes PostgreSQL setup for /home/ethereum storage
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
PKG_NAME        ?= zksync-era
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Apache-2.0 OR MIT
PKG_DESCRIPTION ?= zkSync Era - ZK Rollup for scaling Ethereum
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://zksync.io
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
REPO_URL        := https://github.com/matter-labs/zksync-era.git

# Get the latest core version tag (e.g., core-v29.7.0)
ZKSYNC_VERSION  := $(shell curl -s "https://api.github.com/repos/matter-labs/zksync-era/releases" | \
                       jq -r '[.[] | select(.tag_name | startswith("core-v"))] | first | .tag_name' | \
                       sed 's/core-v//')

ZKSYNC_TAG      := core-v$(ZKSYNC_VERSION)

# Rust toolchain (matches upstream requirement)
RUST_TOOLCHAIN  := nightly-2025-03-19

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(ZKSYNC_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(ZKSYNC_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# Build dependencies (needed on build machine)
# apt install build-essential pkg-config libssl-dev libpq-dev clang cmake
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(ZKSYNC_VERSION) \
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
    $(shell test -d extras && find extras -name 'zksync*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config \
    --depends postgresql

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'zksync*.service' -printf "--rpm-systemd %p ") \
    --depends merge-config \
    --depends postgresql-server

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — Clone and compile from source
# ----------------------------------------------------------------------
prepare: ## Clone and compile zkSync Era from source
	@echo "🔎 Resolving latest zkSync Era version..."
	if [[ -z "$(ZKSYNC_VERSION)" || "$(ZKSYNC_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest zkSync version via GitHub API."; exit 1; \
	fi
	@echo "📥 Version: $(ZKSYNC_VERSION) (tag: $(ZKSYNC_TAG))"
	
	@echo "🦀 Ensuring Rust toolchain $(RUST_TOOLCHAIN)..."
	rustup install $(RUST_TOOLCHAIN) || { echo "❌ Failed to install Rust toolchain"; exit 1; }
	rustup default $(RUST_TOOLCHAIN)
	
	@echo "📥 Cloning zkSync Era repository..."
	rm -rf zksync-era-build
	git clone --depth 1 --branch $(ZKSYNC_TAG) $(REPO_URL) zksync-era-build || \
	    { echo "❌ Git clone failed"; exit 1; }
	
	@echo "🔨 Building zksync_server (this may take a while)..."
	cd zksync-era-build/core && \
	    CARGO_NET_GIT_FETCH_WITH_CLI=true \
	    cargo build --release --bin zksync_server || \
	    { echo "❌ Cargo build failed"; exit 1; }
	
	@echo "📦 Copying binary..."
	mkdir -p $(SOURCESDIR)/usr/bin
	cp zksync-era-build/core/target/release/zksync_server $(SOURCESDIR)/usr/bin/zksync_server
	chmod 0755 $(SOURCESDIR)/usr/bin/zksync_server
	
	@echo "🧹 Cleaning build directory..."
	rm -rf zksync-era-build
	
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/zksync_server"

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
	rm -rf $(SOURCESDIR)/usr/bin/zksync*
	rm -rf zksync-era-build
	@echo "🧹 Clean complete."

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
	echo "Version       : $(ZKSYNC_VERSION)"
	echo "Tag           : $(ZKSYNC_TAG)"
	echo "Rust toolchain: $(RUST_TOOLCHAIN)"
	echo "Sources dir   : $(SOURCESDIR)"
	echo "Output dir    : $(OUTPUTDIR)"
	echo ""
	echo "Build dependencies:"
	echo "  apt install build-essential pkg-config libssl-dev libpq-dev clang cmake"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
