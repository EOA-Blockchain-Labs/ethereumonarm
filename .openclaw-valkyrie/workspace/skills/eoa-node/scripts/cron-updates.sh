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
CLIENTS="geth nethermind erigon besu reth lighthouse prysm nimbus teku lodestar grandine mev-boost"
UPDATES=""
LOCK_KEY=""

[ ! -d "$LOCK_DIR" ] && mkdir -p "$LOCK_DIR"

sudo apt-get update -qq 2>/dev/null

for client in $CLIENTS; do
    if ! dpkg -l "$client" &>/dev/null; then
        continue
    fi

    INSTALLED=$(dpkg -l "$client" 2>/dev/null | awk '/^ii/ {print $3}')
    AVAILABLE=$(apt-cache policy "$client" 2>/dev/null | awk '/Candidate:/ {print $2}')

    if [ -n "$INSTALLED" ] && [ -n "$AVAILABLE" ] && [ "$INSTALLED" != "$AVAILABLE" ]; then
        UPDATES="$UPDATES\n• $client: $INSTALLED → $AVAILABLE"
        LOCK_KEY="${LOCK_KEY}${client}=${AVAILABLE},"
    fi
done

if [ -n "$UPDATES" ]; then
    LOCK_FILE="$LOCK_DIR/updates.lock"
    STORED_KEY=$(cat "$LOCK_FILE" 2>/dev/null)

    if [ "$LOCK_KEY" != "$STORED_KEY" ]; then
        openclaw message send --channel telegram --target "$TELEGRAM_ID" --message "📦 Ethereum client updates available on $(hostname):$(echo -e "$UPDATES")\n\nWould you like me to update any of these clients?"
        echo -n "$LOCK_KEY" > "$LOCK_FILE"
    fi
else
    rm -f "$LOCK_DIR/updates.lock"
fi
