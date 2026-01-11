.. _architecture:

======================
Project Architecture
======================

This page provides an overview of the Ethereum on ARM project architecture, including the 
build system, package distribution, and supported platforms.

High-Level Overview
===================

The Ethereum on ARM project consists of three main components:

1. **Package Builder** (``fpm-package-builder/``) - Creates .deb packages for Ethereum clients
2. **Image Creation Tool** (``image-creation-tool/``) - Builds ready-to-use OS images for ARM devices
3. **APT Repository** (``repo.ethereumonarm.com``) - Hosts the built packages for distribution

.. code-block:: text

   ┌─────────────────────────────────────────────────────────────────────────────┐
   │                        Ethereum on ARM Architecture                         │
   └─────────────────────────────────────────────────────────────────────────────┘
   
   ┌─────────────────────────────┐     ┌──────────────────────────────────────┐
   │   SOURCE CODE / BINARIES    │     │         IMAGE CREATION TOOL          │
   │  ─────────────────────────  │     │  ──────────────────────────────────  │
   │  • Ethereum L1 clients      │     │  Ubuntu Images:                      │
   │  • Ethereum L2 clients      │     │  • Raspberry Pi 5                    │
   │  • Infrastructure tools     │     │  • Rock 5B / 5T                      │
   │  • Web3 applications        │     │  • Orange Pi 5 Plus                  │
   └──────────────┬──────────────┘     │  • NanoPC-T6                         │
                  │                    │  ──────────────────────────────────  │
                  ▼                    │  Cloud Images (Packer):              │
   ┌─────────────────────────────┐     │  • AWS AMI                           │
   │     FPM PACKAGE BUILDER     │     │  • Google Cloud                      │
   │  ─────────────────────────  │     │  • Microsoft Azure                   │
   │  Build Pipeline:            │     └─────────────────┬────────────────────┘
   │  1. Download binaries       │                       │
   │  2. Verify GPG signatures   │                       ▼
   │  3. Stage files             │     ┌──────────────────────────────────────┐
   │  4. Package with FPM        │     │       DISTRIBUTION CHANNELS          │
   │  5. Test & validate         │     │  ──────────────────────────────────  │
   └──────────────┬──────────────┘     │  • Ready-to-flash SBC images         │
                  │                    │  • Cloud marketplace images          │
                  ▼                    │  • Direct image downloads            │
   ┌─────────────────────────────┐     └──────────────────────────────────────┘
   │      APT REPOSITORY         │
   │  ─────────────────────────  │
   │  repo.ethereumonarm.com     │
   │  ─────────────────────────  │
   │  Packages:                  │
   │  • Execution Layer clients  │
   │  • Consensus Layer clients  │
   │  • L2 clients (OP, Arb...)  │
   │  • DVT (Obol, SSV)          │
   │  • MEV-boost, monitoring    │
   └──────────────┬──────────────┘
                  │
                  ▼
   ┌─────────────────────────────────────────────────────────────────────────────┐
   │                            END USER DEVICES                                 │
   │  ─────────────────────────────────────────────────────────────────────────  │
   │                                                                             │
   │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
   │  │  Raspberry   │  │   Rockchip   │  │  Cloud VMs   │  │   Orange Pi  │     │
   │  │    Pi 5      │  │    Rock 5    │  │  (ARM-based) │  │    5 Plus    │     │
   │  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘     │
   │                                                                             │
   └─────────────────────────────────────────────────────────────────────────────┘


Package Builder Structure
=========================

The ``fpm-package-builder/`` directory is organized by client category:

.. code-block:: text

   fpm-package-builder/
   ├── l1-clients/
   │   ├── execution-layer/     # Geth, Besu, Reth, Erigon, Nethermind, Ethrex
   │   └── consensus-layer/     # Lighthouse, Prysm, Teku, Nimbus, Lodestar, Grandine
   ├── l2-clients/
   │   ├── optimism-base/       # OP-Geth, OP-Node, OP-Reth, OP-Challenger
   │   ├── arbitrum/            # Nitro
   │   ├── starknet/            # Juno, Madara, Pathfinder
   │   └── ...
   ├── infra/
   │   ├── dvt/                 # Obol Charon, SSV Network
   │   └── mev-boost/           # MEV-Boost for all networks
   ├── utils/                   # Monitoring exporters, config sync tools
   ├── tools/                   # Staking deposit CLI, liquid staking
   ├── web3/                    # Swarm Bee, IPFS Kubo
   └── build-scripts/           # Version checking, documentation sync


Build Process Flow
==================

Each package follows a consistent build pipeline:

1. **Version Resolution**: Query GitHub API for latest release
2. **Download**: Fetch pre-built binaries (or build from source for Rust/Go)
3. **Signature Verification**: Validate GPG signatures where available
4. **Staging**: Copy binaries, configs, and systemd units to staging directory
5. **Packaging**: Create .deb package using FPM with proper metadata
6. **Testing**: Verify package was created successfully


Configuration Management
========================

Packages use a consistent configuration approach:

- **Configuration files**: ``/etc/ethereum/<service>.conf``
- **Systemd units**: Use ``EnvironmentFile`` to source configuration
- **Data directories**: ``/home/ethereum/.<client>``
- **JWT secrets**: ``/etc/ethereum/jwtsecret``

Example systemd service pattern:

.. code-block:: ini

   [Unit]
   Description=Geth Execution Layer Client
   After=network-online.target
   Wants=network-online.target

   [Service]
   EnvironmentFile=/etc/ethereum/geth.conf
   ExecStart=/usr/bin/geth $ARGS
   Restart=on-failure
   User=ethereum

   [Install]
   WantedBy=multi-user.target


See Also
========

- :ref:`getting-started` - Quick start guide for new users
- :ref:`supported-hardware` - List of supported ARM devices
- :ref:`contributing-sources` - How to build from source
