#!/usr/bin/env bash

# Check for required dependencies
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# GitHub API token (optional, to handle rate limits)
GITHUB_TOKEN=""
AUTH_HEADER=""
if [[ -n "$GITHUB_TOKEN" ]]; then
    AUTH_HEADER="-H Authorization: token $GITHUB_TOKEN"
fi

# Function to fetch the latest release version from GitHub
fetch_github_release() {
    local repo="$1"
    local latest_release

    # Fetch the latest release tag using GitHub API
    latest_release=$(curl -sL $AUTH_HEADER "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name' 2>/dev/null)

    # Normalize: Remove 'v' prefix and any branch names like "op-batcher/"
    latest_release=$(echo "$latest_release" | sed -E 's/^v|.*\///')

    # Fallback: Fetch the latest tag if releases are unavailable
    if [[ -z "$latest_release" || "$latest_release" == "null" ]]; then
        latest_release=$(curl -sL $AUTH_HEADER "https://api.github.com/repos/$repo/tags" | jq -r '.[0].name' 2>/dev/null | sed 's/^v//')
    fi

    if [[ -z "$latest_release" ]]; then
        echo "Error: Unable to fetch release for $repo" >&2
        echo ""
    else
        echo "$latest_release"
    fi
}

# Function to get the latest version of a package from the repository
get_latest_repo_version() {
    local package="$1"
    local latest_version

    # Fetch the latest version from the repository's HTML
    latest_version=$(curl -s "${BASE_URL}" | grep -oP "(?<=<a href=\")$package"_'[^"]*\.deb' | sort -V | tail -n 1 | grep -oP '(?<=_)[^_]+(?=_)')

    # Fallback pattern if the initial regex fails
    if [[ -z "$latest_version" ]]; then
        latest_version=$(curl -s "${BASE_URL}" | grep -oP "(?<=<a href=\")$package"_'[^"]*\.deb' | sort -V | tail -n 1 | grep -oP '(?<=_)[^_]+(?=\.deb)')
    fi

    # Remove suffix (e.g., -0, -1)
    latest_version=$(echo "$latest_version" | sed 's/-[0-9]*$//')

    if [[ -z "$latest_version" ]]; then
        echo "Error: Unable to fetch repo version for $package" >&2
        echo ""
    else
        echo "$latest_version"
    fi
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
    [ethereum-optimism/op-geth]="optimism-op-geth"
    [maticnetwork/bor]="polygon-bor"
    [NethermindEth/juno]="starknet-juno"
    [starkware-libs/sequencer]="starknet-sequencer"
    [FuelLabs/fuel-core]="fuel-network"
)

# Base URL of the repository
BASE_URL="https://repo.ethereumonarm.com/pool/main/"

# Header for output
printf "%-25s | %-15s | %-15s\n" "Package" "GitHub Version" "Repo Version"
printf "%-25s | %-15s | %-15s\n" "-------------------------" "---------------" "---------------"

# Compare and display results
mismatches=0
for repo in "${!projects[@]}"; do
    package="${projects[$repo]}"
    github_version=$(fetch_github_release "$repo")
    repo_version=$(get_latest_repo_version "$package")

    if [[ "$github_version" != "$repo_version" ]]; then
        mismatches=$((mismatches + 1))
        printf "\033[1;31m%-25s | %-15s | %-15s\033[0m\n" "$package" "${github_version:-N/A}" "${repo_version:-N/A}"
    else
        printf "%-25s | %-15s | %-15s\n" "$package" "${github_version:-N/A}" "${repo_version:-N/A}"
    fi
done

# Summary
echo
echo "Total mismatches: $mismatches"

