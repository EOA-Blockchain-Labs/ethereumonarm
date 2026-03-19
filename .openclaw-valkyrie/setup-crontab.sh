#!/bin/bash
# setup-crontab.sh — install system cron jobs for the ethereum user

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPTS_DIR="/home/ethereum/.openclaw/workspace/skills/eoa-node/scripts"
LOG_DIR="/home/ethereum/.openclaw/cronlogs"
CRON_HEALTH="*/15 * * * * /bin/bash $SCRIPTS_DIR/cron-health.sh >> $LOG_DIR/cron-health.log 2>&1"
CRON_SYNC="*/15 * * * * /bin/bash $SCRIPTS_DIR/cron-sync.sh >> $LOG_DIR/cron-sync.log 2>&1"
CRON_UPDATES="0 8 * * * /bin/bash $SCRIPTS_DIR/cron-updates.sh >> $LOG_DIR/cron-updates.log 2>&1"
CRON_SYNCREPORT="*/15 * * * * /bin/bash $SCRIPTS_DIR/cron-syncreport.sh >> $LOG_DIR/cron-syncreport.log 2>&1"

echo ""
echo "=================================================="
echo "  OpenClaw Ethereum Node Agent — Crontab Setup"
echo "=================================================="
echo ""

# ── Check scripts exist ───────────────────────────────────────────────────────
for script in cron-health.sh cron-sync.sh cron-updates.sh cron-syncreport.sh; do
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        echo -e "${RED}Error: $script not found at $SCRIPTS_DIR/$script${NC}"
        exit 1
    fi
done

# ── Create log directory ──────────────────────────────────────────────────────
[ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"

# ── Make scripts executable ───────────────────────────────────────────────────
chmod +x "$SCRIPTS_DIR/cron-health.sh"
chmod +x "$SCRIPTS_DIR/cron-sync.sh"
chmod +x "$SCRIPTS_DIR/cron-updates.sh"
chmod +x "$SCRIPTS_DIR/cron-syncreport.sh"

# ── Get current crontab ───────────────────────────────────────────────────────
CURRENT_CRONTAB=$(sudo -u ethereum crontab -l 2>/dev/null)

# ── Check if jobs already exist ───────────────────────────────────────────────
ALREADY_INSTALLED=false
if echo "$CURRENT_CRONTAB" | grep -q "cron-health.sh" && \
   echo "$CURRENT_CRONTAB" | grep -q "cron-sync.sh" && \
   echo "$CURRENT_CRONTAB" | grep -q "cron-updates.sh" && \
   echo "$CURRENT_CRONTAB" | grep -q "cron-syncreport.sh"; then
    ALREADY_INSTALLED=true
fi

if [ "$ALREADY_INSTALLED" = "true" ]; then
    echo -e "${YELLOW}Cron jobs already installed. Reinstall?${NC}"
    read -p "  Reinstall? [y/N] " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted. No changes were made."
        exit 0
    fi
    # Remove existing entries
    CURRENT_CRONTAB=$(echo "$CURRENT_CRONTAB" | grep -v "cron-health.sh" | grep -v "cron-sync.sh" | grep -v "cron-updates.sh" | grep -v "cron-syncreport.sh")
fi

# ── Install cron jobs ─────────────────────────────────────────────────────────
NEW_CRONTAB=$(printf "%s\n%s\n%s\n%s\n%s" "$CURRENT_CRONTAB" "$CRON_HEALTH" "$CRON_SYNC" "$CRON_UPDATES" "$CRON_SYNCREPORT")

echo "$NEW_CRONTAB" | sudo -u ethereum crontab -

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: failed to install crontab.${NC}"
    exit 1
fi

echo -e "${GREEN}Cron jobs installed successfully.${NC}"
echo ""
echo "Installed jobs:"
sudo -u ethereum crontab -l | grep -E "cron-health|cron-sync|cron-updates|cron-syncreport"
echo ""
echo "To verify all cron jobs:"
echo "  sudo -u ethereum crontab -l"
echo ""
echo "To monitor cron logs:"
echo "  tail -f $LOG_DIR/cron-health.log"
echo "  tail -f $LOG_DIR/cron-sync.log"
echo "  tail -f $LOG_DIR/cron-updates.log"
echo "  tail -f $LOG_DIR/cron-syncreport.log"
echo ""
