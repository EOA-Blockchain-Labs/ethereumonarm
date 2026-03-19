#!/bin/bash
# Detects which consensus and execution clients are currently running.
# Covers mainnet, hoodi, sepolia and MEV boost variants.

NETWORKS="mainnet hoodi sepolia"

EL_CLIENTS="geth nethermind erigon besu reth"
CL_CLIENTS="lighthouse prysm nimbus teku lodestar grandine"

RUNNING_EL=""
RUNNING_EL_NETWORK=""
RUNNING_CL=""
RUNNING_CL_NETWORK=""
RUNNING_CL_MEV=false

echo "=== Running Ethereum Clients ==="

# --- Detect running execution client ---
for client in $EL_CLIENTS; do
  # mainnet (no suffix)
  if systemctl is-active --quiet "$client" 2>/dev/null; then
    RUNNING_EL="$client"
    RUNNING_EL_NETWORK="mainnet"
    RUNNING_EL_SERVICE="$client"
    break
  fi
  # testnets
  for network in hoodi sepolia; do
    if systemctl is-active --quiet "${client}-${network}" 2>/dev/null; then
      RUNNING_EL="$client"
      RUNNING_EL_NETWORK="$network"
      RUNNING_EL_SERVICE="${client}-${network}"
      break 2
    fi
  done
done

# --- Detect running consensus client ---
for client in $CL_CLIENTS; do
  # mainnet, no MEV
  if systemctl is-active --quiet "${client}-beacon" 2>/dev/null; then
    RUNNING_CL="$client"
    RUNNING_CL_NETWORK="mainnet"
    RUNNING_CL_MEV=false
    RUNNING_CL_SERVICE="${client}-beacon"
    break
  fi
  # mainnet, MEV
  if systemctl is-active --quiet "${client}-beacon-mev" 2>/dev/null; then
    RUNNING_CL="$client"
    RUNNING_CL_NETWORK="mainnet"
    RUNNING_CL_MEV=true
    RUNNING_CL_SERVICE="${client}-beacon-mev"
    break
  fi
  # testnets
  for network in hoodi sepolia; do
    # testnet, no MEV
    if systemctl is-active --quiet "${client}-beacon-${network}" 2>/dev/null; then
      RUNNING_CL="$client"
      RUNNING_CL_NETWORK="$network"
      RUNNING_CL_MEV=false
      RUNNING_CL_SERVICE="${client}-beacon-${network}"
      break 2
    fi
    # testnet, MEV
    if systemctl is-active --quiet "${client}-beacon-mev-${network}" 2>/dev/null; then
      RUNNING_CL="$client"
      RUNNING_CL_NETWORK="$network"
      RUNNING_CL_MEV=true
      RUNNING_CL_SERVICE="${client}-beacon-mev-${network}"
      break 2
    fi
  done
done

# --- Report ---
if [ -n "$RUNNING_EL" ] && [ -n "$RUNNING_CL" ]; then
  echo "STATUS          : RUNNING"
  echo "Network         : $RUNNING_CL_NETWORK"
  echo "Consensus client: $RUNNING_CL_SERVICE"
  echo "Execution client: $RUNNING_EL_SERVICE"
  echo "MEV Boost       : $RUNNING_CL_MEV"
  echo "Node pair       : $RUNNING_CL_SERVICE + $RUNNING_EL_SERVICE"
elif [ -n "$RUNNING_EL" ] && [ -z "$RUNNING_CL" ]; then
  echo "STATUS          : INCOMPLETE — execution client running without consensus"
  echo "Execution client: $RUNNING_EL_SERVICE"
  echo "Consensus client: none"
  echo "WARNING: A full node requires both clients running simultaneously."
elif [ -z "$RUNNING_EL" ] && [ -n "$RUNNING_CL" ]; then
  echo "STATUS          : INCOMPLETE — consensus client running without execution"
  echo "Consensus client: $RUNNING_CL_SERVICE"
  echo "Execution client: none"
  echo "WARNING: A full node requires both clients running simultaneously."
else
  echo "STATUS          : STOPPED — no ethereum clients running"
  echo "Consensus client: none"
  echo "Execution client: none"
fi
