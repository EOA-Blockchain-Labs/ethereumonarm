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
    local level="${3:-info}"    # alert level: critical | info | detailed
    local lock="obol-svc-${svc}"

    if service_active "$svc"; then
        clear_lock_alert "$lock" "$(node_label)
✅ <b>Resolved: Service Restored</b>

<code>${svc}</code> (${label}) is running again." "$level"
    else
        lock_alert "$lock" "$(node_label)
🚨 <b>Service DOWN</b>: <code>${svc}</code> (${label}) is not running.

Suggested actions:
• Check status: <code>sudo systemctl status ${svc}</code>
• Check logs: <code>sudo journalctl -u ${svc} -n 50</code>
• Restart: <code>sudo systemctl restart ${svc}</code>" "$level"
    fi
}

# Charon and Validator are CRITICAL — cluster cannot sign without them.
# EL, CL, MEV are INFO — important but node may still participate briefly.
check_service "$EL_SERVICE"        "Execution client"        "info"
check_service "$CL_SERVICE"        "Consensus client (beacon)" "info"
check_service "$MEV_SERVICE"       "MEV Boost"               "info"
check_service "$CHARON_SERVICE"    "Charon DVT"              "critical"
check_service "$VALIDATOR_SERVICE" "Validator client"        "critical"

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
• Verify peer count and network connectivity." "info"
    elif [ "$EL_SYNC" = "error" ]; then
        lock_alert "obol-el-rpc" "$(node_label)
⚠️ <b>EL RPC unreachable</b>: cannot reach <code>${EL_RPC}</code>.

The execution client may have crashed or is still starting up.
• Check status: <code>sudo systemctl status ${EL_SERVICE}</code>" "info"
    else
        clear_lock_alert "obol-el-sync" "$(node_label)
✅ <b>Resolved: EL Client Synced</b>

<code>${EL_SERVICE}</code> is fully synced." "info"
        clear_lock_alert "obol-el-rpc" "$(node_label)
✅ <b>Resolved: EL RPC Reachable</b>

<code>${EL_RPC}</code> is responding normally." "info"
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
• Verify peer count." "info"
    elif [ "$CL_SYNC" = "error" ]; then
        lock_alert "obol-cl-api" "$(node_label)
⚠️ <b>CL API unreachable</b>: cannot reach <code>${CL_API}</code>.

The consensus client may have crashed or is still starting up.
• Check status: <code>sudo systemctl status ${CL_SERVICE}</code>" "info"
    else
        clear_lock_alert "obol-cl-sync" "$(node_label)
✅ <b>Resolved: CL Client Synced</b>

<code>${CL_SERVICE}</code> is fully synced." "info"
        clear_lock_alert "obol-cl-api" "$(node_label)
✅ <b>Resolved: CL API Reachable</b>

<code>${CL_API}</code> is responding normally." "info"
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
• Check logs: <code>sudo journalctl -u ${EL_SERVICE} -n 30</code>" "detailed"
        else
            clear_lock_alert "obol-el-peers" "$(node_label)
✅ <b>Resolved: EL Peers Recovered</b>

<code>${EL_SERVICE}</code> now has <b>${EL_P}</b> peer(s) connected (minimum: ${EL_PEERS_MIN:-5})." "detailed"
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
• Check logs: <code>sudo journalctl -u ${CL_SERVICE} -n 30</code>" "detailed"
        else
            clear_lock_alert "obol-cl-peers" "$(node_label)
✅ <b>Resolved: CL Peers Recovered</b>

<code>${CL_SERVICE}</code> now has <b>${CL_P}</b> peer(s) connected (minimum: ${CL_PEERS_MIN:-10})." "detailed"
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
• Check cluster peer config in <code>/home/ethereum/.charon/</code>" "critical"
    else
        clear_lock_alert "obol-charon-peers" "$(node_label)
✅ <b>Resolved: Charon Peers Recovered</b>

Charon now has <b>${CHARON_CONNECTED}</b> peer(s) connected (minimum: ${CHARON_PEERS_MIN:-2})." "critical"
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
• Check Charon logs: <code>sudo journalctl -u ${CHARON_SERVICE} -n 30</code>" "info"
    else
        clear_lock_alert "obol-charon-latency" "$(node_label)
✅ <b>Resolved: Charon Peer Latency Normal</b>

All peer latencies are within threshold (${CHARON_LATENCY_ALERT_MS:-500}ms)." "info"
    fi

    # ------------------------------------------------------------------
    # Charon attestation submission delay (from Charon service logs)
    #
    # Scans the last 6 minutes of Charon logs for lines matching
    # "Successfully submitted v2 attestations". The "delay" field is the
    # gap between receiving the minimum valid partial-signature set and
    # actually submitting to the beacon node — a direct proxy for how
    # late the slowest contributing peer was.
    #
    # The "peer" field names the Charon node whose partial signature
    # was the last one needed to meet the threshold, making it the
    # most actionable signal for identifying a slow cluster node.
    #
    # Fires when BCAST_DELAY_COUNT_MIN or more submissions exceed
    # BCAST_DELAY_ALERT_MS within the 5-minute cron window.
    # ------------------------------------------------------------------
    BCAST_DATA=$(journalctl -u "$CHARON_SERVICE" --since "6 minutes ago" \
        --no-pager -q 2>/dev/null | python3 -c "
import sys, re, json
from collections import defaultdict

threshold_ms = ${BCAST_DELAY_ALERT_MS:-3000}
delays = []
peer_counts = defaultdict(int)

for line in sys.stdin:
    if 'Successfully submitted v2 attestations' not in line:
        continue
    m = re.search(r'\{.*\}', line)
    if not m:
        continue
    try:
        data = json.loads(m.group())
        delay_str = data.get('delay', '')
        peer = data.get('peer', 'unknown')
        ms = None
        if delay_str.endswith('ms'):
            ms = float(delay_str[:-2])
        elif delay_str.endswith('s'):
            s_part = delay_str[:-1]
            if 'm' in s_part:
                mins, secs = s_part.split('m', 1)
                ms = float(mins) * 60000 + float(secs or 0) * 1000
            else:
                ms = float(s_part) * 1000
        if ms is not None and ms >= threshold_ms:
            delays.append(ms)
            peer_counts[peer] += 1
    except:
        pass

count = len(delays)
print(f'COUNT:{count}')
if delays:
    top_peer = max(peer_counts, key=peer_counts.get)
    print(f'MAX_MS:{max(delays):.0f}')
    print(f'TOP_PEER:{top_peer}')
    print(f'TOP_COUNT:{peer_counts[top_peer]}')
else:
    print('MAX_MS:0')
    print('TOP_PEER:')
    print('TOP_COUNT:0')
" 2>/dev/null)

    BCAST_HIGH=$(  echo "$BCAST_DATA" | grep '^COUNT:'     | cut -d: -f2)
    BCAST_MAX=$(   echo "$BCAST_DATA" | grep '^MAX_MS:'    | cut -d: -f2)
    BCAST_PEER=$(  echo "$BCAST_DATA" | grep '^TOP_PEER:'  | cut -d: -f2)
    BCAST_PCOUNT=$(echo "$BCAST_DATA" | grep '^TOP_COUNT:' | cut -d: -f2)

    echo "  Bcast high-delay (>${BCAST_DELAY_ALERT_MS:-3000}ms): ${BCAST_HIGH:-0} submissions in last 5 min"

    if [ "${BCAST_HIGH:-0}" -ge "${BCAST_DELAY_COUNT_MIN:-4}" ]; then
        lock_alert "obol-charon-bcast-delay" "$(node_label)
⚠️ <b>Charon slow attestation submissions</b>

High-delay submissions  : <b>${BCAST_HIGH}</b> in last 5 min (threshold: ≥${BCAST_DELAY_COUNT_MIN:-4})
Highest delay           : <b>${BCAST_MAX}ms</b>  (alert above: ${BCAST_DELAY_ALERT_MS:-3000}ms)
Most frequent slow peer : <b>${BCAST_PEER}</b> (${BCAST_PCOUNT} of ${BCAST_HIGH} submissions)

The delay is the gap between the first valid partial-signature set and
actual beacon node submission. A high value means one Charon peer is
consistently late — this degrades head vote timing even without a full
attestation miss.

Suggested actions:
• Check system load on <b>${BCAST_PEER}</b>: <code>uptime</code>, <code>top</code>
• Charon bcast logs : <code>sudo journalctl -u ${CHARON_SERVICE} -n 100 | grep bcast</code>
• Tailscale latency : <code>tailscale ping &lt;peer-tailscale-ip&gt;</code>" "info"
    else
        clear_lock_alert "obol-charon-bcast-delay" "$(node_label)
✅ <b>Resolved: Charon Attestation Submissions Normal</b>

High-delay attestation submissions are no longer detected." "info"
    fi
fi

# =============================================================================
# 5. SYSTEM RESOURCES
# =============================================================================

# --- Swap usage ---
SWAP_KB=$(swap_used_kb)
SWAP_GB=$(swap_used_gb)
SWAP_THRESHOLD_KB=$(( ${SWAP_ALERT_GB:-6} * 1048576 ))

if [ "${SWAP_KB:-0}" -gt "$SWAP_THRESHOLD_KB" ] 2>/dev/null; then
    lock_alert "obol-swap" "$(node_label)
⚠️ <b>High swap usage</b>: <b>${SWAP_GB} GB</b> of swap in use (threshold: ${SWAP_ALERT_GB} GB).

Possible causes:
• Ethereum clients consuming more RAM than available — common during sync
• Memory pressure from running multiple services (EL + CL + Charon + validator)

Suggested actions:
• Check memory: <code>free -h</code>
• Check top consumers: <code>ps aux --sort=-%mem | head -10</code>
• If persistent, consider restarting the highest-RAM client" "info"
else
    clear_lock_alert "obol-swap" "$(node_label)
✅ <b>Resolved: Swap Usage Normal</b>

Swap is back below threshold (currently <b>${SWAP_GB} GB</b>, threshold: ${SWAP_ALERT_GB:-6} GB)." "info"
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
• Consider pruning or switching to a more space-efficient client" "critical"
else
    clear_lock_alert "obol-disk-eth" "$(node_label)
✅ <b>Resolved: Disk Space Recovered</b>

<code>/home/ethereum</code> now has <b>${ETH_FREE} GB</b> free (threshold: ${DISK_ETH_ALERT_GB:-150} GB)." "critical"
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
• Check and rotate logs: <code>sudo journalctl --vacuum-size=500M</code>" "info"
else
    clear_lock_alert "obol-disk-root" "$(node_label)
✅ <b>Resolved: Root Disk Space Recovered</b>

<code>/</code> (root) is now at <b>${ROOT_PCT}%</b> used (threshold: ${DISK_ROOT_ALERT_PCT:-85}%)." "info"
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
• Consider reducing CPU governor: <code>cpufreq-info</code>" "info"
else
    clear_lock_alert "obol-cpu-temp" "$(node_label)
✅ <b>Resolved: CPU Temperature Normal</b>

CPU temperature is back below threshold (currently <b>${CPU_TEMP}°C</b>, threshold: ${CPU_TEMP_ALERT_C:-80}°C)." "info"
fi

# =============================================================================
# 6. CLUSTER DISRUPTION RISK — recommend stopping Charon when node is unhealthy
# =============================================================================
#
# A node that is swapping heavily, overloaded, or falling behind the chain
# degrades QBFT consensus for the whole cluster: it causes round changes that
# delay attestation signing for every other node.
# Stopping Charon on a sick node is better than letting it drag the cluster.
#
# A single CRITICAL alert fires when ANY of these is true:
#   1. Swap usage exceeds CHARON_STOP_SWAP_GB (early warning comes from SWAP_ALERT_GB)
#   2. 1-min load average exceeds CHARON_STOP_CPU_LOAD × number of CPU cores
#   3. CL is actively syncing (sync_distance >= CL_SYNC_DISTANCE_ALERT)
#
# The alert clears automatically once all three conditions resolve.
# =============================================================================

DISRUPT_REASONS=""

# --- Condition 1: Swap above the stop threshold ---
# SWAP_KB was already read in section 5; reuse it to avoid a duplicate call.
CHARON_STOP_SWAP_KB=$(( ${CHARON_STOP_SWAP_GB:-10} * 1048576 ))
if [ "${SWAP_KB:-0}" -gt "$CHARON_STOP_SWAP_KB" ] 2>/dev/null; then
    DISRUPT_REASONS="${DISRUPT_REASONS}• 🔴 <b>Swap critically high</b>: <b>${SWAP_GB} GB</b> in use (stop threshold: ${CHARON_STOP_SWAP_GB:-10} GB)\n"
fi

# --- Condition 2: CPU load average (absolute threshold) ---
# Reads /proc/loadavg (1-minute figure) and compares directly to CHARON_STOP_CPU_LOAD_AVG.
# Uses python3 for float arithmetic; bash cannot handle decimals natively.
LOAD_DATA=$(python3 -c "
try:
    load1 = float(open('/proc/loadavg').read().split()[0])
    threshold = ${CHARON_STOP_CPU_LOAD_AVG:-6}
    over = load1 > threshold
    print(f'LOAD1:{load1:.2f}')
    print(f'THRESHOLD:{threshold}')
    print(f'OVER:true' if over else 'OVER:false')
except Exception:
    print('OVER:error')
" 2>/dev/null)

LOAD1=$(    echo "$LOAD_DATA" | grep '^LOAD1:'     | cut -d: -f2)
LOAD_THR=$( echo "$LOAD_DATA" | grep '^THRESHOLD:' | cut -d: -f2)
LOAD_OVER=$(echo "$LOAD_DATA" | grep '^OVER:'      | cut -d: -f2)

if [ "$LOAD_OVER" = "true" ]; then
    DISRUPT_REASONS="${DISRUPT_REASONS}• 🔴 <b>CPU load critically high</b>: 1-min average <b>${LOAD1}</b> (stop threshold: ${LOAD_THR})\n"
fi

# --- Condition 3: CL sync — sliding-window event counter ---
# A single brief sync detection is noise. This fires only after more than
# CHARON_STOP_SYNC_EVENTS detections within a 1-hour sliding window,
# whether consecutive or not (e.g. backfill slowing the node intermittently).
#
# Each time CL is found syncing, the current timestamp is appended to a JSON
# state file. Events older than 1 hour are pruned. The condition triggers
# when the remaining count exceeds the threshold.
# When CL is healthy the counter naturally decays without needing a reset.
#
# Re-evaluated independently so it works even when section 2 was skipped.

DISRUPT_SYNC_FILE="${HOME:-/home/ethereum}/.obol-monitor/cache/charon-disrupt-sync.json"
DISRUPT_CL_SYNC=$(cl_syncing)
DISRUPT_SYNC_INFO=""

SYNC_DATA=$(python3 -c "
import json, os, sys
state_file = '${DISRUPT_SYNC_FILE}'
now = $(date +%s)
window = 3600  # 1 hour
threshold = ${CHARON_STOP_SYNC_EVENTS:-1}  # fire when count > this
cl_syncing = '${DISRUPT_CL_SYNC}'

# Load existing events
events = []
if os.path.exists(state_file):
    try:
        events = json.load(open(state_file))
    except Exception:
        events = []

# Record a new event if CL is currently syncing
if cl_syncing == 'true':
    events.append(now)

# Prune events older than the window
events = [t for t in events if now - t <= window]

# Persist updated list
os.makedirs(os.path.dirname(state_file), exist_ok=True)
json.dump(events, open(state_file, 'w'))

count = len(events)
over = count > threshold
print(f'COUNT:{count}')
print(f'THRESHOLD:{threshold}')
print(f'OVER:true' if over else 'OVER:false')
" 2>/dev/null)

SYNC_COUNT=$(echo "$SYNC_DATA" | grep '^COUNT:'     | cut -d: -f2)
SYNC_THR=$(  echo "$SYNC_DATA" | grep '^THRESHOLD:' | cut -d: -f2)
SYNC_OVER=$( echo "$SYNC_DATA" | grep '^OVER:'      | cut -d: -f2)

if [ "$SYNC_OVER" = "true" ]; then
    if [ "$DISRUPT_CL_SYNC" = "true" ]; then
        DISRUPT_SYNC_INFO=$(curl -s --max-time 5 "${CL_API:-http://localhost:5052}/eth/v1/node/syncing" \
            2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)['data']
    print(f'head={d[\"head_slot\"]} distance={d[\"sync_distance\"]} slots')
except:
    print('unknown')
")
        DISRUPT_REASONS="${DISRUPT_REASONS}• 🔴 <b>CL repeatedly out of sync</b>: <b>${SYNC_COUNT}</b> detections in last hour (${DISRUPT_SYNC_INFO})\n"
    else
        DISRUPT_REASONS="${DISRUPT_REASONS}• 🔴 <b>CL repeatedly out of sync</b>: <b>${SYNC_COUNT}</b> detections in last hour (currently recovering)\n"
    fi
fi

# --- Fire or clear the composite alert ---
if [ -n "$DISRUPT_REASONS" ]; then
    lock_alert "obol-charon-disrupt" "$(node_label)
🛑 <b>Cluster Disruption Risk — Consider stopping Charon</b>

This node is likely degrading the DVT cluster. A slow or out-of-sync node
triggers QBFT round changes that stall attestation signing for every peer.
Stopping Charon here is safer than letting it drag the whole cluster.

<b>Triggered by:</b>
$(printf "$DISRUPT_REASONS")
<b>Recommended action:</b>
<code>sudo systemctl stop charon</code>

Wait until the node is fully healthy, then restart:
<code>sudo systemctl start charon</code>

Quick status check:
• Memory : <code>free -h</code>
• CPU load: <code>uptime</code>
• CL sync : <code>sudo systemctl status ${CL_SERVICE}</code>" "critical"
else
    clear_lock_alert "obol-charon-disrupt" "$(node_label)
✅ <b>Resolved: Cluster Disruption Risk Cleared</b>

This node has returned to a healthy state:
• Swap below ${CHARON_STOP_SWAP_GB:-10} GB
• CPU load below ${CHARON_STOP_CPU_LOAD_AVG:-6}
• CL sync events in last hour: ${SYNC_COUNT:-0} (threshold: &gt;${CHARON_STOP_SYNC_EVENTS:-1})

If Charon was stopped, restart it now:
<code>sudo systemctl start charon</code>" "critical"
fi