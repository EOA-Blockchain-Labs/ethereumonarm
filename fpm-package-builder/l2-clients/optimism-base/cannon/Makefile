# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (cannon)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - Clones and builds the 'cannon' binary from source
# - Stages files into ./sources/usr/bin
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
DOCKER_IMAGE := eoa-builder
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
PKG_NAME        ?= optimism-cannon
PKG_RELEASE     ?= 0
PKG_ARCH        ?= arm64
PKG_ARCH_RPM    ?= aarch64
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= MIT
PKG_DESCRIPTION ?= Cannon Fault Proof Virtual Machine for Optimism
PKG_MAINTAINER  ?= Ethereum on ARM <info@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/ethereum-optimism/optimism/tree/develop/cannon
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../../packages

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
# Get the full tag (e.g., op-challenger/v1.0.0) from the latest release
# Note: Cannon is released alongside op-challenger, so we use the op-challenger tag
CANNON_TAG := $(shell curl -s "https://api.github.com/repos/ethereum-optimism/optimism/releases" | jq -r '[.[] | select(.tag_name | startswith("op-challenger/"))] | sort_by(.published_at) | .[-1].tag_name')

# Get the version number (e.g., 1.0.0) by stripping the prefix
CANNON_VERSION := $(patsubst op-challenger/v%,%,$(CANNON_TAG))

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(CANNON_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(CANNON_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

# ----------------------------------------------------------------------
# FPM common options
# ----------------------------------------------------------------------
FPM_COMMON_OPTS = \
	-s dir \
	-n $(PKG_NAME) \
	-v $(CANNON_VERSION) \
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
	@echo "🔎 Resolving latest cannon version..."
	if [[ -z "$(CANNON_TAG)" || "$(CANNON_TAG)" == "null" ]]; then \
		echo "❌ Could not determine latest cannon version via GitHub API."; exit 1; \
	fi
	@echo "🔽 Cloning optimism monorepo at tag $(CANNON_TAG)..."
	mkdir -p .build/cannon_src $(SOURCESDIR)/usr/bin
	git clone --depth 1 --branch $(CANNON_TAG) https://github.com/ethereum-optimism/optimism.git .build/cannon_src || { echo "❌ Git clone failed"; exit 1; }
	
	@echo "🛠 Building cannon binary from source..."
	cd .build/cannon_src/cannon && \
		env GO111MODULE=on CGO_ENABLED=1 GOOS=linux CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOARCH=arm64 \
		go build -v -o ./build/bin/cannon . \
		|| { echo "❌ Go build failed"; exit 1; }
	
	@echo "📂 Staging binary..."
	cp .build/cannon_src/cannon/build/bin/cannon $(SOURCESDIR)/usr/bin/cannon
	chmod 0755 $(SOURCESDIR)/usr/bin/cannon
	@echo "✅ Binary ready at $(SOURCESDIR)/usr/bin/cannon"

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
	rm -rf $(SOURCESDIR)/usr/bin/cannon* .build
	@echo "🧹 Clean complete."

test:
	if [[ -f "$(PKG_DEB)" ]]; then echo "🧪 Test: .deb exists — OK ✅"; else echo "🧪 Test: .deb missing — ❌"; exit 1; fi

release: clean prepare deb rpm test
	@echo "🎉 All packages built successfully"
# ======================================================================
# End of file
# ======================================================================
endif
