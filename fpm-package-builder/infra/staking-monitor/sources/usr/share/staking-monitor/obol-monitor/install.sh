#!/bin/bash
# =============================================================================
# install.sh — Install or manage obol-monitor.
#
# Usage:
#   bash install.sh obol                      — full setup on an Obol node
#   bash install.sh control                   — full setup on primary control node
#   bash install.sh control-failover          — full setup on backup control node
#   bash install.sh obol crontab              — install crontab only (Obol node)
#   bash install.sh control crontab           — install crontab only (control node)
#   bash install.sh control-failover crontab  — install crontab only (failover node)
# =============================================================================
# control          : primary — always runs health checks
# control-failover : backup  — only runs if primary is unreachable

set -e

NODE_TYPE="${1:-}"
SUBCOMMAND="${2:-}"

if [ "$NODE_TYPE" != "obol" ] && \
   [ "$NODE_TYPE" != "control" ] && \
   [ "$NODE_TYPE" != "control-failover" ]; then
    echo "Usage: bash install.sh obol|control|control-failover [crontab]"
    exit 1
fi

INSTALL_DIR="/home/ethereum/.obol-monitor"
SCRIPT_SRC="$(cd "$(dirname "$0")" && pwd)"
CONF="${INSTALL_DIR}/conf/node.env"

# =============================================================================
# SUBCOMMAND: crontab only
# =============================================================================

if [ "$SUBCOMMAND" = "crontab" ]; then
    # control-failover uses the same crontab as control
    _cron_type="$NODE_TYPE"
    [ "$_cron_type" = "control-failover" ] && _cron_type="control"
    # Read directly from /usr/share/ — always up to date after apt upgrade
    CRONTAB_FILE="${SCRIPT_SRC}/crontabs/${_cron_type}-crontab"
    if [ ! -f "$CRONTAB_FILE" ]; then
        echo "ERROR: ${CRONTAB_FILE} not found."
        exit 1
    fi
    echo "=== Crontab installer (${NODE_TYPE}) ==="
    echo ""
    echo "Preview:"
    cat "$CRONTAB_FILE"
    echo ""
    read -rp "Install this crontab for the 'ethereum' user? [y/N] " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        # Use temp file with guaranteed trailing newline
        _tmp_cron=$(mktemp)
        cat "$CRONTAB_FILE" > "$_tmp_cron"
        echo "" >> "$_tmp_cron"
        sudo -u ethereum crontab "$_tmp_cron"
        rm -f "$_tmp_cron"
        echo "✅ Crontab installed."
    else
        echo "Skipped."
    fi
    exit 0
fi

# =============================================================================
# FULL INSTALL — banner
# =============================================================================

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        obol-monitor installer            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Node type : ${NODE_TYPE}"
echo "  Install to: ${INSTALL_DIR}"
echo ""

# =============================================================================
# HELPERS
# =============================================================================

ask() {
    # ask <prompt> <default>  →  sets $ANSWER
    local prompt="$1" default="$2"
    if [ -n "$default" ]; then
        read -rp "  ${prompt} [${default}]: " ANSWER
        ANSWER="${ANSWER:-$default}"
    else
        read -rp "  ${prompt}: " ANSWER
    fi
}

ask_required() {
    # ask_required <prompt>  →  keeps asking until non-empty  →  sets $ANSWER
    local prompt="$1"
    while true; do
        read -rp "  ${prompt}: " ANSWER
        [ -n "$ANSWER" ] && break
        echo "  ⚠️  This field is required."
    done
}

# =============================================================================
# STEP 1 — AUTO-DETECT RUNNING ETHEREUM CLIENTS
# =============================================================================

detect_clients() {
    local EL_CLIENTS="geth nethermind erigon besu reth ethrex"
    local CL_CLIENTS="lighthouse prysm nimbus teku lodestar grandine"

    local found_el="" found_el_svc=""
    local found_cl="" found_cl_svc=""
    local found_network="mainnet"

    # Execution client — mainnet, hoodi, sepolia
    for client in $EL_CLIENTS; do
        if systemctl is-active --quiet "$client" 2>/dev/null; then
            found_el="$client"; found_el_svc="$client"; found_network="mainnet"; break
        fi
        if systemctl is-active --quiet "${client}-hoodi" 2>/dev/null; then
            found_el="$client"; found_el_svc="${client}-hoodi"; found_network="hoodi"; break
        fi
        if systemctl is-active --quiet "${client}-sepolia" 2>/dev/null; then
            found_el="$client"; found_el_svc="${client}-sepolia"; found_network="sepolia"; break
        fi
    done

    # Consensus client — MEV variants first (Obol nodes always run -mev)
    for client in $CL_CLIENTS; do
        for suffix in "-beacon-mev" "-beacon-mev-hoodi" "-beacon-mev-sepolia" \
                      "-beacon" "-beacon-hoodi" "-beacon-sepolia"; do
            if systemctl is-active --quiet "${client}${suffix}" 2>/dev/null; then
                found_cl="$client"; found_cl_svc="${client}${suffix}"; break 2
            fi
        done
    done

    # MEV Boost — derived from network
    local mev_svc="mev-boost"
    case "$found_network" in
        hoodi)   mev_svc="mev-boost-hoodi" ;;
        sepolia) mev_svc="mev-boost-sepolia" ;;
    esac

    DETECTED_EL_CLIENT="${found_el:-UNKNOWN}"
    DETECTED_CL_CLIENT="${found_cl:-UNKNOWN}"
    DETECTED_NETWORK="${found_network}"
    DETECTED_EL_SERVICE="${found_el_svc:-UNKNOWN}"
    DETECTED_CL_SERVICE="${found_cl_svc:-UNKNOWN}"
    DETECTED_MEV_SERVICE="${mev_svc}"

    echo "─── Client auto-detection ───────────────────"
    if [ -n "$found_el" ]; then
        echo "  EL : ${found_el} → service: ${found_el_svc}"
    else
        echo "  EL : ⚠️  not detected (no execution client active)"
    fi
    if [ -n "$found_cl" ]; then
        echo "  CL : ${found_cl} → service: ${found_cl_svc}"
    else
        echo "  CL : ⚠️  not detected (no consensus client active)"
    fi
    echo "  Network  : ${found_network}"
    echo "  MEV Boost: ${mev_svc}"
    if [ -z "$found_el" ] && [ -z "$found_cl" ]; then
        echo ""
        echo "  ⚠️  No clients running. UNKNOWN will be written — edit"
        echo "     EL_SERVICE / CL_SERVICE in node.env manually afterwards."
    fi
    echo ""
}

detect_clients

# =============================================================================
# STEP 2 — INTERACTIVE QUESTIONS
# =============================================================================

# --------------------------------------------------------------------------
# Obol node questions
# --------------------------------------------------------------------------
if [ "$NODE_TYPE" = "obol" ]; then

    echo "─── Obol node configuration ─────────────────"
    echo ""

    # -- Lido CSM -----------------------------------------------------------
    echo "  Are you using Lido CSM?"
    echo "    1) No  — standard Obol validator"
    echo "    2) Yes — Lido CSM (mainnet only)"
    echo ""
    while true; do
        read -rp "  Choice [1/2]: " LIDO_CHOICE
        case "$LIDO_CHOICE" in
            1) USING_LIDO="no";  break ;;
            2) USING_LIDO="yes"; break ;;
            *) echo "  Please enter 1 or 2." ;;
        esac
    done
    echo ""

    # -- Validator service detection ----------------------------------------
    # Scan ALL DVT conf files in /etc/ethereum/dvt/ independently of which
    # beacon client is running. This avoids the bug where the beacon client
    # and the validator client belong to different software (e.g. lighthouse
    # beacon + prysm validator). An active service takes priority; otherwise
    # we look for a matching .conf file.
    DVT_DIR="/etc/ethereum/dvt"
    DETECTED_VALIDATOR_SERVICE="UNKNOWN"

    if [ "$USING_LIDO" = "yes" ]; then
        # Lido: pattern is <cl>-validator-obol-lido (mainnet only)
        LIDO_PATTERN="-validator-obol-lido"

        # 1. Check for any active Lido DVT validator service
        for svc_file in "${DVT_DIR}"/*${LIDO_PATTERN}.conf; do
            [ -f "$svc_file" ] || continue
            svc_name="$(basename "$svc_file" .conf)"
            if systemctl is-active --quiet "$svc_name" 2>/dev/null; then
                DETECTED_VALIDATOR_SERVICE="$svc_name"
                echo "  ✅ Validator service (active): ${DETECTED_VALIDATOR_SERVICE}"
                break
            fi
        done

        # 2. If none active, pick the first conf that exists
        if [ "$DETECTED_VALIDATOR_SERVICE" = "UNKNOWN" ]; then
            for svc_file in "${DVT_DIR}"/*${LIDO_PATTERN}.conf; do
                [ -f "$svc_file" ] || continue
                DETECTED_VALIDATOR_SERVICE="$(basename "$svc_file" .conf)"
                echo "  ✅ Validator service (conf found): ${DETECTED_VALIDATOR_SERVICE}"
                break
            done
        fi

        if [ "$DETECTED_VALIDATOR_SERVICE" = "UNKNOWN" ]; then
            echo "  ⚠️  No Lido CSM validator conf found in ${DVT_DIR}/"
            echo "     Set VALIDATOR_SERVICE manually in node.env."
        fi

    else
        # Standard Obol: pattern depends on network
        case "${DETECTED_NETWORK}" in
            hoodi)   NET_PATTERN="-validator-hoodi-obol" ;;
            sepolia) NET_PATTERN="-validator-sepolia-obol" ;;
            *)       NET_PATTERN="-validator-obol" ;;
        esac

        # 1. Check for any active standard Obol validator service
        for svc_file in "${DVT_DIR}"/*${NET_PATTERN}.conf; do
            [ -f "$svc_file" ] || continue
            svc_name="$(basename "$svc_file" .conf)"
            if systemctl is-active --quiet "$svc_name" 2>/dev/null; then
                DETECTED_VALIDATOR_SERVICE="$svc_name"
                echo "  ✅ Validator service (active): ${DETECTED_VALIDATOR_SERVICE}"
                break
            fi
        done

        # 2. If none active, pick the first matching conf
        if [ "$DETECTED_VALIDATOR_SERVICE" = "UNKNOWN" ]; then
            for svc_file in "${DVT_DIR}"/*${NET_PATTERN}.conf; do
                [ -f "$svc_file" ] || continue
                DETECTED_VALIDATOR_SERVICE="$(basename "$svc_file" .conf)"
                echo "  ✅ Validator service (conf found): ${DETECTED_VALIDATOR_SERVICE}"
                break
            done
        fi

        if [ "$DETECTED_VALIDATOR_SERVICE" = "UNKNOWN" ]; then
            echo "  ⚠️  No matching DVT validator conf found in ${DVT_DIR}/"
            echo "     Expected pattern: *${NET_PATTERN}.conf"
            echo "     Set VALIDATOR_SERVICE manually in node.env."
        fi
    fi
    echo ""

    # -- Cluster size -------------------------------------------------------
    echo "─── Cluster size ────────────────────────────"
    echo ""
    echo "  Minimum for an Obol cluster is 3 nodes."
    while true; do
        ask_required "Total number of nodes in the cluster (e.g. 3, 5, 9)"
        if [[ "$ANSWER" =~ ^[0-9]+$ ]] && [ "$ANSWER" -ge 3 ]; then
            Q_CLUSTER_SIZE="$ANSWER"
            break
        else
            echo "  ⚠️  Must be a number ≥ 3."
        fi
    done
    Q_CHARON_PEERS_MIN=$(( Q_CLUSTER_SIZE - 1 ))
    echo "  Charon peers minimum set to: ${Q_CHARON_PEERS_MIN} (cluster_size - 1)"
    echo ""

    # -- Identity -----------------------------------------------------------
    echo "─── Node identity ───────────────────────────"
    echo ""
    ask_required "Node number (1 to ${Q_CLUSTER_SIZE})"
    Q_NODE_ID="$ANSWER"

    ask "Node name" "obol-node-${Q_NODE_ID}"
    Q_NODE_NAME="$ANSWER"

    echo ""
    echo "─── Telegram ────────────────────────────────"
    echo ""
    ask_required "Telegram Bot Token"
    Q_BOT_TOKEN="$ANSWER"

    ask_required "Telegram Chat ID"
    Q_CHAT_ID="$ANSWER"

    echo ""
    echo "─── VPN / Tailscale (optional) ──────────────"
    echo ""
    echo "  Leave empty if you do not want to record this node's VPN IP."
    read -rp "  VPN IP (e.g. 100.x.x.x): " Q_VPN_IP
    echo ""

# --------------------------------------------------------------------------
# Control node questions
# --------------------------------------------------------------------------
else

    echo "─── Control node configuration ──────────────"
    echo ""

    # Standard (non-DVT) validator — derived from beacon client name
    if [ -n "$DETECTED_CL_CLIENT" ] && [ "$DETECTED_CL_CLIENT" != "UNKNOWN" ]; then
        DETECTED_VALIDATOR_SERVICE="${DETECTED_CL_CLIENT}-validator"
        echo "  Validator service: ${DETECTED_VALIDATOR_SERVICE}"
    else
        DETECTED_VALIDATOR_SERVICE="UNKNOWN-validator"
        echo "  ⚠️  CL not detected. Set VALIDATOR_SERVICE manually in node.env."
    fi
    USING_LIDO="no"
    echo ""

    # -- Cluster size -------------------------------------------------------
    echo "─── Cluster size ────────────────────────────"
    echo ""
    while true; do
        ask_required "Total number of Obol nodes in the cluster (e.g. 3, 5, 9)"
        if [[ "$ANSWER" =~ ^[0-9]+$ ]] && [ "$ANSWER" -ge 3 ]; then
            Q_CLUSTER_SIZE="$ANSWER"
            break
        else
            echo "  ⚠️  Must be a number ≥ 3."
        fi
    done
    Q_CHARON_PEERS_EXPECTED=$(( Q_CLUSTER_SIZE - 1 ))
    echo "  CHARON_PEERS_EXPECTED set to: ${Q_CHARON_PEERS_EXPECTED} (cluster_size - 1)"
    echo ""

    # -- Identity -----------------------------------------------------------
    echo "─── Node identity ───────────────────────────"
    echo ""
    ask_required "Node number (1 or 2)"
    Q_NODE_ID="$ANSWER"

    ask "Node name" "control-node-${Q_NODE_ID}"
    Q_NODE_NAME="$ANSWER"

    echo ""
    echo "─── Telegram ────────────────────────────────"
    echo ""
    ask_required "Telegram Bot Token"
    Q_BOT_TOKEN="$ANSWER"

    ask_required "Telegram Chat ID"
    Q_CHAT_ID="$ANSWER"

    # -- Obol node IPs and names (dynamic) ----------------------------------
    echo ""
    echo "─── Obol cluster node IPs ───────────────────"
    echo ""

    declare -a Q_OBOL_IPS
    declare -a Q_OBOL_NAMES

    for i in $(seq 1 "$Q_CLUSTER_SIZE"); do
        ask_required "Obol node ${i} IP"
        Q_OBOL_IPS[$i]="$ANSWER"
    done

    echo ""
    echo "─── Obol cluster node names (labels) ────────"
    echo ""

    for i in $(seq 1 "$Q_CLUSTER_SIZE"); do
        ask "Obol node ${i} name" "obol-node-${i}"
        Q_OBOL_NAMES[$i]="$ANSWER"
    done

    echo ""
    echo "─── VPN / Tailscale (optional) ──────────────"
    echo ""
    echo "  Leave empty if you do not want to record this node's VPN IP."
    read -rp "  VPN IP (e.g. 100.x.x.x): " Q_VPN_IP

    echo ""
    if [ "$NODE_TYPE" = "control" ]; then
        echo "─── Failover node monitoring ─────────────────"
        echo ""
        echo "  The primary node can monitor the failover node and alert if it goes down."
        echo "  Leave empty if you do not have a failover node yet."
        read -rp "  Failover control node VPN IP (leave empty to skip): " Q_FAILOVER_CONTROL_IP
        echo ""
    else
        Q_FAILOVER_CONTROL_IP=""
    fi

    if [ "$NODE_TYPE" = "control-failover" ]; then
        echo "─── Failover: primary control node ──────────"
        echo ""
        echo "  This is the BACKUP control node. It will skip all checks when"
        echo "  the primary control node is reachable over VPN."
        echo ""
        ask_required "Primary control node VPN IP"
        Q_PEER_CONTROL_IP="$ANSWER"
    else
        # Primary control node — no peer, always runs
        Q_PEER_CONTROL_IP=""
    fi
    echo ""

    echo "─── Validator duties monitoring ─────────────"
    echo ""
    echo "  The control node checks missed attestations and proposals via the"
    echo "  local beacon API. Provide the directory containing keystore .json files."
    echo ""
    echo "  Common locations:"
    echo "    Lighthouse : /home/ethereum/.lighthouse/mainnet/validators"
    echo "    Nimbus     : /home/ethereum/.nimbus-beacon/validators"
    echo "    Teku       : /home/ethereum/.teku/validator/key-manager/local"
    echo "    Prysm      : /home/ethereum/.prysm-beacon/validator"
    echo "    Lodestar   : /home/ethereum/.lodestar-beacon/validator/keystores"
    echo "    Grandine   : /home/ethereum/.grandine-beacon/mainnet/validator"
    echo ""
    ask_required "Path to directory containing keystore .json files"
    Q_KEYSTORE_DIR="$ANSWER"
    echo ""

fi

# =============================================================================
# STEP 3 — SUMMARY BEFORE WRITING
# =============================================================================

echo "─── Configuration summary ───────────────────"
echo ""
echo "  Node type      : ${NODE_TYPE}"
echo "  Node ID        : ${Q_NODE_ID}"
echo "  Node name      : ${Q_NODE_NAME}"
echo "  Telegram token : ${Q_BOT_TOKEN:0:6}… (truncated)"
echo "  Telegram chat  : ${Q_CHAT_ID}"
echo "  EL service     : ${DETECTED_EL_SERVICE}"
echo "  CL service     : ${DETECTED_CL_SERVICE}"
echo "  MEV Boost      : ${DETECTED_MEV_SERVICE}"
echo "  Validator      : ${DETECTED_VALIDATOR_SERVICE}"
echo "  Cluster size   : ${Q_CLUSTER_SIZE}"

if [ "$NODE_TYPE" = "obol" ]; then
    echo "  Lido CSM       : ${USING_LIDO}"
    echo "  Charon peers min: ${Q_CHARON_PEERS_MIN}"
else
    echo "  Charon peers exp: ${Q_CHARON_PEERS_EXPECTED}"
    for i in $(seq 1 "$Q_CLUSTER_SIZE"); do
        echo "  Obol node ${i}     : ${Q_OBOL_NAMES[$i]} @ ${Q_OBOL_IPS[$i]}"
    done
fi
[ -n "$Q_VPN_IP" ] && echo "  VPN IP         : ${Q_VPN_IP}" || echo "  VPN IP         : (not set)"
if [ "$NODE_TYPE" = "control" ]; then
    echo "  Role           : PRIMARY (always runs)"
    [ -n "$Q_FAILOVER_CONTROL_IP" ] \
        && echo "  Failover IP    : ${Q_FAILOVER_CONTROL_IP}" \
        || echo "  Failover IP    : (not set)"
    echo "  Keystore dir   : ${Q_KEYSTORE_DIR}"
elif [ "$NODE_TYPE" = "control-failover" ]; then
    echo "  Role           : FAILOVER (runs only if primary at ${Q_PEER_CONTROL_IP} is down)"
    echo "  Primary IP     : ${Q_PEER_CONTROL_IP}"
    echo "  Keystore dir   : ${Q_KEYSTORE_DIR}"
fi
echo ""
read -rp "  Proceed with these settings? [y/N] " CONFIRM
if ! [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted. Nothing was written."
    exit 0
fi
echo ""

# =============================================================================
# STEP 4 — CREATE DIRECTORIES AND COPY FILES
# =============================================================================

# Scripts and lib live in /usr/share/ and are updated automatically by apt.
# Only create data directories and copy crontabs for user review.
mkdir -p "${INSTALL_DIR}/conf"          "${INSTALL_DIR}/crontabs"          "${INSTALL_DIR}/locks"          "${INSTALL_DIR}/logs"

if [ "$NODE_TYPE" = "obol" ]; then
    cp "${SCRIPT_SRC}/crontabs/obol-crontab"  "${INSTALL_DIR}/crontabs/"
else
    mkdir -p "${INSTALL_DIR}/cache"
    cp "${SCRIPT_SRC}/crontabs/control-crontab" "${INSTALL_DIR}/crontabs/"
fi

# =============================================================================
# STEP 5 — WRITE node.env
# =============================================================================

if [ -f "$CONF" ]; then
    BACKUP="${CONF}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$CONF" "$BACKUP"
    echo "ℹ️  Existing node.env backed up to: ${BACKUP}"
fi

# control-failover uses the same env template as control
_conf_type="$NODE_TYPE"
[ "$_conf_type" = "control-failover" ] && _conf_type="control"
# Support both .example (package install) and plain (development)
_env_src="${SCRIPT_SRC}/conf/${_conf_type}-node.env"
[ ! -f "$_env_src" ] && _env_src="${SCRIPT_SRC}/conf/${_conf_type}-node.env.example"
cp "$_env_src" "$CONF"

# -- Common substitutions ---------------------------------------------------
sed -i \
    -e "s|__NODE_ID__|${Q_NODE_ID}|g" \
    -e "s|__NODE_NAME__|${Q_NODE_NAME}|g" \
    -e "s|__TELEGRAM_BOT_TOKEN__|${Q_BOT_TOKEN}|g" \
    -e "s|__TELEGRAM_CHAT_ID__|${Q_CHAT_ID}|g" \
    -e "s|__EL_CLIENT__|${DETECTED_EL_CLIENT}|g" \
    -e "s|__CL_CLIENT__|${DETECTED_CL_CLIENT}|g" \
    -e "s|__NETWORK__|${DETECTED_NETWORK}|g" \
    -e "s|__EL_SERVICE__|${DETECTED_EL_SERVICE}|g" \
    -e "s|__CL_SERVICE__|${DETECTED_CL_SERVICE}|g" \
    -e "s|__MEV_SERVICE__|${DETECTED_MEV_SERVICE}|g" \
    -e "s|__VALIDATOR_SERVICE__|${DETECTED_VALIDATOR_SERVICE}|g" \
    -e "s|__VPN_IP__|${Q_VPN_IP}|g" \
    -e "s|__PEER_CONTROL_IP__|${Q_PEER_CONTROL_IP}|g" \
    -e "s|__FAILOVER_CONTROL_IP__|${Q_FAILOVER_CONTROL_IP}|g" \
    -e "s|__KEYSTORE_DIR__|${Q_KEYSTORE_DIR}|g" \
    -e "s|__CLUSTER_SIZE__|${Q_CLUSTER_SIZE}|g" \
    -e "s|__USING_LIDO__|${USING_LIDO}|g" \
    -e "s|__NODE_TYPE__|${NODE_TYPE}|g" \
    "$CONF"

# -- Obol-only substitutions ------------------------------------------------
if [ "$NODE_TYPE" = "obol" ]; then
    sed -i \
        -e "s|__CHARON_PEERS_MIN__|${Q_CHARON_PEERS_MIN}|g" \
        "$CONF"
fi

# -- Control/failover substitutions ----------------------------------------
if [ "$NODE_TYPE" = "control" ] || [ "$NODE_TYPE" = "control-failover" ]; then
    sed -i \
        -e "s|__CHARON_PEERS_EXPECTED__|${Q_CHARON_PEERS_EXPECTED}|g" \
        "$CONF"

    # Build the dynamic OBOL_NODES_BLOCK and replace the placeholder
    NODES_BLOCK=""
    for i in $(seq 1 "$Q_CLUSTER_SIZE"); do
        ip="${Q_OBOL_IPS[$i]}"
        name="${Q_OBOL_NAMES[$i]}"
        NODES_BLOCK="${NODES_BLOCK}OBOL_NODE_${i}_IP=\"${ip}\"
OBOL_NODE_${i}_NAME=\"${name}\"
OBOL_NODE_${i}_BASE=\"http://${ip}:3620\"
"
    done

    # Use python3 for the replacement to handle newlines and special chars
    python3 - "$CONF" "$NODES_BLOCK" << 'PYEOF'
import sys
path = sys.argv[1]
block = sys.argv[2]
with open(path) as f:
    c = f.read()
c = c.replace("__OBOL_NODES_BLOCK__", block.rstrip())
with open(path, "w") as f:
    f.write(c)
PYEOF
fi

chown -R ethereum:ethereum "${INSTALL_DIR}"
echo "✅ node.env written to: ${CONF}"
echo ""

# Run initial validator index sync for control nodes
if [ "$NODE_TYPE" = "control" ] || [ "$NODE_TYPE" = "control-failover" ]; then
if [ -n "$Q_KEYSTORE_DIR" ] && [ -d "$Q_KEYSTORE_DIR" ]; then
    echo "─── Building validator index cache ──────────"
    echo ""
    sudo -u ethereum bash "${INSTALL_DIR}/scripts/sync-indices.sh"
    echo ""
fi
fi

# =============================================================================
# STEP 6 — FILES INSTALLED
# =============================================================================

echo "─── Files installed ─────────────────────────"
find "${INSTALL_DIR}" \
    -not -path "*/locks/*" \
    -not -path "*/logs/*" \
    | sort | sed 's|^|  |'
echo ""

# =============================================================================
# STEP 7 — NEXT STEPS
# =============================================================================

echo "─── Next steps ──────────────────────────────"
echo ""
echo "  1. Review node.env:"
echo "       ${CONF}"
echo ""
echo "  2. Test scripts:"
if [ "$NODE_TYPE" = "obol" ]; then
    echo "       sudo -u ethereum bash ${SCRIPT_SRC}/scripts/obol-health.sh"
    echo "       sudo -u ethereum bash ${SCRIPT_SRC}/scripts/obol-status.sh"
else
    echo "       sudo -u ethereum bash ${SCRIPT_SRC}/scripts/control-health.sh"
    echo "       sudo -u ethereum bash ${SCRIPT_SRC}/scripts/control-status.sh"
    echo "       sudo -u ethereum bash ${SCRIPT_SRC}/scripts/validator-duties.sh"
fi
echo ""
echo "  3. Install crontab when ready:"
echo "       bash ${SCRIPT_SRC}/install.sh ${NODE_TYPE} crontab"
if [ "$NODE_TYPE" = "control" ] || [ "$NODE_TYPE" = "control-failover" ]; then
    echo ""
    echo "  4. Allow Charon port 3620 from this node on each Obol node:"
    echo "       sudo ufw allow from <this-node-vpn-ip> to any port 3620"
fi
echo ""
echo "Done. ✅"