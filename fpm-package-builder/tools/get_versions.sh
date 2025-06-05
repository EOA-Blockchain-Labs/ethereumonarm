#!/usr/bin/env bash
set -uo pipefail

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Compare Ethereum-based GitHub repos with EthereumonARM .deb repository versions.
Lists packages sorted alphabetically within their groups.

Options:
  -t <token>    GitHub token to avoid rate limits
  -h            Display help
EOF
    exit 0
}

GITHUB_TOKEN=""

while getopts ":ht:" opt; do
    case $opt in
    h)
        usage
        ;;
    t)
        GITHUB_TOKEN="$OPTARG"
        ;;
    *)
        echo "Invalid option: -$OPTARG" >&2
        usage
        ;;
    esac
done

shift $((OPTIND - 1))

# --- Dependency Check ---
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd not installed." >&2
        exit 1
    fi
done

# --- GitHub Authentication Header ---
if [[ -n "$GITHUB_TOKEN" ]]; then
    AUTH_HEADER=(-H "Authorization: token $GITHUB_TOKEN")
else
    AUTH_HEADER=()
fi

BASE_URL="https://repo.ethereumonarm.com/pool/main/"

# --- Function to fetch latest GitHub release/tag ---
fetch_github_release() {
    local repo="$1"
    local latest_release

    # Try getting the latest release first
    latest_release=$(curl -fsSL --retry 3 \
        -H "User-Agent: EthRepoComparator/1.0" \
        "${AUTH_HEADER[@]}" \
        "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | # Suppress curl errors here, check jq output
        jq -r '.tag_name')

    # If no latest release, try getting the latest tag
    if [[ -z "$latest_release" || "$latest_release" == "null" ]]; then
        latest_release=$(curl -fsSL --retry 3 \
            -H "User-Agent: EthRepoComparator/1.0" \
            "${AUTH_HEADER[@]}" \
            "https://api.github.com/repos/${repo}/tags" 2>/dev/null | # Suppress curl errors here
            jq -r '.[0].name')
    fi

    # Clean the version string
    latest_release="${latest_release##*/}" # Remove leading path if any
    latest_release="${latest_release#v}"   # Remove leading 'v'

    echo "${latest_release:-N/A}" # Output N/A if still empty
}

# --- Function to get latest version from the repository index ---
get_latest_repo_version() {
    local package="$1"
    local latest_version

    # Fetch the index, grep for the package, sort by version, get the last one, extract version
    latest_version=$(curl -fsSL "$BASE_URL" |
        grep -oP "(?<=<a href=\")${package}_[^\"]*\.deb" |
        sort -V | tail -n1 | grep -oP '(?<=_)[^_]+(?=_)')

    # Clean the version string (remove ABI/build suffix like -arm64)
    latest_version="${latest_version%-*}"

    echo "${latest_version:-N/A}" # Output N/A if still empty
}

# --- Package Definitions (Original Grouping) ---
declare -A layer1_consensus=(
    [grandinetech/grandine]=grandine
    [sigp/lighthouse]=lighthouse
    [ChainSafe/lodestar]=lodestar
    [status-im/nimbus-eth2]=nimbus
    [prysmaticlabs/prysm]=prysm
    [ConsenSys/teku]=teku
)

declare -A layer1_execution=(
    [hyperledger/besu]=besu
    [ledgerwatch/erigon]=erigon
    [ethereum/go-ethereum]=geth
    [NethermindEth/nethermind]=nethermind
    [paradigmxyz/reth]=reth
)

declare -A layer2=(
    [OffchainLabs/nitro]=arbitrum-nitro
    [ethereum-optimism/op-geth]=optimism-op-geth
    [paradigmxyz/reth]=op-reth
    [eqlabs/pathfinder]=starknet-pathfinder
    [NethermindEth/juno]=starknet-juno
    [FuelLabs/fuel-core]=fuel-network
)

declare -A infra=(
    [ethereum/staking-deposit-cli]=staking-deposit-cli
    [eth-educators/ethstaker-deposit-cli]=ethstaker-deposit-cli
    [ObolNetwork/charon]=dvt-obol
    [flashbots/mev-boost]=mev-boost
)

declare -A web3=(
    [ipfs/kubo]=kubo
    [ethersphere/bee]=bee
)

# --- Function to print a single row (kept from original) ---
print_table() {
    local pkg="$1" gh_ver="$2" repo_ver="$3"
    if [[ "$gh_ver" != "$repo_ver" ]]; then
        printf "\033[1;31m| %-23s | %-15s | %-15s |\033[0m\n" "$pkg" "$gh_ver" "$repo_ver"
    else
        printf "| %-23s | %-15s | %-15s |\n" "$pkg" "$gh_ver" "$repo_ver"
    fi
}

# --- Function to compare and print versions for a group (MODIFIED for sorting) ---
compare_group() {
    local group_name="$1"
    local -n group_ref="$2" # Reference to the associative array

    echo -e "\n===== $group_name =====\n"
    echo "+-------------------------+-----------------+-----------------+"
    echo "| Package                 | GitHub Version  | Repo Version    |"
    echo "+-------------------------+-----------------+-----------------+"

    local sorted_repos
    # Extract keys (GitHub repos), sort them alphabetically, and store in an array
    IFS=$'\n' sorted_repos=($(sort <<<"${!group_ref[*]}"))
    unset IFS

    # Loop through the sorted list of repository names
    for repo in "${sorted_repos[@]}"; do
        pkg=${group_ref[$repo]} # Get the package name from the repo name
        # Use a subshell for parallel execution
        (
            gh_ver=$(fetch_github_release "$repo")
            repo_ver=$(get_latest_repo_version "$pkg")
            print_table "$pkg" "$gh_ver" "$repo_ver"
        ) & # Run in background
    done

    # Wait for all background jobs for this group to finish
    wait
    echo "+-------------------------+-----------------+-----------------+"
}

# --- Main logic (Original Structure) ---
main() {
    compare_group "Layer 1 Consensus" layer1_consensus
    compare_group "Layer 1 Execution" layer1_execution
    compare_group "Layer 2" layer2
    compare_group "Infra" infra
    compare_group "Web3" web3
}

main