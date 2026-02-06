# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Besu)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads the latest upstream Besu binary from GitHub
# - Stages files into ./sources/usr/bin and ./sources/usr/share
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= besu
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= Apache License 2.0
PKG_DESCRIPTION ?= Hyperledger Ethereum 1.0 java client
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://www.hyperledger.org/use/besu
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
BESU_VERSION := $(shell curl -sL https://api.github.com/repos/hyperledger/besu/releases/latest | jq -r '.tag_name'| tr -d 'v')
BESU_ZIP     := besu-$(BESU_VERSION).zip
BESU_URL     := https://github.com/hyperledger/besu/releases/download/$(BESU_VERSION)/$(BESU_ZIP)

# SHA256 checksum extracted from GitHub release changelog (body field)
# Format in release notes: "HASH  besu-X.X.X.zip"
# SHA256 checksum extracted from GitHub release changelog (body field) within the prepare target to ensure robustness

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(BESU_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(BESU_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(BESU_VERSION) \
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
# Includes dynamic systemd unit detection and dynamic config-file tracking
FPM_DEB_OPTS = $(FPM_COMMON_OPTS) \
    -t deb \
    --architecture $(PKG_ARCH) \
    --deb-no-default-config-files \
    $(shell test -d extras && find extras -name '$(PKG_NAME)*.service' -printf "--deb-systemd %p " || true) \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
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
    $(shell test -d extras && find extras -name '$(PKG_NAME)*.service' -printf "--rpm-systemd %p " || true) \
    --depends openjdk-21-jre-headless \
    --depends "libsecp256k1-0 | libsecp256k1-1" \
    --depends merge-config \
    --depends libjemalloc-devel

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — download & stage Besu binary
# ----------------------------------------------------------------------
prepare: ## Download latest Besu and stage into $(SOURCESDIR)
	@echo "🔎 Resolving latest Besu version..."
	if [[ -z "$(BESU_VERSION)" || "$(BESU_VERSION)" == "null" ]]; then \
	    echo "❌ Could not determine latest Besu version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Downloading Besu $(BESU_VERSION)..."
	# Use a local .build dir instead of /tmp
	mkdir -p .build $(SOURCESDIR)/usr/bin $(SOURCESDIR)/usr/share/besu/lib
	wget -q -O ".build/$(BESU_ZIP)" "$(BESU_URL)" || { echo "❌ Download failed: $(BESU_URL)"; exit 1; };
	
	@echo "🔎 Extracting checksum from release notes..."
	CHECKSUM=$$(curl -sL https://api.github.com/repos/hyperledger/besu/releases/latest | jq -r '.body' | grep "$(BESU_ZIP)" | awk '{print $$1}'); \
	if [[ -z "$$CHECKSUM" ]]; then echo "❌ Failed to extract checksum from release notes"; exit 1; fi; \
	echo "🔐 Verifying SHA256 (Hash: $$CHECKSUM)..."; \
	echo "$$CHECKSUM  .build/$(BESU_ZIP)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(BESU_ZIP)"; exit 1; };
	@echo "📦 Extracting files..."
	unzip -o ".build/$(BESU_ZIP)" "besu-$(BESU_VERSION)/bin/besu" -d .build
	unzip -o ".build/$(BESU_ZIP)" "besu-$(BESU_VERSION)/lib/*" -d .build
	@echo "📂 Staging files..."
	cp ".build/besu-$(BESU_VERSION)/bin/besu" "$(SOURCESDIR)/usr/bin/"
	cp ".build/besu-$(BESU_VERSION)/lib/"* "$(SOURCESDIR)/usr/share/besu/lib/"
	@echo "🔧 Patching binary paths..."
	sed -i 's/`pwd -P`/\/usr\/share\/besu\//' "$(SOURCESDIR)/usr/bin/besu"
	chmod 0755 "$(SOURCESDIR)/usr/bin/besu"
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
	rm -rf $(SOURCESDIR)/usr/bin/$(PKG_NAME)* $(SOURCESDIR)/usr/share/besu/lib/* .build
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
	echo "Version resolved: $(BESU_VERSION)"
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
