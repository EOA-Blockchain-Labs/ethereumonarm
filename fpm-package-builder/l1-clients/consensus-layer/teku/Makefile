# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Teku)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Teku binary from ConsenSys
# - Stages files into ./sources/usr/bin and ./sources/usr/share
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= teku
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Apache License 2.0
PKG_DESCRIPTION ?= Consensys Quorum Teku Eth2 java client
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://consensys.net/knowledge-base/ethereum-2/teku/
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
TEKU_VERSION := $(shell curl -sL https://api.github.com/repos/ConsenSys/teku/releases/latest | jq -r '.name' | tr -d 'v')

TEKU_TARBALL := teku-$(TEKU_VERSION).tar.gz
TEKU_URL     := https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/$(TEKU_VERSION)/$(TEKU_TARBALL)

# SHA256 checksum extracted from GitHub release changelog (body field)
# Format in release notes: "tar.gz ... (sha256: `HASH`)"
TEKU_RELEASE_BODY := $(shell curl -sL https://api.github.com/repos/ConsenSys/teku/releases/latest | jq -r '.body')
TEKU_SHA256 := $(shell echo '$(TEKU_RELEASE_BODY)' | grep -oP 'tar\.gz.*?sha256:\s*\`\K[a-f0-9]{64}' | head -1)

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(TEKU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(TEKU_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(TEKU_VERSION) \
    --iteration $(PKG_RELEASE) \
    --vendor "$(PKG_VENDOR)" \
    --license "$(PKG_LICENSE)" \
    --description "$(PKG_DESCRIPTION)" \
    --maintainer "$(PKG_MAINTAINER)" \
    --category "$(CATEGORY)" \
    --url "$(WEB_URL)" \
    --after-install extras/postinst.sh \
    -C $(SOURCESDIR) \
    -x '*/.gitkeep'

# ----------------------------------------------------------------------
# Debian-specific options
# ----------------------------------------------------------------------
FPM_DEB_OPTS = $(FPM_COMMON_OPTS) \
    -t deb \
    --architecture $(PKG_ARCH) \
    --deb-no-default-config-files \
    $(shell test -d extras && find extras -name 'teku-*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends openjdk-21-jre-headless \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'teku-*.service' -printf "--rpm-systemd %p ") \
    --depends openjdk-21-jre-headless \
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
# prepare — download & stage Teku binary
# ----------------------------------------------------------------------
prepare: ## Download latest Teku and stage into $(SOURCESDIR)
	@echo "🔎 Resolving latest Teku version..."
	if [[ -z "$(TEKU_VERSION)" || "$(TEKU_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest Teku version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Teku $(TEKU_VERSION)..."
	# Use a local .build dir instead of /tmp
	mkdir -p .build $(SOURCESDIR)/usr/bin $(SOURCESDIR)/usr/share/teku/lib
	wget -q -O ".build/$(TEKU_TARBALL)" "$(TEKU_URL)" || { echo "❌ Download failed: $(TEKU_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(TEKU_SHA256)  .build/$(TEKU_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(TEKU_TARBALL)"; exit 1; };
	
	@echo "📦 Extracting files..."
	tar -xzf ".build/$(TEKU_TARBALL)" -C .build --strip-components 1
	
	@echo "📂 Staging files..."
	cp ".build/bin/teku" "$(SOURCESDIR)/usr/bin/"
	cp ".build/lib/"* "$(SOURCESDIR)/usr/share/teku/lib/"
	
	@echo "🔧 Patching binary paths..."
	sed -i 's/"$${APP_HOME:-\.\/}\.\."/"$${APP_HOME:-\.\/}\.\.\/share\/teku"/g' "$(SOURCESDIR)/usr/bin/teku"
	chmod 0755 "$(SOURCESDIR)/usr/bin/teku"
	@echo "✅ Binary and libs downloaded and verified in $(SOURCESDIR)"

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
	rm -rf $(SOURCESDIR)/usr/bin/teku* $(SOURCESDIR)/usr/share/teku/lib/* .build
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
	echo "Version resolved: $(TEKU_VERSION)"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================