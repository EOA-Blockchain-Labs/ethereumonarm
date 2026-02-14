# 📦 Ethereum on ARM – Package Builder

[![Build System](https://img.shields.io/badge/Build-FPM-orange?logo=ruby&logoColor=white)](https://github.com/jordansissel/fpm)
[![Platform](https://img.shields.io/badge/Platform-ARM64-blue?logo=arm&logoColor=white)](https://www.arm.com/)
[![Active](https://img.shields.io/badge/Status-Active-success)](https://github.com/EOA-Blockchain-Labs/ethereumonarm)

This repository contains the Makefiles, helper scripts, and tooling used to build and package all Ethereum on ARM software into `.deb` packages for ARM64 boards and multi-arch Ubuntu systems.

The builder creates reproducible `.deb` packages for:

- 🔗 Ethereum execution and consensus clients
- 📊 Utilities and monitoring tools (Grafana, Prometheus, Node Exporter, etc.)
- ⚙️ EOA-specific utilities (EOA-GUI, systemd templates, helper scripts)

> [!NOTE]
> This project is correctly maintained and currently active.

---

## 📁 Project Structure

| Directory | Description |
| --------- | ----------- |
| `l1-clients` | Execution and Consensus layer clients (Geth, Nethermind, Prysm, Lighthouse, etc.) |
| `l2-clients` | Layer 2 solutions (Optimism, Arbitrum, Starknet, zkSync) |
| `infra` | Infrastructure and staking tools (MEV-Boost, SSV, Obol) |
| `web3` | IPFS, Swarm, and other Web3 protocols |
| `utils` | Monitoring and management utilities |
| `tools` | Additional staking tools (ethstaker-deposit, merge-config, stakewise-operator) |
| `build-scripts` | Makefile templates, `run_targets.sh` build runner, helper scripts, and documentation generators |

---

## 🛠️ Builder Features

This project isn't just a collection of scripts; it's a standardized build system using **FPM** (Effing Package Management).

- ✅ **Reproducible Builds**: Consistent package creation using Docker or controlled environments.
- 🔄 **Cross-Compilation**: Build ARM64 packages on Intel/AMD64 hosts transparently.
- ⚙️ **Systemd Integration**: Packages automatically install unit files and enable services.
- 💾 **Config Management**: "Merge-config" logic ensures user configurations are preserved during updates.

---

## 🚀 Quick Start (Docker)

**All builds run inside Docker automatically.** This ensures reproducible builds using the same toolchain as the official packages.

### 📋 Requirements

- [Docker](https://docs.docker.com/get-docker/)

### Build Packages

To build all packages:

```bash
make docker-run cmd="make all"
```

To build a specific package (e.g., Geth):

```bash
make docker-run cmd="make geth"
```

The Docker image will be automatically built on first use.

### Interactive Shell

If you need to debug or run multiple commands:

```bash
make docker-shell
```

---

## 📚 Detailed Documentation

For comprehensive guides, manual setup instructions, and verification details, please refer to our **[Official Documentation](https://ethereum-on-arm-documentation.readthedocs.io)**.

- **[Development Guide](../docs/contributing/building-images.rst)**: Detailed instructions on setting up the build environment manually and understanding the detailed build process.
- **[Adding a New Package](build-scripts/templates/HOWTO_ADD_PROJECT.md)**: Step-by-step guide to adding new software to the repository.
- **[Manual Verification](../docs/advanced/manual-verification.rst)**: A complete list of verified packages and instructions on how to verify binaries manually using PGP and SHA256.
- **[Troubleshooting](../docs/system/troubleshooting.rst)**: Common issues and solutions.

---

## 🤝 Contributing

We welcome contributions! Please check our **[Contributing Guidelines](../CONTRIBUTING.md)** for details on code style, pull requests, and more.

---

## 9️⃣ Related Resources

- **Ethereum on ARM Main Repo**:  
  <https://github.com/EOA-Blockchain-Labs/ethereumonarm>

- **Status Page** (package versions):  
  <https://github.com/EOA-Blockchain-Labs/ethereumonarm/blob/main/STATUS.md>
