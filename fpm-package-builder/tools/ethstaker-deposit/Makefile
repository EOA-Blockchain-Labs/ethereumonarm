# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (ethstaker-deposit-cli)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream ethstaker-deposit-cli binary from GitHub
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= ethstaker-deposit-cli
PKG_RELEASE     ?= 1
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Creative Commons Zero v1.0 Universal
PKG_DESCRIPTION ?= A tool for creating EIP-2335 format BLS12-381 keystores.
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/eth-educators/ethstaker-deposit-cli/
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Use 'releases/latest' to get the package version (e.g., 1.2.2)
DEPOSIT_VERSION := $(shell curl -sL "https://api.github.com/repos/eth-educators/ethstaker-deposit-cli/releases/latest" | jq -r '.tag_name' | tr -d "v")
# Use 'tags' to get the latest tag name (e.g., v1.2.2) and its commit hash (e.g., b13dcb9)
LATEST_TAG_JSON := $(shell curl -sL "https://api.github.com/repos/eth-educators/ethstaker-deposit-cli/tags" | jq -r 'if type=="array" then .[0] else empty end')
DEPOSIT_TAG_V   := $(shell echo '$(LATEST_TAG_JSON)' | jq -r '.name')
DEPOSIT_HASH    := $(shell echo '$(LATEST_TAG_JSON)' | jq -r '.commit.sha' | cut -c1-7)

# The asset filename uses an UNDERSCORE, not a hyphen like PKG_NAME.
DEPOSIT_TARBALL := ethstaker_deposit-cli-$(DEPOSIT_HASH)-linux-$(PKG_ARCH).tar.gz
DEPOSIT_URL     := https://github.com/eth-educators/ethstaker-deposit-cli/releases/download/$(DEPOSIT_TAG_V)/$(DEPOSIT_TARBALL)
DEPOSIT_SHA256_URL := $(DEPOSIT_URL).sha256

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(DEPOSIT_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(DEPOSIT_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(DEPOSIT_VERSION) \
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
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
    --conflicts eth2.0-deposit-cli --conflicts staking-deposit-cli \
    --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    --conflicts eth2.0-deposit-cli --conflicts staking-deposit-cli \
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
# prepare — download & stage ethstaker-deposit-cli binary
# ----------------------------------------------------------------------
prepare: ## Download latest ethstaker-deposit-cli and stage into $(SOURCESDIR)/usr/bin
	@echo "🔎 Resolving latest ethstaker-deposit-cli version..."
	if [[ -z "$(DEPOSIT_TAG_V)" || "$(DEPOSIT_TAG_V)" == "null" || -z "$(DEPOSIT_HASH)" ]]; then \
	    echo "❌ Could not determine latest ethstaker-deposit-cli version or hash via GitHub API."; \
	    echo "   (This may be a network issue or a GitHub API rate limit.)"; exit 1; \
	fi
	@echo "🔽 Downloading ethstaker-deposit-cli $(DEPOSIT_VERSION) (Tag: $(DEPOSIT_TAG_V), Hash: $(DEPOSIT_HASH))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin
	wget -q -O ".build/$(DEPOSIT_TARBALL)" "$(DEPOSIT_URL)" || { echo "❌ Download failed: $(DEPOSIT_URL)"; exit 1; };
	wget -q -O ".build/$(DEPOSIT_TARBALL).sha256" "$(DEPOSIT_SHA256_URL)" || { echo "❌ SHA256 file download failed"; exit 1; };
	
	@echo "🔐 Verifying SHA256..."
	@cd .build && echo "$$(cat $(DEPOSIT_TARBALL).sha256)  $(DEPOSIT_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f "$(DEPOSIT_TARBALL)"; exit 1; };
	
	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(DEPOSIT_TARBALL)" -C .build
	find .build -name deposit -type f -exec mv {} $(SOURCESDIR)/usr/bin/deposit \;
	chmod 0755 "$(SOURCESDIR)/usr/bin/deposit"
	@echo "✅ Binary downloaded and verified at $(SOURCESDIR)/usr/bin/deposit"

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
	rm -rf $(SOURCESDIR)/usr/bin/deposit* .build
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
	@echo ""
	@echo "EOA Packaging — $(PKG_NAME)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_%-]+:.*?##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Package Version : $(DEPOSIT_VERSION)"
	@echo "Release Tag     : $(DEPOSIT_TAG_V)"
	@echo "Release Hash    : $(DEPOSIT_HASH)"
	@echo "Download URL    : $(DEPOSIT_URL)"
	@echo "Sources dir     : $(SOURCESDIR)"
	@echo "Output dir      : $(OUTPUTDIR)"
	@echo ""
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
