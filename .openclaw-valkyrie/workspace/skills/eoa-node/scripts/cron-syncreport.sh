#!/bin/bash
# cron-syncreport.sh — sends a full status report to the agent 24 hours after
# initial sync started. Fires once and never again.

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
LOCK_FILE="$LOCK_DIR/syncreport.lock"

[ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

# ── Only fire once ────────────────────────────────────────────────────────────
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi

# ── Check if a complete node is running ───────────────────────────────────────
RUNNING=$(bash "$(dirname "$0")/running-clients.sh" 2>/dev/null)
STATUS=$(echo "$RUNNING" | awk -F': ' '/^STATUS/ {print $2}' | xargs)

if [ "$STATUS" != "RUNNING" ]; then
    exit 0
fi

# ── Check if the node has been running for at least 24 hours ─────────────────
svc=$(echo "$RUNNING" | awk -F': ' '/^Consensus client/ {print $2}' | xargs)
if [ -z "$svc" ]; then
    exit 0
fi

started=$(systemctl show "$svc" --property=ActiveEnterTimestamp --value 2>/dev/null)
if [ -z "$started" ]; then
    exit 0
fi

started_epoch=$(date -d "$started" +%s 2>/dev/null || echo 0)
now_epoch=$(date +%s)
uptime=$(( now_epoch - started_epoch ))

# 86400 seconds = 24 hours
if [ "$uptime" -lt 86400 ]; then
    exit 0
fi

# ── Node has been running 24+ hours — send report and lock ───────────────────
touch "$LOCK_FILE"

openclaw agent \
    --agent ethereum-node \
    --message "📊 The node has been running for 24 hours. Please run a full health check using health-check.sh and scripts/synced-clients.sh, then send the user a complete status report covering sync progress, peer counts, disk usage, CPU and memory." \
    --deliver \
    --channel telegram \
    --reply-channel telegram \
    --reply-to "$TELEGRAM_ID"
