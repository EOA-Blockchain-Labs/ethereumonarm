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
| `build-scripts` | Makefile templates, helper scripts, and documentation generators |

---

## 🛠️ Builder Features

This project isn't just a collection of scripts; it's a standardized build system using **FPM** (Effing Package Management).

- ✅ **Reproducible Builds**: Consistent package creation using Docker or controlled environments.
- 🔄 **Cross-Compilation**: Build ARM64 packages on Intel/AMD64 hosts transparently.
- ⚙️ **Systemd Integration**: Packages automatically install unit files and enable services.
- 💾 **Config Management**: "Merge-config" logic ensures user configurations are preserved during updates.

---

## 1️⃣ Recommended: Use the Provided Vagrantfile

The **only supported way** to create a fully configured build environment is to use the included Vagrantfile.
It automatically sets up an Ubuntu 24.04 virtual machine with all required dependencies, cross-compilers for ARM64, and toolchains correctly configured.

> [!IMPORTANT]
> The Makefiles in this project are optimized for this Vagrant environment (Linux/Ubuntu 24.04).
> Building directly on macOS or other systems is **not supported** and will likely fail due to missing cross-compilation tools or incorrect LLVM paths.

### 📋 Requirements

- [Vagrant](https://www.vagrantup.com/docs/installation)  
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### 🚀 Steps

```bash
git clone https://github.com/EOA-Blockchain-Labs/ethereumonarm.git
cd ethereumonarm/fpm-package-builder
vagrant up
vagrant ssh
cd ethereumonarm/
```

The VM comes with:

- ✅ All dependencies and cross-compilers installed  
- 🐳 Docker configured for the `vagrant` user  
- 🦀 Rust, Go, and Node environments ready to use  
- 🔧 LLVM 19 and MLIR for Starknet client builds

Once inside the VM, you can immediately build packages (see section 3).

---

## 2️⃣ Manual Setup (Ubuntu 24.04 LTS)

> [!WARNING]
> **Advanced Linux Users Only**: Use this method only if you cannot use Vagrant (e.g., inside a CI pipeline).
> These steps replicate the `provision.sh` environment on a fresh Ubuntu 24.04 machine.
> **Building explicitly on macOS is NOT supported.**

### 2.1 Prepare apt repositories

```bash
echo "# See /etc/apt/sources.list.d/ for repository configuration" | sudo tee /etc/apt/sources.list
sudo rm -f /etc/apt/sources.list.d/ubuntu.sources

UBUNTU_CODENAME=$(lsb_release -cs)

sudo tee /etc/apt/sources.list.d/ubuntu-amd64.sources > /dev/null <<EOF
Types: deb
URIs: http://us.archive.ubuntu.com/ubuntu
Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security ${UBUNTU_CODENAME}-backports
Components: main restricted universe multiverse
Architectures: amd64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

sudo tee /etc/apt/sources.list.d/ubuntu-arm64.sources > /dev/null <<EOF
Types: deb
URIs: http://ports.ubuntu.com
Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security ${UBUNTU_CODENAME}-backports
Components: main restricted universe multiverse
Architectures: arm64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

sudo dpkg --add-architecture arm64
echo 'Acquire::http::Pipeline-Depth "0";' | sudo tee /etc/apt/apt.conf.d/90localsettings
sudo apt-get update -y
```

### 2.2 Install dependencies

```bash
sudo apt-get install -y \
  libssl-dev:arm64 pkg-config software-properties-common docker.io docker-compose \
  clang file make cmake gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  ruby ruby-dev rubygems build-essential rpm vim git jq curl wget python3-pip \
  ca-certificates gnupg

sudo gem install --no-document fpm
```

#### Install LLVM 19 (Required for Starknet Madara)

```bash
wget -qO- https://apt.llvm.org/llvm.sh | sudo bash -s -- 19
sudo apt-get install -y libmlir-19-dev mlir-19-tools clang-19 llvm-19-dev \
  libpolly-19-dev libzstd-dev libxml2-dev protobuf-compiler libudev-dev \
  python3-full python3-pip python3-venv
```

#### Install Go

```bash
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt-get update -y
sudo apt-get install -y golang-go
```

#### Docker permissions

```bash
sudo usermod -aG docker $USER
newgrp docker
```

#### Install Rust

```bash
curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustup target add aarch64-unknown-linux-gnu

mkdir -p "$HOME/.cargo"
cat <<EOF > "$HOME/.cargo/config"
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
EOF
```

#### Install Node.js, Yarn, PNPM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"

nvm install 24
npm install -g yarn
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

---

## 3️⃣ Building Packages

### Build all `.deb` packages

```bash
make
```

### Build a specific package

```bash
cd l1-clients/execution-layer/geth
make
```

Each subdirectory includes a Makefile defining:

- `VERSION` (package version)
- `SOURCE_URL` (GitHub source repository)
- Build and packaging rules

Resulting `.deb` files are placed in a central `packages` directory, relative to the component directory (e.g., `../../packages` as defined in the `Makefile_template`).

---

## 4️⃣ Verifying Builds

```bash
ls -l ../../packages/*.deb
dpkg-deb -I ../../packages/geth_*.deb | grep Version
```

To install locally for testing (adjust path):

```bash
sudo apt install ../../packages/geth_<version>_arm64.deb
```

---

## 5️⃣ Binary Verification Status

All packages with binary downloads are verified cryptographically before packaging.

### ✅ Verified Packages

| Package | Type | Verification | Source |
| --------- | ------ | -------------- | -------- |
| **Prysm** | L1 Consensus | PGP | Key `F1A5036E` from keyserver.ubuntu.com |
| **Lighthouse** | L1 Consensus | PGP | Key `F30674B0` from keyserver.ubuntu.com |
| **Grandine** | L1 Consensus | SHA256 | GitHub API digest |
| **Teku** | L1 Consensus | SHA256 | Release changelog |
| **Lodestar** | L1 Consensus | SHA256 | GitHub API digest |
| **Nimbus** | L1 Consensus | SHA256 | GitHub API digest |
| **Geth** | L1 Execution | PGP | Key `9BA28146` from geth.ethereum.org |
| **Reth** | L1 Execution | PGP | Key `7FBF253E` from keyserver.ubuntu.com |
| **Erigon** | L1 Execution | SHA256 | GitHub API digest |
| **Besu** | L1 Execution | SHA256 | Release changelog |
| **Nethermind** | L1 Execution | SHA256 | GitHub API digest |
| **Ethrex** | L1 Execution | SHA256 | GitHub API digest |
| **Nimbus-EC** | L1 Execution | SHA256 | GitHub API digest (2 tarballs) |
| **MEV-Boost** | Infra | SHA256 | GitHub API digest |
| **Vouch** | Infra | SHA256 | GitHub API digest |
| **DVT-Obol** | Infra | SHA256 | GitHub API digest |
| **Commit-Boost** | Infra | SHA256 | GitHub API digest |
| **ethstaker-deposit-cli** | Infra | SHA256 | Downloaded .sha256 file |
| **StakeWise Operator** | Infra | SHA256 | GitHub API digest |
| **Fuel Network** | L2 | SHA256 | GitHub API digest |
| **Starknet Juno** | L2 | SHA256 | GitHub API digest |
| **Kubo (IPFS)** | Web3 | SHA256 | GitHub API digest |
| **Swarm Bee** | Web3 | SHA256 | GitHub API digest |
| **ethereum-metrics-exporter** | Utils | SHA256 | GitHub API digest |
| **Starknet Pathfinder** | L2 | SHA256 | GitHub API digest |
| **Linea Besu** | L2 | SHA256 | GitHub API digest |
| **Maru** | L2 | SHA256 | GitHub API digest |
| **Anchor** | Infra | SHA256 | GitHub API digest |

### ⏳ Pending Verification

| Package | Type | Notes |
| --------- | ------ | ------- |
| DVT-SSV | Infra | No release assets |
| Vero | Infra | Source tarball (immutable releases, no checksum) |
| Arbitrum Nitro | L2 | No release assets |
| Optimism (op-geth, op-node) | L2 | No release assets |
| Starknet Madara | L2 | No release assets |
| ethereum-validator-metrics-exporter | Utils | Has checksums.txt (could parse) |

### ⚠️ Deprecated (moved to `infra/deprecated/`)

| Package | Notes |
| ------- | ----- |
| staking-deposit-cli | Upstream deprecated, use ethstaker-deposit-cli instead |

---

## 6️⃣ Adding a New Package

1. Create a new directory under `fpm-package-builder/` (e.g., `utils/new-tool/`)
2. Copy the template Makefile:

   ```bash
   cp ../../build-scripts/templates/Makefile .
   ```

   (Or copy from `fpm-package-builder/build-scripts/templates/Makefile` if you are elsewhere)
3. Update all `CHANGEME` variables in the new `Makefile`, paying close attention to:
   - `PKG_NAME`
   - `PKG_DESCRIPTION`
   - `PKG_MAINTAINER`
   - `WEB_URL`
   - The entire "Upstream version and source info" section (this is the most critical part).
   - `OUTPUTDIR` (adjust the path depth, e.g., `../../packages` or `../../../packages`).
4. (Optional) If you need a systemd service or config file, copy them from `build-scripts/templates/`:

   ```bash
   cp ../../build-scripts/templates/service.service extras/package-name.service
   cp ../../build-scripts/templates/config.toml sources/etc/package-name/config.toml
   ```

5. Run `make` inside the directory to build and test.
6. Test on an ARM board (e.g., Rock 5B, Orange Pi 5 Plus).

---

## 7️⃣ Troubleshooting

| Problem | Cause | Solution |
| ------- | ----- | -------- |
| `apt-get update` fails for ARM64 | Wrong codename or URI | Verify `UBUNTU_CODENAME` and repo URLs |
| Rust linker errors | Missing cross-compiler | Ensure `aarch64-linux-gnu-gcc` is installed |
| `nvm` not found | Path not sourced | `export NVM_DIR="$HOME/.nvm" && [ -s ... ] && . "$NVM_DIR/nvm.sh"` |
| Docker permission denied | User not in group | `sudo usermod -aG docker $USER && newgrp docker` |
| `fpm` not found | Ruby PATH issue | `sudo gem install fpm` or export Ruby bin path |
| LLVM/Madara compilation errors | Missing LLVM 19 | Install LLVM 19: `wget -qO- https://apt.llvm.org/llvm.sh \| sudo bash -s -- 19` |

---

## 8️⃣ Contributing

We welcome contributions! You can help by:

- 🆕 Adding new clients or utilities
- 🔄 Updating package versions
- 📝 Improving documentation or Makefiles

Join our Discord to collaborate:  
<https://discord.gg/ve2Z8fxz5N>

---

## 9️⃣ Related Resources

- **Ethereum on ARM Main Repo**:  
  <https://github.com/EOA-Blockchain-Labs/ethereumonarm>

- **EOA Docs Portal**:  
  <https://ethereum-on-arm-documentation.readthedocs.io>

- **Status Page** (package versions):  
  <https://github.com/EOA-Blockchain-Labs/ethereumonarm/blob/main/STATUS.md>

---

## ✅ Done

Your `.deb` packages will appear inside the relative `packages` directory once the build completes successfully.
