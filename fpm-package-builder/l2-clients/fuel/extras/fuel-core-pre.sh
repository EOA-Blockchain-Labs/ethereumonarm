#!/bin/bash

# Ensure the /etc/ethereum/fuel/chain-configuration exists and update or clone
if [ ! -d "/etc/ethereum/fuel/chain-configuration" ]; then
    git clone https://github.com/FuelLabs/chain-configuration /etc/ethereum/fuel/chain-configuration
else
    git -C /etc/ethereum/fuel/chain-configuration pull
fi

# Ensure the fuel.key file exists
if [ ! -f "/etc/ethereum/fuel/fuel.key" ]; then
    fuel-core-keygen new --key-type peering >/etc/ethereum/fuel/fuel.key
    KEYPAIR=$(jq -r '.secret' /etc/ethereum/fuel/fuel.key)
    sed -i "s/\$KEYPAIR[^ ]*/$KEYPAIR/" /etc/ethereum/fuel/fuel.conf
else
    KEYPAIR=$(jq -r '.secret' /etc/ethereum/fuel/fuel.key)
    if grep -q "\$KEYPAIR" "/etc/ethereum/fuel/fuel.conf"; then
        sed -i "s/\$KEYPAIR[^ ]*/$KEYPAIR/" /etc/ethereum/fuel/fuel.conf
    fi
fi
