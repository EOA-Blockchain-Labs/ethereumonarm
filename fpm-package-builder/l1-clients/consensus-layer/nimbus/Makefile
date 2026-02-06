# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Nimbus)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Nimbus binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= nimbus
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= Ethereum 2.0 Nimbus implementation
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://nimbus.team/
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Make one API call to get all assets, then extract info
NIMBUS_LATEST_JSON := $(shell curl -sL https://api.github.com/repos/status-im/nimbus-eth2/releases/latest)
NIMBUS_TAG         := $(shell echo '$(NIMBUS_LATEST_JSON)' | jq -r '.tag_name')
NIMBUS_VERSION     := $(shell echo '$(NIMBUS_TAG)' | tr -d 'v')

# Find the asset JSON that matches our specific tarball (arm64v8 and .tar.gz)
NIMBUS_ASSET_JSON  := $(shell echo '$(NIMBUS_LATEST_JSON)' | jq -r ".assets[] | select(.name | (contains(\"arm64v8\") and endswith(\".tar.gz\")))")
NIMBUS_TARBALL     := $(shell echo '$(NIMBUS_ASSET_JSON)' | jq -r '.name')
NIMBUS_URL         := $(shell echo '$(NIMBUS_ASSET_JSON)' | jq -r '.browser_download_url')

# SHA256 checksum extracted from GitHub API asset digest field
NIMBUS_SHA256      := $(shell echo '$(NIMBUS_ASSET_JSON)' | jq -r '.digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(NIMBUS_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(NIMBUS_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(NIMBUS_VERSION) \
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
    $(shell test -d extras && find extras -name 'nimbus-*.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'nimbus-*.service' -printf "--rpm-systemd %p ") \
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
# prepare — download & stage Nimbus binary
# ----------------------------------------------------------------------
prepare: ## Download latest Nimbus and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest Nimbus version..."
	if [[ -z "$(NIMBUS_TAG)" || "$(NIMBUS_TAG)" == "null" ]]; then \
	    echo "❌ Could not determine latest Nimbus version via GitHub API."; exit 1; \
	fi
	if [[ -z "$(NIMBUS_URL)" || "$(NIMBUS_URL)" == "null" ]]; then \
	    echo "❌ Could not resolve download URL for $(PKG_ARCH_RPM) from GitHub API assets."; exit 1; \
	fi
	@echo "🔽 Downloading Nimbus $(NIMBUS_VERSION) ($(NIMBUS_TAG))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(NIMBUS_TARBALL)" "$(NIMBUS_URL)" || { echo "❌ Download failed: $(NIMBUS_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(NIMBUS_SHA256)  .build/$(NIMBUS_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(NIMBUS_TARBALL)"; exit 1; };
	@echo "📦 Extracting binaries..."
	tar -xzf ".build/$(NIMBUS_TARBALL)" -C $(SOURCESDIR)/usr/bin/ --wildcards --absolute-names --no-anchored --strip-components 2 '*/nimbus_*'
	rm -f $(SOURCESDIR)/usr/bin/nimbus*.sha512sum
	chmod 0755 $(SOURCESDIR)/usr/bin/nimbus*
	@echo "✅ Binaries downloaded and verified in $(SOURCESDIR)/usr/bin"

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
	rm -rf $(SOURCESDIR)/usr/bin/nimbus* .build
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
	echo "Version resolved: $(NIMBUS_VERSION) (Tag: $(NIMBUS_TAG))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""
# ----------------------------------------------------------------------
# docker-build — build inside a Docker container
# ----------------------------------------------------------------------
docker-build: check-qemu ## Run the build inside a Docker container
	# Uses the shared builder image defined in fpm-package-builder/Dockerfile
	docker run --rm -v $(PWD):/workspace -w /workspace \
	    -e PKG_NAME=$(PKG_NAME) \
	    -e PKG_RELEASE=$(PKG_RELEASE) \
	    eoa-builder \
	    /bin/bash -c "make release"

# ----------------------------------------------------------------------
# QEMU check
# ----------------------------------------------------------------------
check-qemu:
	@if [ "$$(uname -m)" = "x86_64" ]; then \
		if [ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ] && [ ! -f /proc/sys/fs/binfmt_misc/aarch64 ]; then \
			echo "⚠️  Warning: Host is x86_64 but qemu-aarch64 binfmt seems missing."; \
			echo "   Installing QEMU binfmt for ARM64 emulation..."; \
			docker run --privileged --rm tonistiigi/binfmt --install all || true; \
		fi \
	fi

# ======================================================================
# End of file
# ======================================================================
