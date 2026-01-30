# Use Ubuntu 24.04 (Noble) as base, matching the target OS
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Base Setup & Common Tools
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    git \
    build-essential \
    software-properties-common \
    ruby-full \
    python3-pip \
    rpm \
    jq \
    file \
    cmake \
    # Cross-compilation tools
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Install FPM (Ruby gem)
RUN gem install --no-document fpm

# 3. Install Go (Golang)
# Using the PPA as done in provision.sh
RUN add-apt-repository -y ppa:longsleep/golang-backports && \
    apt-get update && \
    apt-get install -y golang-go && \
    rm -rf /var/lib/apt/lists/*

# 4. Install Rust (Rustup)
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && \
    rustup target add aarch64-unknown-linux-gnu

# Configure cargo for cross-compilation
RUN mkdir -p /usr/local/cargo && \
    echo '[target.aarch64-unknown-linux-gnu]\nlinker = "aarch64-linux-gnu-gcc"' > /usr/local/cargo/config

# 5. Install Node.js 24
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install -g yarn pnpm && \
    pnpm config --global set only-built-dependencies esbuild && \
    rm -rf /var/lib/apt/lists/*

# 6. Install LLVM 19
RUN wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- 19 && \
    apt-get install -y \
    libmlir-19-dev \
    mlir-19-tools \
    clang-19 \
    llvm-19-dev \
    libpolly-19-dev \
    libzstd-dev \
    libxml2-dev \
    protobuf-compiler \
    libudev-dev && \
    rm -rf /var/lib/apt/lists/*

# Set Working Directory
WORKDIR /workspace

# Default command (optional)
CMD ["make", "help"]
