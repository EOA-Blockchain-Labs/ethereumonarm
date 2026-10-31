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

# =============================================================================
# PRIMARY / FAILOVER DEDUPLICATION — with mutual reachability alerts
# =============================================================================
# PEER_CONTROL_IP empty  → this is the primary; always runs checks.
# PEER_CONTROL_IP set    → this is the failover; pings the primary first.
#   Primary responds     → defer; clear any "taking over" alert and exit.
#   Primary unreachable  → alert once (state file), then run full checks.
#
# PEER_FAILOVER_IP (optional, primary only) → primary pings the failover at
# the end of its run and alerts if unreachable (lock-gated, INFO level).
# =============================================================================

_TAKEOVER_FILE="${HOME:-/home/ethereum}/.obol-monitor/cache/ctrl-takeover.sig"

if [ -n "${PEER_CONTROL_IP:-}" ]; then
    # ---- FAILOVER NODE: check whether primary is reachable ----
    _TAKEOVER_PREV="__unset__"
    [ -f "$_TAKEOVER_FILE" ] && _TAKEOVER_PREV=$(cat "$_TAKEOVER_FILE" 2>/dev/null)

    if ping -c 1 -W "${PEER_CHECK_TIMEOUT:-5}" "$PEER_CONTROL_IP" > /dev/null 2>&1; then
        # Primary is up — clear takeover alert if we were previously standing in
        if [ "$_TAKEOVER_PREV" = "down" ]; then
            mkdir -p "$(dirname "$_TAKEOVER_FILE")"
            echo "up" > "$_TAKEOVER_FILE"
            send_telegram "$(node_label)
✅ <b>Primary control node restored</b>

<b>${PEER_CONTROL_NAME:-primary control}</b> (<code>${PEER_CONTROL_IP}</code>) is reachable again.
This node is standing down — primary has resumed cluster monitoring."
        fi
        echo "Peer control node (${PEER_CONTROL_IP}) is reachable — deferring health check to primary."
        exit 0
    else
        # Primary is unreachable — alert once on transition, then take over
        if [ "$_TAKEOVER_PREV" != "down" ]; then
            mkdir -p "$(dirname "$_TAKEOVER_FILE")"
            echo "down" > "$_TAKEOVER_FILE"
            send_telegram "$(node_label)
🚨 <b>Primary control node unreachable</b>

<b>${PEER_CONTROL_NAME:-primary control}</b> (<code>${PEER_CONTROL_IP}</code>) is not responding.
This node is taking over cluster monitoring.

Suggested actions:
• Check Tailscale: <code>tailscale ping ${PEER_CONTROL_IP}</code>
• Check if the primary control node is online"
        fi
        # Fall through — failover runs the full health check
    fi
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
        eval "OBOL_NODE_${idx}_ONLINE=0"   # tracked for cluster status summary
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
    eval "OBOL_NODE_${idx}_ONLINE=1"       # tracked for cluster status summary
    clear_lock_alert "ctrl-node-${idx}-down" "$(node_label)
✅ <b>Resolved: Obol Node Reachable</b>

<b>${node_name}</b> (<code>${node_ip}</code>) is responding to /livez again." "critical"

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
    clear_lock_alert "ctrl-node-${idx}-metrics" "$(node_label)
✅ <b>Resolved: Charon Metrics Available</b>

<b>${node_name}</b>: metrics endpoint is responding normally." "detailed"

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
        clear_lock_alert "ctrl-node-${idx}-charon-peers" "$(node_label)
✅ <b>Resolved: Charon Peers Recovered</b>

<b>${node_name}</b>: Charon now has <b>${CHARON_PEERS}</b> peer(s) connected (expected: ${CHARON_PEERS_EXPECTED:-2})." "critical"
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
        clear_lock_alert "ctrl-node-${idx}-charon-latency" "$(node_label)
✅ <b>Resolved: Charon Peer Latency Normal</b>

<b>${node_name}</b>: All peer latencies are within threshold (${CHARON_LATENCY_ALERT_MS:-500}ms)." "info"
    fi

    # ------------------------------------------------------------------
    # Charon peer latency outlier detection
    #
    # Computes per-peer average latency from histogram _sum/_count and
    # checks whether ONE peer is significantly slower than all others.
    # A peer is flagged as an outlier when:
    #   avg > 3 × median of all peers   AND   avg > CHARON_LATENCY_ALERT_MS
    #
    # This detects a slow/overloaded Charon instance from its peers'
    # perspective. A slow node causes QBFT round changes that degrade
    # attestation performance even when the node is technically alive.
    #
    # NOTE: peer labels are Charon p2p IDs, not human-readable names.
    # Cross-reference with the daily control-status.sh latency report.
    # ------------------------------------------------------------------
    OUTLIER_PEER=$(echo "$METRICS_RAW" | python3 -c "
import sys, statistics
sums = {}; counts = {}
for line in sys.stdin:
    line = line.strip()
    if not line or line.startswith('#'): continue
    try:
        if '_sum{' in line:     kind = 'sum'
        elif '_count{' in line: kind = 'count'
        else: continue
        labels_part = line.split('{', 1)[1].split('}')[0]
        val = float(line.rsplit('}', 1)[1].strip())
        peer = 'unknown'
        for kv in labels_part.split(','):
            k, _, v = kv.partition('=')
            if k.strip() == 'peer':
                peer = v.strip().strip(chr(34))
        if kind == 'sum':   sums[peer]   = val
        if kind == 'count': counts[peer] = val
    except: pass

avgs = {}
for peer in sums:
    cnt = counts.get(peer, 0)
    if cnt > 0 and peer != 'unknown':
        avgs[peer] = sums[peer] / cnt * 1000  # ms

if len(avgs) < 2:
    sys.exit(0)

vals   = list(avgs.values())
median = statistics.median(vals)
floor  = ${CHARON_LATENCY_ALERT_MS:-500}

worst_peer = max(avgs, key=avgs.get)
worst_ms   = avgs[worst_peer]
others_ms  = [v for p, v in avgs.items() if p != worst_peer]
other_avg  = sum(others_ms) / len(others_ms) if others_ms else 0

if worst_ms > 3 * max(median, 1) and worst_ms > floor:
    print(f'{worst_peer} ({worst_ms:.0f}ms avg vs {other_avg:.0f}ms others avg)')
" 2>/dev/null)

    if [ -n "$OUTLIER_PEER" ]; then
        lock_alert "ctrl-node-${idx}-charon-outlier" "$(node_label)
⚠️ <b>${node_name}</b>: One Charon peer has significantly higher latency than the rest.

Outlier: <b>${OUTLIER_PEER}</b>

A slow Charon instance is worse than a down one — it still participates in
QBFT but causes round changes, stalling consensus for the entire cluster.
This can reduce attestation performance even when all nodes appear reachable.

Suggested actions:
• Check system load on the slow peer: <code>uptime</code>, <code>top</code>
• Check Charon on the slow peer: <code>sudo journalctl -u charon -n 50</code>
• Check Tailscale path quality: <code>tailscale ping &lt;peer-tailscale-ip&gt;</code>" "info"
    else
        clear_lock_alert "ctrl-node-${idx}-charon-outlier" "$(node_label)
✅ <b>Resolved: Charon Peer Latency Balanced</b>

<b>${node_name}</b>: No peer latency outlier detected." "info"
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
# CLUSTER STATUS SUMMARY — fires once per state change (node goes down or up)
# =============================================================================
# After the per-node loop, collect which nodes are online/offline and build a
# sorted state signature. Send one Telegram message whenever the signature
# differs from the last recorded state — a node just went down, or came back.
#
# No lock is used: the state file is the deduplication mechanism. This means
# the message fires exactly once per transition, not once per 24 h like a lock.
# =============================================================================

_CS_DOWN=()
_CS_UP=()
for _idx in $(seq 1 "${CLUSTER_SIZE:-3}"); do
    _cs_ip_var="OBOL_NODE_${_idx}_IP"
    _cs_name_var="OBOL_NODE_${_idx}_NAME"
    _cs_online_var="OBOL_NODE_${_idx}_ONLINE"
    [ -z "${!_cs_ip_var}" ] && continue           # skip unconfigured node slots
    _cs_name="${!_cs_name_var:-obol-node-${_idx}}"
    _cs_online="${!_cs_online_var:-0}"
    if [ "${_cs_online}" = "1" ]; then
        _CS_UP+=("${_cs_name}")
    else
        _CS_DOWN+=("${_cs_name}")
    fi
done
unset _idx _cs_ip_var _cs_name_var _cs_online_var _cs_name _cs_online

_CS_UP_N=${#_CS_UP[@]}
_CS_DOWN_N=${#_CS_DOWN[@]}
_CS_TOTAL=$(( _CS_UP_N + _CS_DOWN_N ))
_CS_QUORUM=$(( (_CS_TOTAL * 2 + 2) / 3 ))   # ceiling of 2N/3 — QBFT signing threshold

# State signature: sorted comma-separated list of down node names (empty = all up)
_CS_SIG=$(printf '%s\n' "${_CS_DOWN[@]}" | sort | paste -sd ',' - 2>/dev/null || echo "")

_CS_STATE_FILE="${HOME:-/home/ethereum}/.obol-monitor/cache/cluster-state.sig"
_CS_PREV_SIG="__unset__"
[ -f "$_CS_STATE_FILE" ] && _CS_PREV_SIG=$(cat "$_CS_STATE_FILE" 2>/dev/null)

if [ "$_CS_SIG" != "$_CS_PREV_SIG" ]; then
    mkdir -p "$(dirname "$_CS_STATE_FILE")"
    echo "$_CS_SIG" > "$_CS_STATE_FILE"

    # Build per-node status lines (up first, then down)
    _CS_LINES=""
    for _n in "${_CS_UP[@]}";   do _CS_LINES="${_CS_LINES}• ✅ ${_n}\n"; done
    for _n in "${_CS_DOWN[@]}"; do _CS_LINES="${_CS_LINES}• 🔴 ${_n} (not responding)\n"; done

    if [ "${_CS_DOWN_N}" -eq 0 ]; then
        send_telegram "$(node_label)
✅ <b>Cluster fully healthy</b> — all <b>${_CS_UP_N}/${_CS_TOTAL}</b> nodes online

$(printf "${_CS_LINES}")"
    else
        send_telegram "$(node_label)
⚠️ <b>Cluster status changed</b>: <b>${_CS_UP_N}/${_CS_TOTAL}</b> nodes online

$(printf "${_CS_LINES}")
Signing requires ≥ <b>${_CS_QUORUM}/${_CS_TOTAL}</b> nodes (2/3 threshold)."
    fi
fi
unset _CS_DOWN _CS_UP _CS_UP_N _CS_DOWN_N _CS_TOTAL _CS_QUORUM
unset _CS_SIG _CS_STATE_FILE _CS_PREV_SIG _CS_LINES _n

# =============================================================================
# SECTION 2 — LOCAL SERVICES (control node itself)
# =============================================================================

check_local_svc() {
    local svc="$1"
    local label="$2"
    local lock="ctrl-local-svc-${svc}"
    if service_active "$svc"; then
        clear_lock_alert "$lock" "$(node_label)
✅ <b>Resolved: Local Service Restored</b>

<code>${svc}</code> (${label}) is running again on <b>${NODE_NAME}</b>." "detailed"
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
    clear_lock_alert "ctrl-local-swap" "$(node_label)
✅ <b>Resolved: Swap Usage Normal</b>

<b>${NODE_NAME}</b> (control): swap is back below threshold (currently <b>${SWAP_GB} GB</b>, threshold: ${SWAP_ALERT_GB:-6} GB)." "info"
fi

# /home/ethereum disk
ETH_FREE=$(disk_free_gb /home/ethereum)
if [ "${ETH_FREE:-999}" -lt "${DISK_ETH_ALERT_GB:-150}" ] 2>/dev/null; then
    lock_alert "ctrl-local-disk-eth" "$(node_label)
🚨 <b>${NODE_NAME}</b> (control): Low disk on <code>/home/ethereum</code> — only <b>${ETH_FREE} GB</b> free (threshold: ${DISK_ETH_ALERT_GB} GB)." "critical"
else
    clear_lock_alert "ctrl-local-disk-eth" "$(node_label)
✅ <b>Resolved: Disk Space Recovered</b>

<b>${NODE_NAME}</b> (control): <code>/home/ethereum</code> now has <b>${ETH_FREE} GB</b> free (threshold: ${DISK_ETH_ALERT_GB:-150} GB)." "critical"
fi

# / disk
ROOT_PCT=$(disk_used_pct /)
if [ "${ROOT_PCT:-0}" -gt "${DISK_ROOT_ALERT_PCT:-85}" ] 2>/dev/null; then
    lock_alert "ctrl-local-disk-root" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): Root <code>/</code> at <b>${ROOT_PCT}%</b> used (threshold: ${DISK_ROOT_ALERT_PCT}%).
• <code>sudo journalctl --vacuum-size=500M</code>
• <code>sudo apt-get clean</code>" "info"
else
    clear_lock_alert "ctrl-local-disk-root" "$(node_label)
✅ <b>Resolved: Root Disk Space Recovered</b>

<b>${NODE_NAME}</b> (control): <code>/</code> is now at <b>${ROOT_PCT}%</b> used (threshold: ${DISK_ROOT_ALERT_PCT:-85}%)." "info"
fi

# CPU temperature
CPU_TEMP=$(cpu_temp_max)
if [ "${CPU_TEMP:-0}" -gt "${CPU_TEMP_ALERT_C:-80}" ] 2>/dev/null; then
    lock_alert "ctrl-local-cpu-temp" "$(node_label)
🌡 <b>${NODE_NAME}</b> (control): CPU temperature <b>${CPU_TEMP}°C</b> (threshold: ${CPU_TEMP_ALERT_C}°C)." "info"
else
    clear_lock_alert "ctrl-local-cpu-temp" "$(node_label)
✅ <b>Resolved: CPU Temperature Normal</b>

<b>${NODE_NAME}</b> (control): CPU temperature is back below threshold (currently <b>${CPU_TEMP}°C</b>, threshold: ${CPU_TEMP_ALERT_C:-80}°C)." "info"
fi

# Local EL sync
if service_active "$EL_SERVICE"; then
    EL_SYNC=$(el_syncing)
    if [ "$EL_SYNC" = "true" ]; then
        lock_alert "ctrl-local-el-sync" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): backup EL client is not synced.
• <code>sudo journalctl -u ${EL_SERVICE} -n 30</code>" "detailed"
    else
        clear_lock_alert "ctrl-local-el-sync" "$(node_label)
✅ <b>Resolved: Backup EL Client Synced</b>

<b>${NODE_NAME}</b> (control): <code>${EL_SERVICE}</code> is fully synced." "detailed"
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
        clear_lock_alert "ctrl-local-cl-sync" "$(node_label)
✅ <b>Resolved: Backup CL Client Synced</b>

<b>${NODE_NAME}</b> (control): <code>${CL_SERVICE}</code> is fully synced." "detailed"
    fi
fi

# =============================================================================
# FAILOVER NODE REACHABILITY CHECK (primary only)
# Runs only when PEER_CONTROL_IP is empty (i.e. this is the primary) and
# PEER_FAILOVER_IP is configured. Alerts when the failover becomes unreachable
# so the operator knows monitoring redundancy has been lost.
# =============================================================================
if [ -z "${PEER_CONTROL_IP:-}" ] && [ -n "${PEER_FAILOVER_IP:-}" ]; then
    if ping -c 1 -W "${PEER_CHECK_TIMEOUT:-5}" "$PEER_FAILOVER_IP" > /dev/null 2>&1; then
        clear_lock_alert "ctrl-failover-down" "$(node_label)
✅ <b>Resolved: Failover control node reachable</b>

<b>${PEER_FAILOVER_NAME:-failover control}</b> (<code>${PEER_FAILOVER_IP}</code>) is responding again.
Cluster monitoring redundancy is restored." "info"
    else
        lock_alert "ctrl-failover-down" "$(node_label)
⚠️ <b>Failover control node unreachable</b>

<b>${PEER_FAILOVER_NAME:-failover control}</b> (<code>${PEER_FAILOVER_IP}</code>) is not responding.
Cluster monitoring has no redundancy until it recovers.

Suggested actions:
• Check Tailscale: <code>tailscale ping ${PEER_FAILOVER_IP}</code>
• Check if the failover control node is online" "info"
    fi
fi