# Image Creation Tool

This directory contains tooling to build custom **Ethereum on ARM** images for various platforms.

## Overview

Ethereum on ARM provides pre-built images that turn ARM devices into full Ethereum nodes with a single flash. This directory contains the build infrastructure used to create those images.

## Image Types

| Directory | Platform | Description |
| --------- | -------- | ----------- |
| [`ubuntu/`](ubuntu/) | **ARM SBCs** | Builds images for single-board computers (Rock 5B, NanoPC T6, etc.) based on Armbian |
| [`cloud/`](cloud/) | **Cloud Providers** | Builds AMIs for AWS, GCP, and Azure using HashiCorp Packer |

## Quick Start

### Build SBC Images

```bash
cd ubuntu
make help                    # Show available options
make all                     # Build all device images
make build DEVICE=rock5b     # Build single device
```

See [`ubuntu/README.md`](ubuntu/README.md) for full documentation.

### Build Cloud Images

```bash
cd cloud
packer init aws.pkr.hcl      # Initialize Packer
packer build aws.pkr.hcl     # Build AWS AMI
```

See [`cloud/README.md`](cloud/README.md) for full documentation.

## Directory Structure

```text
image-creation-tool/
├── README.md                 # This file
├── ubuntu/                   # SBC image builder
│   ├── Makefile              # Build automation
│   └── sources/              # First-boot scripts and configs
│       ├── usr/local/bin/ethereum-first-boot
│       ├── etc/systemd/system/ethereum-first-boot.service
│       └── usr/local/sbin/check_install
└── cloud/                    # Cloud image builder
    ├── aws.pkr.hcl           # AWS Packer template
    ├── gcp.pkr.hcl           # GCP Packer template
    ├── azure.pkr.hcl         # Azure Packer template
    └── scripts/provision.sh  # Cloud provisioning script
```

## Related Resources

- [Ethereum on ARM Documentation](https://ethereum-on-arm-documentation.readthedocs.io/)
- [Package Builder](../fpm-package-builder/) — Builds `.deb` packages for Ethereum clients
