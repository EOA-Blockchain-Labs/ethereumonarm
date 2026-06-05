#!/bin/bash
# =============================================================================
# check-updates.sh — Alert when APT packages for RUNNING clients have updates.
#
# Only checks clients actually running on this node, determined from node.env:
#   EL_CLIENT  → execution client package (geth | nethermind | erigon | besu | reth | ethrex)
#   CL_CLIENT  → consensus client package (lighthouse | prysm | nimbus | teku | lodestar | grandine)
#   MEV_SERVICE → mev-boost (checked if set)
#   obol nodes  → dvt-obol (charon)
#
# Package names confirmed from https://repo.ethereumonarm.com/pool/main/
#
# Lock key: pkg-update-<package>-<new_version>
#   Fires once per available version. Clears naturally when package is installed
#   (old lock key never written again, expires after LOCK_EXPIRY).
#
# Deploy to : /home/ethereum/.obol-monitor/scripts/check-updates.sh
# Crontab   : 0 9 * * * (daily at 09:00)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="${CONF:-/home/ethereum/.obol-monitor/conf/node.env}"

if [ ! -f "$CONF" ]; then
    echo "ERROR: conf not found at $CONF" >&2
    exit 1
fi

. "$CONF"
. "${SCRIPT_DIR}/../lib/common.sh"

TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "=== check-updates — ${TS} ==="
echo "Node type  : ${NODE_TYPE:-unknown}"
echo "EL client  : ${EL_CLIENT:-unknown}"
echo "CL client  : ${CL_CLIENT:-unknown}"
echo ""

# =============================================================================
# check_package <package_name> <label> <icon>
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

    # Verify candidate is actually newer
    local newer
    newer=$(printf '%s\n%s\n' "$installed" "$candidate" | sort -V | tail -n1)
    if [ "$newer" != "$candidate" ]; then
        echo "  ✅ $pkg — installed (${installed}) >= candidate (${candidate})"
        return 0
    fi

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
# Refresh APT index
# =============================================================================
echo "--- Refreshing APT index ---"
if sudo apt-get update -qq 2>/dev/null; then
    echo "  ✅ APT index refreshed"
else
    echo "  ⚠️  apt-get update failed — using cached index"
fi
echo ""

# =============================================================================
# Check only the clients running on this node
# =============================================================================
echo "--- Execution Layer: ${EL_CLIENT:-not set} ---"
if [ -n "${EL_CLIENT:-}" ]; then
    check_package "${EL_CLIENT}" "${EL_CLIENT} (Execution Layer)" "⚙️"
else
    echo "  [SKIP] EL_CLIENT not set in node.env"
fi
echo ""

echo "--- Consensus Layer: ${CL_CLIENT:-not set} ---"
if [ -n "${CL_CLIENT:-}" ]; then
    check_package "${CL_CLIENT}" "${CL_CLIENT} (Consensus Layer)" "🔦"
else
    echo "  [SKIP] CL_CLIENT not set in node.env"
fi
echo ""

echo "--- MEV-Boost ---"
if [ -n "${MEV_SERVICE:-}" ]; then
    check_package "mev-boost" "MEV-Boost" "💰"
else
    echo "  [SKIP] MEV_SERVICE not set in node.env"
fi
echo ""

if [ "${NODE_TYPE:-}" = "obol" ]; then
    echo "--- Charon DVT ---"
    check_package "dvt-obol" "Charon DVT (dvt-obol)" "🔗"
    echo ""
fi

echo "=== check-updates done ==="