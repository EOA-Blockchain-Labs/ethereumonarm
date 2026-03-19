#!/bin/bash
# Checks sync status of both running consensus and execution clients.
# Reads running-clients.sh first to know which clients and network are active.

EL_RPC="http://localhost:8545"
CL_API="http://localhost:5052"

# --- Get current running state ---
RUNNING=$(bash "$(dirname "$0")/running-clients.sh")
echo "$RUNNING"
echo ""

# Bail out if nothing is running
if echo "$RUNNING" | grep -q "STATUS          : STOPPED"; then
  echo "=== Sync Status ==="
  echo "No ethereum clients running — nothing to check."
  exit 0
fi

if echo "$RUNNING" | grep -q "STATUS          : INCOMPLETE"; then
  echo "=== Sync Status ==="
  echo "Node is incomplete — both a consensus and execution client must be running."
  exit 0
fi

# Extract context from running-clients output
NETWORK=$(echo "$RUNNING" | awk -F': ' '/^Network/ {print $2}' | xargs)
CL_SERVICE=$(echo "$RUNNING" | awk -F': ' '/^Consensus client/ {print $2}' | xargs)
EL_SERVICE=$(echo "$RUNNING" | awk -F': ' '/^Execution client/ {print $2}' | xargs)
MEV=$(echo "$RUNNING" | awk -F': ' '/^MEV Boost/ {print $2}' | xargs)

echo "=== Ethereum Node Sync Status ==="
echo "Network         : $NETWORK"
echo "Consensus client: $CL_SERVICE"
echo "Execution client: $EL_SERVICE"
echo "MEV Boost       : $MEV"

# --- Execution Layer ---
echo ""
echo "--- Execution Layer ---"
EL_RESPONSE=$(curl -s --max-time 5 -X POST "$EL_RPC" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' 2>/dev/null)

if [ -z "$EL_RESPONSE" ]; then
  echo "Status : UNREACHABLE (is $EL_SERVICE running?)"
else
  IS_EL_SYNCING=$(echo "$EL_RESPONSE" | python3 -c "import sys,json; r=json.load(sys.stdin).get('result'); print('false' if r is False else 'syncing')" 2>/dev/null)

  if [ "$IS_EL_SYNCING" = "false" ]; then
    CURRENT_BLOCK=$(curl -s --max-time 5 -X POST "$EL_RPC" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' 2>/dev/null | python3 -c "import sys,json; print(int(json.load(sys.stdin)['result'],16))" 2>/dev/null)
    echo "Status        : SYNCED ✅"
    echo "Current block : $CURRENT_BLOCK"
  else
    CURRENT=$(echo "$EL_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin)['result']; print(int(d['currentBlock'],16))" 2>/dev/null)
    HIGHEST=$(echo "$EL_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin)['result']; print(int(d['highestBlock'],16))" 2>/dev/null)
    BEHIND=$((HIGHEST - CURRENT))
    echo "Status        : SYNCING ⏳"
    echo "Current block : $CURRENT"
    echo "Highest block : $HIGHEST"
    echo "Blocks behind : $BEHIND"
  fi
fi

# --- Consensus Layer ---
echo ""
echo "--- Consensus Layer ---"
CL_RESPONSE=$(curl -s --max-time 5 "$CL_API/eth/v1/node/syncing" 2>/dev/null)

if [ -z "$CL_RESPONSE" ]; then
  echo "Status : UNREACHABLE (is $CL_SERVICE running?)"
else
  IS_SYNCING=$(echo "$CL_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['is_syncing'])" 2>/dev/null)
  HEAD_SLOT=$(echo "$CL_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['head_slot'])" 2>/dev/null)
  SYNC_DIST=$(echo "$CL_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['sync_distance'])" 2>/dev/null)

  if [ "$IS_SYNCING" = "False" ]; then
    echo "Status      : SYNCED ✅"
    echo "Head slot   : $HEAD_SLOT"
  else
    echo "Status      : SYNCING ⏳"
    echo "Head slot   : $HEAD_SLOT"
    echo "Slots behind: $SYNC_DIST"
  fi
fi

# --- Summary ---
echo ""
echo "=== Summary ==="

EL_SYNCED=false
CL_SYNCED=false

echo "$EL_RESPONSE" | grep -q '"result":false' && EL_SYNCED=true
[ "$IS_SYNCING" = "False" ] && CL_SYNCED=true

if [ "$EL_SYNCED" = "true" ] && [ "$CL_SYNCED" = "true" ]; then
  echo "NODE FULLY SYNCED ✅"
  echo "Network         : $NETWORK"
  echo "Consensus client: $CL_SERVICE"
  echo "Execution client: $EL_SERVICE"

elif [ "$EL_SYNCED" = "false" ] && [ "$CL_SYNCED" = "true" ]; then
  echo "NODE PARTIALLY SYNCED ⏳ — consensus synced, execution still catching up"
  echo "This is normal on first sync — the EL syncs after the CL."
  echo "Network         : $NETWORK"
  echo "EL current block: ${CURRENT:-unknown}"
  echo "EL highest block: ${HIGHEST:-unknown}"
  echo "EL blocks behind: ${BEHIND:-unknown}"
  echo "CL head slot    : $HEAD_SLOT"

elif [ "$EL_SYNCED" = "true" ] && [ "$CL_SYNCED" = "false" ]; then
  echo "NODE PARTIALLY SYNCED ⏳ — execution synced, consensus still catching up"
  echo "Network         : $NETWORK"
  echo "CL head slot    : ${HEAD_SLOT:-unknown}"
  echo "CL slots behind : ${SYNC_DIST:-unknown}"

else
  echo "NODE SYNCING ⏳ — both clients still catching up"
  echo "Network         : $NETWORK"
  echo "EL current block: ${CURRENT:-unknown}"
  echo "EL highest block: ${HIGHEST:-unknown}"
  echo "EL blocks behind: ${BEHIND:-unknown}"
  echo "CL head slot    : ${HEAD_SLOT:-unknown}"
  echo "CL slots behind : ${SYNC_DIST:-unknown}"
fi
