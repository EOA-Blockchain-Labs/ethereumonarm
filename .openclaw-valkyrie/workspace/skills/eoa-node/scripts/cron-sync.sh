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

LOCK_DIR="/home/ethereum/.openclaw/locks"
INITIAL_SYNC_GRACE=64800
LOCK_EXPIRY=86400

[ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

# ── Expire locks older than 24 hours ─────────────────────────────────────────
for lock in "$LOCK_DIR"/sync-*.lock; do
    if [ -f "$lock" ]; then
        lock_age=$(( $(date +%s) - $(date -r "$lock" +%s 2>/dev/null || echo 0) ))
        if [ "$lock_age" -gt "$LOCK_EXPIRY" ]; then
            rm -f "$lock"
        fi
    fi
done

# ── Run node-status.sh and parse output ──────────────────────────────────────
STATUS_OUTPUT=$(bash "$(dirname "$0")/node-status.sh" 2>/dev/null)
STATUS=$(echo "$STATUS_OUTPUT" | awk -F': ' '/^STATUS/ {print $2}' | xargs | cut -d' ' -f1)
SYNC_STATUS=$(echo "$STATUS_OUTPUT" | awk -F': ' '/^SYNC_STATUS/ {print $2}' | xargs | cut -d' ' -f1)
CL_SERVICE=$(echo "$STATUS_OUTPUT" | awk -F'[()]' '/^Consensus client/ {print $2}')

if [ "$STATUS" = "STOPPED" ]; then
    rm -f "$LOCK_DIR/sync-incomplete.lock"
    rm -f "$LOCK_DIR/sync-cl-behind.lock"
    rm -f "$LOCK_DIR/sync-both-stuck.lock"
    rm -f "$LOCK_DIR/sync-el-stuck.lock"
    exit 0
fi

if [ "$STATUS" = "INCOMPLETE" ]; then
    if [ ! -f "$LOCK_DIR/sync-incomplete.lock" ]; then
        openclaw agent \
            --agent ethereum-node \
            --message "⚠️ Node alert on $(hostname): node setup is incomplete — one client is running without its pair." \
            --deliver \
            --channel telegram \
            --reply-channel telegram \
            --reply-to "$TELEGRAM_ID"
        touch "$LOCK_DIR/sync-incomplete.lock"
    fi
    exit 0
else
    rm -f "$LOCK_DIR/sync-incomplete.lock"
fi

# ── Only runs from here if STATUS = RUNNING ───────────────────────────────────

# Both synced — clear all sync locks
if [ "$SYNC_STATUS" = "SYNCED" ]; then
    rm -f "$LOCK_DIR/sync-cl-behind.lock"
    rm -f "$LOCK_DIR/sync-both-stuck.lock"
    rm -f "$LOCK_DIR/sync-el-stuck.lock"
    exit 0
fi

# Get uptime of consensus service
service_uptime_seconds() {
    if [ -z "$CL_SERVICE" ]; then
        echo 0
        return
    fi
    local started
    started=$(systemctl show "$CL_SERVICE" --property=ActiveEnterTimestamp --value 2>/dev/null)
    if [ -n "$started" ]; then
        local started_epoch now_epoch
        started_epoch=$(date -d "$started" +%s 2>/dev/null || echo 0)
        now_epoch=$(date +%s)
        echo $(( now_epoch - started_epoch ))
        return
    fi
    echo 0
}

UPTIME=$(service_uptime_seconds)

EL_SYNC=$(echo "$STATUS_OUTPUT" | awk '/^Execution client/ {print ($3 == "SYNCED") ? "false" : "true"}')
CL_SYNC=$(echo "$STATUS_OUTPUT" | awk '/^Consensus client/ {print ($3 == "SYNCED") ? "false" : "true"}')

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
        openclaw agent \
            --agent ethereum-node \
            --message "⚠️ Sync alert on $(hostname): EL is synced but CL is behind — check consensus client logs." \
            --deliver \
            --channel telegram \
            --reply-channel telegram \
            --reply-to "$TELEGRAM_ID"
        touch "$LOCK_DIR/sync-cl-behind.lock"
    fi
    exit 0
else
    rm -f "$LOCK_DIR/sync-cl-behind.lock"
fi

# Both still syncing past grace period
if [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "true" ]; then
    if [ ! -f "$LOCK_DIR/sync-both-stuck.lock" ]; then
        openclaw agent \
            --agent ethereum-node \
            --message "⚠️ Sync alert on $(hostname): Both clients still syncing after 18 hours — may indicate a stuck sync." \
            --deliver \
            --channel telegram \
            --reply-channel telegram \
            --reply-to "$TELEGRAM_ID"
        touch "$LOCK_DIR/sync-both-stuck.lock"
    fi
fi

# EL still catching up past grace period
if [ "$EL_SYNC" = "true" ] && [ "$CL_SYNC" = "false" ]; then
    if [ ! -f "$LOCK_DIR/sync-el-stuck.lock" ]; then
        openclaw agent \
            --agent ethereum-node \
            --message "⚠️ Sync alert on $(hostname): EL still catching up after 18 hours — may indicate a stuck sync." \
            --deliver \
            --channel telegram \
            --reply-channel telegram \
            --reply-to "$TELEGRAM_ID"
        touch "$LOCK_DIR/sync-el-stuck.lock"
    fi
else
    rm -f "$LOCK_DIR/sync-el-stuck.lock"
fi
