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
LOCK_EXPIRY=86400

[ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

# ── Expire locks older than 24 hours ─────────────────────────────────────────
for lock in "$LOCK_DIR"/health-*.lock; do
    if [ -f "$lock" ]; then
        lock_age=$(( $(date +%s) - $(date -r "$lock" +%s 2>/dev/null || echo 0) ))
        if [ "$lock_age" -gt "$LOCK_EXPIRY" ]; then
            rm -f "$lock"
        fi
    fi
done

# ── Check if any node is running — skip peer check if not ────────────────────
STATUS_OUTPUT=$(bash "$(dirname "$0")/node-status.sh" 2>/dev/null)
STATUS=$(echo "$STATUS_OUTPUT" | awk -F': ' '/^STATUS/ {print $2}' | xargs | cut -d' ' -f1)

# ── Disk free at /home/ethereum ───────────────────────────────────────────────
DISK_FREE_GB=$(df -BG /home/ethereum | awk 'NR==2 {gsub("G",""); print $4}')
if [ "$DISK_FREE_GB" -lt 50 ]; then
    ALERTS="$ALERTS\nDISK"
else
    rm -f "$LOCK_DIR/health-disk.lock"
fi

# ── CPU load ──────────────────────────────────────────────────────────────────
LOAD1=$(cat /proc/loadavg | awk '{print $1}' | cut -d. -f1)
if [ "$LOAD1" -gt 4 ]; then
    LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    ALERTS="$ALERTS\nCPU"
else
    rm -f "$LOCK_DIR/health-cpu.lock"
fi

# ── Swap usage ────────────────────────────────────────────────────────────────
SWAP_USED_KB=$(free -k | awk '/^Swap:/ {print $3}')
if [ "$SWAP_USED_KB" -gt 5242880 ]; then
    SWAP_USED_GB=$(echo "scale=1; $SWAP_USED_KB / 1048576" | bc 2>/dev/null || echo "?")
    ALERTS="$ALERTS\nSWAP"
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
        ALERTS="$ALERTS\nPEERS"
    else
        rm -f "$LOCK_DIR/health-peers.lock"
    fi
fi

# ── Notify agent respecting lock files ───────────────────────────────────────
send_alert() {
    local lock="$1"
    local message="$2"
    if [ ! -f "$LOCK_DIR/${lock}.lock" ]; then
        openclaw agent \
            --agent ethereum-node \
            --message "$message" \
            --deliver \
            --channel telegram \
            --reply-channel telegram \
            --reply-to "$TELEGRAM_ID"
        touch "$LOCK_DIR/${lock}.lock"
    fi
}

if echo "$ALERTS" | grep -q "DISK"; then
    send_alert "health-disk" "🚨 Health alert on $(hostname): disk space is critically low — only ${DISK_FREE_GB}GB free on /home/ethereum.

Possible causes:
- Ethereum client blockchain data is growing normally — this is expected over time
- Old client data from a previous node run was not cleaned up
- Log files or other data accumulating unexpectedly

Suggested actions:
- Run the Pre-Start Resource Check from SKILL.md to find old client databases
- Check which client is running and how much space its data is using
- Offer the user to delete old unused client data
- Check for large files: du -sh /home/ethereum/*"
fi

if echo "$ALERTS" | grep -q "CPU"; then
    send_alert "health-cpu" "🚨 Health alert on $(hostname): CPU load is high — load average is $LOAD.

Possible causes:
- Node is actively syncing — high CPU during initial sync is normal
- Client is processing a large number of transactions or blocks
- Another process is consuming CPU unexpectedly

Suggested actions:
- Check which process is consuming CPU: top -bn1 | head -20
- Check if the node is syncing: run node-status.sh
- If the node has been synced for a while and CPU is still high, check client logs for errors
- If load persists above 8, consider restarting the affected client"
fi

if echo "$ALERTS" | grep -q "SWAP"; then
    send_alert "health-swap" "🚨 Health alert on $(hostname): swap usage is high — ${SWAP_USED_GB}GB of swap in use.

Possible causes:
- Ethereum clients are consuming more RAM than available — common during initial sync
- Multiple processes competing for memory
- Memory leak in one of the clients

Suggested actions:
- Check memory usage: free -h
- Check which process is using the most memory: ps aux --sort=-%mem | head -10
- Check client logs for out-of-memory errors
- Consider restarting the client with highest memory usage if it has been running for a long time
- If RAM is consistently insufficient, the board may not meet the minimum 15GB requirement"
fi

if echo "$ALERTS" | grep -q "PEERS"; then
    send_alert "health-peers" "🚨 Health alert on $(hostname): execution client has very few peers — only $EL_PEERS peer(s) connected.

Possible causes:
- Node just started and is still discovering peers — this is normal in the first few minutes
- Network connectivity issue on the board
- Firewall blocking P2P ports (default: 30303 TCP/UDP for most EL clients)
- ISP or router blocking peer-to-peer traffic

Suggested actions:
- Check if the issue is recent: run node-status.sh to see current peer count
- Verify network connectivity: ping google.com
- Check if P2P port is reachable from outside
- Check client logs for connection errors
- If the node has been running for more than 30 minutes with no peers, consider restarting the execution client"
fi
