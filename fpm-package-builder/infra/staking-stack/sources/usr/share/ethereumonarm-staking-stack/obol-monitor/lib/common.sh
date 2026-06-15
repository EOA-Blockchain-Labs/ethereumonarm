#!/bin/bash
# =============================================================================
# lib/common.sh — shared helpers for all obol-monitor scripts
# Source this file at the top of every script:
#   . "$(dirname "$0")/../lib/common.sh"
# Requires node.env to be loaded first.
# =============================================================================

# -----------------------------------------------------------------------------
# send_telegram <message>
# Sends a plain-text message to the configured Telegram chat.
# Returns 0 on success, 1 on failure.
# -----------------------------------------------------------------------------
send_telegram() {
    local message="$1"
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo "ERROR: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set" >&2
        return 1
    fi
    curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"${TELEGRAM_CHAT_ID}\",
            \"text\": $(printf '%s' "$message" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))'),
            \"parse_mode\": \"HTML\"
        }" \
        --max-time 15 \
        -o /dev/null
}

# -----------------------------------------------------------------------------
# lock_alert <lock_name> <message>
# Sends <message> via Telegram only if no lock exists for <lock_name>.
# Creates a lock file so the same alert is not sent more than once per
# LOCK_EXPIRY window (default 24 h, set in node.env).
# -----------------------------------------------------------------------------
lock_alert() {
    local lock_name="$1"
    local message="$2"
    local custom_expiry="${3:-}"  # optional: override LOCK_EXPIRY for this alert
    local expiry="${custom_expiry:-${LOCK_EXPIRY:-86400}}"
    local lock_file="${LOCK_DIR}/alert-${lock_name}.lock"

    [ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

    # Expire stale lock
    if [ -f "$lock_file" ]; then
        local age=$(( $(date +%s) - $(date -r "$lock_file" +%s 2>/dev/null || echo 0) ))
        if [ "$age" -gt "$expiry" ]; then
            rm -f "$lock_file"
        fi
    fi

    if [ ! -f "$lock_file" ]; then
        send_telegram "$message" && touch "$lock_file"
        return 0  # alert was sent
    fi
    return 1  # suppressed — lock already existed
}

# -----------------------------------------------------------------------------
# clear_lock <lock_name>
# Removes a lock so the next failure triggers a fresh alert.
# Call when a condition returns to normal but no recovery notification needed.
# -----------------------------------------------------------------------------
clear_lock() {
    local lock_name="$1"
    rm -f "${LOCK_DIR}/alert-${lock_name}.lock"
}

# -----------------------------------------------------------------------------
# recovery_alert <lock_name> <message>
# Sends a recovery Telegram notification if a previous alert was fired
# (i.e. the lock file exists). Removes the lock after notifying.
# Does nothing if no alert was previously sent for this condition.
# -----------------------------------------------------------------------------
recovery_alert() {
    local lock_name="$1"
    local message="$2"
    local lock_file="${LOCK_DIR}/alert-${lock_name}.lock"
    if [ -f "$lock_file" ]; then
        send_telegram "$message"
        rm -f "$lock_file"
    fi
}

# -----------------------------------------------------------------------------
# expire_locks [prefix]
# Removes all lock files older than LOCK_EXPIRY seconds.
# Optional prefix filters which locks are expired.
# -----------------------------------------------------------------------------
expire_locks() {
    local prefix="${1:-}"
    [ ! -d "$LOCK_DIR" ] && return
    for lock in "${LOCK_DIR}/alert-${prefix}"*.lock; do
        [ -f "$lock" ] || continue
        local age=$(( $(date +%s) - $(date -r "$lock" +%s 2>/dev/null || echo 0) ))
        if [ "$age" -gt "${LOCK_EXPIRY:-86400}" ]; then
            rm -f "$lock"
        fi
    done
}

# -----------------------------------------------------------------------------
# cpu_temp_max
# Returns the highest CPU temperature in degrees Celsius found in
# /sys/class/thermal/thermal_zone*/temp (millidegrees → degrees).
# Returns -1 if no sensor is found.
# -----------------------------------------------------------------------------
cpu_temp_max() {
    local max=-1
    for f in /sys/class/thermal/thermal_zone*/temp; do
        [ -f "$f" ] || continue
        local raw
        raw=$(cat "$f" 2>/dev/null)
        local deg=$(( raw / 1000 ))
        [ "$deg" -gt "$max" ] && max="$deg"
    done
    echo "$max"
}

# -----------------------------------------------------------------------------
# disk_free_gb <mount>
# Returns free space in GB (integer) for the given mount point.
# Returns 999999 on error so threshold comparisons fail safe (no false alert).
# -----------------------------------------------------------------------------
disk_free_gb() {
    local val
    val=$(df -BG "$1" 2>/dev/null | awk 'NR==2 {gsub("G",""); print $4}')
    # Ensure we got a plain integer; fall back to a large number on failure
    if [[ "$val" =~ ^[0-9]+$ ]]; then
        echo "$val"
    else
        echo "999999"
    fi
}

# -----------------------------------------------------------------------------
# disk_used_pct <mount>
# Returns used percentage (integer, no % sign) for the given mount point.
# -----------------------------------------------------------------------------
disk_used_pct() {
    df "$1" 2>/dev/null | awk 'NR==2 {gsub("%",""); print $5}'
}

# -----------------------------------------------------------------------------
# swap_used_gb
# Returns swap currently in use, in GB (one decimal place).
# -----------------------------------------------------------------------------
swap_used_gb() {
    local kb
    kb=$(free -k | awk '/^Swap:/ {print $3}')
    echo "scale=1; ${kb:-0} / 1048576" | bc 2>/dev/null || echo "0"
}

# -----------------------------------------------------------------------------
# swap_used_kb
# Returns swap in use in kilobytes (integer).
# -----------------------------------------------------------------------------
swap_used_kb() {
    free -k | awk '/^Swap:/ {print $3}'
}

# -----------------------------------------------------------------------------
# el_peers
# Returns the execution client peer count via JSON-RPC, or -1 on failure.
# -----------------------------------------------------------------------------
el_peers() {
    curl -s --max-time 5 -X POST "${EL_RPC:-http://localhost:8545}" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['result'], 16))
except:
    print(-1)
"
}

# -----------------------------------------------------------------------------
# cl_peers_connected
# Returns the number of connected CL peers from the Beacon API, or -1.
# -----------------------------------------------------------------------------
cl_peers_connected() {
    curl -s --max-time 5 "${CL_API:-http://localhost:5052}/eth/v1/node/peer_count" \
        2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['data']['connected']))
except:
    print(-1)
"
}

# -----------------------------------------------------------------------------
# el_syncing
# Returns 'true' if EL is still syncing, 'false' if synced, 'error' on failure.
# -----------------------------------------------------------------------------
el_syncing() {
    local result
    result=$(curl -s --max-time 5 -X POST "${EL_RPC:-http://localhost:8545}" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        2>/dev/null | python3 -c "
import sys, json
try:
    r = json.load(sys.stdin).get('result', True)
    print('false' if r is False else 'true')
except:
    print('error')
")
    echo "$result"
}

# -----------------------------------------------------------------------------
# cl_syncing
# Returns 'true' if CL is still syncing, 'false' if synced, 'error' on failure.
# -----------------------------------------------------------------------------
cl_syncing() {
    curl -s --max-time 5 "${CL_API:-http://localhost:5052}/eth/v1/node/syncing" \
        2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)['data']
    print(str(data['is_syncing']).lower())
except:
    print('error')
"
}

# -----------------------------------------------------------------------------
# service_active <service_name>
# Returns 0 (true) if the systemd service is active, 1 otherwise.
# -----------------------------------------------------------------------------
service_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

# -----------------------------------------------------------------------------
# node_label
# Returns a short label string for use in alert messages.
# -----------------------------------------------------------------------------
node_label() {
    echo "🖥 <b>${NODE_NAME:-$HOSTNAME}</b>"
}
# -----------------------------------------------------------------------------
# _peer_check_result <peer_ip> <timeout> <relay_port> <retry_delay>
# Runs the 3-step probe and returns a result string:
#   "healthy"        — EL API responded
#   "el_down"        — relay responded, EL down
#   "el_relay_down"  — ping responded, both EL and relay down
#   "down"           — all three failed
# -----------------------------------------------------------------------------
_peer_check_result() {
    local _ip="$1" _timeout="$2" _relay_port="$3" _retry_delay="$4"

    # Step 1 — EL API
    _r=$(curl -s --max-time "$_timeout"         -H "Content-type: application/json"         -X POST         --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}'         "$_ip" 2>/dev/null)
    if echo "$_r" | grep -q '"result"'; then echo "healthy"; return; fi

    # Step 2 — Charon relay
    _rc=$(curl -s --max-time "$_timeout" -o /dev/null -w "%{http_code}"         "http://${_ip}:${_relay_port}/" 2>/dev/null)
    if [ -n "$_rc" ] && [ "$_rc" != "000" ]; then echo "el_down"; return; fi

    # Step 3 — Ping (after delay)
    sleep "$_retry_delay"
    if ping -c 1 -W "$_timeout" "$_ip" > /dev/null 2>&1; then
        echo "el_relay_down"; return
    fi

    echo "down"
}

# -----------------------------------------------------------------------------
# is_primary
# Returns 0 (true) if this node should run health checks, 1 if it should defer.
# Sets global IS_PRIMARY_REASON describing the outcome.
#
# Alerts and failover only trigger after TWO consecutive failing cycles.
# A single failure is written to a state file but causes no action — this
# absorbs transient VPN re-keying gaps and one-off connectivity blips.
#
# IS_PRIMARY_REASON values:
#   "always_primary"      — no PEER_CONTROL_IP configured
#   "peer_healthy"        — EL API responded
#   "peer_el_down"        — relay responded, EL down (first or consecutive)
#   "peer_el_relay_down"  — ping ok, EL+relay down (first or consecutive)
#   "peer_down"           — all three failed on TWO consecutive cycles
# -----------------------------------------------------------------------------
IS_PRIMARY_REASON="always_primary"

is_primary() {
    IS_PRIMARY_REASON="always_primary"

    if [ -z "${PEER_CONTROL_IP:-}" ]; then
        return 0  # no peer configured — always run as primary
    fi

    local _timeout="${PEER_CHECK_TIMEOUT:-5}"
    local _retry_delay="${PEER_RETRY_DELAY:-10}"
    local _relay_port="${PEER_RELAY_PORT:-3640}"
    local _state_file="${LOCK_DIR}/peer-primary-state.dat"

    [ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

    local _result
    _result=$(_peer_check_result "$PEER_CONTROL_IP" "$_timeout" "$_relay_port" "$_retry_delay")

    case "$_result" in
        healthy)
            IS_PRIMARY_REASON="peer_healthy"
            echo "ok" > "$_state_file"
            return 1
            ;;
        el_down)
            IS_PRIMARY_REASON="peer_el_down"
            echo "ok" > "$_state_file"  # relay responds — node is up
            return 1
            ;;
        el_relay_down)
            IS_PRIMARY_REASON="peer_el_relay_down"
            # Only alert on second consecutive failure
            local _prev
            _prev=$(cat "$_state_file" 2>/dev/null || echo "ok")
            echo "el_relay_down" > "$_state_file"
            if [ "$_prev" = "el_relay_down" ] || [ "$_prev" = "down" ]; then
                return 1  # alert handled in control scripts via IS_PRIMARY_REASON
            fi
            # First failure — defer silently, no alert yet
            IS_PRIMARY_REASON="peer_healthy"  # treat as healthy for this cycle
            return 1
            ;;
        down)
            IS_PRIMARY_REASON="peer_down"
            local _prev
            _prev=$(cat "$_state_file" 2>/dev/null || echo "ok")
            if [ "$_prev" = "down" ] || [ "$_prev" = "el_relay_down" ]; then
                # Second consecutive failure — confirmed, take over
                echo "down" > "$_state_file"
                return 0
            fi
            # First failure — write state, defer for one more cycle
            echo "down" > "$_state_file"
            IS_PRIMARY_REASON="peer_healthy"  # suppress action this cycle
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# check_failover
# Called by the PRIMARY control node to monitor the failover node.
# Alerts only fire after TWO consecutive failing cycles (same logic as
# is_primary). Never changes script behaviour — only sends Telegram alerts.
# -----------------------------------------------------------------------------
check_failover() {
    if [ -z "${FAILOVER_CONTROL_IP:-}" ]; then
        return 0  # no failover configured — nothing to check
    fi

    local _timeout="${PEER_CHECK_TIMEOUT:-5}"
    local _retry_delay="${PEER_RETRY_DELAY:-10}"
    local _relay_port="${PEER_RELAY_PORT:-3640}"
    local _state_file="${LOCK_DIR}/peer-failover-state.dat"

    [ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

    local _result
    _result=$(_peer_check_result "$FAILOVER_CONTROL_IP" "$_timeout" "$_relay_port" "$_retry_delay")

    local _prev
    _prev=$(cat "$_state_file" 2>/dev/null || echo "ok")

    case "$_result" in
        healthy|el_down)
            # Node is up (EL-only failure is not alertable — node is reachable)
            echo "ok" > "$_state_file"
            recovery_alert "ctrl-failover-relay-down" "$(node_label)
✅ <b>Failover control node services restored</b>
Node <code>${FAILOVER_CONTROL_IP}</code> is fully reachable again."
            recovery_alert "ctrl-failover-node-down" "$(node_label)
✅ <b>Failover control node is back online</b>
Node <code>${FAILOVER_CONTROL_IP}</code> is reachable again."
            clear_lock "ctrl-failover-el-down"
            ;;
        el_relay_down)
            if [ "$_prev" = "el_relay_down" ] || [ "$_prev" = "down" ]; then
                # Confirmed second consecutive failure
                echo "el_relay_down" > "$_state_file"
                clear_lock "ctrl-failover-node-down"
                lock_alert "ctrl-failover-relay-down" "$(node_label)
⚠️ <b>Failover control node: EL and relay both down</b>

Failover node <code>${FAILOVER_CONTROL_IP}</code> responds to ping but both
EL API (port 80) and Charon relay (port ${_relay_port}) are not responding.
This has been confirmed over two consecutive check cycles.

Suggested actions:
• SSH into the failover node and check:
  <code>systemctl status ethrex nethermind reth erigon geth besu 2>/dev/null | grep -E "active|failed"</code>
• Check relay: <code>sudo systemctl status charon-relay</code>
• Check nginx: <code>sudo systemctl status nginx</code>" 259200
            else
                # First failure — write state, no alert yet
                echo "el_relay_down" > "$_state_file"
                echo "Failover EL+relay down (first occurrence) — waiting for confirmation."
            fi
            ;;
        down)
            if [ "$_prev" = "down" ] || [ "$_prev" = "el_relay_down" ]; then
                # Confirmed second consecutive failure
                echo "down" > "$_state_file"
                clear_lock "ctrl-failover-el-down"
                clear_lock "ctrl-failover-relay-down"
                lock_alert "ctrl-failover-node-down" "$(node_label)
🚨 <b>Failover control node is DOWN</b>

Failover node <code>${FAILOVER_CONTROL_IP}</code> did not respond to
EL API, Charon relay, or ping.
This has been confirmed over two consecutive check cycles.

The cluster is running without a backup control node.

Suggested actions:
• Check VPN: <code>tailscale ping ${FAILOVER_CONTROL_IP}</code>
• Physical inspection may be required" 259200
            else
                # First failure — write state, no alert yet
                echo "down" > "$_state_file"
                echo "Failover node unreachable (first occurrence) — waiting for confirmation."
            fi
            ;;
    esac
}



# =============================================================================
# BEACON API HELPERS
# Used by sync-indices.sh and validator-duties.sh
# =============================================================================

# -----------------------------------------------------------------------------
# beacon_get <path>
# GET request to the local beacon API. Returns the raw response body.
# -----------------------------------------------------------------------------
beacon_get() {
    curl -s --max-time 15 \
        -H "Accept: application/json" \
        "${CL_API:-http://localhost:5052}${1}" 2>/dev/null
}

# -----------------------------------------------------------------------------
# beacon_post <path> <json_body>
# POST to the local beacon API. Outputs response body to stdout.
#
# HTTP status code is written to _BEACON_CODE_FILE (a temp file created once
# at source time) because beacon_post is always called inside $(...) command
# substitution — a subshell — so any variable assignment inside the function
# is invisible to the parent shell. Reading the code from a file sidesteps
# the subshell barrier.
#
# Usage:
#   RESP=$(beacon_post "/path" "$body")
#   CODE=$(beacon_http_code)   # read code written by last beacon_post call
# -----------------------------------------------------------------------------
_BEACON_CODE_FILE=$(mktemp)

beacon_post() {
    local _body_tmp _code
    _body_tmp=$(mktemp)
    _code=$(curl -s --max-time 15 \
        -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -w "%{http_code}" \
        -o "$_body_tmp" \
        -d "$2" \
        "${CL_API:-http://localhost:5052}${1}" 2>/dev/null)
    echo "$_code" > "$_BEACON_CODE_FILE"
    cat "$_body_tmp"
    rm -f "$_body_tmp"
}

# -----------------------------------------------------------------------------
# beacon_http_code
# Returns the HTTP status code from the most recent beacon_post call.
# Returns "0" if no code has been recorded yet.
# -----------------------------------------------------------------------------
beacon_http_code() {
    cat "$_BEACON_CODE_FILE" 2>/dev/null || echo "0"
}

# -----------------------------------------------------------------------------
# current_epoch
# Returns the current beacon chain epoch derived from the head slot.
# Slots per epoch = 32 (mainnet constant).
# -----------------------------------------------------------------------------
current_epoch() {
    beacon_get "/eth/v1/node/syncing" | \
        python3 -c "
import sys, json
try:
    slot = int(json.load(sys.stdin)['data']['head_slot'])
    print(slot // 32)
except:
    print('')
"
}

# -----------------------------------------------------------------------------
# finalized_epoch
# Returns the most recently finalized epoch from the beacon API.
# Required by the rewards/attestations endpoint — Lighthouse returns 404
# for epochs that are not yet finalized.
# -----------------------------------------------------------------------------
finalized_epoch() {
    beacon_get "/eth/v1/beacon/states/finalized/finality_checkpoints" | \
        python3 -c "
import sys, json
try:
    print(json.load(sys.stdin)['data']['finalized']['epoch'])
except:
    print('')
"
}

# -----------------------------------------------------------------------------
# check_epoch
# Returns current_epoch - 1: the epoch to use for liveness checks.
# Tested and confirmed working with both Lighthouse and Nimbus — most
# beacon clients restrict /eth/v1/validator/liveness/{epoch} to the current
# or previous epoch only and return HTTP 400 for older epochs.
# Do NOT use for the rewards/attestations endpoint — use finalized_epoch()
# instead, as Lighthouse returns 404 for non-finalized epochs.
# -----------------------------------------------------------------------------
check_epoch() {
    local ep
    ep=$(current_epoch)
    if [ -z "$ep" ]; then
        echo ""
        return
    fi
    echo $(( ep - 1 ))
}

# -----------------------------------------------------------------------------
# is_optimistic
# Returns "true" if the beacon node's head is optimistically synced (i.e.
# the execution payload of the head block has not been validated by the EL
# yet — common while the EL is syncing from scratch).
#
# While optimistic, duty/liveness data derived from the head state may be
# unreliable: validators can appear as "not live" even though they attested
# correctly, because the head state itself is not yet fully verified.
# -----------------------------------------------------------------------------
is_optimistic() {
    beacon_get "/eth/v1/node/syncing" | \
        python3 -c "
import sys, json
try:
    print(str(json.load(sys.stdin)['data']['is_optimistic']).lower())
except:
    print('false')
"
}