# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Juno)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Juno binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= starknet-juno
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU General Public License v3.0
PKG_DESCRIPTION ?= StarkNet Juno node by Nethermind
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/NethermindEth/juno
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v0.12.0)
JUNO_TAG_V := $(shell curl -s "https://api.github.com/repos/NethermindEth/juno/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 0.12.0)
JUNO_VERSION := $(shell echo "$(JUNO_TAG_V)" | tr -d "v")

JUNO_ZIP_FILE := juno-$(JUNO_TAG_V)-linux-$(PKG_ARCH).zip
JUNO_BIN_FILE := juno-$(JUNO_TAG_V)-linux-$(PKG_ARCH)
JUNO_URL      := https://github.com/NethermindEth/juno/releases/download/$(JUNO_TAG_V)/$(JUNO_ZIP_FILE)

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(JUNO_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(JUNO_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
  -s dir \
  -n $(PKG_NAME) \
  -v $(JUNO_VERSION) \
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
  $(shell test -d extras && find extras -name 'juno*.service' -printf "--deb-systemd %p ") \
  $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
  --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
  -t rpm \
  --architecture $(PKG_ARCH_RPM) \
  $(shell test -d extras && find extras -name 'juno*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Juno binary
# ----------------------------------------------------------------------
prepare: ## Download latest Juno and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Juno version..."
	if [[ -z "$(JUNO_TAG_V)" || "$(JUNO_TAG_V)" == "null" ]]; then \
	  echo "❌ Could not determine latest Juno version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Juno $(JUNO_VERSION) ($(JUNO_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(JUNO_ZIP_FILE)" "$(JUNO_URL)" || { echo "❌ Download failed: $(JUNO_URL)"; exit 1; };
	
	@echo "📦 Extracting binary..."
	unzip -o ".build/$(JUNO_ZIP_FILE)" -d .build
	
	@echo "📂 Staging binary..."
	cp ".build/$(JUNO_BIN_FILE)" "$(SOURCESDIR)/usr/bin/juno"
	chmod 0755 "$(SOURCESDIR)/usr/bin/juno"
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/juno"

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
	rm -rf $(SOURCESDIR)/usr/bin/juno* .build
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
	echo "Version resolved: $(JUNO_VERSION) (Tag: $(JUNO_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================