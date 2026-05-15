#!/bin/bash
# =============================================================================
# diagnose-connectivity.sh — Debug inter-node connectivity issues.
#
# Run on EITHER control node to test reachability of the peer.
# Shows routing, timing, and per-interface details.
#
# Usage:
#   bash diagnose-connectivity.sh <peer-vpn-ip>
#   bash diagnose-connectivity.sh          # uses PEER_CONTROL_IP / FAILOVER_CONTROL_IP from node.env
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="/home/ethereum/.obol-monitor/conf/node.env"
[ -f "$CONF" ] && . "$CONF"

PEER_IP="${1:-}"

# Determine peer IP from config if not given
if [ -z "$PEER_IP" ]; then
    if [ -n "${FAILOVER_CONTROL_IP:-}" ]; then
        PEER_IP="$FAILOVER_CONTROL_IP"
        echo "Using FAILOVER_CONTROL_IP: $PEER_IP"
    elif [ -n "${PEER_CONTROL_IP:-}" ]; then
        PEER_IP="$PEER_CONTROL_IP"
        echo "Using PEER_CONTROL_IP: $PEER_IP"
    else
        echo "ERROR: No peer IP configured. Pass as argument: bash diagnose-connectivity.sh <ip>"
        exit 1
    fi
fi

EL_PORT="${2:-80}"
RELAY_PORT="${PEER_RELAY_PORT:-3640}"
TIMEOUT=5
SEP="─────────────────────────────────────────"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   obol-monitor connectivity diagnostic   ║"
echo "╚══════════════════════════════════════════╝"
echo "  Peer target : ${PEER_IP}"
echo "  Timestamp   : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "  This node   : ${NODE_NAME:-$(hostname)} (${VPN_IP:-unknown VPN IP})"
echo ""

# =============================================================================
# 1. Network interfaces
# =============================================================================
echo "${SEP}"
echo "1. Network interfaces"
echo "${SEP}"
ip -brief addr show | awk '{printf "  %-18s %-10s %s\n", $1, $2, $3}'
echo ""
echo "  Default routes:"
ip route show default | sed 's/^/  /'
echo ""

# Check for multiple VPN interfaces
VPN_IFACES=$(ip -brief addr show | awk '$1 ~ /^(tailscale|wg|tun|vpn)/ {print $1, $3}')
if [ -n "$VPN_IFACES" ]; then
    echo "  ⚠️  Multiple VPN interfaces detected:"
    echo "$VPN_IFACES" | sed 's/^/    /'
    echo "  Multiple VPNs can cause routing conflicts. Check which handles ${PEER_IP}:"
fi
echo ""

# =============================================================================
# 2. Routing to peer
# =============================================================================
echo "${SEP}"
echo "2. Route to ${PEER_IP}"
echo "${SEP}"
ip route get "$PEER_IP" 2>&1 | sed 's/^/  /'
echo ""

# Which interface will actually be used?
OUTBOUND_IFACE=$(ip route get "$PEER_IP" 2>/dev/null | awk '/dev / {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
echo "  Outbound interface: ${OUTBOUND_IFACE:-unknown}"

# Warn if not tailscale
if [ -n "$OUTBOUND_IFACE" ] && ! echo "$OUTBOUND_IFACE" | grep -qi 'tailscale\|ts'; then
    echo "  ⚠️  Traffic is NOT going through Tailscale!"
    echo "  If ${PEER_IP} is a Tailscale IP, this will fail."
    echo "  Possible cause: WireGuard or another VPN has captured the route."
fi
echo ""

# =============================================================================
# 3. Ping test
# =============================================================================
echo "${SEP}"
echo "3. Ping (5 packets)"
echo "${SEP}"
ping -c 5 -W "$TIMEOUT" "$PEER_IP" 2>&1 | tail -5 | sed 's/^/  /'
echo ""

# =============================================================================
# 4. Tailscale-specific check
# =============================================================================
echo "${SEP}"
echo "4. Tailscale status for peer"
echo "${SEP}"
if command -v tailscale > /dev/null 2>&1; then
    echo "  tailscale ping (direct path check):"
    tailscale ping --timeout=5s "$PEER_IP" 2>&1 | sed 's/^/    /'
    echo ""
    echo "  Peer status in tailscale:"
    tailscale status 2>/dev/null | grep "$PEER_IP" | sed 's/^/    /' || echo "    (not found in tailscale status)"
else
    echo "  tailscale not found in PATH"
fi
echo ""

# =============================================================================
# 5. EL API (nginx port 80)
# =============================================================================
echo "${SEP}"
echo "5. EL API — http://${PEER_IP}:${EL_PORT}  (nginx proxy)"
echo "${SEP}"
EL_START=$(date +%s%3N)
EL_RESP=$(curl -s --max-time "$TIMEOUT" \
    -H "Content-type: application/json" \
    -X POST \
    --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' \
    "$PEER_IP" 2>&1)
EL_END=$(date +%s%3N)
EL_MS=$(( EL_END - EL_START ))

if echo "$EL_RESP" | grep -q '"result"'; then
    BLOCK=$(echo "$EL_RESP" | python3 -c "
import sys,json
try:
    n=json.load(sys.stdin).get('result',{}).get('number','')
    print(f'block {int(n,16):,}' if n else '(no block number)')
except: print('(parse error)')
" 2>/dev/null)
    echo "  ✅ RESPONDING (${EL_MS}ms) — ${BLOCK}"
elif [ -z "$EL_RESP" ]; then
    echo "  ❌ NO RESPONSE (${EL_MS}ms) — connection refused or timeout"
else
    echo "  ❌ ERROR (${EL_MS}ms)"
    echo "$EL_RESP" | head -3 | sed 's/^/    /'
fi
echo ""

# =============================================================================
# 6. Charon relay (port 3640)
# =============================================================================
echo "${SEP}"
echo "6. Charon relay — http://${PEER_IP}:${RELAY_PORT}"
echo "${SEP}"
RELAY_START=$(date +%s%3N)
RELAY_CODE=$(curl -s --max-time "$TIMEOUT" \
    -o /dev/null -w "%{http_code}" \
    "http://${PEER_IP}:${RELAY_PORT}/" 2>/dev/null)
RELAY_END=$(date +%s%3N)
RELAY_MS=$(( RELAY_END - RELAY_START ))

if [ -n "$RELAY_CODE" ] && [ "$RELAY_CODE" != "000" ]; then
    echo "  ✅ RESPONDING (${RELAY_MS}ms) — HTTP ${RELAY_CODE}"
else
    echo "  ❌ NO RESPONSE (${RELAY_MS}ms) — connection refused or timeout"
fi
echo ""

# =============================================================================
# 7. Concurrent timing test (what the health scripts do)
# =============================================================================
echo "${SEP}"
echo "7. Concurrent probe (simulates health script)"
echo "${SEP}"
echo "  Running EL + relay probes simultaneously 3 times with 5s gap..."
echo ""
for i in 1 2 3; do
    T=$(date +%s%3N)
    EL=$(curl -s --max-time "$TIMEOUT" \
        -H "Content-type: application/json" -X POST \
        --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' \
        "$PEER_IP" 2>/dev/null | grep -c '"result"')
    RLY=$(curl -s --max-time "$TIMEOUT" -o /dev/null -w "%{http_code}" \
        "http://${PEER_IP}:${RELAY_PORT}/" 2>/dev/null)
    PING_OK=$(ping -c 1 -W "$TIMEOUT" "$PEER_IP" > /dev/null 2>&1 && echo "ok" || echo "fail")
    MS=$(( $(date +%s%3N) - T ))

    EL_S=$([ "$EL" = "1" ] && echo "✅" || echo "❌")
    RLY_S=$([ -n "$RLY" ] && [ "$RLY" != "000" ] && echo "✅ HTTP${RLY}" || echo "❌")
    PING_S=$([ "$PING_OK" = "ok" ] && echo "✅" || echo "❌")

    echo "  Run $i (${MS}ms): EL=${EL_S}  Relay=${RLY_S}  Ping=${PING_S}"
    [ "$i" -lt 3 ] && sleep 5
done
echo ""

# =============================================================================
# 8. WireGuard interference check
# =============================================================================
echo "${SEP}"
echo "8. WireGuard / dual-VPN check"
echo "${SEP}"
# Check for WireGuard interfaces — may have custom names (e.g. "nanopct6", "wg0")
WG_IFACES=$(ip -brief addr show | awk '$1 ~ /^wg/ {print $1, $3}')
# Also detect non-standard names by checking WireGuard kernel module
if command -v wg > /dev/null 2>&1; then
    WG_EXTRA=$(wg show interfaces 2>/dev/null | tr ' ' '\n' | while read iface; do
        addr=$(ip -brief addr show "$iface" 2>/dev/null | awk '{print $1, $3}')
        [ -n "$addr" ] && echo "$addr"
    done)
    WG_IFACES=$(printf "%s\n%s" "$WG_IFACES" "$WG_EXTRA" | sort -u | grep -v "^$")
fi
if [ -n "$WG_IFACES" ]; then
    echo "  ⚠️  WireGuard interfaces found:"
    echo "$WG_IFACES" | sed 's/^/    /'
    echo ""
    echo "  WireGuard routing table:"
    ip route show table all 2>/dev/null | grep -i 'wg\|wireguard' | head -10 | sed 's/^/    /' \
        || echo "    (no WireGuard-specific routes)"
    echo ""
    echo "  Check if WireGuard is routing ${PEER_IP}:"
    ip route show table all 2>/dev/null | grep "${PEER_IP%.*}" | sed 's/^/    /'
    echo ""
    echo "  Possible fix: ensure Tailscale routes take priority."
    echo "  Run: sudo ip route del <conflicting-route>"
    echo "  Or: check your WireGuard AllowedIPs to exclude Tailscale CGNAT range (100.64.0.0/10)"
else
    echo "  No WireGuard interfaces detected on this node."
fi
echo ""

echo "${SEP}"
echo "Diagnostic complete — $(date -u '+%H:%M:%S UTC')"
echo "${SEP}"
