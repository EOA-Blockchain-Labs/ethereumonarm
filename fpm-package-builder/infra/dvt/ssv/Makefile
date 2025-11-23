# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (dvt-ssv)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Clones and builds 'ssvnode' (Go) and 'ssv-keys' (Node) from source
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= dvt-ssv
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU Lesser General Public License v3.0
PKG_DESCRIPTION ?= SSV DVT client
PKG_MAINTAINER  ?= Diego Losada <dlosada@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ssvlabs/ssv
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages
PKG_AFTER_INSTALL ?= extras/postinstall

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
SSV_TAG_V := $(shell curl -s "https://api.github.com/repos/ssvlabs/ssv/releases/latest" | jq -r '.tag_name')
SSV_VERSION := $(shell echo "$(SSV_TAG_V)" | tr -d "v")

SSV_KEYS_TAG_V := $(shell curl -s "https://api.github.com/repos/ssvlabs/ssv-keys/releases/latest" | jq -r '.tag_name')
SSV_KEYS_VERSION := $(shell echo "$(SSV_KEYS_TAG_V)" | tr -d "v")

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(SSV_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(SSV_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
  -s dir \
  -n $(PKG_NAME) \
  -v $(SSV_VERSION) \
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
  --after-install $(PKG_AFTER_INSTALL) \
  --deb-no-default-config-files \
  $(shell test -d extras && find extras -name 'ssv*.service' -printf "--deb-systemd %p ") \
  $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
  --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
  -t rpm \
  --architecture $(PKG_ARCH_RPM) \
  --after-install $(PKG_AFTER_INSTALL) \
  $(shell test -d extras && find extras -name 'ssv*.service' -printf "--rpm-systemd %p ") \
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
# prepare — Build binaries from source
# ----------------------------------------------------------------------
prepare: ## Extract ssvnode from Docker and build ssv-keys from source
	@echo "🔎 Resolving latest SSV versions..."
	if [[ -z "$(SSV_TAG_V)" || "$(SSV_TAG_V)" == "null" ]]; then \
	  echo "❌ Could not determine latest ssv version via GitHub API."; exit 1; \
	fi
	if [[ -z "$(SSV_KEYS_TAG_V)" || "$(SSV_KEYS_TAG_V)" == "null" ]]; then \
	  echo "❌ Could not determine latest ssv-keys version via GitHub API."; exit 1; \
	fi
	
	@echo "� Pulling ssvnode Docker image: ssvlabs/ssv-node:$(SSV_TAG_V)..."
	mkdir -p .build/ssv_keys_src $(SOURCESDIR)/usr/bin
	docker pull --platform linux/arm64 ssvlabs/ssv-node:$(SSV_TAG_V) || { echo "❌ Docker pull failed"; exit 1; }

	@echo "� Extracting ssvnode binary from container..."
	CID=$$(docker create --platform linux/arm64 ssvlabs/ssv-node:$(SSV_TAG_V)); \
	docker cp "$$CID:/go/bin/ssvnode" "$(SOURCESDIR)/usr/bin/ssvnode" || { echo "❌ Docker cp failed"; docker rm "$$CID"; exit 1; }; \
	docker rm "$$CID" > /dev/null
	chmod 0755 "$(SOURCESDIR)/usr/bin/ssvnode"

	@echo "🔽 Cloning ssv-keys $(SSV_KEYS_VERSION) ($(SSV_KEYS_TAG_V))..."
	git clone --depth 1 --branch $(SSV_KEYS_TAG_V) https://github.com/ssvlabs/ssv-keys.git .build/ssv_keys_src || { echo "❌ Git clone ssv-keys failed"; exit 1; }

	@echo "🔧 Patching ssv-keys package.json for ARM64..."
	cd .build/ssv_keys_src && \
	  sed -i '/"package-linux": "pkg dist\/cli-interactive.js --targets node22-linux-x64 --output bin\/linux\/ssv-keys-lin --compress GZip",/a \ \ "package-linux-arm64": "pkg dist/cli-interactive.js --targets node22-linux-arm64 --output bin/linux/ssv-keys-lin-arm64 --compress GZip",' package.json \
	  || { echo "❌ Patching ssv-keys failed"; exit 1; }

	@echo "📦 Installing ssv-keys dependencies (pnpm)..."
	cd .build/ssv_keys_src && \
	  pnpm install --fetch-timeout 1000000 || { echo "❌ pnpm install failed"; exit 1; }
	
	@echo "🛠 Building ssv-keys binary..."
	cd .build/ssv_keys_src && \
	  pnpm package-linux-arm64 || { echo "❌ pnpm build failed"; exit 1; }

	@echo "📂 Staging ssv-keys binary..."
	cp .build/ssv_keys_src/bin/linux/ssv-keys-lin-arm64 $(SOURCESDIR)/usr/bin/ssv-keys
	chmod 0755 $(SOURCESDIR)/usr/bin/ssv-keys
	@echo "✅ Binaries ready at $(SOURCESDIR)/usr/bin"

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
	rm -rf $(SOURCESDIR)/usr/bin/ssv* .build
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
	echo "ssvnode Version : $(SSV_VERSION) (Tag: $(SSV_TAG_V))"
	echo "ssv-keys Version: $(SSV_KEYS_VERSION) (Tag: $(SSV_KEYS_TAG_V))"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================