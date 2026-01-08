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
- **Multiple client support**:
  - **Execution layer**: Geth, Erigon, Besu, Nethermind, Reth and EthRex.
  - **Consensus layer**: Prysm, Nimbus, Teku, Lodestar, Lighthouse and Grandine.
- **L2 support**: Compatible with Optimism, Arbitrum, Starknet, Fuel and EthRex L2.
- **Distributed Validator Technology (DVT)**: We support research and
  implementation for better decentralization like SSV and Obol.
- **Client diversity**: We actively promote the use of minority clients.
- **Testnet ready**: Full support for Sepolia, Hoodi, and Ephemery testnets.
- **Advanced monitoring**: Ready-to-use dashboards with Prometheus and Grafana
  for detailed tracking of your node's performance.
- **Optimized operating system**: Custom configurations on top of Armbian to
  ensure your node is stable and efficient.

## ⚙️ Supported devices

- NanoPC-T6
- Rock 5B
- Orange Pi 5 Plus
- Raspberry Pi 5

## 📂 Project Structure

This repository is organized into several key components:

- **[fpm-package-builder](fpm-package-builder/)**: Contains the tooling, Makefiles, and scripts used to build Debian (`.deb`) and RPM packages for all supported Ethereum clients and utilities. This is the core of our package distribution system.
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

## 💖 Acknowledgements

This project is possible thanks to the support and donations from our amazing
community. Thank you all!
