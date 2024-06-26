#!/usr/bin/env bash

# Function to fetch the latest release version from GitHub
fetch_github_release() {
    repo=$1
    # Fetch the latest release tag from GitHub API and remove the leading 'v' if present
    latest_release=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name' | tr -d 'v')
    if [[ -z "$latest_release" ]]; then
        echo "Error: Unable to fetch release for $repo" >&2
    fi
    echo -n "$latest_release"
}

# Define project repositories and corresponding package names
declare -A projects=(
    [grandinetech/grandine]="grandine"
    [sigp/lighthouse]="lighthouse"
    [ChainSafe/lodestar]="lodestar"
    [status-im/nimbus-eth2]="nimbus"
    [prysmaticlabs/prysm]="prysm"
    [ConsenSys/teku]="teku"
    [hyperledger/besu]="besu"
    [ledgerwatch/erigon]="erigon"
    [ethereum/go-ethereum]="geth"
    [NethermindEth/nethermind]="nethermind"
    [paradigmxyz/reth]="reth"
    [OffchainLabs/nitro]="arbitrum-nitro"
    [ethereum-optimism/optimism]="optimism-op-geth"
    [maticnetwork/bor]="polygon-bor"
    [NethermindEth/juno]="starknet-juno"
)

# Base URL of the repository
BASE_URL="https://repo.ethereumonarm.com/pool/main/"

# Function to get the latest version of a package from the repository
get_latest_repo_version() {
    package=$1
    # Fetch the latest version of the package from the repository URL
    latest_version=$(curl -s "${BASE_URL}" | grep -oP "$package"_'[^"]*\.deb' | sort -V | tail -n 1 | grep -oP '(?<=_)[^_]+(?=_)')
    # Fallback if the initial regex pattern does not match
    if [[ -z $latest_version ]]; then
        latest_version=$(curl -s "${BASE_URL}" | grep -oP "$package"_'[^"]*\.deb' | sort -V | tail -n 1 | grep -oP '(?<=_)[^_]+(?=\.deb)')
    fi
    if [[ -z $latest_version ]]; then
        echo "Error: Unable to fetch repo version for $package" >&2
    fi
    echo -n "$latest_version"
}

# Compare and display results
for key in "${!projects[@]}"; do
    github_version=$(fetch_github_release "$key")
    repo_package="${projects[$key]}"
    repo_version=$(get_latest_repo_version "$repo_package")
    echo "$repo_package: GitHub Version = $github_version, Repository Version = $repo_version"
done
