#!/usr/bin/env bash

apt-get update
apt-get install -y clang pkg-config file make cmake gcc-aarch64-linux-gnu g++-aarch64-linux-gnu ruby ruby-dev rubygems build-essential rpm vim git jq curl wget python3-pip
gem install --no-document fpm
sed -i '22a \t: # Ensure this if-clause is not empty. If it were empty, and we had an 'else', then it is an error in shell syntax' /var/lib/gems/2.7.0/gems/fpm-1.12.0/templates/deb/postinst_upgrade.sh.erb
curl https://sh.rustup.rs -sSf | sh -s -- -y
cat <<EOF >> ~/.cargo/config
[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
EOF
source ~/.cargo/env
rustup target add aarch64-unknown-linux-gnu
rustup update
