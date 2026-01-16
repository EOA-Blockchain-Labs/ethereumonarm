# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Helios)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Helios binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= helios
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= "Apache License 2.0"
PKG_DESCRIPTION ?= A fast, secure, and portable light client for Ethereum
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/a16z/helios
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
LATEST_TAG_JSON := $(shell curl -s "https://api.github.com/repos/a16z/helios/releases/latest")
UPSTREAM_TAG_V  := $(shell echo '$(LATEST_TAG_JSON)' | jq -r '.tag_name')
UPSTREAM_VERSION := $(shell echo "$(UPSTREAM_TAG_V)" | tr -d "v")

# Helios naming convention: helios_linux_arm64.tar.gz
# We map PKG_ARCH (arm64) to the filename
UPSTREAM_TARBALL := helios_linux_$(PKG_ARCH).tar.gz
UPSTREAM_URL     := $(WEB_URL)/releases/download/$(UPSTREAM_TAG_V)/$(UPSTREAM_TARBALL)

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
    $(shell test -d extras && find extras -name '*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P ") \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name '*.service' -printf "--rpm-systemd %p ") \
    --depends merge-config

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help docker-build

all: prepare deb clean test ## Default local build pipeline

prepare: ## Download, verify, and stage binary
	@echo "🔎 Resolving latest $(PKG_NAME) version..."
	if [[ -z "$(UPSTREAM_TAG_V)" || "$(UPSTREAM_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading $(PKG_NAME) $(UPSTREAM_VERSION) ($(UPSTREAM_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin

	# Download tarball
	wget -q -O ".build/$(UPSTREAM_TARBALL)" "$(UPSTREAM_URL)" || { echo "❌ Download failed: $(UPSTREAM_URL)"; exit 1; };
	
	@echo "📦 Extracting binary..."
	# Helios tarball contains the binary directly, no directory structure usually
	tar -xzf ".build/$(UPSTREAM_TARBALL)" -C $(SOURCESDIR)/usr/bin/ helios || { echo "❌ Extraction failed"; exit 1; }

	chmod 0755 "$(SOURCESDIR)/usr/bin/helios"
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/helios"

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
	rm -rf $(SOURCESDIR)/usr/bin/$(PKG_NAME)* .build
	@echo "🧹 Clean complete (staged files and .build removed)."

test: ## Check that .deb exists
	if [[ -f "$(PKG_DEB)" ]]; then \
	    echo "🧪 Test: .deb exists — OK ✅"; \
	else \
	    echo "🧪 Test: .deb missing — ❌"; exit 1; \
	fi

release: clean prepare deb rpm test ## Clean + Prepare + Build + Test (all)
	@echo "🎉 All packages built successfully for $(PKG_ARCH)"

help: ## Show available targets
	echo ""
	echo "EOA Packaging — $(PKG_NAME)"
	echo ""
	awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	echo ""
	echo "Version resolved: $(UPSTREAM_VERSION) (Tag: $(UPSTREAM_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""