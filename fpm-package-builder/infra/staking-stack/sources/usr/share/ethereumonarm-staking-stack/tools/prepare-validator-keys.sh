#!/bin/bash
# =============================================================================
# prepare-validator-keys.sh — Rename validator keystores to Obol format.
#
# Obol's charon create cluster --split-existing-keys expects keystores named
# keystore-N.json with a matching keystore-N.txt containing the password.
#
# This script renames all existing keystore files in a directory to this
# format and creates the corresponding password files.
#
# Usage:
#   bash prepare-validator-keys.sh
#   bash prepare-validator-keys.sh --keys-dir /home/ethereum/validator_keys
# =============================================================================
set -euo pipefail

KEYS_DIR=""

SEP="────────────────────────────────────────────"

usage() {
    cat << 'EOF'
Usage: bash prepare-validator-keys.sh [OPTIONS]

Options:
  --keys-dir <path>   Directory containing keystore .json files
  --help              Show this help
EOF
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --keys-dir) KEYS_DIR="$2"; shift 2 ;;
        --help|-h)  usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

echo ""
echo "$SEP"
echo "  Obol Validator Key Preparation"
echo "$SEP"
echo ""

# Ask for keys dir if not provided
if [ -z "$KEYS_DIR" ]; then
    echo "  Enter the directory containing your validator keystore files."
    echo "  Default: /home/ethereum/validator_keys"
    echo ""
    read -rp "  Keys directory [/home/ethereum/validator_keys]: " KEYS_DIR
    KEYS_DIR="${KEYS_DIR:-/home/ethereum/validator_keys}"
fi

if [ ! -d "$KEYS_DIR" ]; then
    echo "ERROR: Directory not found: $KEYS_DIR" >&2
    exit 1
fi

# Count existing keystores
KEYSTORE_COUNT=$(find "$KEYS_DIR" -maxdepth 1 -name "*.json" ! -name "keystore-*.json" 2>/dev/null | wc -l)
ALREADY_NAMED=$(find "$KEYS_DIR" -maxdepth 1 -name "keystore-*.json" 2>/dev/null | wc -l)

echo "  Directory  : $KEYS_DIR"
echo "  JSON files : $(find "$KEYS_DIR" -maxdepth 1 -name "*.json" | wc -l) total"
echo "               $ALREADY_NAMED already in keystore-N.json format"
echo "               $KEYSTORE_COUNT to rename"
echo ""

if [ "$KEYSTORE_COUNT" -eq 0 ] && [ "$ALREADY_NAMED" -eq 0 ]; then
    echo "ERROR: No keystore JSON files found in $KEYS_DIR" >&2
    exit 1
fi

# Ask for password
echo "  Enter the keystore password."
echo "  (All keystores must share the same password for this script.)"
echo "  For keystores with different passwords use --password-file per keystore."
echo ""
read -rsp "  Password: " KEYSTORE_PASS
echo ""

if [ -z "$KEYSTORE_PASS" ]; then
    echo "ERROR: Password cannot be empty." >&2
    exit 1
fi

read -rsp "  Confirm password: " KEYSTORE_PASS_CONFIRM
echo ""

if [ "$KEYSTORE_PASS" != "$KEYSTORE_PASS_CONFIRM" ]; then
    echo "ERROR: Passwords do not match." >&2
    exit 1
fi

echo ""
echo "--- Renaming keystores ---"

# Step 1: rename all keystore-*.json files to a temp name to avoid collisions
# then rename to keystore-N.json sequentially
cd "$KEYS_DIR"

# Collect all .json files (not already correctly named ones are renamed,
# already-named ones keep their sequence and we continue from the last index)
i=0

# First pass: rename any non-standard names to keystore-N.json
for f in *.json; do
    [ -f "$f" ] || continue
    # Skip files already in keystore-N.json format
    if echo "$f" | grep -qE '^keystore-[0-9]+\.json$'; then
        # Extract number to track highest index
        num=$(echo "$f" | grep -oE '[0-9]+')
        [ "$num" -ge "$i" ] && i=$(( num + 1 ))
    fi
done

RENAMED=0
for f in *.json; do
    [ -f "$f" ] || continue
    if ! echo "$f" | grep -qE '^keystore-[0-9]+\.json$'; then
        new_name="keystore-${i}.json"
        mv "$f" "$new_name"
        echo "  $f → $new_name"
        (( i++ )) || true
        (( RENAMED++ )) || true
    fi
done

# Step 2: create password files for all keystore-N.json files
echo ""
echo "--- Creating password files ---"
CREATED=0
for f in keystore-*.json; do
    [ -f "$f" ] || continue
    base="${f%.json}"
    pass_file="${base}.txt"
    if [ ! -f "$pass_file" ]; then
        echo "$KEYSTORE_PASS" > "$pass_file"
        echo "  ✅ $pass_file"
        (( CREATED++ )) || true
    else
        echo "  [SKIP] $pass_file — already exists"
    fi
done

echo ""
echo "$SEP"
echo "  Done"
echo "  Renamed   : $RENAMED keystore file(s)"
echo "  Passwords : $CREATED password file(s) created"
echo ""
echo "  Directory contents:"
ls -1 "$KEYS_DIR" | sed 's/^/    /'
echo ""
echo "  Your keystores are ready for:"
echo "  charon create cluster --split-existing-keys \\"
echo "    --split-keys-dir=$KEYS_DIR ..."
echo "$SEP"
