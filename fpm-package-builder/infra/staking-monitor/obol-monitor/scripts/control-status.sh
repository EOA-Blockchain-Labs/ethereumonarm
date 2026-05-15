#!/bin/bash
# =============================================================================
# control-status.sh — Sends a full cluster status report via Telegram.
# Shows all 3 Obol nodes (via Charon HTTP API) + this control node.
# Run manually or from cron (daily digest at 08:00).
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

# Primary node monitors failover health (only runs on NODE_TYPE=control)
if [ "${NODE_TYPE:-}" = "control" ]; then
    check_failover
fi

# Primary/backup deduplication — three-state check via is_primary()
is_primary
case "$IS_PRIMARY_REASON" in
    always_primary)
        # No peer configured — always run
        ;;
    peer_healthy)
        # Peer EL API responded — fully healthy, defer
        echo "Primary node (${PEER_CONTROL_IP}) is healthy — deferring to primary."
        exit 0
        ;;
    peer_el_down)
        # Relay responded — primary node is up, EL-only issue.
        # No alert: node is reachable, EL may be restarting or behind.
        clear_lock "ctrl-peer-el-down"
        echo "Primary relay responds, EL down — deferring silently."
        exit 0
        ;;
    peer_el_relay_down)
        # Both EL and relay down but ping succeeded — alert, still defer
        lock_alert "ctrl-peer-el-down" "$(node_label)
⚠️ <b>Primary control node: EL and relay both down</b>

Node <code>${PEER_CONTROL_IP}</code> responds to ping but both
EL API (port 80) and Charon relay (port ${PEER_RELAY_PORT:-3640}) are not responding.

Suggested actions:
• Check EL: <code>sudo systemctl status ${EL_SERVICE}</code>
• Check relay: <code>sudo systemctl status ${OBOL_RELAY_SERVICE}</code>"
        echo "Primary EL+relay down but node pings — alert sent, deferring."
        exit 0
        ;;
    peer_down)
        # Both checks failed — peer is down, take over
        clear_lock "ctrl-peer-el-down"
        lock_alert "ctrl-peer-node-down" "$(node_label)
🚨 <b>Primary control node is DOWN</b>

Node <code>${PEER_CONTROL_IP}</code> did not respond to ping or EL API query.
This node (<b>${NODE_NAME}</b>) is taking over as active monitor.

Suggested actions:
• Check Tailscale: <code>tailscale ping ${PEER_CONTROL_IP}</code>
• Check Tailscale admin panel for node status
• Physical inspection of primary node may be required"
        ;;
esac

TS=$(date '+%Y-%m-%d %H:%M:%S %Z')
_NODES_DOWN_FILE=$(mktemp)
_VALIDATORS_DOWN_FILE=$(mktemp)
echo 0 > "$_NODES_DOWN_FILE"
echo 0 > "$_VALIDATORS_DOWN_FILE"

# =============================================================================
# Helper — gather one Obol node's summary via Charon HTTP API only
# =============================================================================
obol_node_summary() {
    local node_ip="$1"
    local node_name="$2"
    local base_url="$3"    # http://<tailscale-ip>:3620

    # --- Reachability via /livez ---
    LIVEZ=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time "${CHARON_API_TIMEOUT:-8}" \
        "${base_url}/livez" 2>/dev/null)

    if [ "$LIVEZ" != "200" ] && [ "$LIVEZ" != "500" ]; then
        echo "❌ <b>${node_name}</b> (<code>${node_ip}</code>) — UNREACHABLE (livez: ${LIVEZ:-no response})"
        # Increment down counter via temp file (subshell-safe)
        echo $(( $(cat "$_NODES_DOWN_FILE" 2>/dev/null || echo 0) + 1 )) > "$_NODES_DOWN_FILE"
        return
    fi

    # --- Metrics fetched first so readyz reason can use app_monitoring_readyz gauge ---
    METRICS_RAW=$(curl -s --max-time "${CHARON_API_TIMEOUT:-8}" \
        "${base_url}/metrics" 2>/dev/null)

    # --- /readyz: 200 = Charon ready (does NOT confirm VC is running) ---
    # app_monitoring_readyz values: 1=ready 2=BN down 3=syncing 4=low peers
    READYZ=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time "${CHARON_API_TIMEOUT:-8}" \
        "${base_url}/readyz" 2>/dev/null)

    if [ "$READYZ" = "200" ]; then
        READYZ_ICON="✅"
        READYZ_LABEL="ready"
    else
        READYZ_VAL=$(echo "$METRICS_RAW" | awk '/^app_monitoring_readyz / {print $2; exit}')
        case "${READYZ_VAL:-0}" in
            2) READYZ_LABEL="beacon node DOWN"      ; READYZ_ICON="🚨" ;;
            3) READYZ_LABEL="beacon node syncing"   ; READYZ_ICON="⚠️" ;;
            4) READYZ_LABEL="insufficient peers"    ; READYZ_ICON="⚠️" ;;
            *) READYZ_LABEL="not ready (${READYZ_VAL:-?})" ; READYZ_ICON="⚠️" ;;
        esac
        echo $(( $(cat "$_VALIDATORS_DOWN_FILE" 2>/dev/null || echo 0) + 1 )) > "$_VALIDATORS_DOWN_FILE"
    fi

    # Count connected peers — one line per peer
    CHARON_PEERS=$(echo "$METRICS_RAW" | \
        grep '^p2p_peer_connection_total{' | wc -l)

    # List connected peer names
    PEER_NAMES=$(echo "$METRICS_RAW" | \
        grep '^p2p_peer_connection_total{' | \
        grep -o 'peer="[^"]*"' | \
        cut -d= -f2 | tr -d '"' | paste -sd ', ')
    [ -z "$PEER_NAMES" ] && PEER_NAMES="none"

    # Latency: histogram average per peer using _sum/_count.
    LATENCY_INFO=$(echo "$METRICS_RAW" | python3 -c "
import sys
threshold = 500 / 1000.0
sums = {}; counts = {}
for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith(\"#\"): continue
    try:
        if \"_sum{\" in line:   kind = \"sum\"
        elif \"_count{\" in line: kind = \"count\"
        else: continue
        labels_part = line.split(\"{\",1)[1].split(\"}\")[0]
        val = float(line.rsplit(\"}\",1)[1].strip())
        peer = \"unknown\"
        for kv in labels_part.split(\",\"):
            k, _, v = kv.partition(\"=\")
            if k.strip() == \"peer\":
                peer = v.strip().strip(chr(34))
        if kind == \"sum\":   sums[peer]   = val
        if kind == \"count\": counts[peer] = val
    except: pass
rows = []
for peer in sums:
    cnt = counts.get(peer, 0)
    if cnt > 0 and peer != \"unknown\":
        rows.append(f\"{peer}: {sums[peer]/cnt*1000:.0f}ms avg\")
print(\", \".join(rows) if rows else \"no data yet\")
" 2>/dev/null)
    [ -z "$LATENCY_INFO" ] && LATENCY_INFO="no data yet"

    [ "$CHARON_PEERS" -ge "${CHARON_PEERS_MIN:-2}" ] 2>/dev/null \
        && PEERS_ICON="✅" || PEERS_ICON="🚨"

    echo "✅ <b>${node_name}</b> (<code>${node_ip}</code>)
  Charon livez : ${LIVEZ}  readyz : ${READYZ} ${READYZ_ICON} ${READYZ_LABEL}
  DVT peers    : ${PEERS_ICON} ${CHARON_PEERS}/${CHARON_PEERS_EXPECTED} — ${PEER_NAMES}
  Latency p50  : ${LATENCY_INFO}"
}

# =============================================================================
# Collect Obol node summaries — dynamic loop over CLUSTER_SIZE
# =============================================================================
OBOL_REPORTS=""
for _idx in $(seq 1 "${CLUSTER_SIZE:-3}"); do
    _ip_var="OBOL_NODE_${_idx}_IP"
    _name_var="OBOL_NODE_${_idx}_NAME"
    _base_var="OBOL_NODE_${_idx}_BASE"
    _ip="${!_ip_var}"
    _name="${!_name_var:-obol-node-${_idx}}"
    _base="${!_base_var}"
    [ -z "$_ip" ] && continue
    OBOL_REPORTS="${OBOL_REPORTS}
$(obol_node_summary "$_ip" "$_name" "$_base")"
done
unset _idx _ip_var _name_var _base_var _ip _name _base

OBOL_NODES_DOWN=$(cat "$_NODES_DOWN_FILE" 2>/dev/null || echo 0)
OBOL_VALIDATORS_DOWN=$(cat "$_VALIDATORS_DOWN_FILE" 2>/dev/null || echo 0)
rm -f "$_NODES_DOWN_FILE" "$_VALIDATORS_DOWN_FILE"

OBOL_NODES_UP=$(( ${CLUSTER_SIZE:-3} - OBOL_NODES_DOWN ))

# Cluster health summary line — shown at top of OBOL NODES section
if [ "$OBOL_NODES_DOWN" -eq 0 ] && [ "$OBOL_VALIDATORS_DOWN" -eq 0 ]; then
    CLUSTER_STATUS="🟢 All ${CLUSTER_SIZE} nodes up — all validators running"
elif [ "$OBOL_NODES_DOWN" -eq 0 ] && [ "$OBOL_VALIDATORS_DOWN" -gt 0 ]; then
    CLUSTER_STATUS="🟡 All ${CLUSTER_SIZE} nodes up — ${OBOL_VALIDATORS_DOWN} validator(s) NOT running"
else
    CLUSTER_STATUS="🔴 ${OBOL_NODES_DOWN}/${CLUSTER_SIZE} node(s) unreachable — ${OBOL_VALIDATORS_DOWN} validator(s) NOT running"
fi

# Compute cluster failure threshold (same logic as control-health.sh)
CLUSTER_FAIL_AT=$(python3 -c "
import math
n = int('${CLUSTER_SIZE:-3}')
print(n - math.ceil(2/3 * n) + 1)
")
CLUSTER_FAILING=false
[ "${OBOL_NODES_DOWN:-0}" -ge "${CLUSTER_FAIL_AT:-2}" ] 2>/dev/null && CLUSTER_FAILING=true

# =============================================================================
# Local control node data
# =============================================================================
LOCAL_EL_I=$(service_active "$EL_SERVICE"          && echo "✅" || echo "❌")
LOCAL_CL_I=$(service_active "$CL_SERVICE"          && echo "✅" || echo "❌")
LOCAL_MEV_I=$(service_active "$MEV_SERVICE"         && echo "✅" || echo "❌")
# Validator: show standby (⏸) when cluster is healthy — it should be stopped.
# Show ✅/🚨 only when the cluster is failing and the validator matters.
if [ "$CLUSTER_FAILING" = "true" ]; then
    LOCAL_VAL_I=$(service_active "$VALIDATOR_SERVICE" && echo "✅" || echo "🚨 DOWN")
else
    LOCAL_VAL_I=$(service_active "$VALIDATOR_SERVICE" && echo "✅ (running)" || echo "⏸ standby")
fi
LOCAL_RELAY_I=$(service_active "$OBOL_RELAY_SERVICE" && echo "✅" || echo "❌")

LOCAL_EL_SYNC=$(el_syncing)
LOCAL_CL_SYNC=$(cl_syncing)
[ "$LOCAL_EL_SYNC" = "false" ] && LOCAL_ES="✅ synced" || LOCAL_ES="⏳ syncing"
[ "$LOCAL_CL_SYNC" = "false" ] && LOCAL_CS="✅ synced" || LOCAL_CS="⏳ syncing"

LOCAL_EL_P=$(el_peers)
LOCAL_CL_P=$(cl_peers_connected)
LOCAL_TEMP=$(cpu_temp_max)
LOCAL_SWAP=$(swap_used_gb)
LOCAL_ETH_FREE=$(disk_free_gb /home/ethereum)
LOCAL_ROOT_PCT=$(disk_used_pct /)
LOCAL_LOAD=$(awk '{print $1}' /proc/loadavg)

# =============================================================================
# Build and send the full report
# =============================================================================

MSG="📊 <b>Obol Cluster Status Report</b>
Reported by: $(node_label) | ${TS}

<b>━━ OBOL CLUSTER ━━━━━━━━━━━━━━━</b>
${CLUSTER_STATUS}

<b>━━ OBOL NODES ━━━━━━━━━━━━━━━━━</b>
${OBOL_REPORTS}

<b>━━ CONTROL NODE (this node) ━━━</b>
<b>${NODE_NAME}</b> (<code>${VPN_IP}</code>)
  Services : EL${LOCAL_EL_I} CL${LOCAL_CL_I} MEV${LOCAL_MEV_I} Val${LOCAL_VAL_I} Relay${LOCAL_RELAY_I}
  Sync     : EL ${LOCAL_ES}  CL ${LOCAL_CS}
  Peers    : EL ${LOCAL_EL_P} | CL ${LOCAL_CL_P}
  System   : CPU ${LOCAL_TEMP}°C | Swap ${LOCAL_SWAP}GB | /eth ${LOCAL_ETH_FREE}GB free | / ${LOCAL_ROOT_PCT}% | Load ${LOCAL_LOAD}"

send_telegram "$MSG"
echo "Cluster status report sent at ${TS}"
