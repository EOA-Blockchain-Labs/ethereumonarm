#!/usr/bin/env bash
set -uo pipefail

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Compare Ethereum-based GitHub repos with EthereumonARM .deb repository versions.

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
        usage
        ;;
    esac
done

shift $((OPTIND - 1))

for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd not installed." >&2
        exit 1
    fi
done

if [[ -n "$GITHUB_TOKEN" ]]; then
    AUTH_HEADER=(-H "Authorization: token $GITHUB_TOKEN")
else
    AUTH_HEADER=()
fi

BASE_URL="https://repo.ethereumonarm.com/pool/main/"

fetch_github_release() {
    local repo="$1"
    local latest_release

    latest_release=$(curl -fsSL --retry 3 \
        -H "User-Agent: EthRepoComparator/1.0" \
        "${AUTH_HEADER[@]}" \
        "https://api.github.com/repos/${repo}/releases/latest" |
        jq -r '.tag_name')

    if [[ -z "$latest_release" || "$latest_release" == "null" ]]; then
        latest_release=$(curl -fsSL --retry 3 \
            -H "User-Agent: EthRepoComparator/1.0" \
            "${AUTH_HEADER[@]}" \
            "https://api.github.com/repos/${repo}/tags" |
            jq -r '.[0].name')
    fi

    latest_release="${latest_release##*/}"
    latest_release="${latest_release#v}"

    echo "${latest_release:-N/A}"
}

get_latest_repo_version() {
    local package="$1"
    local latest_version

    latest_version=$(curl -fsSL "$BASE_URL" |
        grep -oP "(?<=<a href=\")${package}_[^\"]*\.deb" |
        sort -V | tail -n1 | grep -oP '(?<=_)[^_]+(?=_)')

    [[ -z "$latest_version" ]] && latest_version="N/A"

    latest_version="${latest_version%-*}"

    echo "$latest_version"
}

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
    [NethermindEth/juno]=starknet-juno
    [FuelLabs/fuel-core]=fuel-network
)

declare -A infra=(
    [ethereum/staking-deposit-cli]=staking-deposit-cli
    [ObolNetwork/charon]=dvt-obol
    [flashbots/mev-boost]=mev-boost
    [ethpandaops/contributoor]=contributoor
)

declare -A web3=(
    [ipfs/kubo]=kubo
    [ethersphere/bee]=bee
)


print_table() {
    local pkg="$1" gh_ver="$2" repo_ver="$3"
    if [[ "$gh_ver" != "$repo_ver" ]]; then
        printf "\033[1;31m| %-23s | %-15s | %-15s |\033[0m\n" "$pkg" "$gh_ver" "$repo_ver"
    else
        printf "| %-23s | %-15s | %-15s |\n" "$pkg" "$gh_ver" "$repo_ver"
    fi
}

compare_group() {
    local group_name="$1"
    local -n group_ref="$2"
    echo -e "\n===== $group_name =====\n"
    echo "+-------------------------+-----------------+-----------------+"
    echo "| Package                 | GitHub Version  | Repo Version    |"
    echo "+-------------------------+-----------------+-----------------+"

    for repo in "${!group_ref[@]}"; do
        pkg=${group_ref[$repo]}
        (
            gh_ver=$(fetch_github_release "$repo")
            repo_ver=$(get_latest_repo_version "$pkg")
            print_table "$pkg" "$gh_ver" "$repo_ver"
        ) &
    done
    wait
    echo "+-------------------------+-----------------+-----------------+"
}

main() {
    compare_group "Layer 1 Consensus" layer1_consensus
    compare_group "Layer 1 Execution" layer1_execution
    compare_group "Layer 2" layer2
    compare_group "Infra" infra
    compare_group "Web3" web3
}

main
