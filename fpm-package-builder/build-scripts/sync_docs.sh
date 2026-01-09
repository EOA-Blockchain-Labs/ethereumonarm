#!/usr/bin/env bash
# Sync documentation between RST files (source of truth) and README.Debian files.
#
# Usage:
#   sync_docs.sh [--dry-run] [--package <name>]
#
# Options:
#   --dry-run           Show what would be changed without making changes
#   --package <name>    Sync only the specified package (e.g., "geth", "lighthouse")
#   --list              List all package mappings
#   --help              Show this help message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FPM_DIR="${PROJECT_ROOT}/fpm-package-builder"
DOCS_DIR="${PROJECT_ROOT}/docs/packages"

DRY_RUN=false
PACKAGE_FILTER=""
LIST_MODE=false

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    sed -n '2,12p' "$0" | sed 's/^# //'
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run)
        DRY_RUN=true
        shift
        ;;
    --package)
        PACKAGE_FILTER="$2"
        shift 2
        ;;
    --list)
        LIST_MODE=true
        shift
        ;;
    --help | -h) usage ;;
    *)
        echo "Unknown option: $1" >&2
        usage
        ;;
    esac
done

# Define package mappings: "rst_path|readme_path"
# RST path is relative to docs/packages/
# README path is relative to fpm-package-builder/
declare -a PACKAGE_MAPPINGS=(
    # L1 Execution Layer
    "l1/geth.rst|l1-clients/execution-layer/geth/sources/usr/share/doc/geth/README.Debian"
    "l1/besu.rst|l1-clients/execution-layer/besu/sources/usr/share/doc/besu/README.Debian"
    "l1/erigon.rst|l1-clients/execution-layer/erigon/sources/usr/share/doc/erigon/README.Debian"
    "l1/ethrex.rst|l1-clients/execution-layer/ethrex/sources/usr/share/doc/ethrex/README.Debian"
    "l1/nethermind.rst|l1-clients/execution-layer/nethermind/sources/usr/share/doc/nethermind/README.Debian"
    "l1/nimbus-execution.rst|l1-clients/execution-layer/nimbus-ec/sources/usr/share/doc/nimbus-execution/README.Debian"
    "l1/reth.rst|l1-clients/execution-layer/reth/sources/usr/share/doc/reth/README.Debian"

    # L1 Consensus Layer
    "l1/grandine.rst|l1-clients/consensus-layer/grandine/sources/usr/share/doc/grandine/README.Debian"
    "l1/lighthouse.rst|l1-clients/consensus-layer/lighthouse/sources/usr/share/doc/lighthouse/README.Debian"
    "l1/lodestar.rst|l1-clients/consensus-layer/lodestar/sources/usr/share/doc/lodestar/README.Debian"
    "l1/nimbus.rst|l1-clients/consensus-layer/nimbus/sources/usr/share/doc/nimbus/README.Debian"
    "l1/prysm.rst|l1-clients/consensus-layer/prysm/sources/usr/share/doc/prysm/README.Debian"
    "l1/teku.rst|l1-clients/consensus-layer/teku/sources/usr/share/doc/teku/README.Debian"

    # L2 Clients
    "l2/nitro.rst|l2-clients/arbitrum/sources/usr/share/doc/nitro/README.Debian"
    "l2/ethrex-l2.rst|l2-clients/ethrex-l2/sources/usr/share/doc/ethrex-l2/README.Debian"
    "l2/fuel.rst|l2-clients/fuel/sources/usr/share/doc/fuel/README.Debian"
    "l2/cannon.rst|l2-clients/optimism-base/cannon/README.Debian"
    "l2/op-challenger.rst|l2-clients/optimism-base/op-challenger/README.Debian"
    "l2/op-geth.rst|l2-clients/optimism-base/op-geth/sources/usr/share/doc/op-geth/README.Debian"
    "l2/op-node.rst|l2-clients/optimism-base/op-node/sources/usr/share/doc/op-node/README.Debian"
    "l2/op-program.rst|l2-clients/optimism-base/op-program/README.Debian"
    "l2/op-reth.rst|l2-clients/optimism-base/op-reth/sources/usr/share/doc/op-reth/README.Debian"
    "l2/juno.rst|l2-clients/starknet/juno/sources/usr/share/doc/juno/README.Debian"
    "l2/madara.rst|l2-clients/starknet/madara/sources/usr/share/doc/madara/README.Debian"
    "l2/pathfinder.rst|l2-clients/starknet/pathfinder/sources/usr/share/doc/pathfinder/README.Debian"

    # DVT
    "dvt/dvt-obol.rst|infra/dvt/obol/sources/usr/share/doc/dvt-obol/README.Debian"
    "dvt/ssv-node.rst|infra/dvt/ssv/sources/usr/share/doc/ssv-node/README.Debian"

    # Infra
    "infra/commit-boost.rst|infra/commit-boost/sources/usr/share/doc/commit-boost/README.Debian"
    "infra/mev-boost.rst|infra/mev-boost/sources/usr/share/doc/mev-boost/README.Debian"
    "l1/vero.rst|infra/vero/sources/usr/share/doc/vero/README.Debian"
    "l1/vouch.rst|infra/vouch/sources/usr/share/doc/vouch/README.Debian"

    # Utils (infra category in docs)
    "infra/ethereum-metrics-exporter.rst|utils/ethereum-metrics-exporter/sources/usr/share/doc/ethereum-metrics-exporter/README.Debian"
    "infra/ethereum-validator-metrics-exporter.rst|utils/ethereum-validator-metrics-exporter/sources/usr/share/doc/ethereum-validator-metrics-exporter/README.Debian"
    "infra/ethereumonarm-config-sync.rst|utils/ethereumonarm-config-sync/sources/usr/share/doc/ethereumonarm-config-sync/README.Debian"
    "infra/ethereumonarm-monitoring-extras.rst|utils/ethereumonarm-monitoring-extras/sources/usr/share/doc/ethereumonarm-monitoring-extras/README.Debian"
    "infra/ethereumonarm-nginx-proxy-extras.rst|utils/ethereumonarm-nginx-proxy-extras/sources/usr/share/doc/ethereumonarm-nginx-proxy-extras/README.Debian"
    "infra/ethereumonarm-utils.rst|utils/ethereumonarm-utils/sources/usr/share/doc/ethereumonarm-utils/README.Debian"

    # Tools
    "tools/ethstaker-deposit-cli.rst|tools/ethstaker-deposit/sources/usr/share/doc/ethstaker-deposit-cli/README.Debian"
    "tools/ls-lido.rst|tools/liquid-staking/lido/sources/usr/share/doc/ls-lido/README.Debian"
    "tools/merge-config.rst|tools/merge-config/sources/usr/share/doc/merge-config/README.Debian"
    "tools/stakewise-operator.rst|tools/stakewise-operator/sources/usr/share/doc/stakewise-operator/README.Debian"

    # Web3
    "web3/bee.rst|web3/swarm/sources/usr/share/doc/bee/README.Debian"
    "web3/kubo.rst|web3/kubo/sources/usr/share/doc/kubo/README.Debian"
    "infra/statusd.rst|web3/status/sources/usr/share/doc/statusd/README.Debian"
)

# Convert RST to README.Debian format
rst_to_readme() {
    local content="$1"

    # Convert double backticks to single backticks using bash parameter expansion
    content="${content//\`\`/\`}"

    # Output the converted content
    printf '%s' "$content"
}

# List all mappings
list_mappings() {
    echo -e "${BLUE}Package Mappings (${#PACKAGE_MAPPINGS[@]} total):${NC}"
    echo ""
    printf "%-35s | %-60s\n" "RST File" "README.Debian"
    printf "%-35s | %-60s\n" "-----------------------------------" "------------------------------------------------------------"
    for mapping in "${PACKAGE_MAPPINGS[@]}"; do
        rst_rel="${mapping%%|*}"
        readme_rel="${mapping##*|}"
        printf "%-35s | %-60s\n" "$rst_rel" "$readme_rel"
    done
}

# Check if files differ (ignoring backtick formatting)
files_differ() {
    local rst_file="$1"
    local readme_file="$2"

    # Normalize both files and compare
    local rst_normalized readme_normalized
    rst_normalized=$(rst_to_readme "$(cat "$rst_file")")
    readme_normalized=$(cat "$readme_file")

    if [[ "$rst_normalized" != "$readme_normalized" ]]; then
        return 0 # Files differ
    fi
    return 1 # Files are the same
}

# Sync a single package
sync_package() {
    local rst_rel="$1"
    local readme_rel="$2"

    local rst_file="${DOCS_DIR}/${rst_rel}"
    local readme_file="${FPM_DIR}/${readme_rel}"

    # Check if both files exist
    if [[ ! -f "$rst_file" ]]; then
        echo -e "${YELLOW}⚠ RST file not found: $rst_rel${NC}"
        return 1
    fi

    if [[ ! -f "$readme_file" ]]; then
        echo -e "${YELLOW}⚠ README.Debian not found: $readme_rel${NC}"
        return 1
    fi

    # Convert and compare
    local converted_content
    converted_content=$(rst_to_readme "$(cat "$rst_file")")

    if files_differ "$rst_file" "$readme_file"; then
        echo -e "${BLUE}→ Syncing: ${rst_rel} → ${readme_rel}${NC}"

        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}  [DRY-RUN] Would update README.Debian${NC}"
            echo "  Differences:"
            diff --color=always <(cat "$readme_file") <(echo "$converted_content") | head -20 || true
        else
            echo "$converted_content" >"$readme_file"
            echo -e "${GREEN}  ✓ Updated${NC}"
        fi
        return 0
    else
        echo -e "${GREEN}✓ In sync: ${rst_rel}${NC}"
        return 0
    fi
}

# Main execution
main() {
    if [[ "$LIST_MODE" == true ]]; then
        list_mappings
        exit 0
    fi

    echo -e "${BLUE}Documentation Sync Tool${NC}"
    echo -e "${BLUE}=======================${NC}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}Running in DRY-RUN mode - no changes will be made${NC}"
        echo ""
    fi

    local synced=0
    local errors=0

    for mapping in "${PACKAGE_MAPPINGS[@]}"; do
        rst_rel="${mapping%%|*}"
        readme_rel="${mapping##*|}"

        # Filter by package if specified
        if [[ -n "$PACKAGE_FILTER" ]]; then
            if [[ "$rst_rel" != *"$PACKAGE_FILTER"* && "$readme_rel" != *"$PACKAGE_FILTER"* ]]; then
                continue
            fi
        fi

        if sync_package "$rst_rel" "$readme_rel"; then
            ((synced++))
        else
            ((errors++))
        fi
    done

    echo ""
    echo -e "${BLUE}Summary:${NC}"
    echo -e "  Processed: $synced"
    echo -e "  Errors: $errors"

    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo -e "${YELLOW}Run without --dry-run to apply changes${NC}"
    fi
}

main
