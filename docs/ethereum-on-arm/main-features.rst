.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Main Features
=============

The Ethereum on ARM images provide a "Plug & Play" experience, transforming simple ARM boards into fully functional Ethereum nodes. The core features include:

**Optimized System Foundation**

* **Base OS**: Built on **Ubuntu 24.04 LTS (Noble Numbat)** for ARM64, ensuring long-term stability and security.
* **Kernel Enhancements**: Custom configuration optimized specifically for Ethereum node performance and stability, superior to default Armbian or stock OS settings.
* **Storage Optimization**: Automatic NVMe disk partitioning and formatting, tuned for high-throughput I/O required by blockchain clients.
* **Memory Management**: Smart swap memory configuration to prevent OOM (Out of Memory) kills and ensure smooth operation under load.
* **Network & Security**:
    * Automatic network configuration.
    * pre-configured **UFW (Uncomplicated Firewall)** (disabled by default to allow custom user policies).

**Comprehensive Ethereum Stack**

The images come pre-loaded with a wide array of clients and tools, installed as systemd services for reliability:

* **Execution Clients**: Geth, Erigon, Besu, Nethermind, Reth, EthRex
* **Consensus Clients**: Lighthouse, Prysm, Nimbus, Teku, Lodestar, Grandine
* **Layer 2 Solutions**: Optimism, Arbitrum, Starknet (Juno), Gnosis, Fuel
* **Staking Infrastructure**:
    * **Obol Charon** & **Lido** for Distributed Validator Technology (DVT) and liquid staking.
    * **Web3Signer** and other key management tools.

**Integrated Tooling & Usability**

* **Package Management**: Dedicated APT repository (``repo.ethereumonarm.com``) for easy installation, updates, and maintenance of all Ethereum software.
* **Monitoring Stack**: Pre-configured **Grafana** and **Prometheus** dashboards to visualize node health, metrics, and performance instantly.
* **Staking Wizard**: Integrated tools (Ethereum Foundation deposit CLI and EthStakers tools) to guide users through the validator deposit and key generation process.

