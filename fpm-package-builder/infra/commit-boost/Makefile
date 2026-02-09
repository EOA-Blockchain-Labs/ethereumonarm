# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (commit-boost)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream commit-boost-pbs binary from GitHub
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
PKG_NAME        ?= commit-boost
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= Commit-Boost is a sidecar for Ethereum validators to manage commitments.
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/Commit-Boost/commit-boost-client
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v0.9.2)
CB_TAG_V := $(shell curl -s https://api.github.com/repos/Commit-Boost/commit-boost-client/releases/latest | jq -r '.tag_name')
# Get the version without "v" (e.g., 0.9.2)
CB_VERSION := $(shell echo "$(CB_TAG_V)" | tr -d "v")

# Filename format: commit-boost-pbs-v0.9.2-linux_arm64.tar.gz
CB_TARBALL := commit-boost-pbs-$(CB_TAG_V)-linux_$(PKG_ARCH).tar.gz
CB_URL     := https://github.com/Commit-Boost/commit-boost-client/releases/download/$(CB_TAG_V)/$(CB_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
CB_SHA256 := $(shell curl -s https://api.github.com/repos/Commit-Boost/commit-boost-client/releases/latest | jq -r '.assets[] | select(.name == "$(CB_TARBALL)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(CB_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(CB_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(CB_VERSION) \
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
    $(shell test -d extras && find extras -name 'commit-boost*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'commit-boost*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage commit-boost binary
# ----------------------------------------------------------------------
prepare: ## Download latest commit-boost and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest commit-boost version..."
	if [[ -z "$(CB_TAG_V)" || "$(CB_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest commit-boost version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading commit-boost $(CB_VERSION) ($(CB_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(CB_TARBALL)" "$(CB_URL)" || { echo "❌ Download failed: $(CB_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(CB_SHA256)  .build/$(CB_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(CB_TARBALL)"; exit 1; };
	
	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(CB_TARBALL)" -C .build/
	# Move and rename to commit-boost
	mv .build/commit-boost-pbs $(SOURCESDIR)/usr/bin/commit-boost
	chmod 0755 "$(SOURCESDIR)/usr/bin/commit-boost"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/commit-boost"

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
	rm -rf $(SOURCESDIR)/usr/bin/commit-boost* .build
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
	echo "Version resolved: $(CB_VERSION) (Tag: $(CB_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
