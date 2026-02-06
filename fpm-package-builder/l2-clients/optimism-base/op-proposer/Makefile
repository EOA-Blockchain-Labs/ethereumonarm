# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (op-proposer)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Clones and builds the 'op-proposer' binary from source
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= optimism-op-proposer
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= L2 Output Proposer client for Optimism
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ethereum-optimism/optimism/tree/develop/op-proposer
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the full tag (e.g., op-challenger/v1.0.0) from the latest release
# Note: op-proposer is part of the monorepo. We use the op-challenger tag as a reference for the latest release.
OP_PROPOSER_TAG := $(shell curl -s "https://api.github.com/repos/ethereum-optimism/optimism/releases" | jq -r '[.[] | select(.tag_name | startswith("op-challenger/"))] | sort_by(.published_at) | .[-1].tag_name')

# Get the version number (e.g., 1.0.0) by stripping the prefix using a Make function
OP_PROPOSER_VERSION := $(patsubst op-challenger/v%,%,$(OP_PROPOSER_TAG))

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(OP_PROPOSER_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(OP_PROPOSER_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
	-s dir \
	-n $(PKG_NAME) \
	-v $(OP_PROPOSER_VERSION) \
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
	$(shell test -d extras && find extras -name 'op-proposer*.service' -printf "--deb-systemd %p ") \
	$(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
	--depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
	-t rpm \
	--architecture $(PKG_ARCH_RPM) \
	$(shell test -d extras && find extras -name 'op-proposer*.service' -printf "--rpm-systemd %p ") \
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
# prepare — Build binary from source
# ----------------------------------------------------------------------
prepare: ## Build binary from source
	@echo "🔎 Resolving latest op-proposer version..."
	if [[ -z "$(OP_PROPOSER_TAG)" || "$(OP_PROPOSER_TAG)" == "null" ]]; then \
		echo "❌ Could not determine latest op-proposer version via GitHub API. (Found: $(OP_PROPOSER_TAG))"; exit 1; \
	fi
	@echo "🔽 Cloning optimism monorepo at tag $(OP_PROPOSER_TAG)..."
	mkdir -p .build/op-proposer_src $(SOURCESDIR)/usr/bin
	git clone --depth 1 --branch $(OP_PROPOSER_TAG) https://github.com/ethereum-optimism/optimism.git .build/op-proposer_src || { echo "❌ Git clone failed"; exit 1; }
	
	@echo "🛠 Building op-proposer binary from source..."
	cd .build/op-proposer_src/op-proposer && \
		env GO111MODULE=on CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 \
		go build -v -o ./build/bin/op-proposer ./cmd \
		|| { echo "❌ Go build failed"; exit 1; }
	
	@echo "📂 Staging binary..."
	cp .build/op-proposer_src/op-proposer/build/bin/op-proposer $(SOURCESDIR)/usr/bin/op-proposer
	chmod 0755 $(SOURCESDIR)/usr/bin/op-proposer
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/op-proposer"

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
	rm -rf $(SOURCESDIR)/usr/bin/op-proposer* .build
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
	echo "Version resolved: $(OP_PROPOSER_VERSION) (Tag: $(OP_PROPOSER_TAG))"
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
