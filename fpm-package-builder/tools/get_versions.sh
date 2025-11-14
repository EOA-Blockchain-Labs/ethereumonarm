#!/usr/bin/env bash
# Compare upstream GitHub release/tag versions with Ethereum on ARM repo versions
# and optionally generate a grouped Markdown report.
#
# Usage:
#   get_versions.sh [-t <token>] [-m <STATUS.md>] [-h]
#
# Options:
#   -t <token>     GitHub token (Bearer) to avoid rate limits; falls back to env GITHUB_TOKEN if not given.
#   -m <file>      Generate a Markdown status report to the specified file (e.g., STATUS.md).
#   -h             Show help.
#
# Environment:
#   GITHUB_TOKEN    Used if -t is not provided.
#   PACKAGES_URL    Optional. If set, reads this APT Packages index (.gz or plain) to determine latest repo versions.
#                   Example: https://repo.ethereumonarm.com/dists/stable/main/binary-arm64/Packages.gz
#   MAX_PARALLEL    Optional. Max parallel checks (default: 8).

set -euo pipefail
set -E
trap 'rc=$?; echo "Error on line ${BASH_LINENO[0]}: ${BASH_COMMAND} (exit: $rc)" >&2' ERR
IFS=$' \t\n'

readonly USER_AGENT="EthRepoComparator/1.4"
readonly API_VERSION="2022-11-28"
readonly BASE_URL="https://repo.ethereumonarm.com/pool/main/"
readonly RATE_LIMIT_SLEEP=0.5
: "${MAX_PARALLEL:=8}"

MARKDOWN_FILE=""
RESULTS_TMP_FILE=""
GITHUB_TOKEN="${GITHUB_TOKEN-}"
VERBOSE="${VERBOSE:-0}"

usage() {
  cat <<'EOF'
Usage: get_versions.sh [OPTIONS]

Compare Ethereum-based GitHub repos with Ethereum on ARM .deb repository versions.
Lists packages sorted alphabetically within their groups, and optionally generates Markdown.

Options:
  -t <token>      GitHub token (Bearer) to avoid rate limits (falls back to env GITHUB_TOKEN)
  -m <file>       Generate a Markdown status report to the specified file (e.g., STATUS.md)
  -h              Display help

Environment:
  VERBOSE=1       Enable verbose logging
EOF
  exit 0
}

log_verbose() {
  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "[VERBOSE] $*" >&2
  fi
}

cleanup() {
  if [[ -n "${RESULTS_TMP_FILE-}" && -f "${RESULTS_TMP_FILE}" ]]; then
    rm -f -- "${RESULTS_TMP_FILE}"
  fi
}
trap cleanup EXIT

while getopts ":ht:m:" opt; do
  case "${opt}" in
    h) usage ;;
    t) GITHUB_TOKEN="${OPTARG}" ;;
    m) MARKDOWN_FILE="${OPTARG}" ;;
    *) echo "Invalid option: -${OPTARG}" >&2; usage ;;
  esac
done
shift $((OPTIND - 1))

# Check dependencies
for cmd in curl jq sort awk sed grep; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd not installed." >&2; exit 1; }
done
if [[ -n "${PACKAGES_URL-}" && "${PACKAGES_URL}" == *.gz ]]; then
  command -v gzip >/dev/null 2>&1 || { echo "Error: gzip not installed (required for .gz Packages files)." >&2; exit 1; }
fi

is_tty=0
if [[ -t 1 ]]; then is_tty=1; fi
red() { if (( is_tty )); then printf '\033[1;31m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }
green() { if (( is_tty )); then printf '\033[1;32m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }
yellow() { if (( is_tty )); then printf '\033[1;33m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }

if [[ -n "$MARKDOWN_FILE" ]]; then
  RESULTS_TMP_FILE="$(mktemp)"
fi

declare -a API_HEADERS=(
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: ${API_VERSION}"
  -H "User-Agent: ${USER_AGENT}"
)
if [[ -n "${GITHUB_TOKEN}" ]]; then
  API_HEADERS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

http_get() {
  local url="$1"
  local max_retries=3
  local retry_count=0
  
  while (( retry_count < max_retries )); do
    if curl -fsSL --retry 3 --retry-delay 1 --max-time 20 "${API_HEADERS[@]}" "$url" 2>/dev/null; then
      return 0
    fi
    ((++retry_count))
    log_verbose "Retry $retry_count/$max_retries for $url"
    sleep "${RATE_LIMIT_SLEEP}"
  done
  
  log_verbose "Failed to fetch $url after $max_retries attempts"
  return 1
}

normalize_tag() {
  local t="${1##*/}"
  t="${t#v}"
  # Remove common prefixes
  t="${t#release-}"
  t="${t#version-}"
  printf '%s\n' "$t"
}

# Special-case for op-node (ethereum-optimism/optimism monorepo)
fetch_opnode_version() {
  local tag
  tag="$(http_get "https://api.github.com/repos/ethereum-optimism/optimism/releases" \
    | jq -r '[.[] | select(.tag_name | startswith("op-node/"))] | sort_by(.published_at) | .[-1].tag_name | ltrimstr("op-node/v") // empty' 2>/dev/null || true)"
  if [[ -n "$tag" && "$tag" != "null" ]]; then
    printf '%s\n' "$tag"
  else
    log_verbose "Could not fetch op-node version"
    printf 'N/A\n'
  fi
}

fetch_github_release() {
  local repo="$1"
  local tag=""
  
  log_verbose "Fetching release for $repo"
  
  # Try latest release first
  if tag="$(http_get "https://api.github.com/repos/${repo}/releases/latest" \
        | jq -r '.tag_name // empty' 2>/dev/null)"; then
    if [[ -n "$tag" && "$tag" != "null" ]]; then
      normalize_tag "$tag"
      return 0
    fi
  fi
  
  # Fall back to tags
  log_verbose "No release found for $repo, trying tags"
  if tag="$(http_get "https://api.github.com/repos/${repo}/tags?per_page=100" \
        | jq -r '.[].name' 2>/dev/null | sed 's#^.*/##' | sed 's/^v//' \
        | grep -E '^[0-9]+\.[0-9]+' | sort -V | tail -n1)"; then
    if [[ -n "$tag" ]]; then
      printf '%s\n' "$tag"
      return 0
    fi
  fi
  
  log_verbose "Could not fetch version for $repo"
  printf 'N/A\n'
}

get_latest_repo_version_from_packages() {
  local package="$1"
  if [[ -z "${PACKAGES_URL-}" ]]; then 
    printf 'N/A\n'
    return 0
  fi
  
  local versions
  local fetch_cmd
  
  if [[ "${PACKAGES_URL}" == *.gz ]]; then
    fetch_cmd="curl -fsSL '${PACKAGES_URL}' | gzip -cd"
  else
    fetch_cmd="curl -fsSL '${PACKAGES_URL}'"
  fi
  
  versions="$(eval "$fetch_cmd" \
    | awk -v pkg="$package" '
      BEGIN { RS=""; FS="\n" }
      $0 ~ "^Package: "pkg"($|\n)" {
        for (i=1; i<=NF; i++) {
          if ($i ~ "^Version: ") {
            sub("^Version: ", "", $i)
            print $i
          }
        }
      }
    ' \
    | sort -V || true)"
  
  if [[ -n "$versions" ]]; then
    printf '%s\n' "$versions" | tail -n1
  else
    log_verbose "No versions found for $package in Packages index"
    printf 'N/A\n'
  fi
}

get_latest_repo_version_from_html() {
  local package="$1"
  local listing version
  
  if listing="$(curl -fsSL --max-time 20 "${BASE_URL}" 2>/dev/null)"; then
    version="$(printf '%s\n' "$listing" \
      | grep -oE "href=\"${package}_[^\"]*\.deb\"" \
      | sed 's/^href="//; s/"$//' \
      | sed -n "s/^${package}_\([^_][^_]*\)_.*/\1/p" \
      | sed 's/-[^-]*$//' \
      | sort -V \
      | tail -n1)"
    if [[ -n "$version" ]]; then
      printf '%s\n' "$version"
      return 0
    fi
  fi
  
  log_verbose "No version found for $package in HTML listing"
  printf 'N/A\n'
}

get_latest_repo_version() {
  local package="$1"
  if [[ -n "${PACKAGES_URL-}" ]]; then
    get_latest_repo_version_from_packages "$package"
  else
    get_latest_repo_version_from_html "$package"
  fi
}

compare_versions() {
  local v1="$1"
  local v2="$2"
  
  # Return codes: 0 = equal, 1 = v1 > v2, 2 = v1 < v2
  if [[ "$v1" == "$v2" ]]; then
    return 0
  fi
  
  # Use sort -V to compare versions
  if [[ "$(printf '%s\n%s\n' "$v1" "$v2" | sort -V | head -n1)" == "$v1" ]]; then
    return 2  # v1 is older
  else
    return 1  # v1 is newer
  fi
}

print_table_and_store_result() {
  local owner_repo="$1" pkg="$2" gh_ver="$3" repo_ver="$4" group_name="$5"
  local row
  
  printf -v row "| %-23s | %-15s | %-15s |\n" "$pkg" "$gh_ver" "$repo_ver"
  
  if [[ "$gh_ver" != "N/A" && "$repo_ver" != "N/A" ]]; then
    # FIX: Wrap the call in an if/else to safely capture the
    # return code (1 or 2) without triggering 'set -e'.
    local comp_result
    if compare_versions "$repo_ver" "$gh_ver"; then
      comp_result=0
    else
      comp_result=$? # Will be 1 or 2
    fi
    
    if (( comp_result == 0 || comp_result == 1 )); then
      # Up to date or newer - green
      if (( is_tty )); then printf '%s\n' "$(green "${row%$'\n'}")"; else printf '%s' "$row"; fi
    else
      # Outdated (repo < gh) - red
      if (( is_tty )); then printf '%s\n' "$(red "${row%$'\n'}")"; else printf '%s' "$row"; fi
    fi
  else
    # N/A - yellow
    if (( is_tty )); then printf '%s\n' "$(yellow "${row%$'\n'}")"; else printf '%s' "$row"; fi
  fi
  
  if [[ -n "$MARKDOWN_FILE" ]]; then
    printf '%s;%s;%s;%s;%s\n' "$group_name" "$pkg" "$repo_ver" "$gh_ver" "$owner_repo" >>"$RESULTS_TMP_FILE"
  fi
}

HAVE_WAIT_N=0
if [[ -n "${BASH_VERSINFO-}" && ${BASH_VERSINFO[0]} -ge 5 ]]; then HAVE_WAIT_N=1; fi

guard_parallel() {
  while (( $(jobs -rp | wc -l) >= MAX_PARALLEL )); do
    if (( HAVE_WAIT_N )); then
      wait -n || true
    else
      local pid
      pid="$(jobs -rp | head -n1 || true)"
      if [[ -n "$pid" ]]; then
        wait "$pid" || true
      else
        sleep 0.1
      fi
    fi
  done
}

compare_group() {
  local group_name="$1"
  local -n group_ref="$2"
  
  printf '\n===== %s =====\n\n' "$group_name"
  echo "+-------------------------+-----------------+-----------------+"
  echo "| Package                 | GitHub Version  | Repo Version    |"
  echo "+-------------------------+-----------------+-----------------+"
  
  local repo pkg gh_ver repo_ver
  local IFS=$'\n'
  local sorted_repos=($(printf '%s\n' "${!group_ref[@]}" | sort))
  unset IFS
  
  for repo in "${sorted_repos[@]}"; do
    pkg="${group_ref[$repo]}"
    guard_parallel
    (
      # Special handling for op-node
      if [[ "$repo" == "ethereum-optimism/optimism" && "$pkg" == "optimism-op-node" ]]; then
        gh_ver="$(fetch_opnode_version)"
      else
        gh_ver="$(fetch_github_release "$repo")"
      fi
      
      repo_ver="$(get_latest_repo_version "$pkg")"
      print_table_and_store_result "$repo" "$pkg" "$gh_ver" "$repo_ver" "$group_name"
    ) &
  done
  
  wait
  echo "+-------------------------+-----------------+-----------------+"
}

generate_markdown() {
  [[ -n "$MARKDOWN_FILE" ]] || return 0
  [[ -s "$RESULTS_TMP_FILE" ]] || {
    echo "No results to generate Markdown file." >&2
    return 1
  }
  
  local total=0 up_to_date=0 outdated=0 na_count=0
  
  while IFS=';' read -r _ _ repo_ver gh_ver _; do
    ((++total))
    if [[ "$gh_ver" == "N/A" || "$repo_ver" == "N/A" ]]; then
      ((++na_count))
    else
      # FIX: Wrap the call in an if/else to safely capture the
      # return code (1 or 2) without triggering 'set -e'.
      local comp_result
      if compare_versions "$repo_ver" "$gh_ver"; then
        comp_result=0
      else
        comp_result=$? # Will be 1 or 2
      fi
      
      if (( comp_result == 0 || comp_result == 1 )); then # repo_ver >= gh_ver
        ((++up_to_date))
      else # repo_ver < gh_ver
        ((++outdated))
      fi
    fi
  done < "$RESULTS_TMP_FILE"
  
  pct() {
    awk -v a="$1" -v b="$2" 'BEGIN{printf (b>0? "%.1f" : "0.0"), (a*100)/b}'
  }
  
  local p_up="$(pct "$up_to_date" "$total")"
  local p_out="$(pct "$outdated" "$total")"
  local p_na="$(pct "$na_count" "$total")"

  {
    echo "# Ethereum on ARM Package Status"
    echo
    echo "_Last updated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')_"
    echo
    echo "> **What this report compares**"
    echo "> - **GitHub Version**: latest upstream release (or highest tag if no release)."
    echo "> - **Repo Version**: latest version published in the **Ethereum on ARM APT repository**."
    echo
    echo "### Legend"
    echo "- ✅ **Up-to-date** — Repo version matches or is newer than GitHub."
    echo "- ❌ **Outdated** — Repo lags behind GitHub."
    echo "- ❓ **N/A** — Could not determine."
    echo
    echo "### Summary"
    echo "- Total packages checked: **$total**"
    echo "- ✅ Up-to-date: **$up_to_date** ($p_up%)"
    echo "- ❌ Outdated: **$outdated** ($p_out%)"
    echo "- ❓ N/A: **$na_count** ($p_na%)"
    echo
  } > "$MARKDOWN_FILE"

  local current_group=""
  sort -t';' -k1,1 -k2,2 "$RESULTS_TMP_FILE" | while IFS=';' read -r group_name pkg repo_ver gh_ver owner_repo; do
    if [[ "$group_name" != "$current_group" ]]; then
      {
        echo "### $group_name"
        echo
        echo "| Package | GitHub (Upstream) | Repo (Ethereum on ARM) | Status |"
        echo "|:--------|:-------------------|:------------------------|:------:|"
      } >> "$MARKDOWN_FILE"
      current_group="$group_name"
    fi
    
    local status="❓ N/A"
    if [[ "$gh_ver" != "N/A" && "$repo_ver" != "N/A" ]]; then
      # FIX: Wrap the call in an if/else to safely capture the
      # return code (1 or 2) without triggering 'set -e'.
      local comp_result
      if compare_versions "$repo_ver" "$gh_ver"; then
        comp_result=0
      else
        comp_result=$? # Will be 1 or 2
      fi

      if (( comp_result == 0 || comp_result == 1 )); then # repo_ver >= gh_ver
        status="✅ Up-to-date"
      else # comp_result == 2
        status="❌ Outdated"
      fi
    fi
    
    local gh_link="https://github.com/${owner_repo}"
    local gh_cell="\`${gh_ver:-N/A}\` ([${owner_repo}](${gh_link}))"
    
    printf '| `%s` | %s | `%s` | %s |%s' \
      "$pkg" "$gh_cell" "${repo_ver:-N/A}" "$status" $'\n' >> "$MARKDOWN_FILE"
  done
  
  echo
  echo "✓ Markdown report generated at $MARKDOWN_FILE"
}

# --- Package definitions ---
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
  [status-im/nimbus-eth1]=nimbus-ec
  [lambdaclass/ethrex]=ethrex
)

declare -A layer2=(
  [OffchainLabs/nitro]=arbitrum-nitro
  [ethereum-optimism/op-geth]=optimism-op-geth
  [ethereum-optimism/optimism]=optimism-op-node
  [paradigmxyz/reth]=optimism-op-reth
  [eqlabs/pathfinder]=starknet-pathfinder
  [NethermindEth/juno]=starknet-juno
  [FuelLabs/fuel-core]=fuel-network
)

declare -A infra=(
  [ethereum/staking-deposit-cli]=staking-deposit-cli
  [eth-educators/ethstaker-deposit-cli]=ethstaker-deposit-cli
  [ObolNetwork/charon]=dvt-obol
  [flashbots/mev-boost]=mev-boost
  [ethpandaops/ethereum-metrics-exporter]=ethereum-metrics-exporter
  [prometheus-community/json_exporter]=json-exporter
)

declare -A web3=(
  [ipfs/kubo]=kubo
  [ethersphere/bee]=bee
)

main() {
  echo "Starting Ethereum on ARM package version comparison..."
  echo
  
  compare_group "Layer 1 Consensus" layer1_consensus
  compare_group "Layer 1 Execution" layer1_execution
  compare_group "Layer 2" layer2
  compare_group "Infra" infra
  compare_group "Web3" web3
  
  if [[ -n "$MARKDOWN_FILE" ]]; then
    generate_markdown
  fi
  
  echo
  echo "✓ Comparison complete!"
}

main