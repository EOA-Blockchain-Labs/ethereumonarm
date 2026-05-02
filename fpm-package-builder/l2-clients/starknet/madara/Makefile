# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Madara)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Pulls the latest upstream Madara Docker image
# - Extracts the binary from the image
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
PKG_NAME        ?= starknet-madara
PKG_RELEASE     ?= 1
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Apache 2.0
PKG_DESCRIPTION ?= Madara is a powerful hybrid Starknet client written in Rust
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/madara-alliance/madara
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v0.8.0)
MADARA_TAG_V := $(shell curl -s "https://api.github.com/repos/madara-alliance/madara/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 0.8.0)
MADARA_VERSION := $(shell echo "$(MADARA_TAG_V)" | tr -d "v")

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(MADARA_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(MADARA_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(MADARA_VERSION) \
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
    $(shell test -d extras && find extras -name 'madara*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'madara*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Madara binary
# ----------------------------------------------------------------------
prepare: ## Build Madara from source using Docker
	@echo "🔎 Resolving latest Madara version..."
	if [[ -z "$(MADARA_TAG_V)" || "$(MADARA_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest Madara version via GitHub API."; exit 1; \
	fi
	@echo "🏗️  Building Madara $(MADARA_VERSION) from source locally..."
	mkdir -p $(SOURCESDIR)/usr/bin
	mkdir -p .build
	
	# Clone repository
	if [ ! -d ".build/madara" ]; then \
	    git clone --depth 1 --branch $(MADARA_TAG_V) https://github.com/madara-alliance/madara.git .build/madara; \
	fi
	
	# Build Madara
	if [ -z "$(SKIP_BUILD)" ]; then \
	    if [ ! -d ".build/venv" ]; then \
	        python3 -m venv .build/venv; \
	    fi; \
	    .build/venv/bin/python3 -m pip install sympy==1.12 cairo-lang==0.14.0.1; \
	    cd .build/madara && \
	    . ../venv/bin/activate && \
	    export PATH="/usr/lib/llvm-19/bin:$$PATH" && \
	    export LLVM_SYS_190_PREFIX=/usr/lib/llvm-19 && \
	    export MLIR_SYS_190_PREFIX=/usr/lib/llvm-19 && \
	    export TABLEGEN_190_PREFIX=/usr/lib/llvm-19 && \
	    if [ "$$(uname -m)" = "x86_64" ]; then \
	        echo "🖥️  Host is x86_64, cross-compiling for aarch64..."; \
	        export CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc; \
	        export CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++; \
	        cargo build --release --target aarch64-unknown-linux-gnu --manifest-path Cargo.toml -p madara; \
	    else \
	        echo "🖥️  Host is aarch64, building natively..."; \
	        cargo build --release --manifest-path Cargo.toml -p madara; \
	    fi \
	else \
	    echo "⏭️  Skipping build (SKIP_BUILD is set)..."; \
	fi
	
	# Determine binary path
	if [ "$$(uname -m)" = "x86_64" ]; then \
	    BINARY_PATH="target/aarch64-unknown-linux-gnu/release/madara"; \
	else \
	    BINARY_PATH="target/release/madara"; \
	fi && \
	echo "📦 Staging binary..." && \
	mkdir -p $(CURDIR)/$(SOURCESDIR)/usr/bin && \
	cp .build/madara/$$BINARY_PATH $(CURDIR)/$(SOURCESDIR)/usr/bin/madara && \
	echo "📦 Staging presets..." && \
	mkdir -p $(CURDIR)/$(SOURCESDIR)/etc/ethereum/madara/presets && \
	cp -r .build/madara/configs/presets/* $(CURDIR)/$(SOURCESDIR)/etc/ethereum/madara/presets/
	
	chmod 0755 "$(SOURCESDIR)/usr/bin/madara"
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/madara"

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
	rm -rf $(SOURCESDIR)/usr/bin/madara* .build $(SOURCESDIR)/etc/ethereum/madara/presets
	@echo "🧹 Clean complete (staged files removed)."

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
	echo "Version resolved: $(MADARA_VERSION) (Tag: $(MADARA_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ======================================================================
# End of file
# ======================================================================
endif
