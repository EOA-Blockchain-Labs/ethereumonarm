# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (op-program)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Clones and builds the 'op-program' binary from source
# - Stages files into ./sources/usr/bin
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= optimism-op-program
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= Op-program Fault Proof Program for Optimism
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ethereum-optimism/optimism/tree/develop/op-program
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the full tag (e.g., op-challenger/v1.0.0) from the latest release
# Note: op-program is released alongside op-challenger, so we use the op-challenger tag
OP_PROGRAM_TAG := $(shell curl -s "https://api.github.com/repos/ethereum-optimism/optimism/releases" | jq -r '[.[] | select(.tag_name | startswith("op-challenger/"))] | sort_by(.published_at) | .[-1].tag_name')

# Get the version number (e.g., 1.0.0) by stripping the prefix
OP_PROGRAM_VERSION := $(patsubst op-challenger/v%,%,$(OP_PROGRAM_TAG))

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(OP_PROGRAM_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(OP_PROGRAM_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
	-s dir \
	-n $(PKG_NAME) \
	-v $(OP_PROGRAM_VERSION) \
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
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

all: prepare deb clean test

prepare:
	@echo "🔎 Resolving latest op-program version..."
	if [[ -z "$(OP_PROGRAM_TAG)" || "$(OP_PROGRAM_TAG)" == "null" ]]; then \
		echo "❌ Could not determine latest op-program version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Cloning optimism monorepo at tag $(OP_PROGRAM_TAG)..."
	mkdir -p .build/op-program_src $(SOURCESDIR)/usr/bin
	git clone --depth 1 --branch $(OP_PROGRAM_TAG) https://github.com/ethereum-optimism/optimism.git .build/op-program_src || { echo "❌ Git clone failed"; exit 1; }
	
	@echo "🛠 Building op-program binary from source..."
	cd .build/op-program_src/op-program && \
		env GO111MODULE=on CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 \
		go build -v -o ./build/bin/op-program ./host/cmd/main.go \
		|| { echo "❌ Go build failed"; exit 1; }
	
	@echo "📂 Staging binary..."
	cp .build/op-program_src/op-program/build/bin/op-program $(SOURCESDIR)/usr/bin/op-program
	chmod 0755 $(SOURCESDIR)/usr/bin/op-program
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/op-program"

deb: prepare
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building DEB package..."
	fpm $(FPM_COMMON_OPTS) -t deb --architecture $(PKG_ARCH) -p "$(PKG_DEB)" .
	if [[ -f "$(PKG_DEB)" ]]; then echo "✅ DEB package created"; else echo "❌ Failed"; exit 1; fi

rpm: prepare
	mkdir -p $(OUTPUTDIR)
	@echo "📦 Building RPM package..."
	fpm $(FPM_COMMON_OPTS) -t rpm --architecture $(PKG_ARCH_RPM) -p "$(PKG_RPM)" .
	if [[ -f "$(PKG_RPM)" ]]; then echo "✅ RPM package created"; else echo "❌ Failed"; exit 1; fi

clean:
	rm -rf $(SOURCESDIR)/usr/bin/op-program* .build
	@echo "🧹 Clean complete."

test:
	if [[ -f "$(PKG_DEB)" ]]; then echo "🧪 Test: .deb exists — OK ✅"; else echo "🧪 Test: .deb missing — ❌"; exit 1; fi

release: clean prepare deb rpm test
	@echo "🎉 All packages built successfully"
