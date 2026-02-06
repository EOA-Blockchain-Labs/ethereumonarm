# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Linea)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Linea Besu binary from GitHub
# - Stages files into ./sources/usr/bin and ./sources/usr/share
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= maru
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Apache License 2.0
PKG_DESCRIPTION ?= ConsenSys Maru Client
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/Consensys/maru
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Resolve latest release tag
UPSTREAM_TAG_V := $(shell curl -s "https://api.github.com/repos/Consensys/maru/releases/latest" | jq -r '.tag_name')
UPSTREAM_VERSION := $(shell echo "$(UPSTREAM_TAG_V)" | sed 's/^v//')

# Filename matches: maru-v1.0.0-....tar.gz 
UPSTREAM_TARBALL := $(shell curl -s "https://api.github.com/repos/Consensys/maru/releases/latest" | jq -r '.assets[0].name')
UPSTREAM_URL     := $(WEB_URL)/releases/download/$(UPSTREAM_TAG_V)/$(UPSTREAM_TARBALL)

# Digest from asset metadata
UPSTREAM_SHA256 := $(shell curl -s "https://api.github.com/repos/Consensys/maru/releases/latest" | jq -r '.assets[0].digest' | sed 's/^sha256://')

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
    --deb-compression xz \
    $(shell test -d extras && find extras -name '*.service' | sed 's/^/--deb-systemd /') \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f | sed "s|^$(SOURCESDIR)/etc/|/etc/|" | sed 's/^/--config-files /') \
    --depends openjdk-21-jre-headless \
    --depends "libsecp256k1-0|libsecp256k1-1" \
    --depends merge-config \
    --depends libjemalloc-dev

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name '*.service' | sed 's/^/--rpm-systemd /') \
    --depends openjdk-21-jre-headless \
    --depends "libsecp256k1-0 | libsecp256k1-1" \
    --depends merge-config \
    --depends libjemalloc-devel

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

all: prepare deb clean test ## Default local build pipeline

prepare: ## Download, verify, and stage binary
	@echo "🔎 Resolving latest $(PKG_NAME) version..."
	if [[ -z "$(UPSTREAM_TAG_V)" || "$(UPSTREAM_TAG_V)" == "null" ]]; then \
	    echo "❌ Could not determine latest version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading $(PKG_NAME) $(UPSTREAM_VERSION) ($(UPSTREAM_TAG_V))..."
	mkdir -p .build $(SOURCESDIR)/usr/bin $(SOURCESDIR)/usr/share/maru

	# Download tarball
	wget -q -O ".build/$(UPSTREAM_TARBALL)" "$(UPSTREAM_URL)" || { echo "❌ Download failed: $(UPSTREAM_URL)"; exit 1; };
	
	@echo "🔐 Verifying SHA256..."
	@echo "$(UPSTREAM_SHA256)  .build/$(UPSTREAM_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(UPSTREAM_TARBALL)"; exit 1; };

	@echo "📦 Extracting..."
	mkdir -p .build/extracted
	tar -xzf ".build/$(UPSTREAM_TARBALL)" -C .build/extracted || { echo "❌ Extraction failed"; exit 1; }

	@echo "📂 Staging files..."
	mkdir -p "$(SOURCESDIR)/usr/share/maru"
	cp -r .build/extracted/* "$(SOURCESDIR)/usr/share/maru/"
	
	mkdir -p "$(SOURCESDIR)/usr/bin"
	# Binary is generic 'app', rename to 'maru'
	cp "$(SOURCESDIR)/usr/share/maru/bin/app" "$(SOURCESDIR)/usr/bin/maru"

	@echo "🔧 Patching binary paths..."
	sed -i.bak 's|^APP_HOME=.*|APP_HOME="/usr/share/maru"|' "$(SOURCESDIR)/usr/bin/maru"
	rm "$(SOURCESDIR)/usr/bin/maru.bak"
	
	chmod 0755 "$(SOURCESDIR)/usr/bin/maru"
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/maru"

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
	rm -rf $(SOURCESDIR)/usr/bin/$(PKG_NAME)* $(SOURCESDIR)/usr/share/maru .build
	@echo "🧹 Clean complete."

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
