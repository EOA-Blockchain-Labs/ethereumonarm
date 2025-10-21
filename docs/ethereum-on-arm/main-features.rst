.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Main Features
=============

These are the main features of Ethereum on ARM images:

* Based on Ubuntu 24.04 for ARM64.
* Automatic configuration for essential settings like network, user accounts, etc.
* Automatic NVMe disk partitioning and formatting capabilities, optimized for high-performance storage.
* Manages and configures swap memory to help avoid memory-related problems.
* Pre-configured support for a wide range of Ethereum clients and related technologies, including:

  * **Execution Layer Clients**: Geth, Erigon, Besu, Nethermind, Reth, EthRex
  * **Consensus Layer Clients**: Lighthouse, Prysm, Nimbus, Teku, Lodestar, Grandine
  * **L2 Solutions**: Optimism, Arbitrum, Starknet (Juno), Gnosis, Fuel
  * **Staking & DVT**: Lido and Obol

* Includes an APT repository (``repo.ethereumonarm.com``) for installing and upgrading Ethereum software.
* Includes the Ethereum Foundation's and EthStakers tool to assist in starting the staking process.
* Includes pre-configured monitoring dashboards based on Grafana and Prometheus.
* Includes UFW (Uncomplicated Firewall) configuration, which is available but not enabled by default, allowing users to customize their security settings.
* Optimized operating system configurations over default Armbian settings, specifically for Ethereum node performance and stability.

