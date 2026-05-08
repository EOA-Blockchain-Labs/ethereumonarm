# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Vero)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Creates a Python virtual environment
# - Installs Vero from tagged release
# - Stages files into ./sources
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
PKG_NAME        ?= vero
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= Vero is a multi-node validator client software implementation.
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/serenita-org/vero
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v1.3.0) for the download URL
VERO_TAG := $(shell curl -sL "https://api.github.com/repos/serenita-org/vero/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 1.3.0) for the package version
VERO_VERSION := $(shell echo "$(VERO_TAG)" | tr -d "v")

# Ensure we are building for arm64
ifneq ($(PKG_ARCH),arm64)
    $(error This package only supports arm64 architecture)
endif

VERO_TARBALL := vero-$(VERO_VERSION).tar.gz
VERO_URL     := https://github.com/serenita-org/vero/archive/refs/tags/$(VERO_TAG).tar.gz

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(VERO_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(VERO_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(VERO_VERSION) \
    --iteration $(PKG_RELEASE) \
    --vendor "$(PKG_VENDOR)" \
    --license "$(PKG_LICENSE)" \
    --description "$(PKG_DESCRIPTION)" \
    --maintainer "$(PKG_MAINTAINER)" \
    --category "$(CATEGORY)" \
    --url "$(WEB_URL)" \
    -C $(SOURCESDIR) \
    --depends python3 \
    --depends python3-venv \
    -x '*/.gitkeep' \
    -x '*/__pycache__' \
    -x '*.pyc'

# ----------------------------------------------------------------------
# Debian-specific options
# ----------------------------------------------------------------------
FPM_DEB_OPTS = $(FPM_COMMON_OPTS) \
    -t deb \
    --architecture $(PKG_ARCH) \
    --deb-no-default-config-files \
    $(shell test -d extras && find extras -name 'vero.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true)

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'vero.service' -printf "--rpm-systemd %p ")

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — download & stage Vero
# ----------------------------------------------------------------------
prepare: ## Download latest Vero and install into virtualenv
	@echo "🔎 Resolving latest Vero version..."
	if [[ -z "$(VERO_TAG)" || "$(VERO_TAG)" == "null" ]]; then \
	    echo "❌ Could not determine latest Vero version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Vero $(VERO_VERSION) ($(VERO_TAG))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin $(SOURCESDIR)/opt
	wget -q -O ".build/$(VERO_TARBALL)" "$(VERO_URL)" || { echo "❌ Download failed: $(VERO_URL)"; exit 1; };
	
	@echo "📦 Extracting source..."
	mkdir -p .build/src
	tar -xzf ".build/$(VERO_TARBALL)" -C .build/src --strip-components=1
	
	@echo "🐍 Creating virtual environment..."
	python3 -m venv $(SOURCESDIR)/opt/vero
	
	@echo "💿 Installing Vero dependencies and package..."
	# Upgrade setuptools, wheel, and install uv in venv
	$(SOURCESDIR)/opt/vero/bin/python3 -m pip install --upgrade setuptools wheel uv
	# Install from source directory using uv (deps only, code will be run from src)
	$(SOURCESDIR)/opt/vero/bin/python3 -m uv pip install .build/src
	
	@echo "📂 Deploying source code..."
	mkdir -p $(SOURCESDIR)/opt/vero/src
	# Copy contents of .build/src to /opt/vero/src
	cp -r .build/src/* $(SOURCESDIR)/opt/vero/src/
	
	@echo "🔨 Creating wrapper script..."
	# Create a wrapper script to run the application from source
	# We strictly set PYTHONPATH to use the deployed source
	printf '#!/bin/bash\nexport PYTHONPATH=/opt/vero/src\nexec /opt/vero/bin/python3 -m main "$$@"\n' > $(SOURCESDIR)/opt/vero/bin/vero
	chmod +x $(SOURCESDIR)/opt/vero/bin/vero
	
	@echo "🔧 Fixing shebangs..."
	# Replace the build-time absolute path with the install-time absolute path in all bin scripts
	# This ensures the venv is relocatable to /opt/vero
	BUILD_DIR=$$(pwd)/$(SOURCESDIR)/opt/vero; \
	find $(SOURCESDIR)/opt/vero/bin -type f -exec sed -i "s|$$BUILD_DIR|/opt/vero|g" {} +
	
	@echo "🔗 Linking binary..."
	# Create a symlink in /usr/bin to the venv binary
	ln -sf /opt/vero/bin/vero $(SOURCESDIR)/usr/bin/vero
	
	@echo "✅ Setup complete at $(SOURCESDIR)/opt/vero"

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
	rm -rf $(SOURCESDIR)/opt/vero $(SOURCESDIR)/usr/share/python/vero $(SOURCESDIR)/usr/bin/vero .build
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
	awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0M %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	echo ""
	echo "Version resolved: $(VERO_VERSION) (Tag: $(VERO_TAG))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
