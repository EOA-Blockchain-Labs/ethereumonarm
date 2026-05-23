#!/bin/bash
# =============================================================================
# check-updates.sh — Alert when Ethereum on ARM APT packages have new versions.
#
# Checks ALL consensus and execution clients available in the repo, plus MEV-Boost
# and Charon (obol nodes only). An alert fires once per available version and
# clears naturally when the package is installed (old lock key becomes stale).
#
# Package names confirmed from https://repo.ethereumonarm.com/pool/main/
#
# Consensus : lighthouse prysm nimbus teku lodestar grandine
# Execution : geth nethermind erigon besu reth ethrex
# MEV       : mev-boost
# DVT       : dvt-obol  (obol nodes only)
#
# Deploy to : /home/ethereum/.obol-monitor/scripts/check-updates.sh
# Crontab   : 0 9 * * * (daily at 09:00)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="${SCRIPT_DIR}/../conf/node.env"

if [ ! -f "$CONF" ]; then
    echo "ERROR: conf not found at $CONF" >&2
    exit 1
fi

. "$CONF"
. "${SCRIPT_DIR}/../lib/common.sh"

TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "=== check-updates — ${TS} ==="
echo "Node type : ${NODE_TYPE:-unknown}"
echo ""

# =============================================================================
# check_package <package_name> <label> <icon>
#
# Uses apt-cache policy to compare installed vs candidate version.
# Fires a lock_alert keyed by package + new version — fires once per available
# version, and clears naturally when the package is installed (the candidate
# version changes so the old lock key is never written again).
# No sudo required: apt-cache policy reads the cached APT index.
# =============================================================================
check_package() {
    local pkg="$1"
    local label="$2"
    local icon="${3:-📦}"

    local policy
    policy=$(apt-cache policy "$pkg" 2>/dev/null)

    if [ -z "$policy" ]; then
        echo "  [SKIP] $pkg — not found in APT index"
        return 0
    fi

    local installed candidate
    installed=$(echo "$policy" | awk '/Installed:/ {print $2; exit}')
    candidate=$(echo "$policy" | awk '/Candidate:/ {print $2; exit}')

    if [ "${installed:-}" = "(none)" ] || [ -z "${installed:-}" ]; then
        echo "  [SKIP] $pkg — not installed"
        return 0
    fi

    if [ -z "${candidate:-}" ] || [ "${candidate:-}" = "(none)" ]; then
        echo "  [SKIP] $pkg — no candidate version available"
        return 0
    fi

    echo "  $pkg: installed=${installed}  candidate=${candidate}"

    if [ "$candidate" = "$installed" ]; then
        echo "  ✅ $pkg is up to date"
        return 0
    fi

    # Verify candidate is actually newer (guard against downgrades)
    local newer
    newer=$(printf '%s\n%s\n' "$installed" "$candidate" | sort -V | tail -n1)
    if [ "$newer" != "$candidate" ]; then
        echo "  ✅ $pkg — installed (${installed}) >= candidate (${candidate}), skipping"
        return 0
    fi

    # New version available — lock key is version-specific
    lock_alert "pkg-update-${pkg}-${candidate}" "$(node_label)
📦 <b>${label} update available</b>

Package  : <code>${pkg}</code>
Installed: <b>${installed}</b>
Available: <b>${candidate}</b>

A new version is available in the Ethereum on ARM APT repository.

To update:
<code>sudo apt update && sudo apt install ${pkg}</code>

⚠️ Always check the release notes before updating a staking client."
}

# =============================================================================
# Update APT index first so candidates reflect the latest repo state.
# Requires sudo — if this fails (e.g. not in sudoers without password),
# the script falls back to the cached index which is usually recent enough.
# =============================================================================
echo "--- Refreshing APT index ---"
if sudo apt-get update -qq 2>/dev/null; then
    echo "  ✅ APT index refreshed"
else
    echo "  ⚠️  apt-get update failed — using cached index"
fi
echo ""

# =============================================================================
# Consensus Layer clients — check all, regardless of which is active.
# Alerts only fire for installed packages (apt-cache policy skips not-installed).
# =============================================================================
echo "--- Consensus Layer clients ---"
check_package "lighthouse" "Lighthouse (Consensus Layer)" "🔦"
check_package "prysm"      "Prysm (Consensus Layer)"      "🔷"
check_package "nimbus"     "Nimbus (Consensus Layer)"      "🐢"
check_package "teku"       "Teku (Consensus Layer)"        "☕"
check_package "lodestar"   "Lodestar (Consensus Layer)"    "⭐"
check_package "grandine"   "Grandine (Consensus Layer)"    "🦀"
echo ""

# =============================================================================
# Execution Layer clients — check all installed ones.
# =============================================================================
echo "--- Execution Layer clients ---"
check_package "geth"        "Geth (Execution Layer)"        "🐹"
check_package "nethermind"  "Nethermind (Execution Layer)"  "💠"
check_package "erigon"      "Erigon (Execution Layer)"      "🌀"
check_package "besu"        "Besu (Execution Layer)"        "☕"
check_package "reth"        "Reth (Execution Layer)"        "🦀"
check_package "ethrex"      "Ethrex (Execution Layer)"      "🔶"
echo ""

# =============================================================================
# MEV-Boost — all node types
# =============================================================================
echo "--- MEV-Boost ---"
check_package "mev-boost" "MEV-Boost" "💰"
echo ""

# =============================================================================
# Charon / DVT — obol nodes only
# =============================================================================
if [ "${NODE_TYPE:-}" = "obol" ]; then
    echo "--- Charon DVT ---"
    check_package "dvt-obol" "Charon DVT (dvt-obol)" "🔗"
    echo ""
fi

echo "=== check-updates done ==="
