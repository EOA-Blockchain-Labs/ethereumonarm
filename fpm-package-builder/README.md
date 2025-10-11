# Ethereum on ARM – Package Builder

This repository contains the **Makefiles**, **helper scripts**, and **tooling**
used to build and package all **Ethereum on ARM** software into `.deb` packages
for ARM64 boards and multi-arch Ubuntu systems.

The builder creates reproducible `.deb` packages for:

- Ethereum execution and consensus clients
- Utilities and monitoring tools (Grafana, Prometheus, Node Exporter, etc.)
- EOA-specific utilities (EOA-GUI, systemd templates, helper scripts)

---

## 💻 1. Recommended: Use the Provided Vagrantfile

The easiest and most reliable way to create a fully configured build environment
is to use the included **Vagrantfile**. This will automatically set up an Ubuntu
24.04 virtual machine with all required dependencies, compilers, and toolchains.

### Requirements

- [Vagrant](https://www.vagrantup.com/docs/installation)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### Steps

```bash
git clone https://github.com/EOA-Blockchain-Labs/ethereumonarm.git
cd ethereumonarm/fpm-package-builder
vagrant up
vagrant ssh
cd ethereumonarm/
```

The VM comes with:

- All dependencies and cross-compilers installed
- Docker configured for the `vagrant` user
- Rust, Go, and Node environments ready to use

Once inside the VM, you can immediately build packages (see section 3).

---

## 🧩 2. Manual Setup (Ubuntu 24.04 LTS)

> **Note:** Only use this method if you need to build directly on your host
> system or in a CI pipeline. Otherwise, prefer the Vagrant option above.

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
sudo apt-get install -y   libssl-dev:arm64 pkg-config software-properties-common docker.io docker-compose   clang file make cmake gcc-aarch64-linux-gnu g++-aarch64-linux-gnu   ruby ruby-dev rubygems build-essential rpm vim git jq curl wget python3-pip

sudo gem install --no-document fpm
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt-get update -y
sudo apt-get install -y golang-go

sudo usermod -aG docker vagrant
sudo -u vagrant bash -c 'curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable'
sudo -u vagrant bash -c 'source ~/.cargo/env && rustup target add aarch64-unknown-linux-gnu'
sudo -u vagrant bash -c 'mkdir -p /home/vagrant/.cargo && cat <<EOF > /home/vagrant/.cargo/config
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
EOF'

sudo -u vagrant bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash'
sudo -u vagrant bash -c 'export NVM_DIR="$HOME/.nvm" && source $NVM_DIR/nvm.sh && nvm install 20 && npm install -g yarn'
```

---

## ⚙️ 3. Building Packages

### Build all `.deb` packages

```bash
make
```

### Build a specific package

```bash
cd geth
make
```

Each subdirectory includes a Makefile defining:

- `VERSION` (package version)
- `SOURCE_URL` (GitHub source repository)
- Build and packaging rules

Resulting `.deb` files are placed within each component directory.

---

## 🧪 4. Verifying Builds

```bash
ls -l */*.deb
dpkg-deb -I geth/geth_*.deb | grep Version
```

To install locally for testing:

```bash
sudo apt install ./geth/geth_<version>_arm64.deb
```

---

## 🧱 5. Adding a New Package

1. Create a new directory under `fpm-package-builder/`
2. Copy a template Makefile (e.g., from `geth/`)
3. Update variables:
   - `PKG_NAME`
   - `VERSION`
   - `SOURCE_URL`
4. Run `make` inside the directory
5. Test on an ARM board (e.g., Rock 5B, Orange Pi 5 Plus)

---

## 🛠️ 6. Troubleshooting

| Problem | Cause | Solution |
|----------|--------|-----------|
| `apt-get update` fails for ARM64 repos | Wrong codename or URI | Verify `UBUNTU_CODENAME` and repo URLs |
| Rust linker errors | Missing cross-compiler | Ensure `aarch64-linux-gnu-gcc` is installed |
| `nvm` not found | Path not sourced | `source ~/.nvm/nvm.sh` before use |
| Docker permission denied | User not in group | `sudo usermod -aG docker $USER && newgrp docker` |
| `fpm` not found | Ruby PATH issue | `sudo gem install fpm` or export Ruby bin path |

---

## 🤝 7. Contributing

We welcome contributions! You can help by:

- Adding new clients or utilities
- Updating package versions
- Improving documentation or Makefiles

Join our [Discord](https://discord.gg/ve2Z8fxz5N) to collaborate.

---

## 📚 8. Related Resources

- [Ethereum on ARM Main Repo](https://github.com/diglos/ethereumonarm)
- [EOA Docs Portal](https://ethereum-on-arm-documentation.readthedocs.io)
- [Status Page (package versions)](https://github.com/EOA-Blockchain-Labs/ethereumonarm/blob/main/STATUS.md)

---

✅ **Done!**  
Your `.deb` packages will appear inside their respective directories once the
build completes successfully.
