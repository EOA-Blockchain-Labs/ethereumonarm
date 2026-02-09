# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (CHANGEME: Project Name)
# ----------------------------------------------------------------------
# CHANGEME: Update this description to match your project.
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream binary from GitHub
# - Verifies checksums (recommended)
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

# These settings are standard across all Makefiles
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
# CHANGEME: Update all variables in this section for your new package.
# ----------------------------------------------------------------------
PKG_NAME        ?= new-client-name
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= "Apache License 2.0" # Example: "GNU Lesser General Public License v3.0", "MIT"
PKG_DESCRIPTION ?= A clear description of what this package does.
PKG_MAINTAINER  ?= Your Name <your.email@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/project-owner/project-repo # Example: https://nimbus.team/
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages # Adjust path based on dir depth, e.g., ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# CHANGEME: This is the most important section to customize.
#           Select one of the examples below (Download or Build from Source).
# ----------------------------------------------------------------------

# --- EXAMPLE 1: Download binary from GitHub Releases (Most Common Case) ---
# This example fetches the latest release tag (e.g., "v1.2.3")
# CHANGEME: Update the GitHub repo URL
LATEST_TAG_JSON := $(shell curl -s "https://api.github.com/repos/project-owner/project-repo/releases/latest")
UPSTREAM_TAG_V  := $(shell echo '$(LATEST_TAG_JSON)' | jq -r '.tag_name')
# This removes the "v" from the tag for the package version (e.g., "1.2.3")
UPSTREAM_VERSION := $(shell echo "$(UPSTREAM_TAG_V)" | tr -d "v")

# CHANGEME: Define the binary/tarball name and URL.
# Example 1a: For a .tar.gz file
# UPSTREAM_TARBALL := project-name-$(UPSTREAM_TAG_V)-linux-$(PKG_ARCH).tar.gz
# UPSTREAM_URL     := $(WEB_URL)/releases/download/$(UPSTREAM_TAG_V)/$(UPSTREAM_TARBALL)

# Example 1b: For a single binary file
UPSTREAM_BINARY_NAME := project-binary # The name of the binary inside the release
UPSTREAM_URL         := $(WEB_URL)/releases/download/$(UPSTREAM_TAG_V)/$(UPSTREAM_BINARY_NAME)-linux-$(PKG_ARCH)

# CHANGEME: Checksum verification (Highly Recommended)
# Define the URL for the checksum file (usually checksums.txt or SHA256SUMS)
# CHECKSUM_URL := $(WEB_URL)/releases/download/$(UPSTREAM_TAG_V)/checksums.txt
# CHECKSUM_FILE := checksums.txt

# --- EXAMPLE 2: Build from Source (e.g., Go or Node.js projects) ---
# This logic is used for projects like ssv or statusd
# UPSTREAM_TAG_V   := $(shell curl -s "https://api.github.com/repos/project-owner/project-repo/releases/latest" | jq -r '.tag_name')
# UPSTREAM_VERSION := $(shell echo "$(UPSTREAM_TAG_V)" | tr -d "v")
# REPO_URL         := $(WEB_URL).git
# ----------------------------------------------------------------------

# Package output file names
PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(UPSTREAM_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(UPSTREAM_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# (Optional) Install/Remove Scripts
# Example from merge-config, ssv, obol, etc.
# ----------------------------------------------------------------------
# PKG_AFTER_INSTALL ?= extras/postinst
# PKG_BEFORE_REMOVE ?= extras/prerm
# PKG_AFTER_REMOVE  ?= extras/postrm

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
# FPM_DEB_OPTS includes:
# - Architecture definition
# - Disabling default config files
# - Dynamic systemd unit detection (finds .service files in 'extras')
# - Dynamic config-file tracking (finds files in 'sources/etc')
# - Dependencies (merge-config, etc.)
FPM_DEB_OPTS = $(FPM_COMMON_OPTS) \
    -t deb \
    --architecture $(PKG_ARCH) \
    --deb-no-default-config-files \
    $(shell test -d extras && find extras -name '*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P ") \
    --depends merge-config

#  --depends openjdk-21-jre-headless # Example for Java apps
#  --depends jq # Example for scripts that use jq
#  --after-install $(PKG_AFTER_INSTALL) # Example: add post-install script

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name '*.service' -printf "--rpm-systemd %p ") \
    --depends merge-config

#  --depends openjdk-21-jre-headless
#  --depends jq
#  --after-install $(PKG_AFTER_INSTALL)

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — This target stages all files for packaging
# CHANGEME: Select the 'prepare' logic that matches your EXAMPLE above.
# ----------------------------------------------------------------------

# --- PREPARE EXAMPLE 1a: For a .tar.gz file with Checksum & Streaming ---
# prepare: ## Download, verify, and stage binary
# 	@echo "🔎 Resolving latest $(PKG_NAME) version..."
# 	if [[ -z "$(UPSTREAM_TAG_V)" || "$(UPSTREAM_TAG_V)" == "null" ]]; then \
# 	    echo "❌ Could not determine latest version via GitHub API."; exit 1; \
# 	fi
# 	@echo "🔽 Downloading $(PKG_NAME) $(UPSTREAM_VERSION) ($(UPSTREAM_TAG_V))..."
# 	mkdir -p .build $(SOURCESDIR)/usr/bin
#
# 	# Optional: Download and verify checksum
# 	# wget -q -O ".build/$(CHECKSUM_FILE)" "$(CHECKSUM_URL)"
# 	# wget -q -O ".build/$(UPSTREAM_TARBALL)" "$(UPSTREAM_URL)"
# 	# cd .build && sha256sum --ignore-missing -c $(CHECKSUM_FILE) || { echo "❌ Checksum failed!"; exit 1; }
#
# 	# Efficient Streaming Download (if no checksum needed or already verified)
# 	# wget -qO- "$(UPSTREAM_URL)" | tar -xz -C $(SOURCESDIR)/usr/bin --strip-components=1 --wildcards '*/binary-name'
#
# 	# Standard Download & Extract
# 	# wget -q -O ".build/$(UPSTREAM_TARBALL)" "$(UPSTREAM_URL)" || { echo "❌ Download failed: $(UPSTREAM_URL)"; exit 1; };
# 	# tar -xzf ".build/$(UPSTREAM_TARBALL)" -C $(SOURCESDIR)/usr/bin/ --strip-components 1 "*/binary-name"
#
# 	chmod 0755 "$(SOURCESDIR)/usr/bin/binary-name"
# 	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/binary-name"

# --- PREPARE EXAMPLE 1b: For a single binary file ---
# prepare: ## Download latest binary and stage it
# 	@echo "🔎 Resolving latest $(PKG_NAME) version..."
# 	if [[ -z "$(UPSTREAM_TAG_V)" || "$(UPSTREAM_TAG_V)" == "null" ]]; then \
# 	    echo "❌ Could not determine latest version via GitHub API."; exit 1; \
# 	fi
# 	@echo "🔽 Downloading $(PKG_NAME) $(UPSTREAM_VERSION) ($(UPSTREAM_TAG_V))..."
# 	mkdir -p $(SOURCESDIR)/usr/bin
#
# 	# Optional: Download and verify checksum
# 	# mkdir -p .build
# 	# wget -q -O ".build/$(CHECKSUM_FILE)" "$(CHECKSUM_URL)"
# 	# wget -q -O ".build/$(UPSTREAM_BINARY_NAME)" "$(UPSTREAM_URL)"
# 	# cd .build && sha256sum --ignore-missing -c $(CHECKSUM_FILE) || { echo "❌ Checksum failed!"; exit 1; }
# 	# mv ".build/$(UPSTREAM_BINARY_NAME)" "$(SOURCESDIR)/usr/bin/$(PKG_NAME)"
#
# 	# Download the binary directly into the staging dir (if no checksum or already verified)
# 	wget -q -O "$(SOURCESDIR)/usr/bin/$(PKG_NAME)" "$(UPSTREAM_URL)" || { echo "❌ Download failed: $(UPSTREAM_URL)"; exit 1; };
# 	chmod 0755 "$(SOURCESDIR)/usr/bin/$(PKG_NAME)"
# 	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/$(PKG_NAME)"

# --- PREPARE EXAMPLE 2: For Building from Source (Go example) ---
# prepare: ## Build binary from source
# 	@echo "🔎 Resolving latest $(PKG_NAME) version..."
# 	if [[ -z "$(UPSTREAM_TAG_V)" || "$(UPSTREAM_TAG_V)" == "null" ]]; then \
# 	    echo "❌ Could not determine latest version via GitHub API."; exit 1; \
# 	fi
# 	@echo "🔽 Cloning $(PKG_NAME) $(UPSTREAM_VERSION) ($(UPSTREAM_TAG_V))..."
# 	mkdir -p .build/src $(SOURCESDIR)/usr/bin
# 	git clone --depth 1 --branch $(UPSTREAM_TAG_V) $(REPO_URL) .build/src || { echo "❌ Git clone failed"; exit 1; }
#
# 	@echo "🛠 Building binary from source (this may take a while)..."
# 	cd .build/src && \
# 	    env GO111MODULE=on CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 \
# 	    go build -v -o ./build/bin/$(PKG_NAME) ./cmd/main.go \
# 	    || { echo "❌ Go build failed"; exit 1; }
#
# 	@echo "📂 Staging binary..."
# 	cp .build/src/build/bin/$(PKG_NAME) $(SOURCESDIR)/usr/bin/$(PKG_NAME)
# 	chmod 0755 $(SOURCESDIR)/usr/bin/$(PKG_NAME)
# 	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/$(PKG_NAME)"

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
	# CHANGEME: This must match the files created by your 'prepare' target
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
	# This awk script automatically generates help text from the '##' comments
	awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	echo ""
	echo "Version resolved: $(UPSTREAM_VERSION) (Tag: $(UPSTREAM_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================

endif
