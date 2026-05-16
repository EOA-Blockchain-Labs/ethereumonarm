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
        recovery_alert "ctrl-peer-el-down" "$(node_label)
✅ <b>Primary control node fully restored</b> — EL and relay are responding."
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
• Physical inspection may be required"
        (( OBOL_NODES_DOWN++ )) || true
        _STATUS_NEEDED=true  # node down — status needed
        return
    fi
    recovery_alert "ctrl-node-${idx}-down" "$(node_label)
✅ <b>${node_name}</b> is back online (livez 200)."

    # ------------------------------------------------------------------
    # Fetch metrics — used for readyz reason, peer count, latency, VC check
    # ------------------------------------------------------------------
    METRICS_RAW=$(curl -s --max-time "${CHARON_API_TIMEOUT:-8}" \
        "${base_url}/metrics" 2>/dev/null)

    if [ -z "$METRICS_RAW" ]; then
        lock_alert "ctrl-node-${idx}-metrics" "$(node_label)
⚠️ <b>${node_name}</b>: Charon metrics endpoint returned empty response.
Charon may be starting up.
• SSH in and check: <code>sudo systemctl status charon</code>"
        return
    fi
    clear_lock "ctrl-node-${idx}-metrics"

    # ------------------------------------------------------------------
    # readyz check — 200 = ready, 500 = not ready.
    # Reason decoded from app_monitoring_readyz metric:
    #   2 = beacon node down | 3 = syncing | 4 = insufficient peers
    #   any other value = validator client not connected (Charon waiting for VC)
    # ------------------------------------------------------------------
    READYZ_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --max-time "${CHARON_API_TIMEOUT:-8}" \
        "${base_url}/readyz" 2>/dev/null)

    if [ "$READYZ_CODE" = "500" ]; then
        READYZ_VAL=$(echo "$METRICS_RAW" | \
            awk '/^app_monitoring_readyz / {print $2; exit}')
        case "${READYZ_VAL:-0}" in
            2)
                lock_alert "ctrl-node-${idx}-readyz" "$(node_label)
⚠️ <b>${node_name}</b>: Charon not ready — beacon node is DOWN

Charon /readyz returned 500 (code 2).

Suggested actions:
• Check beacon node: <code>sudo journalctl -u ${CL_SERVICE:-beacon} -n 30</code>
• Check Charon logs: <code>sudo journalctl -u charon -n 30</code>"
                ;;
            3)
                lock_alert "ctrl-node-${idx}-readyz" "$(node_label)
⚠️ <b>${node_name}</b>: Charon not ready — beacon node is syncing

Charon /readyz returned 500 (code 3). Beacon node is still catching up.

Suggested actions:
• Check sync: <code>sudo journalctl -u ${CL_SERVICE:-beacon} -n 30</code>"
                ;;
            4)
                lock_alert "ctrl-node-${idx}-readyz" "$(node_label)
⚠️ <b>${node_name}</b>: Charon not ready — insufficient DVT peers

Charon /readyz returned 500 (code 4). Not enough peers connected.
• Check Charon logs: <code>sudo journalctl -u charon -n 30</code>"
                ;;
            *)
                # Unknown code: Charon is waiting for a validator client connection
                lock_alert "ctrl-node-${idx}-vc-inactive" "$(node_label)
🚨 <b>${node_name}</b>: Validator client is NOT connected to Charon

Charon /readyz returned 500 (app_monitoring_readyz=${READYZ_VAL:-?}).
Charon is running and ready but no validator client is attached.

Suggested actions:
• Check validator service: <code>sudo systemctl status &lt;vc-service&gt;</code>
• Check Charon logs: <code>sudo journalctl -u charon -n 50</code>"
                ;;
        esac
    else
        recovery_alert "ctrl-node-${idx}-readyz" "$(node_label)
✅ <b>${node_name}</b>: Charon is ready again (readyz 200)."
        recovery_alert "ctrl-node-${idx}-vc-inactive" "$(node_label)
✅ <b>${node_name}</b>: Validator client is connected to Charon."
    fi


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
• Confirm the missing peer node is reachable"
    else
        recovery_alert "ctrl-node-${idx}-charon-peers" "$(node_label)
✅ <b>${node_name}</b>: Charon peers restored (${CHARON_PEERS}/${CHARON_PEERS_MIN:-2})."
    fi

    # ------------------------------------------------------------------
    # Charon peer latency (p50)
    # p2p_ping_latency_seconds histogram (_sum/_count per peer label)
    # May be absent if no pings recorded yet — skip alert if empty.
    # ------------------------------------------------------------------
    # Latency: histogram average per peer using _sum/_count.
    HIGH_LATENCY=$(echo "$METRICS_RAW" | python3 -c "
import sys
threshold = ${CHARON_LATENCY_ALERT_MS:-500} / 1000.0
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
bad = []
for peer in sums:
    cnt = counts.get(peer, 0)
    if cnt > 0 and peer != \"unknown\" and sums[peer]/cnt > threshold:
        bad.append(f\"{peer} ({sums[peer]/cnt*1000:.0f}ms avg)\")
print(\", \".join(bad))
" 2>/dev/null)

    if [ -n "$HIGH_LATENCY" ]; then
        lock_alert "ctrl-node-${idx}-charon-latency" "$(node_label)
⚠️ <b>${node_name}</b>: Charon high peer latency (p50) exceeding ${CHARON_LATENCY_ALERT_MS}ms:
<b>${HIGH_LATENCY}</b>

High inter-node latency can cause missed attestations in the DVT cluster.

Suggested actions:
• Check Tailscale latency: <code>tailscale ping &lt;peer-tailscale-ip&gt;</code>
• Check Charon logs on ${node_name}: <code>sudo journalctl -u charon -n 30</code>"
    else
        recovery_alert "ctrl-node-${idx}-charon-latency" "$(node_label)
✅ <b>${node_name}</b>: Charon latency back within threshold."
    fi

    # ------------------------------------------------------------------
    # Validator client activity
    #
    # core_scheduler_validators_active is a gauge set by Charon showing
    # how many validators are registered with its scheduler.
    # Value 0 means no VC is connected to this Charon node.
    #
    # NOTE: core_bcast_broadcast_total is not used here — in DVT/QBFT only
    # the slot leader increments it. Per-node broadcast counters are
    # unreliable for VC detection. Attestation monitoring is handled by
    # validator-duties.sh.
    # ------------------------------------------------------------------
    VALIDATORS_ACTIVE=$(echo "$METRICS_RAW" | \
        awk '/^core_scheduler_validators_active\{/ {print $2; exit}')
    VALIDATORS_ACTIVE="${VALIDATORS_ACTIVE:-0}"

    if [ "${VALIDATORS_ACTIVE}" = "0" ]; then
        lock_alert "ctrl-node-${idx}-vc-inactive" "$(node_label)
🚨 <b>${node_name}</b>: No validator client connected to Charon

Metric <code>core_scheduler_validators_active</code> = <b>0</b>

Charon has no validators registered. The validator client is not
running or has not connected to Charon yet.

Suggested actions:
• Check validator service: <code>sudo systemctl status &lt;vc-service&gt;</code>
• Check Charon logs: <code>sudo journalctl -u charon -n 50</code>"
    else
        recovery_alert "ctrl-node-${idx}-vc-inactive" "$(node_label)
✅ <b>${node_name}</b>: Validator client connected — ${VALIDATORS_ACTIVE} validator(s) active."
    fi
}

# Run check for each Obol node — dynamic loop over CLUSTER_SIZE
OBOL_NODES_DOWN=0
_STATUS_NEEDED=false
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

# Determine if the Obol cluster has crossed the DVT failure threshold.
# The cluster can attest as long as >= ceil(2/3 * CLUSTER_SIZE) nodes are up.
# Failure threshold = nodes that must be down to break the cluster:
#   fail_at = CLUSTER_SIZE - ceil(2/3 * CLUSTER_SIZE) + 1
# e.g. 3-node: fail_at=2  |  5-node: fail_at=2  |  9-node: fail_at=4
CLUSTER_FAIL_AT=$(python3 -c "
import math
n = int("${CLUSTER_SIZE:-3}")
print(n - math.ceil(2/3 * n) + 1)
")
CLUSTER_FAILING=false
if [ "${OBOL_NODES_DOWN:-0}" -ge "${CLUSTER_FAIL_AT:-2}" ] 2>/dev/null; then
    CLUSTER_FAILING=true
    echo "⚠️  Cluster failing: ${OBOL_NODES_DOWN} node(s) down (threshold: ${CLUSTER_FAIL_AT})"
fi

# =============================================================================
# SECTION 2 — LOCAL SERVICES (control node itself)
# =============================================================================

check_local_svc() {
    local svc="$1"
    local label="$2"
    local lock="ctrl-local-svc-${svc}"
    if service_active "$svc"; then
        recovery_alert "$lock" "$(node_label)
✅ <b>Local service RESTORED</b>: <code>${svc}</code> (${label}) is running again on <b>${NODE_NAME}</b>."
    else
        lock_alert "$lock" "$(node_label)
🚨 <b>Local service DOWN</b>: <code>${svc}</code> (${label}) is not running on <b>${NODE_NAME}</b>.

• <code>sudo systemctl status ${svc}</code>
• <code>sudo journalctl -u ${svc} -n 50</code>"
    fi
}

check_local_svc "$EL_SERVICE"         "Execution client (backup)"
check_local_svc "$CL_SERVICE"         "Consensus client (backup)"
check_local_svc "$MEV_SERVICE"        "MEV Boost (backup)"
check_local_svc "$OBOL_RELAY_SERVICE" "Obol relay"

# =============================================================================
# CLUSTER FAILURE RESPONSE
# =============================================================================

if [ "$CLUSTER_FAILING" = "true" ]; then

    # ------------------------------------------------------------------
    # Alert 1 — Cluster failure notice (fires immediately when threshold
    # is crossed, regardless of whether the backup validator is running).
    # ------------------------------------------------------------------
    if lock_alert "ctrl-cluster-failing" "$(node_label)
🚨 <b>Obol cluster has FAILED</b>

The cluster has lost <b>${OBOL_NODES_DOWN}/${CLUSTER_SIZE}</b> nodes — the DVT threshold
is broken and validators can no longer attest via Charon.

Recommended actions:
• Investigate which nodes are down (check Tailscale + board power)
• If the cluster cannot recover quickly, start the backup validator:
  <code>sudo systemctl start ${VALIDATOR_SERVICE}</code>
• Monitor: <code>sudo systemctl status ${VALIDATOR_SERVICE}</code>"; then
        _STATUS_NEEDED=true  # cluster failing — status needed
    fi

    # ------------------------------------------------------------------
    # Alert 2 — Backup validator is down while cluster is failing.
    # Escalation of Alert 1: nobody is covering the validators right now.
    # ------------------------------------------------------------------
    if ! service_active "$VALIDATOR_SERVICE"; then
        lock_alert "ctrl-local-svc-${VALIDATOR_SERVICE}" "$(node_label)
🚨 <b>NO VALIDATOR COVERAGE — immediate action required</b>

Obol cluster: <b>FAILED</b> (${OBOL_NODES_DOWN}/${CLUSTER_SIZE} nodes down)
Backup validator on <b>${NODE_NAME}</b>: <b>NOT RUNNING</b>

Validators are currently missing attestations. Start the backup now:
• <code>sudo systemctl start ${VALIDATOR_SERVICE}</code>
• <code>sudo systemctl status ${VALIDATOR_SERVICE}</code>"
    else
        clear_lock "ctrl-local-svc-${VALIDATOR_SERVICE}"
    fi

else
    # Cluster is healthy — clear all failure alerts
    recovery_alert "ctrl-cluster-failing" "$(node_label)
✅ <b>Obol cluster RESTORED</b> — all nodes are back up and attesting."
    recovery_alert "ctrl-local-svc-${VALIDATOR_SERVICE}" "$(node_label)
✅ Cluster restored — backup validator situation resolved."
fi

# =============================================================================
# FAILOVER NODE: check if primary control is already covering validators
# Only runs on control-failover nodes when the cluster is detected as failing.
# Queries local beacon liveness to see if validators are attesting — if yes,
# the primary backup is already running them; no action needed from failover.
# =============================================================================

if [ "${NODE_TYPE:-}" = "control-failover" ] && [ "$CLUSTER_FAILING" = "true" ]; then
    # Load validator indices from cache
    if [ -f "${INDEX_CACHE:-}" ]; then
        ACTIVE_INDICES=$(python3 -c "
import json, sys
with open('$INDEX_CACHE') as f:
    cache = json.load(f)
active = [v['index'] for v in cache.values() if 'active' in v.get('status','')]
print(','.join(active))
" 2>/dev/null)

        if [ -n "$ACTIVE_INDICES" ]; then
            INDICES_JSON=$(python3 -c "
import json, sys
print(json.dumps(sys.argv[1].split(',')))
" "$ACTIVE_INDICES" 2>/dev/null)

            CHECK_EP=$(check_epoch)
            if [ -n "$CHECK_EP" ] && [ -n "$INDICES_JSON" ]; then
                LIVE_RESP=$(beacon_post "/eth/v1/validator/liveness/${CHECK_EP}" "$INDICES_JSON")
                LIVE_HTTP=$(beacon_http_code)

                if [ "$LIVE_HTTP" = "200" ] && [ -n "$LIVE_RESP" ]; then
                    LIVE_COUNT=$(echo "$LIVE_RESP" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)['data']
    print(sum(1 for v in data if v.get('is_live', False)))
except: print(0)
" 2>/dev/null)
                    TOTAL_COUNT=$(echo "$ACTIVE_INDICES" | tr ',' '
' | wc -w | tr -d ' ')

                    if [ "${LIVE_COUNT:-0}" -gt 0 ] 2>/dev/null; then
                        # Validators are attesting — primary backup is running them
                        echo "  Validators live: ${LIVE_COUNT}/${TOTAL_COUNT} — primary backup appears to be covering."
                        clear_lock "ctrl-failover-no-coverage"
                    else
                        # Nobody covering validators — alert failover operator
                        lock_alert "ctrl-failover-no-coverage" "$(node_label)
🚨 <b>Cluster FAILED — validators have NO coverage</b>

Obol cluster: <b>FAILED</b> (${OBOL_NODES_DOWN}/${CLUSTER_SIZE} nodes down)
Validators attesting this epoch: <b>${LIVE_COUNT:-0} / ${TOTAL_COUNT}</b>

The primary control node does not appear to be running the backup validator.
This failover node may need to activate its own backup validator.

Check primary control node status, then if unresponsive:
• <code>sudo systemctl start ${VALIDATOR_SERVICE}</code>
• <code>sudo systemctl status ${VALIDATOR_SERVICE}</code>"
                    fi
                fi
            fi
        fi
    fi
fi

# =============================================================================
# SECTION 3 — LOCAL SYSTEM RESOURCES (control node)
# =============================================================================

# Swap
SWAP_KB=$(swap_used_kb)
SWAP_GB=$(swap_used_gb)
SWAP_THRESH_KB=$(( ${SWAP_ALERT_GB:-10} * 1048576 ))
if [ "${SWAP_KB:-0}" -gt "$SWAP_THRESH_KB" ] 2>/dev/null; then
    lock_alert "ctrl-local-swap" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): High swap usage — <b>${SWAP_GB} GB</b> in use (threshold: ${SWAP_ALERT_GB} GB).
• <code>free -h</code>
• <code>ps aux --sort=-%mem | head -10</code>"
else
    recovery_alert "ctrl-local-swap" "$(node_label)
✅ <b>Swap resolved</b>: swap usage is back below ${SWAP_ALERT_GB:-10} GB on <b>${NODE_NAME}</b>."
fi

# /home/ethereum disk
ETH_FREE=$(disk_free_gb /home/ethereum)
if [ "${ETH_FREE:-999}" -lt "${DISK_ETH_ALERT_GB:-150}" ] 2>/dev/null; then
    lock_alert "ctrl-local-disk-eth" "$(node_label)
🚨 <b>${NODE_NAME}</b> (control): Low disk on <code>/home/ethereum</code> — only <b>${ETH_FREE} GB</b> free (threshold: ${DISK_ETH_ALERT_GB} GB)."
else
    recovery_alert "ctrl-local-disk-eth" "$(node_label)
✅ <b>Disk space restored</b>: /home/ethereum has more than ${DISK_ETH_ALERT_GB:-150} GB free on <b>${NODE_NAME}</b>."
fi

# / disk
ROOT_PCT=$(disk_used_pct /)
if [ "${ROOT_PCT:-0}" -gt "${DISK_ROOT_ALERT_PCT:-85}" ] 2>/dev/null; then
    lock_alert "ctrl-local-disk-root" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): Root <code>/</code> at <b>${ROOT_PCT}%</b> used (threshold: ${DISK_ROOT_ALERT_PCT}%).
• <code>sudo journalctl --vacuum-size=500M</code>
• <code>sudo apt-get clean</code>"
else
    recovery_alert "ctrl-local-disk-root" "$(node_label)
✅ <b>Root disk resolved</b>: / usage is back below ${DISK_ROOT_ALERT_PCT:-85}% on <b>${NODE_NAME}</b>."
fi

# CPU temperature
CPU_TEMP=$(cpu_temp_max)
if [ "${CPU_TEMP:-0}" -gt "${CPU_TEMP_ALERT_C:-80}" ] 2>/dev/null; then
    lock_alert "ctrl-local-cpu-temp" "$(node_label)
🌡 <b>${NODE_NAME}</b> (control): CPU temperature <b>${CPU_TEMP}°C</b> (threshold: ${CPU_TEMP_ALERT_C}°C)."
else
    recovery_alert "ctrl-local-cpu-temp" "$(node_label)
✅ <b>CPU temperature normalized</b>: back below ${CPU_TEMP_ALERT_C:-80}°C on <b>${NODE_NAME}</b>."
fi

# Local EL sync
if service_active "$EL_SERVICE"; then
    EL_SYNC=$(el_syncing)
    if [ "$EL_SYNC" = "true" ]; then
        lock_alert "ctrl-local-el-sync" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): backup EL client is not synced.
• <code>sudo journalctl -u ${EL_SERVICE} -n 30</code>"
    else
        recovery_alert "ctrl-local-el-sync" "$(node_label)
✅ <b>Backup EL client synced</b>: <code>${EL_SERVICE}</code> is now synced on <b>${NODE_NAME}</b>."
    fi
fi

# Local CL sync
if service_active "$CL_SERVICE"; then
    CL_SYNC=$(cl_syncing)
    if [ "$CL_SYNC" = "true" ]; then
        lock_alert "ctrl-local-cl-sync" "$(node_label)
⚠️ <b>${NODE_NAME}</b> (control): backup CL client is not synced.
• <code>sudo journalctl -u ${CL_SERVICE} -n 30</code>"
    else
        recovery_alert "ctrl-local-cl-sync" "$(node_label)
✅ <b>Backup CL client synced</b>: <code>${CL_SERVICE}</code> is now synced on <b>${NODE_NAME}</b>."
    fi
fi

# =============================================================================
# STATUS REPORT TRIGGER
# Fire once when a significant condition first appears (lock prevents repeats).
# Fire again on recovery so the operator sees the cluster is healthy.
# =============================================================================
if [ "$_STATUS_NEEDED" = "true" ]; then
    # lock_alert with empty message: only fires once per LOCK_EXPIRY window.
    # We suppress the Telegram send (empty msg) and use the return code only.
    _STATUS_LOCK="${LOCK_DIR}/alert-ctrl-status-report.lock"
    if [ ! -f "$_STATUS_LOCK" ]; then
        touch "$_STATUS_LOCK"
        "${SCRIPT_DIR}/control-status.sh" >> "${LOCK_DIR}/../logs/control-status.log" 2>&1 &
    fi
else
    # Everything is healthy — if lock existed, cluster just recovered: send one final report
    _STATUS_LOCK="${LOCK_DIR}/alert-ctrl-status-report.lock"
    if [ -f "$_STATUS_LOCK" ]; then
        rm -f "$_STATUS_LOCK"
        "${SCRIPT_DIR}/control-status.sh" >> "${LOCK_DIR}/../logs/control-status.log" 2>&1 &
    fi
fi