#!/bin/bash
# =============================================================================
# obol-health.sh — Obol node health monitor, run by cron every 5 minutes.
# Checks services, sync status, peers, swap, disk, and CPU temperature.
# Sends Telegram alerts only when a condition first appears (lock-gated).
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

expire_locks "obol-"

# =============================================================================
# 1. SERVICE CHECKS
# =============================================================================

check_service() {
    local svc="$1"
    local label="$2"
    local lock="obol-svc-${svc}"

    if service_active "$svc"; then
        recovery_alert "$lock" "$(node_label)
✅ <b>Service RESTORED</b>: <code>${svc}</code> (${label}) is running again."
    else
        lock_alert "$lock" "$(node_label)
🚨 <b>Service DOWN</b>: <code>${svc}</code> (${label}) is not running.

Suggested actions:
• Check status: <code>sudo systemctl status ${svc}</code>
• Check logs: <code>sudo journalctl -u ${svc} -n 50</code>
• Restart: <code>sudo systemctl restart ${svc}</code>"
    fi
}

check_service "$EL_SERVICE"     "Execution client"
check_service "$CL_SERVICE"     "Consensus client (beacon)"
check_service "$MEV_SERVICE"    "MEV Boost"
check_service "$CHARON_SERVICE" "Charon DVT"
check_service "$VALIDATOR_SERVICE" "Validator client"

# =============================================================================
# 2. SYNC STATUS
# =============================================================================

# Only check sync if both EL and CL services are running
if service_active "$EL_SERVICE" && service_active "$CL_SERVICE"; then

    # --- Execution client sync ---
    EL_SYNC=$(el_syncing)
    if [ "$EL_SYNC" = "true" ]; then
        CURRENT=$(curl -s --max-time 5 -X POST "$EL_RPC" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)['result']
    cur = int(d['currentBlock'], 16)
    hi  = int(d['highestBlock'], 16)
    print(f'{cur} / {hi} ({hi-cur} blocks behind)')
except:
    print('unknown')
")
        lock_alert "obol-el-sync" "$(node_label)
⚠️ <b>EL not synced</b>: <code>${EL_SERVICE}</code> is still syncing.

Progress: ${CURRENT}

Suggested actions:
• Check logs: <code>sudo journalctl -u ${EL_SERVICE} -n 30</code>
• Verify peer count and network connectivity."
    elif [ "$EL_SYNC" = "error" ]; then
        lock_alert "obol-el-rpc" "$(node_label)
⚠️ <b>EL RPC unreachable</b>: cannot reach <code>${EL_RPC}</code>.

The execution client may have crashed or is still starting up.
• Check status: <code>sudo systemctl status ${EL_SERVICE}</code>"
    else
        recovery_alert "obol-el-sync" "$(node_label)
✅ <b>EL sync resolved</b>: <code>${EL_SERVICE}</code> is now synced."
        recovery_alert "obol-el-rpc"  "$(node_label)
✅ <b>EL RPC restored</b>: <code>${EL_RPC}</code> is responding."
    fi

    # --- Consensus client sync ---
    CL_SYNC=$(cl_syncing)
    if [ "$CL_SYNC" = "true" ]; then
        CL_INFO=$(curl -s --max-time 5 "${CL_API}/eth/v1/node/syncing" 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)['data']
    print(f'head={d[\"head_slot\"]} distance={d[\"sync_distance\"]} slots')
except:
    print('unknown')
")
        lock_alert "obol-cl-sync" "$(node_label)
⚠️ <b>CL not synced</b>: <code>${CL_SERVICE}</code> is still syncing.

Progress: ${CL_INFO}

Suggested actions:
• Check logs: <code>sudo journalctl -u ${CL_SERVICE} -n 30</code>
• Verify peer count."
    elif [ "$CL_SYNC" = "error" ]; then
        lock_alert "obol-cl-api" "$(node_label)
⚠️ <b>CL API unreachable</b>: cannot reach <code>${CL_API}</code>.

The consensus client may have crashed or is still starting up.
• Check status: <code>sudo systemctl status ${CL_SERVICE}</code>"
    else
        recovery_alert "obol-cl-sync" "$(node_label)
✅ <b>CL sync resolved</b>: <code>${CL_SERVICE}</code> is now synced."
        recovery_alert "obol-cl-api"  "$(node_label)
✅ <b>CL API restored</b>: <code>${CL_API}</code> is responding."
    fi
fi

# =============================================================================
# 3. PEER COUNTS
# =============================================================================

if service_active "$EL_SERVICE"; then
    EL_P=$(el_peers)
    if [ "$EL_P" -ge 0 ] 2>/dev/null; then
        if [ "$EL_P" -lt "${EL_PEERS_MIN:-5}" ]; then
            lock_alert "obol-el-peers" "$(node_label)
⚠️ <b>EL low peers</b>: only <b>${EL_P}</b> peer(s) connected (minimum: ${EL_PEERS_MIN}).

Possible causes:
• Node just started — peer discovery takes a few minutes
• P2P port blocked (default: 30303 TCP/UDP)
• Network connectivity issue

Suggested actions:
• Verify port 30303 is reachable from the internet
• Check logs: <code>sudo journalctl -u ${EL_SERVICE} -n 30</code>"
        else
            recovery_alert "obol-el-peers" "$(node_label)
✅ <b>EL peers restored</b>: peer count is now ${EL_PEER_COUNT} (min ${EL_PEERS_MIN:-5})."
        fi
    fi
fi

if service_active "$CL_SERVICE"; then
    CL_P=$(cl_peers_connected)
    if [ "$CL_P" -ge 0 ] 2>/dev/null; then
        if [ "$CL_P" -lt "${CL_PEERS_MIN:-10}" ]; then
            lock_alert "obol-cl-peers" "$(node_label)
⚠️ <b>CL low peers</b>: only <b>${CL_P}</b> peer(s) connected (minimum: ${CL_PEERS_MIN}).

Possible causes:
• P2P port blocked (default: 9000 TCP/UDP for most CL clients)
• Firewall or NAT issue at the ISP

Suggested actions:
• Verify port 9000 is open
• Check logs: <code>sudo journalctl -u ${CL_SERVICE} -n 30</code>"
        else
            recovery_alert "obol-cl-peers" "$(node_label)
✅ <b>CL peers restored</b>: peer count is now ${CL_PEER_COUNT} (min ${CL_PEERS_MIN:-10})."
        fi
    fi
fi

# =============================================================================
# 4. CHARON PEERS AND LATENCY (via local Prometheus metrics on :3620)
# =============================================================================

if service_active "$CHARON_SERVICE"; then
    METRICS_RAW=$(curl -s --max-time 8 "${CHARON_METRICS}" 2>/dev/null)

    # Each line of p2p_peer_connection_total represents one connected peer.
    # The metric value is a lifetime counter — number of lines = peer count.
    CHARON_CONNECTED=$(echo "$METRICS_RAW" | \
        grep '^p2p_peer_connection_total{' | wc -l)

    if [ "${CHARON_CONNECTED:-0}" -lt "${CHARON_PEERS_MIN:-2}" ] 2>/dev/null; then
        lock_alert "obol-charon-peers" "$(node_label)
🚨 <b>Charon low peer connections</b>: only <b>${CHARON_CONNECTED}</b> peer(s) connected (expected: ${CHARON_PEERS_EXPECTED}).

This means the DVT cluster may not reach the 2/3 threshold for attestations.

Suggested actions:
• Check Charon logs: <code>sudo journalctl -u ${CHARON_SERVICE} -n 50</code>
• Verify Tailscale is running: <code>tailscale status</code>
• Confirm Charon p2p port is reachable from other cluster nodes
• Check cluster peer config in <code>/home/ethereum/.charon/</code>"
    else
        recovery_alert "obol-charon-peers" "$(node_label)
✅ <b>Charon peers restored</b>: ${CHARON_PEERS} peer(s) connected (min ${CHARON_PEERS_MIN:-2})."
    fi

    # Latency — p50 per peer. Empty if no pings recorded yet; skip alert in that case.
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
        lock_alert "obol-charon-latency" "$(node_label)
⚠️ <b>Charon high peer latency</b>: peer(s) exceeding ${CHARON_LATENCY_ALERT_MS}ms (p50):
<b>${HIGH_LATENCY}</b>

High latency between DVT cluster nodes can cause missed attestations.

Suggested actions:
• Check Tailscale latency: <code>tailscale ping &lt;peer-tailscale-ip&gt;</code>
• Check Charon logs: <code>sudo journalctl -u ${CHARON_SERVICE} -n 30</code>"
    else
        recovery_alert "obol-charon-latency" "$(node_label)
✅ <b>Charon latency resolved</b>: peer latency is back within threshold."
    fi
fi

# =============================================================================
# 5. SYSTEM RESOURCES
# =============================================================================

# --- Swap usage ---
SWAP_KB=$(swap_used_kb)
SWAP_GB=$(swap_used_gb)
SWAP_THRESHOLD_KB=$(( ${SWAP_ALERT_GB:-10} * 1048576 ))

if [ "${SWAP_KB:-0}" -gt "$SWAP_THRESHOLD_KB" ] 2>/dev/null; then
    lock_alert "obol-swap" "$(node_label)
⚠️ <b>High swap usage</b>: <b>${SWAP_GB} GB</b> of swap in use (threshold: ${SWAP_ALERT_GB} GB).

Possible causes:
• Ethereum clients consuming more RAM than available — common during sync
• Memory pressure from running multiple services (EL + CL + Charon + validator)

Suggested actions:
• Check memory: <code>free -h</code>
• Check top consumers: <code>ps aux --sort=-%mem | head -10</code>
• If persistent, consider restarting the highest-RAM client"
else
    recovery_alert "obol-swap" "$(node_label)
✅ <b>Swap usage resolved</b>: swap is back below ${SWAP_ALERT_GB:-10} GB."
fi

# --- /home/ethereum disk space ---
ETH_FREE=$(disk_free_gb /home/ethereum)
if [ "${ETH_FREE:-999}" -lt "${DISK_ETH_ALERT_GB:-150}" ] 2>/dev/null; then
    lock_alert "obol-disk-eth" "$(node_label)
🚨 <b>Low disk space</b> on <code>/home/ethereum</code>: only <b>${ETH_FREE} GB</b> free (threshold: ${DISK_ETH_ALERT_GB} GB).

Ethereum client data is growing. If this reaches 0 the node will crash.

Suggested actions:
• Check usage per client: <code>du -sh /home/ethereum/.*</code>
• Check overall usage: <code>df -h /home/ethereum</code>
• Consider pruning or switching to a more space-efficient client"
else
    recovery_alert "obol-disk-eth" "$(node_label)
✅ <b>Disk space restored</b>: /home/ethereum has more than ${DISK_ETH_ALERT_GB:-150} GB free."
fi

# --- / (root) disk space ---
ROOT_PCT=$(disk_used_pct /)
if [ "${ROOT_PCT:-0}" -gt "${DISK_ROOT_ALERT_PCT:-85}" ] 2>/dev/null; then
    lock_alert "obol-disk-root" "$(node_label)
⚠️ <b>Low disk space</b> on <code>/</code> (root): <b>${ROOT_PCT}%</b> used (threshold: ${DISK_ROOT_ALERT_PCT}%).

Suggested actions:
• Check usage: <code>df -h /</code>
• Find large files: <code>du -sh /* 2>/dev/null | sort -rh | head -10</code>
• Clean apt cache: <code>sudo apt-get clean</code>
• Check and rotate logs: <code>sudo journalctl --vacuum-size=500M</code>"
else
    recovery_alert "obol-disk-root" "$(node_label)
✅ <b>Root disk resolved</b>: / usage is back below ${DISK_ROOT_ALERT_PCT:-85}%."
fi

# --- CPU temperature ---
CPU_TEMP=$(cpu_temp_max)
if [ "${CPU_TEMP:-0}" -gt "${CPU_TEMP_ALERT_C:-80}" ] 2>/dev/null; then
    lock_alert "obol-cpu-temp" "$(node_label)
🌡 <b>High CPU temperature</b>: <b>${CPU_TEMP}°C</b> (threshold: ${CPU_TEMP_ALERT_C}°C).

The Rock 5B+ may throttle under sustained heat, causing missed attestations.

Suggested actions:
• Check airflow and heatsink contact
• Check all thermal zones: <code>cat /sys/class/thermal/thermal_zone*/temp</code>
• Monitor over time: <code>watch -n 2 'cat /sys/class/thermal/thermal_zone*/temp | awk \"{print \$1/1000}\"'</code>
• Consider reducing CPU governor: <code>cpufreq-info</code>"
else
    recovery_alert "obol-cpu-temp" "$(node_label)
✅ <b>CPU temperature normalized</b>: back below ${CPU_TEMP_ALERT_C:-80}°C."
fi
