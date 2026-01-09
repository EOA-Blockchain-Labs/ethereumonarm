#!/usr/bin/env bash
# Fetch changelog for a package and output in a specific format
# Usage: ./get_changelog.sh <package_name>

set -euo pipefail

PACKAGES_JSON="./packages.json"
GITHUB_TOKEN="${GITHUB_TOKEN-}"

while getopts ":t:" opt; do
    case "${opt}" in
    t) GITHUB_TOKEN="${OPTARG}" ;;
    *)
        echo "Usage: $0 [-t <token>] <package_name>" >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [-t <token>] <package_name>" >&2
    exit 1
fi

PACKAGE_NAME="$1"

# Locate packages.json
if [[ ! -f "$PACKAGES_JSON" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "${SCRIPT_DIR}/packages.json" ]]; then
        PACKAGES_JSON="${SCRIPT_DIR}/packages.json"
    else
        echo "Error: packages.json not found." >&2
        exit 1
    fi
fi

# Find repo for package
REPO_NAME="$(jq -r --arg pkg "$PACKAGE_NAME" 'to_entries[] | .value | to_entries[] | select(.value == $pkg) | .key' "$PACKAGES_JSON")"

if [[ -z "$REPO_NAME" ]]; then
    echo "Error: Package '$PACKAGE_NAME' not found in packages.json." >&2
    exit 1
fi

# Fetch latest release
API_URL="https://api.github.com/repos/${REPO_NAME}/releases/latest"
HEADERS=(-H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")

if [[ -n "$GITHUB_TOKEN" ]]; then
    HEADERS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

RELEASE_JSON="$(curl -fsSL "${HEADERS[@]}" "$API_URL")"
BODY="$(echo "$RELEASE_JSON" | jq -r '.body')"

# Output in requested format
# Prepare output
OUTPUT="name $PACKAGE_NAME

changelog
$BODY"

# Print to stdout
echo "$OUTPUT"

# Copy to clipboard if possible
if command -v pbcopy >/dev/null 2>&1; then
    echo "$OUTPUT" | pbcopy
    echo >&2
    echo "✓ Output copied to clipboard." >&2
elif command -v xclip >/dev/null 2>&1; then
    echo "$OUTPUT" | xclip -selection clipboard
    echo >&2
    echo "✓ Output copied to clipboard." >&2
fi
