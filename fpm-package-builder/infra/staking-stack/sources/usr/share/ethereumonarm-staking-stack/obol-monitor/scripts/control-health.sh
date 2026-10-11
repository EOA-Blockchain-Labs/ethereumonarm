#!/bin/bash
# =============================================================================
# control-health.sh — Control node health monitor, run by cron every 5 min.
#
# Remote Obol node checks use Charon's HTTP API on port 3620 (no SSH needed):
#   - /livez  → node reachability (200 = up, 000 = unreachable)
#   - /metrics → Charon peer count and ping latency
#
# Local checks: backup EL/CL/MEV/validator/relay services + system resources.
# System resource alerts on Obol nodes are handled by obol-health.sh on each
# node — no duplication here.
# =============================================================================

export HOME=/home/ethereum
export USER=ethereum
export PATH=/home/ethereum/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="/home/ethereum/.obol-monitor/conf/node.env"

if [ ! -f "$CONF" ]; then
    echo "ERROR: $CONF not found. Run install.sh first." >&2
    exit 1
fi
. "$CONF"
. "${SCRIPT_DIR}/../lib/common.sh"

# Primary/backup deduplication: skip if peer control node is reachable
if ! is_primary; then
    echo "Peer control node (${PEER_CONTROL_IP}) is reachable — deferring health check to primary."
    exit 0
fi

expire_locks "ctrl-"

# =============================================================================
# SECTION 1 — REMOTE OBOL NODE CHECKS (via Charon HTTP API on :3620)
# =============================================================================

check_obol_node() {
    local node_ip="$1"
    local node_name="$2"
    local base_url="$3"    # e.g. http://100.x.x.x:3620
    local idx="$4"         # 1, 2, or 3 — used for unique lock names

    # ------------------------------------------------------------------
    # Reachability — GET /livez
    # livez=200 → Charon process is alive and healthy
    # livez=500 → Charon alive but cluster not fully ready (expected when
    #             a peer is down); node itself is up, not alerted here
    # livez=000 → curl got no response; node is completely unreachable
    # ------------------------------------------------------------------
    LIVEZ=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time "${CHARON_API_TIMEOUT:-8}" \
        "${base_url}/livez" 2>/dev/null)

    if [ "$LIVEZ" != "200" ] && [ "$LIVEZ" != "500" ]; then
        lock_alert "ctrl-node-${idx}-down" "$(node_label)
🚨 <b>Obol node unreachable</b>: <b>${node_name}</b> (<code>${node_ip}</code>) is not responding.

Charon /livez returned: <code>${LIVEZ:-no response}</code>

This could mean:
• The board has crashed or lost power
• Tailscale is down on that node
• Charon service is not running

Suggested actions:
• Check Tailscale: <code>tailscale ping ${node_ip}</code>
• Check Tailscale admin panel for node status
• SSH in and check: <code>sudo systemctl status charon</code>
• Physical inspection may be required" "critical"
        return
    fi
    clear_lock "ctrl-node-${idx}-down"

    # ------------------------------------------------------------------
    # Fetch metrics once — reused for peer count and latency checks
    # ------------------------------------------------------------------
    METRICS_RAW=$(curl -s --max-time "${CHARON_API_TIMEOUT:-8}" \
        "${base_url}/metrics" 2>/dev/null)

    if [ -z "$METRICS_RAW" ]; then
        lock_alert "ctrl-node-${idx}-metrics" "$(node_label)
⚠️ <b>${node_name}</b>: Charon metrics endpoint returned empty response.
Charon may be starting up.
• SSH in and check: <code>sudo systemctl status charon</code>" "detailed"
        return
    fi
    clear_lock "ctrl-node-${idx}-metrics"

    # ------------------------------------------------------------------
    # Charon peer connections
    # Each line of p2p_peer_connection_total = one currently connected peer.
    # In a 3-node cluster each node expects 2 peers.
    # ------------------------------------------------------------------
    CHARON_PEERS=$(echo "$METRICS_RAW" | \
        grep '^p2p_peer_connection_total{' | wc -l)

    if [ "${CHARON_PEERS:-0}" -lt "${CHARON_PEERS_MIN:-2}" ] 2>/dev/null; then
        PEER_NAMES=$(echo "$METRICS_RAW" | \
            grep '^p2p_peer_connection_total{' | \
            grep -o 'peer="[^"]*"' | \
            cut -d= -f2 | tr -d '"' | paste -sd ', ')
        [ -z "$PEER_NAMES" ] && PEER_NAMES="none"

        lock_alert "ctrl-node-${idx}-charon-peers" "$(node_label)
🚨 <b>${node_name}</b>: Charon low peer connections — <b>${CHARON_PEERS}</b> of ${CHARON_PEERS_EXPECTED} expected peers connected.
Connected peers: ${PEER_NAMES}

The DVT cluster may not reach the 2/3 threshold for attestations.

Suggested actions:
• Check Charon logs on ${node_name}: <code>sudo journalctl -u charon -n 50</code>
• Verify Tailscale is running on all nodes: <code>tailscale status</code>
• Confirm the missing peer node is reachable" "critical"
    else
        clear_lock "ctrl-node-${idx}-charon-peers"
    fi

    # ------------------------------------------------------------------
    # Charon peer latency (p50)
    # p2p_ping_latency_seconds with quantile="0.5"
    # May be absent if no pings recorded yet — skip alert if empty.
    # ------------------------------------------------------------------
    HIGH_LATENCY=$(echo "$METRICS_RAW" | \
        grep 'p2p_ping_latency_seconds{' | \
        grep 'quantile="0.5"' | \
        python3 -c "
import sys
threshold = ${CHARON_LATENCY_ALERT_MS:-500} / 1000.0
bad = []
for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    try:
        labels_part = line.split('{', 1)[1].split('}')[0]
        val = float(line.rsplit('}', 1)[1].strip())
        peer = ''
        for kv in labels_part.split(','):
            k, _, v = kv.partition('=')
            if k.strip() == 'peer':
                peer = v.strip().strip('\"')
        if val > threshold:
            bad.append(f'{peer} ({val*1000:.0f}ms)')
    except:
        pass
print(', '.join(bad))
" 2>/dev/null)

    if [ -n "$HIGH_LATENCY" ]; then
        lock_alert "ctrl-node-${idx}-charon-latency" "$(node_label)
⚠️ <b>${node_name}</b>: Charon high peer latency (p50) exceeding ${CHARON_LATENCY_ALERT_MS}ms:
<b>${HIGH_LATENCY}</b>

High inter-node latency can cause missed attestations in the DVT cluster.

Suggested actions:
• Check Tailscale latency: <code>tailscale ping &lt;peer-tailscale-ip&gt;</code>
• Check Charon logs on ${node_name}: <code>sudo journalctl -u charon -n 30</code>" "info"
    else
        clear_lock "ctrl-node-${idx}-charon-latency"
    fi
}

# Run check for each Obol node — dynamic loop over CLUSTER_SIZE
for _idx in $(seq 1 "${CLUSTER_SIZE:-3}"); do
    _ip_var="OBOL_NODE_${_idx}_IP"
    _name_var="OBOL_NODE_${_idx}_NAME"
    _base_var="OBOL_NODE_${_idx}_BASE"
    _ip="${!_ip_var}"
    _name="${!_name_var:-obol-node-${_idx}}"
    _base="${!_base_var}"
    if [ -z "$_ip" ]; then
        echo "WARNING: OBOL_NODE_${_idx}_IP is not set — skipping node ${_idx}" >&2
        continue
    fi
    check_obol_node "$_ip" "$_name" "$_base" "$_idx"
done
unset _idx _ip_var _name_var _base_var _ip _name _base

# =============================================================================
# SECTION 2 — LOCAL SERVICES (control node itself)
# =============================================================================

check_local_svc() {
    local svc="$1"
    local label="$2"
    local lock="ctrl-local-svc-${svc}"
    if service_active "$svc"; then
        clear_lock "$lock"
    else
        # Control node services are backup/monitoring only — DETAILED level.
        # If these go down the cluster still operates via Obol nodes.
        lock_alert "$lock" "$(node_label)
🚨 <b>Local service DOWN</b>: <code>${svc}</code> (${label}) is not running on <b>${NODE_NAME}</b>.

• <code>sudo systemctl status ${svc}</code>
• <code>sudo journalctl -u ${svc} -n 50</code>" "detailed"
    fi
}

check_local_svc "$EL_SERVICE"          "Execution client (backup)"
check_local_svc "$CL_SERVICE"          "Consensus client (backup)"
check_local_svc "$MEV_SERVICE"         "MEV Boost (backup)"
check_local_svc "$VALIDATOR_SERVICE"   "Validator client (backup)"
check_local_svc "$OBOL_RELAY_SERVICE"  "Obol relay"

# =============================================================================
# SECTION 3 — LOCAL SYSTEM RESOURCES (control node)
# =============================================================================

# Swap
SWAP_KB=$(swap_used_kb)
SWAP_GB=$(swap_used_gb)
SWAP_THRESH_KB=$(( ${SWAP_ALERT_GB:-6} * 1048576 ))
if [ "${SWAP_KB:-0}" -gt "$SWAP_THRESH_KB" ] 2>/dev/null; then
    lock_alert "ctrl-local-swap" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): High swap usage — <b>${SWAP_GB} GB</b> in use (threshold: ${SWAP_ALERT_GB} GB).
• <code>free -h</code>
• <code>ps aux --sort=-%mem | head -10</code>" "info"
else
    clear_lock "ctrl-local-swap"
fi

# /home/ethereum disk
ETH_FREE=$(disk_free_gb /home/ethereum)
if [ "${ETH_FREE:-999}" -lt "${DISK_ETH_ALERT_GB:-150}" ] 2>/dev/null; then
    lock_alert "ctrl-local-disk-eth" "$(node_label)
🚨 <b>${NODE_NAME}</b> (control): Low disk on <code>/home/ethereum</code> — only <b>${ETH_FREE} GB</b> free (threshold: ${DISK_ETH_ALERT_GB} GB)." "critical"
else
    clear_lock "ctrl-local-disk-eth"
fi

# / disk
ROOT_PCT=$(disk_used_pct /)
if [ "${ROOT_PCT:-0}" -gt "${DISK_ROOT_ALERT_PCT:-85}" ] 2>/dev/null; then
    lock_alert "ctrl-local-disk-root" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): Root <code>/</code> at <b>${ROOT_PCT}%</b> used (threshold: ${DISK_ROOT_ALERT_PCT}%).
• <code>sudo journalctl --vacuum-size=500M</code>
• <code>sudo apt-get clean</code>" "info"
else
    clear_lock "ctrl-local-disk-root"
fi

# CPU temperature
CPU_TEMP=$(cpu_temp_max)
if [ "${CPU_TEMP:-0}" -gt "${CPU_TEMP_ALERT_C:-80}" ] 2>/dev/null; then
    lock_alert "ctrl-local-cpu-temp" "$(node_label)
🌡 <b>${NODE_NAME}</b> (control): CPU temperature <b>${CPU_TEMP}°C</b> (threshold: ${CPU_TEMP_ALERT_C}°C)." "info"
else
    clear_lock "ctrl-local-cpu-temp"
fi

# Local EL sync
if service_active "$EL_SERVICE"; then
    EL_SYNC=$(el_syncing)
    if [ "$EL_SYNC" = "true" ]; then
        lock_alert "ctrl-local-el-sync" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): backup EL client is not synced.
• <code>sudo journalctl -u ${EL_SERVICE} -n 30</code>" "detailed"
    else
        clear_lock "ctrl-local-el-sync"
    fi
fi

# Local CL sync
if service_active "$CL_SERVICE"; then
    CL_SYNC=$(cl_syncing)
    if [ "$CL_SYNC" = "true" ]; then
        lock_alert "ctrl-local-cl-sync" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): backup CL client is not synced.
• <code>sudo journalctl -u ${CL_SERVICE} -n 30</code>" "detailed"
    else
        clear_lock "ctrl-local-cl-sync"
    fi
fi