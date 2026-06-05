#!/bin/bash
# =============================================================================
# install.sh — Install validator-monitor on a standalone validator node.
#
# Usage: bash install.sh
#
# What this does:
#   1. Creates directories under /home/ethereum/.validator-monitor/
#   2. Copies scripts and library files
#   3. Asks for configuration values and writes validator-monitor.env
#   4. Runs sync-indices.sh to build the initial validator index cache
#   5. Optionally installs the crontab
# =============================================================================

set -e

INSTALL_DIR="/home/ethereum/.validator-monitor"
SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)"
CONF="${INSTALL_DIR}/conf/validator-monitor.env"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     validator-monitor installer          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

ask() {
    local prompt="$1" default="$2"
    if [ -n "$default" ]; then
        read -rp "  ${prompt} [${default}]: " ANSWER
        ANSWER="${ANSWER:-$default}"
    else
        read -rp "  ${prompt}: " ANSWER
    fi
}

ask_required() {
    local prompt="$1"
    while true; do
        read -rp "  ${prompt}: " ANSWER
        [ -n "$ANSWER" ] && break
        echo "  ⚠️  This field is required."
    done
}

# =============================================================================
# STEP 1 — CREATE DIRECTORIES AND COPY FILES
# =============================================================================

echo "─── Creating directories ─────────────────"
mkdir -p "${INSTALL_DIR}/conf"
mkdir -p "${INSTALL_DIR}/lib"
mkdir -p "${INSTALL_DIR}/scripts"
mkdir -p "${INSTALL_DIR}/crontabs"
mkdir -p "${INSTALL_DIR}/cache"
mkdir -p "${INSTALL_DIR}/locks"
mkdir -p "${INSTALL_DIR}/logs"

# Scripts and lib stay in /usr/share/ — updated by apt upgrade
cp "${SCRIPT_SRC}/crontabs/validator-crontab"  "${INSTALL_DIR}/crontabs/"

chmod 644 "${INSTALL_DIR}/lib/common.sh"
chmod +x  "${INSTALL_DIR}/scripts/sync-indices.sh"
chmod +x  "${INSTALL_DIR}/scripts/validator-duties.sh"

chown -R ethereum:ethereum "${INSTALL_DIR}"
echo "  ✅ Files installed."
echo ""

# =============================================================================
# STEP 2 — INTERACTIVE CONFIGURATION
# =============================================================================

echo "─── Configuration ────────────────────────"
echo ""

ask "Node name (shown in Telegram alerts)" "validator-node"
Q_NODE_NAME="$ANSWER"

echo ""
echo "─── Telegram ────────────────────────────"
echo ""
ask_required "Telegram Bot Token (from @BotFather)"
Q_BOT_TOKEN="$ANSWER"

ask_required "Telegram Chat ID"
Q_CHAT_ID="$ANSWER"

echo ""
echo "─── Validator keys ──────────────────────"
echo ""
echo "  Common keystore locations:"
echo "    Lighthouse : /home/ethereum/.lighthouse/mainnet/validators"
echo "    Teku       : /home/ethereum/.teku/validator/key-manager/local"
echo "    Prysm      : /home/ethereum/.prysm-beacon/validator"
echo "    Nimbus     : /home/ethereum/.nimbus-beacon/validators"
echo "    Lodestar   : /home/ethereum/.lodestar-beacon/validator/keystores"
echo "    Grandine   : /home/ethereum/.grandine-beacon/mainnet/validator"
echo ""
ask_required "Path to directory containing keystore .json files"
Q_KEYSTORE_DIR="$ANSWER"

if [ ! -d "$Q_KEYSTORE_DIR" ]; then
    echo "  ⚠️  Directory does not exist. You can still continue and edit node.env manually."
fi

echo ""
echo "─── Beacon node ─────────────────────────"
echo ""
ask "Beacon API endpoint" "http://localhost:5052"
Q_CL_API="$ANSWER"

echo ""
echo "─── Configuration summary ───────────────"
echo ""
echo "  Node name    : ${Q_NODE_NAME}"
echo "  Bot token    : ${Q_BOT_TOKEN:0:6}… (truncated)"
echo "  Chat ID      : ${Q_CHAT_ID}"
echo "  Keystore dir : ${Q_KEYSTORE_DIR}"
echo "  Beacon API   : ${Q_CL_API}
  Validator svc: ${Q_VALIDATOR_SERVICE}
  Beacon svc   : ${Q_BEACON_SERVICE}"
echo ""
read -rp "  Proceed? [y/N] " CONFIRM
if ! [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# =============================================================================
# STEP 3 — WRITE CONFIGURATION FILE
# =============================================================================

if [ -f "$CONF" ]; then
    BACKUP="${CONF}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$CONF" "$BACKUP"
    echo "ℹ️  Existing config backed up to: ${BACKUP}"
fi

# Support both .example (package install) and plain (development)
_env_src="${SCRIPT_SRC}/conf/validator-monitor.env"
[ ! -f "$_env_src" ] && _env_src="${SCRIPT_SRC}/conf/validator-monitor.env.example"
cp "$_env_src" "$CONF"

sed -i \
    -e "s|^NODE_NAME=.*|NODE_NAME=\"${Q_NODE_NAME}\"|" \
    -e "s|^TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=\"${Q_BOT_TOKEN}\"|" \
    -e "s|^TELEGRAM_CHAT_ID=.*|TELEGRAM_CHAT_ID=\"${Q_CHAT_ID}\"|" \
    -e "s|^KEYSTORE_DIR=.*|KEYSTORE_DIR=\"${Q_KEYSTORE_DIR}\"|" \
    -e "s|^CL_API=.*|CL_API=\"${Q_CL_API}\"|" \
    "$CONF"

chown ethereum:ethereum "$CONF"
echo "✅ Configuration written to: ${CONF}"
echo ""

# =============================================================================
# STEP 4 — INITIAL INDEX SYNC
# =============================================================================

echo "─── Building validator index cache ──────"
echo ""
sudo -u ethereum bash "${INSTALL_DIR}/scripts/sync-indices.sh"
echo ""

# =============================================================================
# STEP 5 — CRONTAB (optional)
# =============================================================================

echo "─── Crontab ─────────────────────────────"
echo ""
cat "${INSTALL_DIR}/crontabs/validator-crontab"
echo ""
read -rp "  Install this crontab for the 'ethereum' user? [y/N] " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    sudo -u ethereum crontab "${INSTALL_DIR}/crontabs/validator-crontab"
    echo "  ✅ Crontab installed."
else
    echo "  Skipped. Install manually when ready:"
    echo "    sudo -u ethereum crontab ${INSTALL_DIR}/crontabs/validator-crontab"
fi

echo ""
echo "─── Next steps ──────────────────────────"
echo ""
echo "  1. Review and adjust thresholds in:"
echo "       ${CONF}"
echo ""
echo "  2. Test the duty checker manually:"
echo "       sudo -u ethereum bash ${INSTALL_DIR}/scripts/validator-duties.sh"
echo ""
echo "  3. Re-run index sync any time you add/remove validators:"
echo "       sudo -u ethereum bash ${INSTALL_DIR}/scripts/sync-indices.sh"
echo ""
echo "Done. ✅"