#!/bin/bash
set -e

echo "Starting provisioning script..."

# Ensure the main sources.list is empty or minimal, as we're using .sources files
echo "# See /etc/apt/sources.list.d/ for repository configuration" >/etc/apt/sources.list

# Remove the default ubuntu.sources file if it exists to avoid duplication
rm -f /etc/apt/sources.list.d/ubuntu.sources

# Get the codename (e.g., noble)
UBUNTU_CODENAME=$(lsb_release -cs)

# Create the .sources file for AMD64 repositories
cat <<EOF >/etc/apt/sources.list.d/ubuntu-amd64.sources
Types: deb
URIs: http://us.archive.ubuntu.com/ubuntu
Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security ${UBUNTU_CODENAME}-backports
Components: main restricted universe multiverse
Architectures: amd64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

# Create the .sources file for ARM64 repositories
cat <<EOF >/etc/apt/sources.list.d/ubuntu-arm64.sources
Types: deb
URIs: http://ports.ubuntu.com
Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-security ${UBUNTU_CODENAME}-backports
Components: main restricted universe multiverse
Architectures: arm64
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

# Add arm64 architecture for multi-arch support
dpkg --add-architecture arm64

# Update the package lists for all repositories
# The 'Acquire::http::Pipeline-Depth "0";' line is often a workaround for network issues or specific proxy configurations.
echo 'Acquire::http::Pipeline-Depth "0";' >/etc/apt/apt.conf.d/90localsettings
apt-get update -y

# Install development tools and dependencies
# Installing libssl-dev:arm64 for ARM64 cross-compilation needs
# Also installing cross-compilers for aarch64
apt-get install -y \
  libssl-dev:arm64 \
  pkg-config \
  software-properties-common \
  docker.io \
  docker-compose \
  clang \
  file \
  make \
  cmake \
  gcc-aarch64-linux-gnu \
  g++-aarch64-linux-gnu \
  ruby \
  ruby-dev \
  rubygems \
  build-essential \
  rpm \
  vim \
  git \
  jq \
  curl \
  wget \
  python3-pip \
  ca-certificates \
  gnupg

# Install the fpm package management tool for Ruby
gem install --no-document fpm

# Install LLVM 19 and dependencies for Madara
# We use the official LLVM script to ensure we get version 19
wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- 19
apt-get install -y \
  libmlir-19-dev \
  mlir-19-tools \
  clang-19 \
  llvm-19-dev \
  libpolly-19-dev \
  libzstd-dev \
  libxml2-dev \
  protobuf-compiler \
  libudev-dev \
  python3-full \
  python3-pip \
  python3-venv

# Add the longsleep/golang-backports PPA to the list of repositories
# This PPA provides more up-to-date Go versions.
add-apt-repository -y ppa:longsleep/golang-backports

# Update the package lists again, including the newly added PPA
apt-get update -y

# Install the Go programming language
# golang-go will install the latest available from PPA
apt-get -y install golang-go

# Add the vagrant user to the docker group to run docker commands without sudo
usermod -aG docker vagrant

# Install Rustup, the Rust toolchain installer, as the vagrant user
su - vagrant -c "curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable"

# Add the aarch64 architecture as a Rust target for cross-compilation
# Ensure .cargo/env is sourced for the rustup command
su - vagrant -c "source ~/.cargo/env && rustup target add aarch64-unknown-linux-gnu"

# Configure linker for aarch64 Rust target
# This tells Rust to use the aarch64-linux-gnu-gcc cross-compiler when building for that target.
sudo -u vagrant bash -c 'mkdir -p /home/vagrant/.cargo && cat <<EOF > /home/vagrant/.cargo/config
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
EOF'

# Initialize the NodeSource repository for Node.js 24
# This involves adding the GPG key and creating the source list file manually
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Add the NodeSource repository to sources.list.d
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Install Node.js from the new repository
apt-get update -y
apt-get install -y nodejs

# Install Yarn and pnpm globally using npm
npm install -g yarn pnpm

# Configure Git to suppress detached HEAD advice for the vagrant user
sudo -u vagrant git config --global advice.detachedHead false

# Configure pnpm to allow esbuild build scripts (required for ssv-keys)
sudo -u vagrant pnpm config --global set only-built-dependencies esbuild

echo "Provisioning script finished!"
