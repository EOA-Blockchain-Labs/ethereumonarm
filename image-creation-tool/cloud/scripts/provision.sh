#!/bin/bash
#
# provisioning script for Ethereum on ARM Cloud Images
# This script installs all necessary dependencies, Ethereum clients, and monitoring tools.
# It is designed to run during the Packer build process.

set -e

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# --- Configuration ---
# Packages
BASE_PACKAGES="apt-utils nginx bash-completion file gdisk gpg parted net-tools rsync software-properties-common dphys-swapfile ufw vim wget kitty-terminfo"
ETHEREUM_PACKAGES="arbitrum-nitro bee besu commit-boost dvt-obol dvt-ssv erigon ethstaker-deposit-cli ethereumonarm-utils ethrex fuel-network geth grandine kubo lighthouse lodestar ls-lido mev-boost nethermind nimbus optimism-cannon optimism-op-challenger optimism-op-geth optimism-op-node optimism-op-program optimism-op-proposer optimism-op-reth prysm reth starknet-juno starknet-madara starknet-pathfinder teku vero vouch"
MONITORING_PACKAGES="ethereumonarm-monitoring-extras grafana prometheus prometheus-node-exporter ethereum-metrics-exporter"
NGINX_PACKAGES="ethereumonarm-config-sync ethereumonarm-nginx-proxy-extras"

# --- Functions ---

wait_for_apt_lock() {
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "Waiting for other apt processes to finish..."
        sleep 1
    done
}

# --- Main Install Logic ---

echo "Starting provisioning..."

# 1. Basic System Prep
echo "Updating system..."
wait_for_apt_lock
apt-get update
wait_for_apt_lock
apt-get -y upgrade

echo "Installing base packages..."
wait_for_apt_lock
# shellcheck disable=SC2086
apt-get -y install $BASE_PACKAGES

# 2. Add Repositories
echo "Adding Ethereum on ARM repository..."
wget -qO- http://apt.ethereumonarm.com/eoa.apt.keyring.gpg | tee /etc/apt/trusted.gpg.d/eoa.gpg >/dev/null
add-apt-repository -y -n "deb http://apt.ethereumonarm.com noble main"

echo "Cleaning up old Grafana keys from the deprecated apt-key keyring..."
OLD_GRAFANA_KEY_ID=$(apt-key list 2>/dev/null | grep -i 'Grafana Labs' -B 1 | head -n 1 | awk '{print $NF}' | cut -d/ -f2 | tail -c 9)
if [ -n "$OLD_GRAFANA_KEY_ID" ]; then
    echo "Found old Grafana key ID in apt keyring: ${OLD_GRAFANA_KEY_ID}. Deleting it..."
    apt-key del "$OLD_GRAFANA_KEY_ID"
else
    echo "No old Grafana key found in the deprecated apt keyring. Skipping deletion."
fi
rm -f /usr/share/keyrings/grafana.key

echo "Adding Grafana repository..."
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

echo "Updating package lists..."
wait_for_apt_lock
apt-get update

# 3. Create Users
echo "Creating ethereum user..."
if ! id -u ethereum >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" ethereum
    # Set default password (should be changed by user, or disabled for key-only access)
    echo "ethereum:ethereum" | chpasswd
    chage -d 0 ethereum

    # Add to groups
    for GRP in sudo netdev audio video dialout plugdev; do
        adduser ethereum "$GRP"
    done
fi

# Passwordless sudo for ethereum user
echo "ethereum ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/90-ethereum-nopasswd
chmod 0440 /etc/sudoers.d/90-ethereum-nopasswd

# 4. Install Software
echo "Installing Ethereum packages..."
wait_for_apt_lock
# shellcheck disable=SC2086
apt-get -y install $ETHEREUM_PACKAGES

echo "Installing Monitoring packages..."
# Create prometheus user first
if ! id -u prometheus >/dev/null 2>&1; then
    adduser --quiet --system --home /home/prometheus --no-create-home --group --gecos "Prometheus daemon" prometheus
fi
mkdir -p /home/prometheus/{metrics2,node-exporter}
chown -R prometheus:prometheus /home/prometheus/{metrics2,node-exporter}

wait_for_apt_lock
# shellcheck disable=SC2086
apt-get -y install $MONITORING_PACKAGES

echo "Installing Nginx..."
wait_for_apt_lock
# shellcheck disable=SC2086
apt-get -y install $NGINX_PACKAGES

# 5. Configuration & Services

# Swap Configuration (Adaptive)
echo "Configuring Swap..."
MEM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
SWAP_SIZE=$((MEM_MB * 2))
[ "$SWAP_SIZE" -gt 65536 ] && SWAP_SIZE=65536 # Cap at 64GB
echo "Calculated Swap Size: ${SWAP_SIZE} MB"

sed -i "s|#CONF_SWAPFILE=.*|CONF_SWAPFILE=/home/ethereum/swapfile|" /etc/dphys-swapfile
sed -i "s|#CONF_SWAPSIZE=.*|CONF_SWAPSIZE=${SWAP_SIZE}|" /etc/dphys-swapfile
sed -i "s|#CONF_MAXSWAP=.*|CONF_MAXSWAP=${SWAP_SIZE}|" /etc/dphys-swapfile

systemctl enable dphys-swapfile --now || echo "Warning: Failed to enable swap"

# Time sync (NTP)
mkdir -p /etc/systemd/timesyncd.conf.d/
cat <<EOF >/etc/systemd/timesyncd.conf.d/eoa.conf
[Time]
NTP=time1.google.com time2.google.com time3.google.com time4.google.com
PollIntervalMinSec=16
PollIntervalMaxSec=64
RootDistanceMaxSec=100
EOF
timedatectl set-ntp true

# EOA Release Info
# EOA Release Info
EOA_MINOR_VERSION=${EOA_MINOR_VERSION:-0}
EOA_MAJOR_VERSION=$(date +"%y.%m")
EOA_VERSION="Ethereum on ARM $EOA_MAJOR_VERSION.$EOA_MINOR_VERSION"
echo "$EOA_VERSION" >/etc/eoa-release


# Bash Alias
echo "alias update-ethereum='sudo apt-get update && sudo apt-get install $ETHEREUM_PACKAGES'" >>/etc/bash.bashrc
if ! grep -q "if \[ -f /etc/bash.bashrc \];" /etc/profile; then
    echo "if [ -f /etc/bash.bashrc ]; then . /etc/bash.bashrc; fi" >>/etc/profile
fi

# Monitoring configuration
systemctl enable grafana-server
systemctl enable prometheus prometheus-node-exporter ethereum-metrics-exporter
set-ethereumonarm-monitoring-extras -o || echo "Warning: Failed to apply specific monitoring settings."

# Nginx
systemctl enable nginx

# 6. Security Hardening & Firewall
echo "Applying basic security hardening..."
passwd -l root

echo "Disabling UFW firewall..."
ufw --force disable

echo "Ensuring correct ownership for /home/ethereum..."
chown -R ethereum:ethereum /home/ethereum/

# 7. Cleanup
echo "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Provisioning complete."
exit 0
