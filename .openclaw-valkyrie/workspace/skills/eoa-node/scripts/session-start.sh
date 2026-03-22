#!/bin/bash
# session-start.sh — runs at the beginning of every agent session.
# Outputs structured CHECK lines for the agent to interpret and act on.

echo "=== Ethereum on ARM Compatibility Check ==="

# --- Check EOA image ---
if [ ! -f /etc/eoa-release ]; then
    echo "EOA image : NOT FOUND"
    echo "EOA_CHECK : FAIL — /etc/eoa-release missing. This board is not running an Ethereum on ARM image."
else
    echo "EOA image : $(tr -d '\0' < /etc/eoa-release)"
    echo "EOA_CHECK : OK"
fi

# --- Check board compatibility ---
BOARD=$(strings /proc/device-tree/model 2>/dev/null | head -1 || echo "unknown")
echo "Board     : $BOARD"
SUPPORTED=false
case "$BOARD" in
    *"Rock 5B"* | *"ROCK 5B"*)
        SUPPORTED=true
        BOARD_NAME="Rock 5B"
        ;;
    *"NanoPC-T6"* | *"NanoPC T6"*)
        SUPPORTED=true
        BOARD_NAME="NanoPC-T6"
        ;;
    *"Orange Pi 5 Plus"* | *"OrangePi 5 Plus"*)
        SUPPORTED=true
        BOARD_NAME="Orange Pi 5 Plus"
        ;;
esac
if [ "$SUPPORTED" = "false" ]; then
    echo "BOARD_CHECK : WARN — '$BOARD' is not a recognised EOA board. Supported: Rock 5B, NanoPC-T6, Orange Pi 5 Plus."
else
    echo "BOARD_CHECK : OK — $BOARD_NAME"
fi

echo ""
echo "=== Memory ==="
TOTAL_RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
free -h | awk '/^Mem:/ {print "Total RAM: " $2 "  Available: " $7}'
if [ "$TOTAL_RAM_GB" -lt 15 ]; then
    echo "RAM_CHECK : FAIL — found ${TOTAL_RAM_GB}GB, minimum required is 15GB."
else
    echo "RAM_CHECK : OK — ${TOTAL_RAM_GB}GB"
fi

echo ""
echo "=== Disk ==="
DISK_TOTAL_GB=$(df -BG /home/ethereum | awk 'NR==2 {gsub("G",""); print $2}')
DISK_AVAIL_GB=$(df -BG /home/ethereum | awk 'NR==2 {gsub("G",""); print $4}')
DISK_USED_GB=$(df -BG /home/ethereum | awk 'NR==2 {gsub("G",""); print $3}')
DISK_USE_PCT=$(df /home/ethereum | awk 'NR==2 {print $5}')

df -h /home/ethereum | awk 'NR==2 {print "Total: " $2 "  Used: " $3 "  Available: " $4 "  Usage: " $5}'

if [ "$DISK_TOTAL_GB" -lt 1700 ]; then
    echo "DISK_CHECK : FAIL — total disk is ${DISK_TOTAL_GB}GB, minimum required is 1.7TB."
else
    EL_RUNNING=$(bash "$(dirname "$0")/node-status.sh" 2>/dev/null | awk -F'[()]' '/^Execution client/ {print $2}')
    if [ -n "$EL_RUNNING" ] && [ "$EL_RUNNING" != "none" ]; then
        echo "DISK_CHECK : OK — total ${DISK_TOTAL_GB}GB, available ${DISK_AVAIL_GB}GB, used ${DISK_USED_GB}GB (${DISK_USE_PCT}). Disk usage includes running execution client ($EL_RUNNING) — available space is expected to be lower while the node is syncing."
    elif [ "$DISK_AVAIL_GB" -lt 1500 ]; then
        echo "DISK_CHECK : WARN — total disk is ${DISK_TOTAL_GB}GB but only ${DISK_AVAIL_GB}GB available and no node is running. Old client data is likely consuming space. Run Pre-Start Resource Check before starting any node."
    else
        echo "DISK_CHECK : OK — total ${DISK_TOTAL_GB}GB, available ${DISK_AVAIL_GB}GB, used ${DISK_USED_GB}GB (${DISK_USE_PCT})"
    fi
fi

# --- Write board-info.md once ---
BOARD_INFO="/home/ethereum/.openclaw/workspace/memory/board-info.md"
if [ ! -f "$BOARD_INFO" ]; then
    mkdir -p "$(dirname "$BOARD_INFO")"
    cat > "$BOARD_INFO" << BOARDEOF
# Board Info — written once on first session start
- EOA image  : $(tr -d '\0' < /etc/eoa-release 2>/dev/null || echo "unknown")
- Board      : $BOARD
- Total RAM  : $(free -h | awk '/^Mem:/ {print $2}')
- Total disk : $(df -h /home/ethereum | awk 'NR==2 {print $2}')
BOARDEOF
fi

# --- Node status — AGENT MUST READ THIS AND ACT ON IT ---
echo ""
echo "======================================================="
echo "=== NODE STATUS — READ THIS AND ACT ON IT          ==="
echo "======================================================="
echo ""
bash "$(dirname "$0")/node-status.sh"
echo ""
echo "======================================================="
echo "IMPORTANT: Based on the STATUS and SYNC_STATUS lines:"
echo "  - STATUS STOPPED   → no node is running. Tell the user"
echo "    and encourage them to start one for Ethereum"
echo "    decentralization."
echo "  - STATUS INCOMPLETE → one client is missing its pair."
echo "    Tell the user and offer to fix it."
echo "  - STATUS RUNNING   → report the active pair, network,"
echo "    MEV Boost status, and SYNC_STATUS to the user."
echo "  - SYNC_STATUS SYNCED   → both clients are fully synced."
echo "  - SYNC_STATUS SYNCING  → report which client is behind"
echo "    and how far."
echo "  - DISK_CHECK WARN  → available disk is below 1.5TB and"
echo "    no node is running. This is likely caused by old"
echo "    client data remaining on disk from a previous node"
echo "    run. Inform the user, then immediately run the"
echo "    Pre-Start Resource Check from SKILL.md to find and"
echo "    report old client databases before attempting to"
echo "    start any node."
echo "======================================================="
