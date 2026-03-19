#!/bin/bash
# health-check.sh — full manual health check, run on demand by the agent

CONSENSUS_API="http://localhost:5052"
EXECUTION_RPC="http://localhost:8545"
SEP="------------------------------------------------------------"

echo "$SEP"
echo "HEALTH CHECK — $(date)"
echo "$SEP"

# ── 1. RUNNING CLIENTS ───────────────────────────────────────────────────────
echo ""
echo "## Running Clients"
bash "$(dirname "$0")/running-clients.sh"

# ── 2. SYNC STATUS ───────────────────────────────────────────────────────────
echo ""
echo "## Sync Status"
bash "$(dirname "$0")/synced-clients.sh"

# ── 3. SYSTEM RESOURCES ──────────────────────────────────────────────────────
echo ""
echo "## System Resources"

LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
echo "CPU load avg (1m 5m 15m): $LOAD"
LOAD1=$(echo $LOAD | awk '{print $1}' | cut -d. -f1)
if [ "$LOAD1" -gt 4 ]; then
    echo "WARN cpu: load average is high ($LOAD)"
fi

MEM=$(free -h | awk '/^Mem:/ {printf "total=%s used=%s free=%s available=%s", $2, $3, $4, $7}')
echo "RAM: $MEM"

SWAP_USED_KB=$(free -k | awk '/^Swap:/ {print $3}')
SWAP_USED_GB=$(echo "scale=1; $SWAP_USED_KB / 1048576" | bc 2>/dev/null || echo "?")
echo "Swap used: ${SWAP_USED_GB} GB"
if [ "$SWAP_USED_KB" -gt 5242880 ]; then
    echo "WARN swap: swap usage is high (${SWAP_USED_GB} GB)"
fi

DISK=$(df -h /home/ethereum | awk 'NR==2 {printf "total=%s used=%s free=%s use%%=%s", $2, $3, $4, $5}')
echo "Disk /home/ethereum: $DISK"
DISK_FREE_GB=$(df -BG /home/ethereum | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$DISK_FREE_GB" -lt 50 ]; then
    echo "WARN disk: only ${DISK_FREE_GB} GB free on /home/ethereum"
fi

DISK_ROOT=$(df -h / | awk 'NR==2 {printf "total=%s used=%s free=%s use%%=%s", $2, $3, $4, $5}')
echo "Disk /: $DISK_ROOT"

# ── 4. SERVICE STATUS ────────────────────────────────────────────────────────
echo ""
echo "## Service Status"

EL_CLIENTS="geth nethermind erigon besu reth"
CL_CLIENTS="lighthouse-beacon prysm-beacon nimbus-beacon teku-beacon lodestar-beacon grandine-beacon"

for base in $EL_CLIENTS; do
    for suffix in "" "-hoodi" "-sepolia"; do
        svc="${base}${suffix}"
        state=$(systemctl is-active "$svc" 2>/dev/null)
        if [ "$state" = "active" ]; then
            echo "  EL $svc: active"
        elif [ "$state" = "failed" ]; then
            echo "  EL $svc: FAILED"
        fi
    done
done

for base in $CL_CLIENTS; do
    for suffix in "" "-mev" "-hoodi" "-mev-hoodi" "-sepolia" "-mev-sepolia"; do
        svc="${base}${suffix}"
        state=$(systemctl is-active "$svc" 2>/dev/null)
        if [ "$state" = "active" ]; then
            echo "  CL $svc: active"
        elif [ "$state" = "failed" ]; then
            echo "  CL $svc: FAILED"
        fi
    done
done

for svc in mev-boost mev-boost-hoodi mev-boost-sepolia; do
    state=$(systemctl is-active "$svc" 2>/dev/null)
    if [ "$state" = "active" ]; then
        echo "  MEV $svc: active"
    elif [ "$state" = "failed" ]; then
        echo "  MEV $svc: FAILED"
    fi
done

# ── 5. RECENT ERRORS IN LOGS ─────────────────────────────────────────────────
echo ""
echo "## Recent Errors (last 15 min)"

for base in $EL_CLIENTS; do
    for suffix in "" "-hoodi" "-sepolia"; do
        svc="${base}${suffix}"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            ERRORS=$(journalctl -u "$svc" --since "15 minutes ago" -p err --no-pager -q 2>/dev/null | tail -5)
            if [ -n "$ERRORS" ]; then
                echo "  Errors in $svc:"
                echo "$ERRORS" | sed 's/^/    /'
            fi
        fi
    done
done

for base in $CL_CLIENTS; do
    for suffix in "" "-mev" "-hoodi" "-mev-hoodi" "-sepolia" "-mev-sepolia"; do
        svc="${base}${suffix}"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            ERRORS=$(journalctl -u "$svc" --since "15 minutes ago" -p err --no-pager -q 2>/dev/null | tail -5)
            if [ -n "$ERRORS" ]; then
                echo "  Errors in $svc:"
                echo "$ERRORS" | sed 's/^/    /'
            fi
        fi
    done
done

# ── 6. PEER COUNTS ───────────────────────────────────────────────────────────
echo ""
echo "## Peer Counts"

EL_PEERS=$(curl -s -X POST "$EXECUTION_RPC" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' 2>/dev/null | python3 -c "
import sys, json
try:
    print(int(json.load(sys.stdin)['result'], 16))
except:
    print('unavailable')
")
echo "  EL peers: $EL_PEERS"
if [ "$EL_PEERS" != "unavailable" ] && [ "$EL_PEERS" -lt 3 ] 2>/dev/null; then
    echo "  WARN peers: EL peer count is very low ($EL_PEERS)"
fi

CL_PEERS=$(curl -s "$CONSENSUS_API/eth/v1/node/peer_count" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)['data']
    print('connected=' + data['connected'] + ' disconnecting=' + data['disconnecting'])
except:
    print('unavailable')
")
echo "  CL peers: $CL_PEERS"

# ── 7. UPTIME ────────────────────────────────────────────────────────────────
echo ""
echo "## System Uptime"
uptime

echo ""
echo "$SEP"
echo "Health check complete."
echo "$SEP"
