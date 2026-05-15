#!/bin/bash
# =============================================================================
# obol-status.sh — Sends a full status report of this Obol node via Telegram.
# Run manually or from cron (e.g. daily digest).
# =============================================================================

export HOME=/home/ethereum
export USER=ethereum
export PATH=/home/ethereum/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="/home/ethereum/.obol-monitor/conf/node.env"

if [ ! -f "$CONF" ]; then
    echo "ERROR: $CONF not found." >&2
    exit 1
fi
. "$CONF"
. "${SCRIPT_DIR}/../lib/common.sh"

# =============================================================================
# Gather data
# =============================================================================

TS=$(date '+%Y-%m-%d %H:%M:%S %Z')

# Services
svc_icon() { service_active "$1" && echo "✅" || echo "❌"; }

EL_ICON=$(svc_icon "$EL_SERVICE")
CL_ICON=$(svc_icon "$CL_SERVICE")
MEV_ICON=$(svc_icon "$MEV_SERVICE")
CHARON_ICON=$(svc_icon "$CHARON_SERVICE")
VAL_ICON=$(svc_icon "$VALIDATOR_SERVICE")

# Sync
EL_SYNC=$(el_syncing)
CL_SYNC=$(cl_syncing)

if [ "$EL_SYNC" = "false" ]; then
    EL_BLOCK=$(curl -s --max-time 5 -X POST "$EL_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        2>/dev/null | python3 -c "
import sys, json
try: print(int(json.load(sys.stdin)['result'], 16))
except: print('?')
")
    EL_STATUS="✅ Synced (block ${EL_BLOCK})"
elif [ "$EL_SYNC" = "true" ]; then
    PROGRESS=$(curl -s --max-time 5 -X POST "$EL_RPC" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)['result']
    cur = int(d['currentBlock'], 16)
    hi  = int(d['highestBlock'], 16)
    pct = round(cur * 100 / hi, 1) if hi > 0 else 0
    print(f'{pct}% ({hi-cur} blocks behind)')
except: print('?')
")
    EL_STATUS="⏳ Syncing — ${PROGRESS}"
else
    EL_STATUS="❓ Unreachable"
fi

if [ "$CL_SYNC" = "false" ]; then
    CL_HEAD=$(curl -s --max-time 5 "${CL_API}/eth/v1/node/syncing" 2>/dev/null | \
        python3 -c "
import sys, json
try: print(json.load(sys.stdin)['data']['head_slot'])
except: print('?')
")
    CL_STATUS="✅ Synced (slot ${CL_HEAD})"
elif [ "$CL_SYNC" = "true" ]; then
    CL_INFO=$(curl -s --max-time 5 "${CL_API}/eth/v1/node/syncing" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)['data']
    print(f'{d[\"sync_distance\"]} slots behind (head={d[\"head_slot\"]})')
except: print('?')
")
    CL_STATUS="⏳ Syncing — ${CL_INFO}"
else
    CL_STATUS="❓ Unreachable"
fi

# Peers
EL_P=$(el_peers)
CL_P=$(cl_peers_connected)
[ "$EL_P" -lt 0 ] 2>/dev/null && EL_P="?"
[ "$CL_P" -lt 0 ] 2>/dev/null && CL_P="?"

# Charon peers from metrics
# Each line of p2p_peer_connection_total = one connected peer
CHARON_CONNECTED=$(curl -s --max-time 8 "${CHARON_METRICS}" 2>/dev/null | \
    grep '^p2p_peer_connection_total{' | wc -l)
[ -z "$CHARON_CONNECTED" ] && CHARON_CONNECTED="?"

# System
SWAP_GB=$(swap_used_gb)
ETH_FREE=$(disk_free_gb /home/ethereum)
ETH_USED_PCT=$(disk_used_pct /home/ethereum)
ROOT_USED_PCT=$(disk_used_pct /)
CPU_TEMP=$(cpu_temp_max)
LOAD=$(awk '{print $1, $2, $3}' /proc/loadavg)
RAM=$(free -h | awk '/^Mem:/ {print "used " $3 " / " $2 " (avail " $7 ")"}')
UPTIME=$(uptime -p)

# =============================================================================
# Build and send report
# =============================================================================

MSG="📊 <b>Obol Node Status Report</b>
$(node_label) | ${TS}

<b>── Services ──────────────────</b>
${EL_ICON} Execution  : <code>${EL_SERVICE}</code>
${CL_ICON} Consensus  : <code>${CL_SERVICE}</code>
${MEV_ICON} MEV Boost  : <code>${MEV_SERVICE}</code>
${CHARON_ICON} Charon DVT : <code>${CHARON_SERVICE}</code>
${VAL_ICON} Validator  : <code>${VALIDATOR_SERVICE}</code>

<b>── Sync Status ───────────────</b>
EL: ${EL_STATUS}
CL: ${CL_STATUS}

<b>── Peers ─────────────────────</b>
EL peers   : ${EL_P} (min: ${EL_PEERS_MIN})
CL peers   : ${CL_P} (min: ${CL_PEERS_MIN})
Charon DVT : ${CHARON_CONNECTED} / ${CHARON_PEERS_EXPECTED} cluster peers

<b>── System ────────────────────</b>
CPU temp   : ${CPU_TEMP}°C (alert &gt;${CPU_TEMP_ALERT_C}°C)
Load avg   : ${LOAD}
RAM        : ${RAM}
Swap used  : ${SWAP_GB} GB (alert &gt;${SWAP_ALERT_GB} GB)
/home/eth  : ${ETH_FREE} GB free (${ETH_USED_PCT}% used)
/ root     : ${ROOT_USED_PCT}% used (alert &gt;${DISK_ROOT_ALERT_PCT}%)
Uptime     : ${UPTIME}"

send_telegram "$MSG"
echo "Status report sent at ${TS}"
