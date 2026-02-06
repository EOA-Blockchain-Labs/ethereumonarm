# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Kona)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Clones the ethereum-optimism/optimism repository
# - Builds kona-host from source using Cargo
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= kona
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= "MIT"
PKG_DESCRIPTION ?= Portable implementation of the OP Stack's fault proof verification logic (kona-host)
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ethereum-optimism/optimism/tree/develop/kona
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Using 'develop' branch as there are no stable releases for kona yet.
# We will use the latest commit short hash as the version for now,
# or a placeholder if preferred. For simplicity, let's fetch the latest
# tag from the monorepo, BUT kona might not follow op-node tags.
# Let's use a date-based version or 'develop' + commit hash if possible.
# For this iteration, let's use the monorepo's latest tag to keep it clean,
# even if kona is experimental.
# Using 'develop' branch checkouts for now, or deriving from latest op-node release.
# Note: existing tags are like 'op-node/v1.16.6'.
# We extract the tag safely.
UPSTREAM_TAG_V   := $(shell curl -s "https://api.github.com/repos/ethereum-optimism/optimism/releases/latest" | jq -r '.tag_name')
# Extract version: 'op-node/v1.16.6' -> '1.16.6'
UPSTREAM_VERSION := $(shell echo "$(UPSTREAM_TAG_V)" | sed 's|.*/v||')
REPO_URL         := https://github.com/ethereum-optimism/optimism.git

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(UPSTREAM_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(UPSTREAM_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(UPSTREAM_VERSION) \
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
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    --depends merge-config

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help docker-build

all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — Build binary from source
# ----------------------------------------------------------------------
prepare: ## Build binary from source
	@echo "🔎 Resolving latest $(PKG_NAME) version..."
	if [[ -z "$(UPSTREAM_TAG_V)" || "$(UPSTREAM_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Cloning $(PKG_NAME) from $(UPSTREAM_TAG_V)..."
	mkdir -p .build/src $(SOURCESDIR)/usr/bin
	# Cloning the monorepo might be heavy, use depth 1
	git clone --depth 1 --branch $(UPSTREAM_TAG_V) $(REPO_URL) .build/src || { echo "❌ Git clone failed"; exit 1; }

	@echo "🛠 Building kona-host binary from source..."
	# We need to build specifically 'kona-host'
	cd .build/src/kona && \
	    env CARGO_NET_GIT_FETCH_WITH_CLI=true \
	    cargo build --release --bin kona-host \
	    || { echo "❌ Cargo build failed"; exit 1; }

	@echo "📂 Staging binary..."
	cp .build/src/kona/target/release/kona-host $(SOURCESDIR)/usr/bin/kona-host
	chmod 0755 $(SOURCESDIR)/usr/bin/kona-host
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/kona-host"

deb: prepare ## Build .deb package
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building DEB package..."
	fpm $(FPM_DEB_OPTS) -p "$(PKG_DEB)" .
	if [[ -f "$(PKG_DEB)" ]]; then \
	    echo "✅ DEB package created at $(PKG_DEB)"; \
	else \
	    echo "❌ DEB package creation failed."; exit 1; \
	fi

rpm: prepare ## Build .rpm package
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building RPM package..."
	fpm $(FPM_RPM_OPTS) -p "$(PKG_RPM)" .
	if [[ -f "$(PKG_RPM)" ]]; then \
	    echo "✅ RPM package created at $(PKG_RPM)"; \
	else \
	    echo "❌ RPM package creation failed."; exit 1; \
	fi

clean: ## Remove staged binaries and temp files
	rm -rf $(SOURCESDIR)/usr/bin/kona-host* .build
	@echo "🧹 Clean complete (staged files and .build removed)."

test: ## Check that .deb exists
	if [[ -f "$(PKG_DEB)" ]]; then \
	    echo "🧪 Test: .deb exists — OK ✅"; \
	else \
	    echo "🧪 Test: .deb missing — ❌"; exit 1; \
	fi

release: clean prepare deb rpm test ## Clean + Prepare + Build + Test (all)
	@echo "🎉 All packages built successfully for $(PKG_ARCH)"
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
