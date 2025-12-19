# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Nethermind)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Nethermind binary from GitHub
# - Stages files into ./sources/opt/nethermind
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= nethermind
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU General Public License v3.0
PKG_DESCRIPTION ?= Ethereum 1 client written in .NET
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://nethermind.io
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Query each value directly from the API to avoid JSON corruption in Make variables
NETHERMIND_API_URL := https://api.github.com/repos/NethermindEth/nethermind/releases/latest
NETHERMIND_JQ_FILTER := .assets[] | select(.name | endswith("linux-$(PKG_ARCH).zip"))

NETHERMIND_VERSION := $(shell curl -sL "$(NETHERMIND_API_URL)" | jq -r '.name' | tr -d "v")
NETHERMIND_ZIP     := $(shell curl -sL "$(NETHERMIND_API_URL)" | jq -r '$(NETHERMIND_JQ_FILTER) | .name')
NETHERMIND_URL     := $(shell curl -sL "$(NETHERMIND_API_URL)" | jq -r '$(NETHERMIND_JQ_FILTER) | .browser_download_url')
NETHERMIND_SHA256  := $(shell curl -sL "$(NETHERMIND_API_URL)" | jq -r '$(NETHERMIND_JQ_FILTER) | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(NETHERMIND_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(NETHERMIND_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(NETHERMIND_VERSION) \
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
    $(shell test -d extras && find extras -name '$(PKG_NAME)*.service' -printf "--deb-systemd %p " || true) \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --deb-user ethereum \
    --deb-group ethereum \
    --directories /opt/nethermind \
    --depends libsnappy-dev \
    --depends libc6-dev \
    --depends libc6 \
    --conflicts librocksdb-dev --conflicts librocksdb5.17 \
    --depends unzip \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name '$(PKG_NAME)*.service' -printf "--rpm-systemd %p " || true) \
    --rpm-user ethereum \
    --rpm-group ethereum \
    --directories /opt/nethermind \
    --depends snappy-devel \
    --depends glibc-devel \
    --depends glibc \
    --conflicts rocksdb-devel \
    --depends unzip

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — download & stage Nethermind binary
# ----------------------------------------------------------------------
prepare: ## Download latest Nethermind and stage into $(SOURCESDIR)/opt
	@echo "🔎 Resolving latest Nethermind version..."
	if [[ -z "$(NETHERMIND_VERSION)" || "$(NETHERMIND_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest Nethermind version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Nethermind $(NETHERMIND_VERSION) for $(PKG_ARCH)..."
	mkdir -p .build $(SOURCESDIR)/opt/nethermind/logs
	wget -q -O ".build/$(NETHERMIND_ZIP)" "$(NETHERMIND_URL)" || { echo "❌ Download failed: $(NETHERMIND_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(NETHERMIND_SHA256)  .build/$(NETHERMIND_ZIP)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(NETHERMIND_ZIP)"; exit 1; };
	@echo "📦 Extracting files..."
	unzip -o ".build/$(NETHERMIND_ZIP)" -d "$(SOURCESDIR)/opt/nethermind"
	@echo "✅ Files downloaded and verified in $(SOURCESDIR)/opt/nethermind"

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
clean: ## Remove staged binaries, cache, and temp files
	rm -rf $(SOURCESDIR)/opt/nethermind/* .build
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
	awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z09_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	echo ""
	echo "Version resolved: $(NETHERMIND_VERSION)"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================