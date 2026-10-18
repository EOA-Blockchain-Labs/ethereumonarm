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
# _alert_level_num <level>
# Maps an alert level name to a numeric value for comparison.
#   critical → 1   (most restrictive — only the most important alerts)
#   info     → 2   (default — operational issues worth acting on)
#   detailed → 3   (all alerts, including low-severity diagnostics)
# Unknown values map to 2 (info) as a safe default.
# -----------------------------------------------------------------------------
_alert_level_num() {
    case "${1:-info}" in
        critical) echo 1 ;;
        info)     echo 2 ;;
        detailed) echo 3 ;;
        *)        echo 2 ;;
    esac
}

# -----------------------------------------------------------------------------
# should_alert <level>
# Returns 0 (fire) if the alert's level is within the configured ALERT_LEVEL.
# Hierarchy: critical(1) ⊂ info(2) ⊂ detailed(3)
# Example: ALERT_LEVEL=info → critical and info fire; detailed is suppressed.
# ALERT_LEVEL defaults to "info" when not set in node.env.
# -----------------------------------------------------------------------------
should_alert() {
    local req_num cfg_num
    req_num=$(_alert_level_num "${1:-info}")
    cfg_num=$(_alert_level_num "${ALERT_LEVEL:-info}")
    [ "$req_num" -le "$cfg_num" ]
}

# -----------------------------------------------------------------------------
# lock_alert <lock_name> <message> [level]
# Sends <message> via Telegram only if no lock exists for <lock_name>.
# Creates a lock file so the same alert is not sent more than once per
# LOCK_EXPIRY window (default 24 h, set in node.env).
#
# Optional third argument <level> (critical | info | detailed, default: info)
# gates the alert against the ALERT_LEVEL setting. If the alert's level
# exceeds the configured threshold it is silently skipped — no lock is
# created, so the condition will be re-evaluated on the next run.
# -----------------------------------------------------------------------------
lock_alert() {
    local lock_name="$1"
    local message="$2"
    local level="${3:-info}"
    local lock_file="${LOCK_DIR}/alert-${lock_name}.lock"

    # Suppress alert if its level exceeds the configured ALERT_LEVEL
    should_alert "$level" || return 0

    [ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

    # Expire stale lock
    if [ -f "$lock_file" ]; then
        local age=$(( $(date +%s) - $(date -r "$lock_file" +%s 2>/dev/null || echo 0) ))
        if [ "$age" -gt "${LOCK_EXPIRY:-86400}" ]; then
            rm -f "$lock_file"
        fi
    fi

    if [ ! -f "$lock_file" ]; then
        send_telegram "$message" && touch "$lock_file"
    fi
}

# -----------------------------------------------------------------------------
# clear_lock <lock_name>
# Removes a lock so the next failure triggers a fresh alert.
# Call this when a condition returns to normal.
# No Telegram message is sent — use clear_lock_alert when a "resolved"
# notification is needed.
# -----------------------------------------------------------------------------
clear_lock() {
    local lock_name="$1"
    rm -f "${LOCK_DIR}/alert-${lock_name}.lock"
}

# -----------------------------------------------------------------------------
# clear_lock_alert <lock_name> <resolved_message> [level]
# If a lock exists for <lock_name>, sends <resolved_message> via Telegram
# and then removes the lock. Does nothing when the lock is not present
# (condition was never alerted, or already resolved).
# The optional <level> must match the level of the original lock_alert call
# so the resolved message is gated by the same ALERT_LEVEL threshold.
# -----------------------------------------------------------------------------
clear_lock_alert() {
    local lock_name="$1"
    local resolved_message="$2"
    local level="${3:-info}"
    local lock_file="${LOCK_DIR}/alert-${lock_name}.lock"
    if [ -f "$lock_file" ]; then
        should_alert "$level" && send_telegram "$resolved_message"
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
# Returns 'true' if CL is meaningfully behind, 'false' if synced or close
# enough, 'error' on failure.
#
# Uses sync_distance instead of is_syncing to avoid spurious alerts when the
# node is only 1 slot behind (normal propagation lag). Alert fires only when
# distance >= CL_SYNC_DISTANCE_ALERT (default: 2 slots).
# -----------------------------------------------------------------------------
cl_syncing() {
    curl -s --max-time 5 "${CL_API:-http://localhost:5052}/eth/v1/node/syncing" \
        2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)['data']
    distance = int(data.get('sync_distance', 0))
    threshold = ${CL_SYNC_DISTANCE_ALERT:-2}
    print('true' if distance >= threshold else 'false')
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
# is_primary
# Returns 0 (true) if this node should run health checks, 1 if it should defer
# to the peer control node.
#
# Logic:
#   - PEER_CONTROL_IP is empty → always primary → always run → return 0
#   - PEER_CONTROL_IP is set → ping peer over VPN:
#       peer responds   → peer is primary, we are backup → skip → return 1
#       peer unreachable → peer is down, we take over   → run  → return 0
# -----------------------------------------------------------------------------
is_primary() {
    if [ -z "${PEER_CONTROL_IP:-}" ]; then
        return 0  # no peer configured — always run
    fi
    if ping -c 1 -W "${PEER_CHECK_TIMEOUT:-5}" "$PEER_CONTROL_IP" > /dev/null 2>&1; then
        return 1  # peer is alive — defer to it
    else
        return 0  # peer is unreachable — take over
    fi
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
# check_epoch
# Returns current_epoch - 1: the epoch to use for attestation checks.
# Tested and confirmed working with both Lighthouse and Nimbus.
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