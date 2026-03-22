#!/bin/bash
# cron-updates.sh — runs via system cron, messages agent if updates are available

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
LOCK_FILE="$LOCK_DIR/updates.lock"
LOCK_EXPIRY=86400
CLIENTS="geth nethermind erigon besu reth lighthouse prysm nimbus teku lodestar grandine mev-boost"
UPDATES=""
LOCK_KEY=""

[ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

# ── Expire updates lock older than 24 hours ───────────────────────────────────
if [ -f "$LOCK_FILE" ]; then
    lock_age=$(( $(date +%s) - $(date -r "$LOCK_FILE" +%s 2>/dev/null || echo 0) ))
    if [ "$lock_age" -gt "$LOCK_EXPIRY" ]; then
        rm -f "$LOCK_FILE"
    fi
fi

sudo apt-get update -qq 2>/dev/null

# ── Get currently running clients ─────────────────────────────────────────────
STATUS_OUTPUT=$(bash "$(dirname "$0")/node-status.sh" 2>/dev/null)
EL_RUNNING=$(echo "$STATUS_OUTPUT" | awk -F': ' '/^Execution client/ {print $2}' | awk '{print $1}')
CL_RUNNING=$(echo "$STATUS_OUTPUT" | awk -F': ' '/^Consensus client/ {print $2}' | awk '{print $1}')

RUNNING_UPDATES=""

for client in $CLIENTS; do
    if ! dpkg -l "$client" &>/dev/null; then
        continue
    fi

    INSTALLED=$(dpkg -l "$client" 2>/dev/null | awk '/^ii/ {print $3}')
    AVAILABLE=$(apt-cache policy "$client" 2>/dev/null | awk '/Candidate:/ {print $2}')

    if [ -n "$INSTALLED" ] && [ -n "$AVAILABLE" ] && [ "$INSTALLED" != "$AVAILABLE" ]; then
        IS_RUNNING=""
        if [ "$client" = "$EL_RUNNING" ] || [ "$client" = "$CL_RUNNING" ]; then
            IS_RUNNING=" ⚠️ CURRENTLY RUNNING"
        fi
        UPDATES="$UPDATES\n• $client: $INSTALLED → $AVAILABLE${IS_RUNNING}"
        LOCK_KEY="${LOCK_KEY}${client}=${AVAILABLE},"
    fi
done

if [ -n "$UPDATES" ]; then
    STORED_KEY=$(cat "$LOCK_FILE" 2>/dev/null)

    if [ "$LOCK_KEY" != "$STORED_KEY" ]; then
        RUNNING_NOTE=""
        if echo "$UPDATES" | grep -q "CURRENTLY RUNNING"; then
            RUNNING_NOTE="

⚠️ One or more CURRENTLY RUNNING clients have updates available. Inform the user that updating running clients will cause them to restart automatically — the node will briefly go offline during the restart."
        fi

        openclaw agent \
            --agent ethereum-node \
            --message "📦 Ethereum client updates available on $(hostname):$(echo -e "$UPDATES")${RUNNING_NOTE}

Please inform the user of the available updates and ask if they would like to update any of these clients. Remind them that on Ethereum on ARM, systemd automatically restarts running services after an update — they do not need to restart manually." \
            --deliver \
            --channel telegram \
            --reply-channel telegram \
            --reply-to "$TELEGRAM_ID"
        echo -n "$LOCK_KEY" > "$LOCK_FILE"
    fi
else
    rm -f "$LOCK_FILE"
fi
