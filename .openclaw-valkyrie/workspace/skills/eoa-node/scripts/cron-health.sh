#!/bin/bash
# cron-health.sh — runs via system cron, messages agent only if there is an alert

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

EXECUTION_RPC="http://localhost:8545"
LOCK_DIR="/home/ethereum/.openclaw/locks"
ALERTS=""

[ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

# ── Check if any node is running — skip peer check if not ────────────────────
RUNNING=$(bash "$(dirname "$0")/running-clients.sh" 2>/dev/null)
STATUS=$(echo "$RUNNING" | awk -F': ' '/^STATUS/ {print $2}' | xargs)

# ── Disk free at /home/ethereum ───────────────────────────────────────────────
DISK_FREE_GB=$(df -BG /home/ethereum | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$DISK_FREE_GB" -lt 50 ]; then
    ALERTS="$ALERTS\n• DISK: only ${DISK_FREE_GB} GB free on /home/ethereum"
else
    rm -f "$LOCK_DIR/health-disk.lock"
fi

# ── CPU load ──────────────────────────────────────────────────────────────────
LOAD1=$(cat /proc/loadavg | awk '{print $1}' | cut -d. -f1)
if [ "$LOAD1" -gt 4 ]; then
    LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    ALERTS="$ALERTS\n• CPU: load average is high ($LOAD)"
else
    rm -f "$LOCK_DIR/health-cpu.lock"
fi

# ── Swap usage ────────────────────────────────────────────────────────────────
SWAP_USED_KB=$(free -k | awk '/^Swap:/ {print $3}')
if [ "$SWAP_USED_KB" -gt 5242880 ]; then
    SWAP_USED_GB=$(echo "scale=1; $SWAP_USED_KB / 1048576" | bc 2>/dev/null || echo "?")
    ALERTS="$ALERTS\n• SWAP: usage is high (${SWAP_USED_GB} GB)"
else
    rm -f "$LOCK_DIR/health-swap.lock"
fi

# ── EL peer count — only if node is running ───────────────────────────────────
if [ "$STATUS" = "RUNNING" ]; then
    EL_PEERS=$(curl -s -X POST "$EXECUTION_RPC" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' 2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['result'], 16))
except:
    print(-1)
")
    if [ "$EL_PEERS" != "-1" ] && [ "$EL_PEERS" -lt 3 ] 2>/dev/null; then
        ALERTS="$ALERTS\n• PEERS: EL peer count is very low ($EL_PEERS) — possible network issue"
    else
        rm -f "$LOCK_DIR/health-peers.lock"
    fi
fi

# ── Notify agent respecting lock files ───────────────────────────────────────
ALERTS_TO_SEND=""

if echo "$ALERTS" | grep -q "DISK"; then
    if [ ! -f "$LOCK_DIR/health-disk.lock" ]; then
        ALERTS_TO_SEND="$ALERTS_TO_SEND\n• DISK: only ${DISK_FREE_GB} GB free on /home/ethereum"
        touch "$LOCK_DIR/health-disk.lock"
    fi
fi

if echo "$ALERTS" | grep -q "CPU"; then
    if [ ! -f "$LOCK_DIR/health-cpu.lock" ]; then
        ALERTS_TO_SEND="$ALERTS_TO_SEND\n• CPU: load average is high ($LOAD)"
        touch "$LOCK_DIR/health-cpu.lock"
    fi
fi

if echo "$ALERTS" | grep -q "SWAP"; then
    if [ ! -f "$LOCK_DIR/health-swap.lock" ]; then
        ALERTS_TO_SEND="$ALERTS_TO_SEND\n• SWAP: usage is high (${SWAP_USED_GB} GB)"
        touch "$LOCK_DIR/health-swap.lock"
    fi
fi

if echo "$ALERTS" | grep -q "PEERS"; then
    if [ ! -f "$LOCK_DIR/health-peers.lock" ]; then
        ALERTS_TO_SEND="$ALERTS_TO_SEND\n• PEERS: EL peer count is very low ($EL_PEERS) — possible network issue"
        touch "$LOCK_DIR/health-peers.lock"
    fi
fi

if [ -n "$ALERTS_TO_SEND" ]; then
    openclaw message send --channel telegram --target "$TELEGRAM_ID" --message "🚨 Health alert on $(hostname):$(echo -e "$ALERTS_TO_SEND")"
fi
