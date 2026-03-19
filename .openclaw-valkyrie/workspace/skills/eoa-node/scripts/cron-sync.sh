#!/bin/bash
# cron-sync.sh — runs via system cron, messages agent only if sync is lost

export HOME=/home/ethereum
export USER=ethereum
export PATH=/home/ethereum/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

CRON_CONF="/home/ethereum/.openclaw/cron.conf"
if [ ! -f "$CRON_CONF" ]; then
    echo "Error: $CRON_CONF not found. Run setup-openclaw.sh first."
    exit 1
fi
. "$CRON_CONF"
if [ -z "$TELEGRAM_ID" ]; then
    echo "Error: TELEGRAM_ID is not set in $CRON_CONF"
    exit 1
fi

CONSENSUS_API="http://localhost:5052/eth/v1/node/syncing"
EXECUTION_RPC="http://localhost:8545"
INITIAL_SYNC_GRACE=64800
LOCK_DIR="/home/ethereum/.openclaw/locks"

[ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

# ── Check if a complete node is running — exit if not ────────────────────────
RUNNING=$(bash "$(dirname "$0")/running-clients.sh" 2>/dev/null)
STATUS=$(echo "$RUNNING" | awk -F': ' '/^STATUS/ {print $2}' | xargs)

if [ "$STATUS" = "STOPPED" ]; then
    rm -f "$LOCK_DIR/sync-incomplete.lock"
    rm -f "$LOCK_DIR/sync-cl-behind.lock"
    rm -f "$LOCK_DIR/sync-both-stuck.lock"
    rm -f "$LOCK_DIR/sync-el-stuck.lock"
    exit 0
fi

if [ "$STATUS" = "INCOMPLETE" ]; then
    if [ ! -f "$LOCK_DIR/sync-incomplete.lock" ]; then
        openclaw message send --channel telegram --target "$TELEGRAM_ID" --message "⚠️ Node alert on $(hostname): node setup is incomplete — one client is running without its pair."
        touch "$LOCK_DIR/sync-incomplete.lock"
    fi
    exit 0
else
    rm -f "$LOCK_DIR/sync-incomplete.lock"
fi

# ── Only runs from here if STATUS = RUNNING ───────────────────────────────────

el_syncing() {
    local result
    result=$(curl -s -X POST "$EXECUTION_RPC" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' 2>/dev/null | python3 -c "
import sys, json
try:
    r = json.load(sys.stdin).get('result', True)
    print('false' if r is False else 'true')
except:
    print('true')
")

    if [ "$result" = "false" ]; then
        BLOCK=$(curl -s -X POST "$EXECUTION_RPC" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' 2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['result'], 16))
except:
    print(0)
")
        if [ "$BLOCK" -lt 1000 ] 2>/dev/null; then
            echo "true"
            return
        fi
    fi

    echo "$result"
}

cl_syncing() {
    curl -s "$CONSENSUS_API" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(str(data['data']['is_syncing']).lower())
except:
    print('true')
"
}

service_uptime_seconds() {
    local svc
    svc=$(echo "$RUNNING" | awk -F': ' '/^Consensus client/ {print $2}' | xargs)
    if [ -z "$svc" ]; then
        echo 0
        return
    fi
    local started
    started=$(systemctl show "$svc" --property=ActiveEnterTimestamp --value 2>/dev/null)
    if [ -n "$started" ]; then
        local started_epoch now_epoch
        started_epoch=$(date -d "$started" +%s 2>/dev/null || echo 0)
        now_epoch=$(date +%s)
        echo $(( now_epoch - started_epoch ))
        return
    fi
    echo 0
}

EL_SYNC=$(el_syncing)
CL_SYNC=$(cl_syncing)

# Both synced — clear all sync locks
if [ "$EL_SYNC" = "false" ] && [ "$CL_SYNC" = "false" ]; then
    rm -f "$LOCK_DIR/sync-cl-behind.lock"
    rm -f "$LOCK_DIR/sync-both-stuck.lock"
    rm -f "$LOCK_DIR/sync-el-stuck.lock"
    exit 0
fi

UPTIME=$(service_uptime_seconds)

# Both syncing within grace period — normal initial sync
if [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "true" ]; then
    if [ "$UPTIME" -lt "$INITIAL_SYNC_GRACE" ]; then
        exit 0
    fi
fi

# CL synced EL catching up within grace period — normal first sync
if [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "false" ]; then
    if [ "$UPTIME" -lt "$INITIAL_SYNC_GRACE" ]; then
        exit 0
    fi
fi

# EL synced but CL behind — always alert
if [ "$EL_SYNC" = "false" ] && [ "$CL_SYNC" = "true" ]; then
    if [ ! -f "$LOCK_DIR/sync-cl-behind.lock" ]; then
        openclaw message send --channel telegram --target "$TELEGRAM_ID" --message "⚠️ Sync alert on $(hostname): EL is synced but CL is behind — check consensus client logs."
        touch "$LOCK_DIR/sync-cl-behind.lock"
    fi
    exit 0
else
    rm -f "$LOCK_DIR/sync-cl-behind.lock"
fi

# Both still syncing past grace period
if [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "true" ]; then
    if [ ! -f "$LOCK_DIR/sync-both-stuck.lock" ]; then
        openclaw message send --channel telegram --target "$TELEGRAM_ID" --message "⚠️ Sync alert on $(hostname): Both clients still syncing after 18 hours — may indicate a stuck sync."
        touch "$LOCK_DIR/sync-both-stuck.lock"
    fi
fi

# EL still catching up past grace period
if [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "false" ]; then
    if [ ! -f "$LOCK_DIR/sync-el-stuck.lock" ]; then
        openclaw message send --channel telegram --target "$TELEGRAM_ID" --message "⚠️ Sync alert on $(hostname): EL still catching up after 18 hours — may indicate a stuck sync."
        touch "$LOCK_DIR/sync-el-stuck.lock"
    fi
else
    rm -f "$LOCK_DIR/sync-el-stuck.lock"
fi
