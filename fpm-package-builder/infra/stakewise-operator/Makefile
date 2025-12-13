# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (StakeWise V3 Operator)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Downloads StakeWise V3 Operator binary from GitHub
# - Stages files into ./sources/usr/local/bin
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= stakewise-operator
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= StakeWise V3 Operator is a tool for managing StakeWise V3 validators.
PKG_MAINTAINER  ?= Fernando <fernando@ethereumonarm.com>
CATEGORY        ?= net
WEB_URL         ?= https://github.com/stakewise/v3-operator
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the tag with "v" (e.g., v4.0.17) for the download URL
STAKEWISE_TAG := $(shell curl -sL "https://api.github.com/repos/stakewise/v3-operator/releases/latest" | jq -r '.tag_name')
# Get the version without "v" (e.g., 4.0.17) for the package version
STAKEWISE_VERSION := $(shell echo "$(STAKEWISE_TAG)" | tr -d "v")

# Ensure we are building for arm64
ifneq ($(PKG_ARCH),arm64)
    $(error This package only supports arm64 architecture)
endif

# Using Ubuntu 22.04 ARM64 binary as baseline
STAKEWISE_TARBALL := operator-$(STAKEWISE_TAG)-ubuntu-22.04-arm64.tar.gz
STAKEWISE_URL     := https://github.com/stakewise/v3-operator/releases/download/$(STAKEWISE_TAG)/$(STAKEWISE_TARBALL)

# SHA256 checksum extracted from GitHub API asset digest field
STAKEWISE_RELEASE_JSON := $(shell curl -sL "https://api.github.com/repos/stakewise/v3-operator/releases/latest")
STAKEWISE_SHA256 := $(shell echo '$(STAKEWISE_RELEASE_JSON)' | jq -r '.assets[] | select(.name == "$(STAKEWISE_TARBALL)") | .digest' | sed 's/sha256://')

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(STAKEWISE_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(STAKEWISE_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
    -s dir \
    -n $(PKG_NAME) \
    -v $(STAKEWISE_VERSION) \
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
    $(shell test -d extras && find extras -name 'stakewise-operator.service' -printf "--deb-systemd %p ") \
    $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true)

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
    -t rpm \
    --architecture $(PKG_ARCH_RPM) \
    $(shell test -d extras && find extras -name 'stakewise-operator.service' -printf "--rpm-systemd %p ")

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

all: prepare deb clean test

prepare:
	@echo "🔽 Downloading StakeWise Operator $(STAKEWISE_VERSION)..."
	mkdir -p .build $(SOURCESDIR)/usr/local/bin
	wget -q -O ".build/$(STAKEWISE_TARBALL)" "$(STAKEWISE_URL)" || { echo "❌ Download failed: $(STAKEWISE_URL)"; exit 1; };
	@echo "🔐 Verifying SHA256..."
	@echo "$(STAKEWISE_SHA256)  .build/$(STAKEWISE_TARBALL)" | sha256sum -c - || { echo "❌ SHA256 verification FAILED!"; rm -f ".build/$(STAKEWISE_TARBALL)"; exit 1; };
	@echo "📦 Extracting binary..."
	tar -xzf ".build/$(STAKEWISE_TARBALL)" -C .build/
	# The tarball contains a binary named 'operator' - rename to stakewise-operator
	if [[ -f ".build/operator" ]]; then \
		mv .build/operator $(SOURCESDIR)/usr/local/bin/stakewise-operator; \
	else \
		echo "⚠️ 'operator' binary not found in tarball root, checking subdirs..."; \
		find .build -name operator -exec mv {} $(SOURCESDIR)/usr/local/bin/stakewise-operator \;; \
	fi
	chmod 0755 "$(SOURCESDIR)/usr/local/bin/stakewise-operator"
	@echo "✅ Binary downloaded and verified"

deb: prepare
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building DEB package..."
	fpm $(FPM_DEB_OPTS) -p "$(PKG_DEB)" .

rpm: prepare
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building RPM package..."
	fpm $(FPM_RPM_OPTS) -p "$(PKG_RPM)" .

clean:
	rm -rf .build
	rm -f $(SOURCESDIR)/usr/local/bin/$(PKG_NAME)
	# Do not remove sources/etc as it contains static config

test:
	if [[ -f "$(PKG_DEB)" ]]; then echo "✅ .deb exists"; else echo "❌ .deb missing"; exit 1; fi

release: clean prepare deb rpm test
