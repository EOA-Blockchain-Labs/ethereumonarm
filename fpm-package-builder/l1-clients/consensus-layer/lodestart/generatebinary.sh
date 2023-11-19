#!/bin/bash

# Update package lists
sudo apt-get update

# Install required packages
sudo apt-get install -y make gcc g++ jq ruby ruby-dev rubygems build-essential rpm
gem install --no-document fpm

# Set a default Node.js version
DEFAULT_NODE_VERSION="v20.9.0"

# Fetch the latest LTS version of Node.js, use default if the command fails
NODE_VERSION=$(curl -s https://api.github.com/repos/nodejs/node/releases | jq -r '[.[] | select(.name | contains("LTS"))][0].tag_name')
NODE_VERSION=${NODE_VERSION:-$DEFAULT_NODE_VERSION}

# Remove the 'v' prefix from the version, if present
NODE_VERSION=${NODE_VERSION#v}

# Define the Node.js tarball name
TARBALL_NAME="node-v$NODE_VERSION-linux-arm64.tar.xz"

# Check if the Node.js tarball already exists
if [ ! -f $TARBALL_NAME ]; then
    # Download the Node.js version for Linux x64
    wget https://nodejs.org/dist/v$NODE_VERSION/$TARBALL_NAME
fi

# Create a directory for Node.js installation
sudo mkdir -p /usr/local/lib/nodejs

# Extract the downloaded tarball into the created directory, silently
sudo tar -xJf $TARBALL_NAME -C /usr/local/lib/nodejs

# Update .bashrc for the current user with Node.js environment variables
echo "export PATH=/usr/local/lib/nodejs/node-v$NODE_VERSION-linux-arm64/bin:$PATH" >> /home/$USER/.bashrc

# Source the updated .bashrc to apply changes
source /home/$USER/.bashrc

# Check if yarn is installed, install if not
if ! command -v yarn > /dev/null; then
    npm install -g yarn
fi

# Install caxa
npm install --save-dev caxa

# Define the lodestar repository directory
LODESTAR_DIR="/home/$USER/lodestar"

# Check if the lodestar repository is already cloned
if [ -d "$LODESTAR_DIR" ]; then
    # Update the repository
    cd $LODESTAR_DIR
    git pull
else
    # Clone the lodestar repository
    git clone https://github.com/ChainSafe/lodestar.git $LODESTAR_DIR
    cd $LODESTAR_DIR
fi

# Install dependencies and build using yarn
yarn install
yarn build

# Package the application using caxa
npx caxa --input . --output "lodestar.bin" -- "{{caxa}}/node_modules/.bin/node" "{{caxa}}/node_modules/.bin/lodestar"
