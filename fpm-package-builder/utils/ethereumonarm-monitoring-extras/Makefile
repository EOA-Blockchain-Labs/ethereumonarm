# ======================================================================
# Ethereum on ARM — Production Packaging Makefile (Monitoring Extras)
# ----------------------------------------------------------------------
# Builds .deb and .rpm packages for ARM systems using FPM.
# - This is a meta-package that ships monitoring config files
# - Applies EOA packaging standards and metadata
# ======================================================================

.SILENT:
SHELL := /bin/bash
.DEFAULT_GOAL := all

# ----------------------------------------------------------------------
# Package metadata
# ----------------------------------------------------------------------
PKG_NAME        ?= ethereumonarm-monitoring-extras
PKG_RELEASE     ?= 0
PKG_ARCH        ?= all
PKG_ARCH_RPM    ?= noarch
PKG_VENDOR      ?= Ethereum on ARM
PKG_LICENSE     ?= GNU General Public License v3.0
PKG_DESCRIPTION ?= Ethereum on ARM monitoring config
PKG_MAINTAINER  ?= Fernando Collado <fcollado@ethereumonarm.com>
CATEGORY        ?= science
WEB_URL         ?= https://github.com/EOA-Blockchain-Labs/ethereumonarm
SOURCESDIR      ?= sources
OUTPUTDIR       ?= ../../packages

# ----------------------------------------------------------------------
# Install/Remove Scripts
# ----------------------------------------------------------------------
PKG_AFTER_INSTALL ?= extras/postinst

# ----------------------------------------------------------------------
# Upstream version and source info
# ----------------------------------------------------------------------
PKG_VERSION ?= 1.2.7

PKG_DEB      := $(OUTPUTDIR)/$(PKG_NAME)_$(PKG_VERSION)-$(PKG_RELEASE)_$(PKG_ARCH).deb
PKG_RPM      := $(OUTPUTDIR)/$(PKG_NAME)-$(PKG_VERSION)-$(PKG_RELEASE).$(PKG_ARCH_RPM).rpm

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
  --deb-no-default-config-files \
  $(shell test -d $(SOURCESDIR)/etc && find $(SOURCESDIR)/etc -type f -printf "--config-files /etc/%P " || true) \
  --depends grafana \
  --depends prometheus \
  --depends prometheus-node-exporter \
  --depends ufw \
  --depends ethereum-metrics-exporter \
  --depends merge-config

# ----------------------------------------------------------------------
# RPM-specific options
# ----------------------------------------------------------------------
FPM_RPM_OPTS = $(FPM_COMMON_OPTS) \
  -t rpm \
  --architecture $(PKG_ARCH_RPM) \
  --after-install $(PKG_AFTER_INSTALL) \
  --depends grafana \
  --depends prometheus \
  --depends prometheus-node-exporter \
  --depends ufw \
  --depends ethereum-metrics-exporter \
  --depends merge-config

# ----------------------------------------------------------------------
# Targets
# ----------------------------------------------------------------------
.PHONY: all prepare deb rpm clean test release help

# ----------------------------------------------------------------------