# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (staking-monitor)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - This is a meta-package that ships bash scripts and config files
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:

SHELL := /bin/bash

.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Docker enforcement: Auto-invoke inside eoa-builder if not already there
# ----------------------------------------------------------------------
ifndef EOA_BUILDER

# Find project root (where Dockerfile lives)
PROJECT_ROOT := $(shell d=$$(pwd); while [ "$$d" != "/" ]; do [ -f "$$d/Dockerfile" ] && echo "$$d" && break; d=$$(dirname "$$d"); done)

RELATIVE_DIR := $(shell pwd | sed "s|^$(PROJECT_ROOT)/||")

DOCKER_IMAGE    := eoa-builder
DOCKER_PLATFORM := linux/arm64

.PHONY: all clean test release deb rpm prepare help

all clean test release deb rpm prepare help:
	@cd $(PROJECT_ROOT) && \
	if [ -z "$$(docker images -q $(DOCKER_IMAGE) 2>/dev/null)" ]; then \
		echo "🐳 Building Docker image $(DOCKER_IMAGE)..."; \
		docker build --platform $(DOCKER_PLATFORM) -t $(DOCKER_IMAGE) . ; \
	fi && \
	echo "🐳 Running build inside Docker container..." && \
	docker run --rm --platform $(DOCKER_PLATFORM) \
		-v "$(PROJECT_ROOT)":/workspace -w /workspace \
		$(DOCKER_IMAGE) \
		make -C "$(RELATIVE_DIR)" $@

else

# Running inside Docker container - proceed with actual build

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= staking-monitor
PKG_RELEASE     ?= 0
PKG_ARCH        ?= all
PKG_ARCH_RPM    ?= noarch
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= Telegram health monitoring and alerting for Ethereum staking \
infrastructure on ARM (Rock 5B, Orange Pi 5 Plus, NanoPC-T6). \
Includes obol-monitor for Obol DVT cluster monitoring and \
validator-monitor for standalone validator duty monitoring.
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= utils
WEB_URL         ?= https://github.com/EOA-Blockchain-Labs/ethereumonarm

SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Install/Remove Scripts
# ----------------------------------------------------------------------
PKG_AFTER_INSTALL ?= sources/extras/postinst
PKG_BEFPRE_REMOVE ?= sources/extras/prerm

# ----------------------------------------------------------------------
# Version
# ----------------------------------------------------------------------
PKG_VERSION ?= $(shell cat sources/VERSION 2>/dev/null || echo "1.0.0")

PKG_DEB := $(OUTPUTDIR)/$(PKG_NAME)_$(PKG_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM := $(OUTPUTDIR)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
	-s dir \
	-n $(PKG_NAME) \
	-v $(PKG_VERSION) \
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
	--before-remove $(PKG_BEFPRE_REMOVE) \
	--deb-no-default-config-files \
	--depends bash \
	--depends curl \
	--depends python3 \
	--depends jq

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
	-t rpm \
	--architecture $(PKG_ARCH_RPM) \
	--after-install $(PKG_AFTER_INSTALL) \
	--before-remove $(PKG_BEFPRE_REMOVE) \
	--depends bash \
	--depends curl \
	--depends python3 \
	--depends jq

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------
# all — default target for local builds
# ----------------------------------------------------------------------
all: prepare deb clean test ## Default local build pipeline

# ----------------------------------------------------------------------
# prepare — fix permissions on scripts
# ----------------------------------------------------------------------
prepare: ## Fix permissions on scripts and config files
	@echo "🌱 Preparing sources..."
	find $(SOURCESDIR)/usr/share/staking-monitor -name "*.sh" -exec chmod 755 {} \;
	find $(SOURCESDIR)/usr/share/staking-monitor -name "*.env.example" -exec chmod 644 {} \;
	find $(SOURCESDIR)/usr/share/staking-monitor -name "*-crontab" -exec chmod 644 {} \;
	find $(SOURCESDIR)/usr/share/staking-monitor -name "*.md" -exec chmod 644 {} \;
	chmod 755 $(SOURCESDIR)/extras/postinst
	chmod 755 $(SOURCESDIR)/extras/prerm
	@echo "🌱 Sources ready"

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
clean: ## No binaries to clean
	@echo "🧹 No binaries to clean for this package."

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
	echo "Version resolved: $(PKG_VERSION)"
	echo "Sources dir     : $(SOURCESDIR)"
	echo "Output dir      : $(OUTPUTDIR)"
	echo ""

# ======================================================================
# End of file
# ======================================================================

endif
