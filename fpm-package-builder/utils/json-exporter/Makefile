# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (json-exporter)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream json_exporter binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= json-exporter
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= A prometheus exporter which scrapes remote JSON by JSONPath
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/prometheus-community/json_exporter
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v0.6.0)
JEXP_TAG_V := $(shell curl -s https://api.github.com/repos/prometheus-community/json_exporter/releases/latest | jq -r '.tag_name')
# Get the version without "v" (e.g., 0.6.0)
JEXP_VERSION := $(shell echo "$(JEXP_TAG_V)" | tr -d "v")

JEXP_TARBALL := json_exporter-$(JEXP_VERSION).linux-$(PKG_ARCH).tar.gz
JEXP_URL     := https://github.com/prometheus-community/json_exporter/releases/download/$(JEXP_TAG_V)/$(JEXP_TARBALL)

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(JEXP_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(JEXP_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
  -s dir \
  -n $(PKG_NAME) \
  -v $(JEXP_VERSION) \
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
  $(shell test -d extras && find extras -name 'json-exporter*.service' -printf "--deb-systemd %p ") \
  $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
  --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
  -t rpm \
  --architecture $(PKG_ARCH_RPM) \
  $(shell test -d extras && find extras -name 'json-exporter*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage json-exporter binary
# ----------------------------------------------------------------------
prepare: ## Download latest json-exporter and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest json-exporter version..."
	if [[ -z "$(JEXP_TAG_V)" || "$(JEXP_TAG_V)" == "null" ]]; then \
	 echo "❌ Could not determine latest json-exporter version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading json-exporter $(JEXP_VERSION) ($(JEXP_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(JEXP_TARBALL)" "$(JEXP_URL)" || { echo "❌ Download failed: $(JEXP_URL)"; exit 1; };
	
	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(JEXP_TARBALL)" -C $(SOURCESDIR)/usr/bin/ --strip-components 1 --wildcards "*/json_exporter"
	chmod 0755 "$(SOURCESDIR)/usr/bin/json_exporter"
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/json_exporter"

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
	rm -rf $(SOURCESDIR)/usr/bin/json_exporter* .build
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
	echo "Version resolved: $(JEXP_VERSION) (Tag: $(JEXP_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================