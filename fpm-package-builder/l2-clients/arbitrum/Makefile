# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Arbitrum Nitro)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Pulls the latest upstream Docker container
# - Extracts the 'nitro' binary from the container
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
PKG_NAME        ?= arbitrum-nitro
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= Arbitrum nitro node
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://nitro.ethereum.org
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
NITRO_VERSION := $(shell curl -s "https://api.github.com/repos/OffchainLabs/nitro/releases/latest" | jq -r '.tag_name' | tr -d "v")
DOCKER_CONTAINER := $(shell curl -s "https://api.github.com/repos/OffchainLabs/nitro/releases/latest" | jq -r '.body' | grep -oP 'offchainlabs\/nitro-node:v\d+\.\d+\.\d+(?:-[0-9a-f]+)?' | head -n 1)

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(NITRO_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(NITRO_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(NITRO_VERSION) \
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
    $(shell test -d extras && find extras -name 'nitro*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'nitro*.service' -printf "--rpm-systemd %p ") \
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
# prepare — Extract binary from Docker container
# ----------------------------------------------------------------------
prepare: ## Extract binary from Docker container
	@echo "🔎 Resolving latest Nitro version..."
	if [[ -z "$(NITRO_VERSION)" || "$(NITRO_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest Nitro version via GitHub API."; exit 1; \
	fi
	if [[ -z "$(DOCKER_CONTAINER)" || "$(DOCKER_CONTAINER)" == "null" ]]; then \
	    echo "❌ Could not determine Docker container from release body."; exit 1; \
	fi
	@echo "🐳 Pulling Docker image: $(DOCKER_CONTAINER)..."
	mkdir -p $(SOURCESDIR)/usr/bin
	docker pull --platform linux/arm64 $(DOCKER_CONTAINER) || { echo "❌ Docker pull failed"; exit 1; }
	
	@echo "📦 Extracting binary from container..."
	# Create a container instance, copy the file, and remove the instance
	CID=$$(docker create --platform linux/arm64 $(DOCKER_CONTAINER)); \
	docker cp "$$CID:/usr/local/bin/nitro" "$(SOURCESDIR)/usr/bin/nitro" || { echo "❌ Docker cp failed"; docker rm "$$CID"; exit 1; }; \
	docker rm "$$CID" > /dev/null
	
	chmod 0755 "$(SOURCESDIR)/usr/bin/nitro"
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/nitro"

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
	rm -rf $(SOURCESDIR)/usr/bin/nitro*
	@echo "🧹 Clean complete (staged binary removed)."

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
	echo "Version resolved: $(NITRO_VERSION)"
	echo "Container       : $(DOCKER_CONTAINER)"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
