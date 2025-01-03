#!/usr/bin/env bash
set -uo pipefail

########################################
# 0. Usage and Option Parsing (getopts)
########################################
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Compare the latest versions of various Ethereum-based repos on GitHub with
the versions in the EthereumonARM .deb repository, highlighting mismatches in red.

Options:
  -t <token>    Provide a GitHub personal access token to avoid rate-limits
  -h            Show this help message

Examples:
  $0
  $0 -t ghp_1234567890abcdef

EOF
    exit 0
}

GITHUB_TOKEN=""

# Parse command-line arguments
while getopts ":ht:" opt; do
  case $opt in
    h)
      usage
      ;;
    t)
      GITHUB_TOKEN="$OPTARG"
      ;;
    \?)
      echo "Error: Invalid option '-$OPTARG'" >&2
      usage
      ;;
    :)
      echo "Error: Option '-$OPTARG' requires an argument." >&2
      usage
      ;;
  esac
done

# Shift off processed options/arguments
shift $((OPTIND-1))

########################################
# 1. Check for required dependencies
########################################
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again." >&2
        exit 1
    fi
done

########################################
# 2. Set up authorization header array
########################################
# Using an array avoids tricky quoting issues when expanding.
if [[ -n "$GITHUB_TOKEN" ]]; then
    AUTH_HEADER=(-H "Authorization: token $GITHUB_TOKEN")
else
    AUTH_HEADER=()
fi

########################################
# 3. Function: Fetch latest release/tag
########################################
fetch_github_release() {
    local repo="$1"
    local latest_release

    # Attempt to fetch the latest "release" from GitHub
    if ! latest_release=$(
        curl --fail -sL "${AUTH_HEADER[@]}" \
             "https://api.github.com/repos/$repo/releases/latest" \
        | jq -r '.tag_name' 2>/dev/null
    ); then
        echo "Error: Failed to fetch 'releases/latest' from GitHub for $repo" >&2
        echo ""
        return 1
    fi

    # If empty or "null", fallback to fetching the first tag
    if [[ -z "$latest_release" || "$latest_release" == "null" ]]; then
        if ! latest_release=$(
            curl --fail -sL "${AUTH_HEADER[@]}" \
                 "https://api.github.com/repos/$repo/tags" \
            | jq -r '.[0].name' 2>/dev/null
        ); then
            echo "Error: Failed to fetch 'tags' from GitHub for $repo" >&2
            echo ""
            return 1
        fi
    fi

    # Normalize: remove any path segments & strip leading "v"
    latest_release="$(echo "$latest_release" \
        | sed -E 's|^.*/||' \
        | sed -E 's/^v//')"

    echo "$latest_release"
}

########################################
# 4. Function: Fetch latest version from .deb repo
########################################
BASE_URL="https://repo.ethereumonarm.com/pool/main/"

get_latest_repo_version() {
    local package="$1"
    local latest_version=""

    # Scrape the HTML index for .deb files matching the package name
    if ! latest_version=$(
        curl --fail -s "${BASE_URL}" \
        | grep -oP "(?<=<a href=\")${package}_[^\"]*\.deb" \
        | sort -V \
        | tail -n 1 \
        | grep -oP '(?<=_)[^_]+(?=_)'
    ); then
        echo "Error: Failed to fetch package versions for $package" >&2
        echo ""
        return 1
    fi

    # Fallback if it didn't match exactly
    if [[ -z "$latest_version" ]]; then
        latest_version=$(
            curl --fail -s "${BASE_URL}" \
            | grep -oP "(?<=<a href=\")${package}_[^\"]*\.deb" \
            | sort -V \
            | tail -n 1 \
            | grep -oP '(?<=_)[^_]+(?=\.deb)'
        )
    fi

    # Strip trailing "-0", "-1", etc.
    latest_version="$(echo "$latest_version" | sed -E 's/-[0-9]+$//')"

    echo "$latest_version"
}

########################################
# 5. Define Repositories & Packages (Grouped)
########################################
# ---- Layer 1 Consensus ----
declare -A layer1_consensus=(
    [grandinetech/grandine]="grandine"
    [sigp/lighthouse]="lighthouse"
    [ChainSafe/lodestar]="lodestar"
    [status-im/nimbus-eth2]="nimbus"
    [prysmaticlabs/prysm]="prysm"
    [ConsenSys/teku]="teku"
)

# ---- Layer 1 Execution ----
declare -A layer1_execution=(
    [hyperledger/besu]="besu"
    [ledgerwatch/erigon]="erigon"
    [ethereum/go-ethereum]="geth"
    [NethermindEth/nethermind]="nethermind"
    [paradigmxyz/reth]="reth"
)

# ---- Layer 2 ----
declare -A layer2=(
    [OffchainLabs/nitro]="arbitrum-nitro"
    [ethereum-optimism/op-geth]="optimism-op-geth"
    [maticnetwork/bor]="polygon-bor"
    [NethermindEth/juno]="starknet-juno"
    [FuelLabs/fuel-core]="fuel-network"
)

########################################
# 6. Helpers for prettier ASCII-table output
########################################
print_table_border() {
    echo "+-------------------------+-----------------+-----------------+"
}

print_table_header() {
    print_table_border
    echo "| Package                 | GitHub Version  | Repo Version    |"
    print_table_border
}

print_table_row() {
    local package="$1"
    local github_version="$2"
    local repo_version="$3"
    local mismatch="$4"  # yes/no

    if [[ "$mismatch" == "yes" ]]; then
        # Print row in red
        printf "\033[1;31m| %-23s | %-15s | %-15s |\033[0m\n" \
            "$package" "$github_version" "$repo_version"
    else
        printf "| %-23s | %-15s | %-15s |\n" \
            "$package" "$github_version" "$repo_version"
    fi
}

########################################
# 7. Compare and display (grouped)
#    Store mismatch count in a global
########################################
_LAST_GROUP_MISMATCHES=0  # global scratch variable

print_group() {
    local group_name="$1"
    local -n group_array="$2"

    _LAST_GROUP_MISMATCHES=0

    echo
    echo "===== ${group_name} ====="
    echo

    print_table_header

    for repo in "${!group_array[@]}"; do
        local package="${group_array[$repo]}"
        local github_version
        local repo_version

        github_version="$(fetch_github_release "$repo" || echo "")"
        repo_version="$(get_latest_repo_version "$package" || echo "")"

        github_version="${github_version:-N/A}"
        repo_version="${repo_version:-N/A}"

        if [[ "$github_version" != "$repo_version" ]]; then
            _LAST_GROUP_MISMATCHES=$((_LAST_GROUP_MISMATCHES + 1))
            print_table_row "$package" "$github_version" "$repo_version" "yes"
        else
            print_table_row "$package" "$github_version" "$repo_version" "no"
        fi
    done

    print_table_border

    # Always return 0 (success) so "set -e" doesn't abort the script.
    return 0
}

########################################
# 8. Main Execution
########################################
main() {
    local total_mismatches=0

    # ---- Layer 1 Consensus ----
    print_group "Layer 1 Consensus" layer1_consensus
    (( total_mismatches += _LAST_GROUP_MISMATCHES ))

    # ---- Layer 1 Execution ----
    print_group "Layer 1 Execution" layer1_execution
    (( total_mismatches += _LAST_GROUP_MISMATCHES ))

    # ---- Layer 2 ----
    print_group "Layer 2" layer2
    (( total_mismatches += _LAST_GROUP_MISMATCHES ))

    echo
    echo "Total mismatches: $total_mismatches"
}

main

