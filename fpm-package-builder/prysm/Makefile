#install fpm
#apt-get install ruby ruby-dev rubygems build-essential rpm
#gem install --no-document fpm
SHELL := /bin/bash

#PRYSM_VERSION := $(shell curl -s "https://api.github.com/repos/prysmaticlabs/prysm/releases/latest" | jq -r '.tag_name' | tr -d "v")
#PRYSM_DHASH :=$(shell curl -s "https://api.github.com/repos/prysmaticlabs/prysm/tags" | jq -c 'map(select(.name | contains("$(PRYSM_VERSION)")))' | jq -r '.[0].commit.sha' | cut -c1-8)
PRYSM_VERSION := $(shell date +"%y%m%d")


PKG_RELEASE := 0
PKG_NAME := prysm-kintsugi

PKG_DESCRIPTION := "Ethereum 2.0 Prysmatic Labs Kintsugi implementation"
PKG_MAINTAINER := "diego losada <dlosada@ethereumonarm.com>"
CATEGORY := science
WEB_URL := https://github.com/prysmaticlabs/prysm

PKG_VENDOR := "Ethereum on ARM"
PKG_LICENSE := "GNU General Public License v3.0"

PKG_ARCH_DEB := arm64
PKG_ARCH_RPM := arm64

SOURCESDIR := sources/
OUTPUTDIR := ../packages

PKG_RPM := ${pkg_name}-${prysm_version}-${pkg_release}_${pkg_arch_rpm}.rpm
PKG_DEB := ${pkg_name}_${prysm_version}-${pkg_release}_${pkg_arch_deb}.deb

FPM_DEB_OPTS := -s dir -n $(PKG_NAME) -v $(PRYSM_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_DEB) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep\
	--deb-systemd extras/pry-geth-beacon.service\
	--deb-systemd extras/pry-geth-validator.service\
	--depends kintsugi-config\
	--provides prysm-beacon\
	--provides prysm-validator\

FPM_RPM_OPTS := -s dir -n $(PKG_NAME) -v $(PRYSM_VERSION) --license $(PKG_LICENSE) --vendor $(PKG_VENDOR)\
	--iteration $(PKG_RELEASE) -C $(SOURCESDIR) --maintainer $(PKG_MAINTAINER) --description $(PKG_DESCRIPTION)\
	-a $(PKG_ARCH_RPM) --category $(CATEGORY) --url $(WEB_URL) -p $(OUTPUTDIR) -x */.gitkeep

all: prepare deb clean

prepare: ## Donwload the latest binary and prepare the package files
	mkdir -p /tmp/prysm_tmp
	cd /tmp/prysm_tmp ; git clone -b kintsugi https://github.com/prysmaticlabs/prysm.git ; cd prysm ; bazel build //beacon-chain --config=linux_arm64_docker --workspace_status_command=hack/workspace_status.sh --stamp ; bazel build //validator --config=linux_arm64_docker --workspace_status_command=hack/workspace_status.sh --stamp
	cp /tmp/prysm_tmp/prysm/bazel-bin/cmd/beacon-chain/beacon-chain_/beacon-chain sources/usr/bin/beacon-chain-ks
	cp /tmp/prysm_tmp/prysm/bazel-bin/cmd/validator/validator_/validator sources/usr/bin/validator-ks
	rm -rf /tmp/prysm_tmp

deb: ## Create deb package
	fpm -t deb -p $(PKG_DEB) $(FPM_DEB_OPTS)

rpm: ## Create rpm package
	fpm -t rpm -p $(PKG_RPM) $(FPM_RPM_OPTS)

.PHONY: clean
clean: ## Clean up
	rm sources/usr/bin/*
