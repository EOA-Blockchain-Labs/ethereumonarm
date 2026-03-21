#!/bin/bash
# node-status.sh — detects running Ethereum clients and checks sync status.
# Outputs structured lines for the agent and cron scripts to interpret.

CONSENSUS_API="http://localhost:5052/eth/v1/node/syncing"
EXECUTION_RPC="http://localhost:8545"

EL_CLIENT=""
EL_SERVICE=""
CL_CLIENT=""
CL_SERVICE=""

# ── Execution clients ─────────────────────────────────────────────────────────
EL_CLIENTS="geth nethermind erigon erigon-archive besu reth"
for base in $EL_CLIENTS; do
    for suffix in "" "-hoodi" "-sepolia"; do
        svc="${base}${suffix}"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            EL_CLIENT="$base"
            EL_SERVICE="$svc"
            break 2
        fi
    done
done

# ── Consensus clients ─────────────────────────────────────────────────────────
CL_CLIENTS="lighthouse prysm nimbus teku lodestar grandine"
for base in $CL_CLIENTS; do
    for suffix in "-beacon" "-beacon-mev" "-beacon-hoodi" "-beacon-hoodi-mev" "-beacon-sepolia" "-beacon-sepolia-mev"; do
        svc="${base}${suffix}"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            CL_CLIENT="$base"
            CL_SERVICE="$svc"
            break 2
        fi
    done
done

# ── Determine network from service name ───────────────────────────────────────
NETWORK="mainnet"
if echo "$EL_SERVICE" | grep -q "\-hoodi"; then
    NETWORK="hoodi"
elif echo "$EL_SERVICE" | grep -q "\-sepolia"; then
    NETWORK="sepolia"
fi

# ── Determine MEV from service name ───────────────────────────────────────────
MEV="no"
if echo "$CL_SERVICE" | grep -q "\-mev"; then
    MEV="yes"
fi

echo "=== Running Ethereum Clients ==="
echo "Execution client : ${EL_CLIENT:-none} (${EL_SERVICE:-none})"
echo "Consensus client : ${CL_CLIENT:-none} (${CL_SERVICE:-none})"
echo "Network          : $NETWORK"
echo "MEV Boost        : $MEV"

# ── Determine STATUS ──────────────────────────────────────────────────────────
if [ -z "$EL_CLIENT" ] && [ -z "$CL_CLIENT" ]; then
    echo "STATUS           : STOPPED — no Ethereum clients running"
    exit 0
elif [ -z "$EL_CLIENT" ] || [ -z "$CL_CLIENT" ]; then
    echo "STATUS           : INCOMPLETE — one client is running without its pair"
    exit 0
fi

echo "STATUS           : RUNNING"

# ── Sync status — only if both clients are running ────────────────────────────
echo ""
echo "=== Sync Status ==="

el_syncing() {
    local result
    result=$(curl -s -X POST "$EXECUTION_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        2>/dev/null | python3 -c "
import sys, json
try:
    r = json.load(sys.stdin).get('result', True)
    print('false' if r is False else 'true')
except:
    print('true')
")

    if [ "$result" = "false" ]; then
        BLOCK=$(curl -s -X POST "$EXECUTION_RPC" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['result'], 16))
except:
    print(0)
")
        if [ "$BLOCK" -lt 1000 ] 2>/dev/null; then
            echo "true"
            return
        fi
    fi
    echo "$result"
}

cl_syncing() {
    curl -s "$CONSENSUS_API" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    is_syncing = data['data']['is_syncing']
    sync_distance = int(data['data'].get('sync_distance', 0))
    head_slot = int(data['data'].get('head_slot', 0))
    print(str(is_syncing).lower())
    print('sync_distance=' + str(sync_distance))
    print('head_slot=' + str(head_slot))
except:
    print('true')
    print('sync_distance=unknown')
    print('head_slot=unknown')
"
}

el_block() {
    curl -s -X POST "$EXECUTION_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['result'], 16))
except:
    print('unknown')
"
}

el_peers() {
    curl -s -X POST "$EXECUTION_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['result'], 16))
except:
    print('unknown')
"
}

EL_SYNC=$(el_syncing)
CL_SYNC_RAW=$(cl_syncing)
CL_SYNC=$(echo "$CL_SYNC_RAW" | head -1)
CL_DISTANCE=$(echo "$CL_SYNC_RAW" | grep sync_distance | cut -d= -f2)
CL_HEAD=$(echo "$CL_SYNC_RAW" | grep head_slot | cut -d= -f2)
EL_BLOCK=$(el_block)
EL_PEERS=$(el_peers)

echo "Execution client : $([ "$EL_SYNC" = "false" ] && echo "SYNCED" || echo "SYNCING") — block $EL_BLOCK — peers $EL_PEERS"
echo "Consensus client : $([ "$CL_SYNC" = "false" ] && echo "SYNCED" || echo "SYNCING") — head slot $CL_HEAD — distance $CL_DISTANCE slots"

if [ "$EL_SYNC" = "false" ] && [ "$CL_SYNC" = "false" ]; then
    echo "SYNC_STATUS      : SYNCED — both clients are fully synced"
elif [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "true" ]; then
    echo "SYNC_STATUS      : SYNCING — both clients are still syncing"
elif [ "$EL_SYNC" = "false" ] && [ "$CL_SYNC" = "true" ]; then
    echo "SYNC_STATUS      : SYNCING — EL synced, CL still catching up ($CL_DISTANCE slots behind)"
elif [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "false" ]; then
    echo "SYNC_STATUS      : SYNCING — CL synced, EL still catching up (block $EL_BLOCK)"
fi
