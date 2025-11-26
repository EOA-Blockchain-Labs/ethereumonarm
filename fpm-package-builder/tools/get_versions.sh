#!/usr/bin/env bash
# Compare upstream GitHub release/tag versions with Ethereum on ARM repo versions
# and optionally generate a grouped Markdown report.
#
# Usage:
#   get_versions.sh [-t <token>] [-m <STATUS.md>] [-c <packages.json>] [-h]
#
# Options:
#   -t <token>     GitHub token (Bearer) to avoid rate limits; falls back to env GITHUB_TOKEN if not given.
#   -m <file>      Generate a Markdown status report to the specified file (e.g., STATUS.md).
#   -c <file>      Path to packages.json configuration file (default: ./packages.json).
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

readonly USER_AGENT="EthRepoComparator/1.5"
readonly API_VERSION="2022-11-28"
readonly BASE_URL="https://repo.ethereumonarm.com/pool/main/"
readonly RATE_LIMIT_SLEEP=0.5
: "${MAX_PARALLEL:=8}"

MARKDOWN_FILE=""
RESULTS_TMP_FILE=""
REPO_CACHE_FILE=""
PACKAGES_JSON="./packages.json"
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
  -c <file>       Path to packages.json configuration file (default: ./packages.json)
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
  if [[ -n "${REPO_CACHE_FILE-}" && -f "${REPO_CACHE_FILE}" ]]; then
    rm -f -- "${REPO_CACHE_FILE}"
  fi
}
trap cleanup EXIT

while getopts ":ht:m:c:" opt; do
  case "${opt}" in
    h) usage ;;
    t) GITHUB_TOKEN="${OPTARG}" ;;
    m) MARKDOWN_FILE="${OPTARG}" ;;
    c) PACKAGES_JSON="${OPTARG}" ;;
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

if [[ ! -f "$PACKAGES_JSON" ]]; then
  # Try looking in the same directory as the script
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "${SCRIPT_DIR}/packages.json" ]]; then
    PACKAGES_JSON="${SCRIPT_DIR}/packages.json"
  else
    echo "Error: packages.json not found at '$PACKAGES_JSON' or '${SCRIPT_DIR}/packages.json'" >&2
    exit 1
  fi
fi

is_tty=0
if [[ -t 1 ]]; then is_tty=1; fi
red() { if (( is_tty )); then printf '\033[1;31m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }
green() { if (( is_tty )); then printf '\033[1;32m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }
yellow() { if (( is_tty )); then printf '\033[1;33m%s\033[0m' "$*"; else printf '%s' "$*"; fi; }

if [[ -n "$MARKDOWN_FILE" ]]; then
  RESULTS_TMP_FILE="$(mktemp)"
fi

REPO_CACHE_FILE="$(mktemp)"

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

# Initialize the repository cache
init_repo_cache() {
  log_verbose "Initializing repository cache..."
  if [[ -n "${PACKAGES_URL-}" ]]; then
    if [[ "${PACKAGES_URL}" == *.gz ]]; then
      curl -fsSL "${PACKAGES_URL}" | gzip -cd > "$REPO_CACHE_FILE"
    else
      curl -fsSL "${PACKAGES_URL}" > "$REPO_CACHE_FILE"
    fi
  else
    curl -fsSL --max-time 30 "${BASE_URL}" > "$REPO_CACHE_FILE"
  fi
  
  if [[ ! -s "$REPO_CACHE_FILE" ]]; then
    echo "Warning: Failed to download repository index. All repo versions will be N/A." >&2
  else
    log_verbose "Repository cache initialized ($(wc -l < "$REPO_CACHE_FILE") lines)."
  fi
}

get_latest_repo_version_from_packages() {
  local package="$1"
  local versions
  
  versions="$(awk -v pkg="$package" '
      BEGIN { RS=""; FS="\n" }
      $0 ~ "^Package: "pkg"($|\n)" {
        for (i=1; i<=NF; i++) {
          if ($i ~ "^Version: ") {
            sub("^Version: ", "", $i)
            print $i
          }
        }
      }
    ' "$REPO_CACHE_FILE" | sort -V || true)"
  
  if [[ -n "$versions" ]]; then
    printf '%s\n' "$versions" | tail -n1
  else
    log_verbose "No versions found for $package in Packages index"
    printf 'N/A\n'
  fi
}

get_latest_repo_version_from_html() {
  local package="$1"
  local version
  
  version="$(grep -oE "href=\"${package}_[^\"]*\.deb\"" "$REPO_CACHE_FILE" \
    | sed 's/^href="//; s/"$//' \
    | sed -n "s/^${package}_\([^_][^_]*\)_.*/\1/p" \
    | sed 's/-[^-]*$//' \
    | sort -V \
    | tail -n1)"
    
  if [[ -n "$version" ]]; then
    printf '%s\n' "$version"
    return 0
  fi
  
  log_verbose "No version found for $package in HTML listing"
  printf 'N/A\n'
}

get_latest_repo_version() {
  local package="$1"
  if [[ ! -s "$REPO_CACHE_FILE" ]]; then
    printf 'N/A\n'
    return 0
  fi

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
  # We read the group from the JSON file
  
  printf '\n===== %s =====\n\n' "$group_name"
  echo "+-------------------------+-----------------+-----------------+"
  echo "| Package                 | GitHub Version  | Repo Version    |"
  echo "+-------------------------+-----------------+-----------------+"
  
  # Read repos and packages for this group from JSON
  # Output format: "repo package"
  local items
  items="$(jq -r --arg g "$group_name" '.[$g] | to_entries[] | "\(.key) \(.value)"' "$PACKAGES_JSON")"
  
  if [[ -z "$items" ]]; then
    echo "| No packages found in this group.                            |"
    echo "+-------------------------+-----------------+-----------------+"
    return
  fi

  local IFS=$'\n'
  for item in $items; do
    local repo="${item%% *}"
    local pkg="${item#* }"
    
    guard_parallel
    (
      local gh_ver repo_ver
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
  unset IFS
  
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
    echo "### Infra"
    echo
    echo "| Package | GitHub (Upstream) | Repo (Ethereum on ARM) | Status |"
    echo "|:--------|:-------------------|:------------------------|:------:|"
  } > "$MARKDOWN_FILE"

  # We need to process the results in the order of groups defined in packages.json
  # But the results file is just lines. We can read the JSON keys and then grep the results for each group.
  
  local groups
  groups="$(jq -r 'keys[]' "$PACKAGES_JSON")"
  
  local IFS=$'\n'
  for group_name in $groups; do
    # Check if we have results for this group
    if grep -q "^${group_name};" "$RESULTS_TMP_FILE"; then
       {
         echo
         echo "### $group_name"
         echo
         echo "| Package | GitHub (Upstream) | Repo (Ethereum on ARM) | Status |"
         echo "|:--------|:-------------------|:------------------------|:------:|"
       } >> "$MARKDOWN_FILE"
       
       # Filter results for this group and sort by package name
       grep "^${group_name};" "$RESULTS_TMP_FILE" | sort -t';' -k2,2 | while IFS=';' read -r _ pkg repo_ver gh_ver owner_repo; do
          local status="❓ N/A"
          if [[ "$gh_ver" != "N/A" && "$repo_ver" != "N/A" ]]; then
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
    fi
  done
  unset IFS
  
  echo
  echo "✓ Markdown report generated at $MARKDOWN_FILE"
}

main() {
  echo "Starting Ethereum on ARM package version comparison..."
  echo
  
  init_repo_cache
  
  # Get groups from JSON
  local groups
  groups="$(jq -r 'keys[]' "$PACKAGES_JSON")"
  
  local IFS=$'\n'
  for group in $groups; do
    compare_group "$group"
  done
  unset IFS
  
  if [[ -n "$MARKDOWN_FILE" ]]; then
    generate_markdown
  fi
  
  echo
  echo "✓ Comparison complete!"
}

main