# Ethereum on ARM

[![Repository](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/EOA-Blockchain-Labs/ethereumonarm)
[![Release](https://img.shields.io/github/v/release/EOA-Blockchain-Labs/ethereumonarm)](https://github.com/EOA-Blockchain-Labs/ethereumonarm/releases)
[![Docs](https://img.shields.io/badge/Docs-Read%20the%20Docs-3a7bd5?logo=readthedocs)](https://ethereum-on-arm-documentation.readthedocs.io)
[![Discord](https://img.shields.io/badge/Discord-Join%20Server-7289DA?logo=discord&logoColor=white)](https://discord.gg/ve2Z8fxz5N)
[![Twitter](https://img.shields.io/twitter/follow/EthereumOnARM?style=social)](https://x.com/EthereumOnARM)
[![Bluesky](https://img.shields.io/badge/Bluesky-Follow-0085FF?logo=bluesky&logoColor=white)](https://bsky.app/profile/ethereumonarm.bsky.social)
[![Farcaster](https://img.shields.io/badge/Farcaster-Follow-8A63D2?logo=farcaster&logoColor=white)](https://farcaster.xyz/ethereumonarm)
[![License](https://img.shields.io/github/license/EOA-Blockchain-Labs/ethereumonarm)](https://github.com/EOA-Blockchain-Labs/ethereumonarm/blob/main/LICENSE)
[![GitPOAP Badge](https://public-api.gitpoap.io/v1/repo/diglos/ethereumonarm/badge)](https://www.gitpoap.io/gh/diglos/ethereumonarm)

**Ethereum on ARM** is a project that makes it easy to run a full Ethereum node on
low-power ARM devices. We provide Plug-and-Play (PnP) Ubuntu/Armbian images for a
variety of ARM64 boards, allowing users to easily set up and maintain both
execution and consensus nodes.

Our main goal is to lower the barrier to entry so more people can participate in
the Ethereum network, either by running a full node or by staking from home.

## ✨ Main features

- **Graphical User Interface (EOA-gui)**: A console menu that simplifies the
  setup of L1/L2 nodes, for both full and archive nodes (currently in alpha).
- **Extensive Protocol Support**: Full support for L1 Consensus & Execution clients, Layer 2 networks, and DVT infrastructure.
- **Client diversity**: We actively promote the use of minority clients.
- **Testnet ready**: Full support for Sepolia, Holesky, and Ephemery testnets.
- **Advanced monitoring**: Ready-to-use dashboards with Prometheus and Grafana
  for detailed tracking of your node's performance.
- **Optimized operating system**: Custom configurations on top of Armbian to
  ensure your node is stable and efficient.

## 📦 Supported Software

We support a wide range of Ethereum software, all packaged as standard `.deb` files for easy management.

### Layer 1 Consensus

| Client | Repository |
| :--- | :--- |
| **Grandine** | [grandinetech/grandine](https://github.com/grandinetech/grandine) |
| **Lighthouse** | [sigp/lighthouse](https://github.com/sigp/lighthouse) |
| **Lodestar** | [ChainSafe/lodestar](https://github.com/ChainSafe/lodestar) |
| **Nimbus** | [status-im/nimbus-eth2](https://github.com/status-im/nimbus-eth2) |
| **Prysm** | [prysmaticlabs/prysm](https://github.com/prysmaticlabs/prysm) |
| **Teku** | [ConsenSys/teku](https://github.com/ConsenSys/teku) |

#### Light Clients

| Client | Repository |
| :--- | :--- |
| **Helios** | [a16z/helios](https://github.com/a16z/helios) |

### Layer 1 Execution

| Client | Repository |
| :--- | :--- |
| **Besu** | [hyperledger/besu](https://github.com/hyperledger/besu) |
| **Erigon** | [ledgerwatch/erigon](https://github.com/ledgerwatch/erigon) |
| **EthRex** | [lambdaclass/ethrex](https://github.com/lambdaclass/ethrex) |
| **Geth** | [ethereum/go-ethereum](https://github.com/ethereum/go-ethereum) |
| **Nethermind** | [NethermindEth/nethermind](https://github.com/NethermindEth/nethermind) |
| **Nimbus EL** | [status-im/nimbus-eth1](https://github.com/status-im/nimbus-eth1) |
| **Reth** | [paradigmxyz/reth](https://github.com/paradigmxyz/reth) |

### Layer 2

| Component | Repository |
| :--- | :--- |
| **Arbitrum Nitro** | [OffchainLabs/nitro](https://github.com/OffchainLabs/nitro) |
| **EthRex L2** | [lambdaclass/ethrex](https://github.com/lambdaclass/ethrex) |
| **Fuel Core** | [FuelLabs/fuel-core](https://github.com/FuelLabs/fuel-core) |
| **Linea Besu** | [Consensys/linea-monorepo](https://github.com/Consensys/linea-monorepo) |
| **Maru** | [Consensys/maru](https://github.com/Consensys/maru) |
| **Optimism** (Components) | [ethereum-optimism/optimism](https://github.com/ethereum-optimism/optimism) |
| **Optimism Cannon** | [ethereum-optimism/optimism](https://github.com/ethereum-optimism/optimism/tree/develop/cannon) |
| **Optimism Kona** | [ethereum-optimism/optimism](https://github.com/ethereum-optimism/optimism/tree/develop/kona) |
| **Optimism** (op-geth) | [ethereum-optimism/op-geth](https://github.com/ethereum-optimism/op-geth) |
| **Optimism** (op-reth) | [paradigmxyz/reth](https://github.com/paradigmxyz/reth) |
| **Starknet Juno** | [NethermindEth/juno](https://github.com/NethermindEth/juno) |
| **Starknet Madara** | [madara-alliance/madara](https://github.com/madara-alliance/madara) |
| **Starknet Pathfinder** | [eqlabs/pathfinder](https://github.com/eqlabs/pathfinder) |
| **zkSync Era** | [matter-labs/zksync-era](https://github.com/matter-labs/zksync-era) |

### Infrastructure & Tools

| Tool | Repository |
| :--- | :--- |
| **Commit-Boost** | [Commit-Boost/commit-boost-client](https://github.com/Commit-Boost/commit-boost-client) |
| **DVT Anchor** | [sigp/anchor](https://github.com/sigp/anchor) |
| **Obol Charon** | [ObolNetwork/charon](https://github.com/ObolNetwork/charon) |
| **SSV Node** | [ssvlabs/ssv](https://github.com/ssvlabs/ssv) |
| **MEV-Boost** | [flashbots/mev-boost](https://github.com/flashbots/mev-boost) |
| **Lido Liquid Staking** | [lido.fi](https://lido.fi) |
| **Vouch** | [attestantio/vouch](https://github.com/attestantio/vouch) |
| **Vero** | [serenita-org/vero](https://github.com/serenita-org/vero) |
| **Eth. Metrics Exporter** | [ethpandaops/ethereum-metrics-exporter](https://github.com/ethpandaops/ethereum-metrics-exporter) |
| **Val. Metrics Exporter** | [ethpandaops/ethereum-validator-metrics-exporter](https://github.com/ethpandaops/ethereum-validator-metrics-exporter) |
| **EthStaker Deposit CLI** | [eth-educators/ethstaker-deposit-cli](https://github.com/eth-educators/ethstaker-deposit-cli) |
| **StakeWise Operator** | [stakewise/v3-operator](https://github.com/stakewise/v3-operator) |

### Web3

| Application | Repository |
| :--- | :--- |
| **Swarm Bee** | [ethersphere/bee](https://github.com/ethersphere/bee) |
| **IPFS Kubo** | [ipfs/kubo](https://github.com/ipfs/kubo) |
| **Status-Go** | [status-im/status-go](https://github.com/status-im/status-go) |

## ⚙️ Supported devices

- NanoPC-T6
- Rock 5B
- Rock 5T (Rock 5 ITX)
- Orange Pi 5 Plus
- Raspberry Pi 5

## 📂 Project Structure

This repository is organized into several key components:

- **[fpm-package-builder](fpm-package-builder/)**: Contains the tooling, Makefiles, and scripts used to build Debian (`.deb`) and RPM packages for all supported Ethereum clients and utilities. This system uses a **Docker-based workflow** to ensure reproducible builds across different environments.
- **[image-creation-tool](image-creation-tool/)**: Scripts and configurations for generating the custom Ubuntu and Armbian images that come pre-configured with our optimizations.
- **[docs](docs/)**: Source files for our official documentation.

## 📦 Package status

For a detailed list of all supported packages and their current status, please
see our **[Status Page](STATUS.md)**.

## 🚀 Installation

### Using our Images (Recommended)

To get started quickly, we recommend using our pre-built images. Please follow our
**[step-by-step installation guide](https://ethereum-on-arm-documentation.readthedocs.io)**.

### Building from Source

If you prefer to build packages yourself or contribute to the project, check out the **[Package Builder README](fpm-package-builder/README.md)** for detailed instructions on setting up a build environment.

## 🤝 Community and support

- **Discord**: Join our **[Discord channel](https://discord.gg/ve2Z8fxz5N)** to
  get help, discuss ideas, or chat with other community members.
- **X/Twitter**: Follow us on **[@EthereumOnARM](https://x.com/EthereumOnARM)**
  to stay updated with the latest news.

## 🔒 Security Standards

Security is our top priority. All software packages in this repository are:

1. **Verified**: Every binary is verified against its upstream SHA256 checksum or GPG signature before being packaged.
2. **Isolated**: Software runs with dedicated user permissions, never as root (unless strictly required by the OS).
3. **Auditable**: Our build system (`fpm-package-builder`) is open source, allowing anyone to verify exactly how packages are constructed.

## 💖 Acknowledgements

This project is possible thanks to the support and donations from our amazing
community. Thank you all!
