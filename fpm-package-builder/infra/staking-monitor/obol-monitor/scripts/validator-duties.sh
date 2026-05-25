#!/bin/bash
# =============================================================================
# validator-duties.sh — Per-validator missed attestation and missed block
# proposal checker. Run by cron every 7 minutes (just over one epoch = 6.4 min).
#
# Checks via the standard Ethereum Beacon API (localhost:5052):
#
#   Missed attestations:
#     POST /eth/v1/validator/liveness/{epoch}
#     → is_live: false means the validator did not participate in the epoch.
#     Checked against the last FINALIZED epoch to avoid false positives from
#     partially-elapsed epochs.
#
#   Missed block proposals:
#     GET /eth/v1/validator/duties/proposer/{epoch}
#     → list of (slot, validator_index) pairs scheduled to propose.
#     GET /eth/v1/beacon/headers/{slot}
#     → 404 = slot has no block = proposal was missed.
#     Checked for the last PROPOSAL_CHECK_EPOCHS epochs.
#
# Alert deduplication: one alert per validator per epoch (lock file keyed by
# validator_index + epoch). Locks are auto-expired after LOCK_EXPIRY seconds.
# =============================================================================

export HOME=/home/ethereum
export USER=ethereum
export PATH=/home/ethereum/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="/home/ethereum/.obol-monitor/conf/node.env"

if [ ! -f "$CONF" ]; then
    echo "ERROR: $CONF not found." >&2
    exit 1
fi
. "$CONF"
. "${SCRIPT_DIR}/../lib/common.sh"

# Failover node defers to primary — only run if this node is active
is_primary
case "$IS_PRIMARY_REASON" in
    peer_healthy|peer_el_down)
        echo "Primary node is up — deferring validator-duties to primary."
        exit 0
        ;;
esac

TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "=== validator-duties check — ${TS} ==="

expire_locks "vd-"

# =============================================================================
# Sanity checks
# =============================================================================

if [ ! -f "$INDEX_CACHE" ]; then
    echo "ERROR: Index cache not found at ${INDEX_CACHE}." >&2
    echo "       Run sync-indices.sh first." >&2
    lock_alert "vd-no-cache" "$(node_label)
⚠️ <b>validator-duties</b>: index cache missing.
Run <code>bash /home/ethereum/.validator-monitor/scripts/sync-indices.sh</code> to rebuild it."
    exit 1
fi

# Load all validator indices from cache (only active validators are monitored)
# Cache format: { "0xpubkey": {"index": "12345", "status": "active_ongoing"}, ... }
ACTIVE_INDICES=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    cache = json.load(f)
active = [v['index'] for v in cache.values() if 'active' in v.get('status','')]
print(','.join(active))
" "$INDEX_CACHE")

if [ -z "$ACTIVE_INDICES" ]; then
    echo "No active validators in cache. Nothing to check."
    exit 0
fi

ACTIVE_COUNT=$(echo "$ACTIVE_INDICES" | tr ',' '\n' | wc -l | tr -d ' ')
echo "Monitoring ${ACTIVE_COUNT} active validator(s)."

# Build a JSON array of active indices for API calls
INDICES_JSON=$(python3 -c "
import json, sys
indices = sys.argv[1].split(',')
print(json.dumps(indices))
" "$ACTIVE_INDICES")

# Build a lookup map: index → short pubkey label (for human-readable alerts)
LABEL_MAP=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    cache = json.load(f)
result = {v['index']: k[:10]+'...'+k[-6:] for k, v in cache.items()}
print(json.dumps(result))
" "$INDEX_CACHE")

# Helper: get pubkey label for a validator index
get_label() {
    echo "$LABEL_MAP" | python3 -c "
import sys, json
m = json.load(sys.stdin)
print(m.get('$1', 'idx:$1'))
"
}

# =============================================================================
# SECTION 1 — MISSED ATTESTATIONS (via /beacon/rewards/attestations)
#
# Endpoint: POST /eth/v1/beacon/rewards/attestations/{epoch}
# Body    : ["index1", "index2", ...]
# Response: data.total_rewards[].{ validator_index, head, target, source }
#
# A validator missed its attestation when ALL of head, target and source
# equal "0" (or are negative/zero post-Electra). These are integer strings
# in Gwei. We only check for the miss/not-miss condition — reward amounts
# are intentionally discarded.
#
# Uses current_epoch - 2 (same as beaconcha.in): the latest completed epoch
# where all attestations have had time to be included on-chain.
# =============================================================================

echo ""
echo "--- Missed attestation check ---"

# Rewards endpoint requires a FINALIZED epoch — Lighthouse returns 404
# for epochs not yet finalized. Use finalized_epoch(), not check_epoch().
CHECK_EPOCH=$(finalized_epoch)
if [ -z "$CHECK_EPOCH" ]; then
    echo "WARNING: Could not determine finalized epoch. Skipping attestation check."
else
    CURRENT_EPOCH=$(current_epoch)
    echo "Checking epoch ${CHECK_EPOCH} (finalized; head epoch: ${CURRENT_EPOCH})"

    # ------------------------------------------------------------------
    # Missed attestation check via rewards/attestations endpoint.
    # head + target + source all ≤ 0 → validator missed the attestation.
    # Requires a finalized epoch — Lighthouse returns 404 otherwise.
    # ------------------------------------------------------------------
    ATT_RESP=$(beacon_post "/eth/v1/beacon/rewards/attestations/${CHECK_EPOCH}" "$INDICES_JSON")
    ATT_HTTP=$(beacon_http_code)

    if [ "$ATT_HTTP" = "200" ] && [ -n "$ATT_RESP" ]; then
        # ── Method 1: rewards endpoint (on-chain confirmed) ────────────────
        PARSE_RESULT=$(echo "$ATT_RESP" | python3 -c "
import sys, json
try:
    rewards = json.load(sys.stdin)['data']['total_rewards']
    missed, ok = [], []
    for r in rewards:
        idx = str(r.get('validator_index', ''))
        try:
            h = int(r.get('head',   0))
            t = int(r.get('target', 0))
            s = int(r.get('source', 0))
        except:
            h = t = s = 0
        if h <= 0 and t <= 0 and s <= 0:
            missed.append(idx)
        else:
            ok.append(idx)
    print('MISSED:' + ' '.join(missed))
    print('OK:'     + ' '.join(ok))
except Exception as e:
    print(f'ERROR:{e}', file=sys.stderr)
    print('MISSED:')
    print('OK:')
")
        MISSED_ATTESTERS=$(echo "$PARSE_RESULT" | grep '^MISSED:' | cut -d: -f2)
        OK_ATTESTERS=$(echo    "$PARSE_RESULT" | grep '^OK:'     | cut -d: -f2)

    elif [ "${ATT_HTTP:-0}" = "0" ] || echo "$ATT_RESP" | grep -q 'missing state\|NOT_FOUND'; then
        # ── Method 2: liveness fallback ────────────────────────────────────
        # Triggered when:
        #   HTTP 0   → client does not support the endpoint (Nimbus)
        #   NOT_FOUND → Lighthouse checkpoint-sync missing historical state
        # Falls back to liveness/{epoch} which only needs the head state.
        echo "  Rewards endpoint unavailable (HTTP ${ATT_HTTP:-0}). Falling back to liveness."
        LIVE_EPOCH=$(check_epoch)
        LIVE_RESP=$(beacon_post "/eth/v1/validator/liveness/${LIVE_EPOCH}" "$INDICES_JSON")
        LIVE_HTTP=$(beacon_http_code)
        if [ "$LIVE_HTTP" = "200" ] && [ -n "$LIVE_RESP" ]; then
            PARSE_RESULT=$(echo "$LIVE_RESP" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)['data']
    missed = [str(v['index']) for v in data if not v.get('is_live', True)]
    ok     = [str(v['index']) for v in data if     v.get('is_live', True)]
    print('MISSED:' + ' '.join(missed))
    print('OK:'     + ' '.join(ok))
except Exception as e:
    print(f'ERROR:{e}', file=sys.stderr)
    print('MISSED:')
    print('OK:')
")
            MISSED_ATTESTERS=$(echo "$PARSE_RESULT" | grep '^MISSED:' | cut -d: -f2)
            OK_ATTESTERS=$(echo    "$PARSE_RESULT" | grep '^OK:'     | cut -d: -f2)
        else
            echo "WARNING: Both rewards and liveness endpoints failed. Skipping."
            MISSED_ATTESTERS=""
            OK_ATTESTERS=""
        fi

    else
        echo "WARNING: Attestation rewards endpoint returned HTTP ${ATT_HTTP:-0}. Skipping epoch ${CHECK_EPOCH}."
        MISSED_ATTESTERS=""
        OK_ATTESTERS=""
    fi

        # ------------------------------------------------------------------
    # Alert on missed validators
    # If >= MASS_MISS_THRESHOLD validators missed the same epoch, send one
    # global alert instead of per-validator messages (cluster/ISP outage).
    # If < threshold, send individual alerts per validator.
    # ------------------------------------------------------------------
    MISSED_COUNT=$(echo "$MISSED_ATTESTERS" | wc -w | tr -d ' ')
    OK_COUNT=$(echo     "$OK_ATTESTERS"     | wc -w | tr -d ' ')
    TOTAL_COUNT=$(( MISSED_COUNT + OK_COUNT ))
    echo "  Attested: ${OK_COUNT}  |  Missed: ${MISSED_COUNT}"

    MASS_MISS_THRESHOLD="${MASS_MISS_THRESHOLD:-10}"

    if [ "${MISSED_COUNT}" -ge "${MASS_MISS_THRESHOLD}" ] 2>/dev/null; then
        # ── Global alert: too many misses to be a per-validator issue ──────
        # Global key (no epoch) — fires once per 6h window regardless of epoch
        LOCK_KEY="vd-att-mass-global"
        lock_alert "$LOCK_KEY" "$(node_label)
🚨 <b>Mass Missed Attestations — Cluster/ISP Issue</b>

Epoch       : <b>${CHECK_EPOCH}</b>
Missed      : <b>${MISSED_COUNT} / ${TOTAL_COUNT}</b> validators
Attested    : ${OK_COUNT}

${MISSED_COUNT} validators missed attestations in the same epoch.
This strongly suggests a cluster-wide or infrastructure problem,
not an individual validator fault.

Possible causes:
• One or more Obol nodes are down
• ISP or network outage affecting the cluster
• Beacon node crashed or lost sync
• Charon DVT threshold not reached

Suggested actions:
• Check Obol node status from control node
• Check beacon node: <code>sudo systemctl status ${CL_SERVICE:-beacon}</code>
• Check validator client: <code>sudo journalctl -u ${VALIDATOR_SERVICE:-validator} -n 50</code>
• Check Tailscale connectivity between cluster nodes" 21600

        for IDX in $MISSED_ATTESTERS; do
            clear_lock "vd-att-${IDX}-${CHECK_EPOCH}"
        done

    else
        # ── Per-validator alerts: isolated misses ──────────────────────────
        # Only send mass-miss recovery when ALL validators are attesting (0 missed)
        if [ "${MISSED_COUNT}" -eq 0 ] 2>/dev/null; then
            recovery_alert "vd-att-mass-global" "$(node_label)
✅ <b>Attestation Mass Issue Resolved</b>

Epoch     : <b>${CHECK_EPOCH}</b>
Attested  : <b>${OK_COUNT} / ${TOTAL_COUNT}</b> validators

All validators are attesting correctly again."
        fi

        for IDX in $MISSED_ATTESTERS; do
            LABEL=$(get_label "$IDX")
            LOCK_KEY="vd-att-${IDX}-${CHECK_EPOCH}"
            lock_alert "$LOCK_KEY" "$(node_label)
❌ <b>Missed / Late Attestation</b>

Validator : <code>${IDX}</code> (<code>${LABEL}</code>)
Epoch     : <b>${CHECK_EPOCH}</b>
Explorer  : https://beaconcha.in/validator/${IDX}

The validator either missed its attestation duty or attested
with a high inclusion distance — its attestation reward for
this epoch was zero or below threshold.

Check beaconcha.in → <b>Attestations</b> tab to distinguish:
• <b>Included (late)</b>: attested but with high inclusion distance
• <b>Missing</b>: attestation was not included on-chain at all

Possible causes:
• Late block arrival causing a head vote miss (high inclusion distance)
• Validator client offline or crashed during this epoch
• Beacon node was not synced or unreachable
• Network connectivity issue (P2P port blocked)

Check: <code>sudo journalctl -u ${VALIDATOR_SERVICE:-validator} -n 50</code>"
        done
    fi

    for IDX in $OK_ATTESTERS; do
        LABEL=$(get_label "$IDX")
        recovery_alert "vd-att-${IDX}-${CHECK_EPOCH}" "$(node_label)
✅ <b>Attestation Restored</b>

Validator : <code>${IDX}</code> (<code>${LABEL}</code>)
Epoch     : <b>${CHECK_EPOCH}</b>
Explorer  : https://beaconcha.in/validator/${IDX}

Validator is attesting correctly again."
    done
fi

# =============================================================================
# SECTION 2 — MISSED BLOCK PROPOSALS
#
# Step A: Get proposer duties for recent epochs.
#   GET /eth/v1/validator/duties/proposer/{epoch}
#   → returns all (slot, validator_index) pairs for that epoch.
#   We filter to only the validator indices we own.
#
# Step B: For each owned proposal slot in the past, check if a block exists.
#   GET /eth/v1/beacon/headers/{slot}
#   → HTTP 200 = block was proposed ✅
#   → HTTP 404 / empty data = slot was missed ❌
#
# We only alert on slots in the PAST (slot < current head slot).
# Future/current-epoch proposal duties are informational only.
# =============================================================================

echo ""
echo "--- Block proposal check ---"

CURRENT_EPOCH=$(current_epoch)
if [ -z "$CURRENT_EPOCH" ]; then
    echo "WARNING: Could not determine current epoch. Skipping proposal check."
else
    # Build a set of our validator indices for fast lookup
    OUR_INDICES_SET=$(echo "$ACTIVE_INDICES" | tr ',' '\n' | sort)

    # Get current head slot to distinguish past from future proposals
    HEAD_SLOT=$(beacon_get "/eth/v1/node/syncing" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin)['data']['head_slot'])
except:
    print(0)
")

    # Check the last PROPOSAL_CHECK_EPOCHS epochs
    START_EPOCH=$(( CURRENT_EPOCH - ${PROPOSAL_CHECK_EPOCHS:-3} ))
    [ "$START_EPOCH" -lt 0 ] && START_EPOCH=0

    for EPOCH in $(seq "$START_EPOCH" "$CURRENT_EPOCH"); do
        DUTIES_RESP=$(beacon_get "/eth/v1/validator/duties/proposer/${EPOCH}")

        if [ -z "$DUTIES_RESP" ]; then
            echo "  Epoch ${EPOCH}: no response from proposer duties endpoint."
            continue
        fi

        # Extract duties for our validators only
        OUR_DUTIES=$(echo "$DUTIES_RESP" | python3 -c "
import sys, json
our = set(sys.argv[1].split(','))
try:
    data = json.load(sys.stdin).get('data', [])
except: data = []
for d in data:
    idx = str(d.get('validator_index',''))
    slot = str(d.get('slot',''))
    if idx in our: print(idx+' '+slot)
" "$ACTIVE_INDICES")

        if [ -z "$OUR_DUTIES" ]; then
            echo "  Epoch ${EPOCH}: no proposal duties for our validators."
            continue
        fi

        echo "  Epoch ${EPOCH}: found proposal duties:"
        while IFS=' ' read -r IDX SLOT; do
            LABEL=$(get_label "$IDX")

            # Only check past slots — future slots have not been proposed yet
            if [ "$SLOT" -ge "$HEAD_SLOT" ] 2>/dev/null; then
                echo "    Slot ${SLOT} — validator ${IDX} (${LABEL}): upcoming, skipping."
                continue
            fi

            echo -n "    Slot ${SLOT} — validator ${IDX} (${LABEL}): "

            # Check if a block exists for this slot
            HEADER_RESP=$(beacon_get "/eth/v1/beacon/headers/${SLOT}")

            # A 404 or empty response means the slot was missed
            HAS_BLOCK=$(echo "$HEADER_RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # code != 200 or data missing = missed
    if d.get('code', 200) != 200:
        print('missed')
    elif not d.get('data'):
        print('missed')
    else:
        print('proposed')
except:
    print('missed')
" 2>/dev/null)

            if [ "$HAS_BLOCK" = "proposed" ]; then
                echo "✅ proposed"
                # Alert on successful proposal — rare event, always worth knowing
                lock_alert "vd-proposal-ok-${IDX}-${SLOT}" "$(node_label)
🎉 <b>Block Proposal SUCCESS</b>

Validator : <code>${IDX}</code> (<code>${LABEL}</code>)
Slot      : <b>${SLOT}</b>  (epoch ${EPOCH})

Your validator successfully proposed a block.

• Slot on explorer     : https://beaconcha.in/slot/${SLOT}
• Validator on explorer: https://beaconcha.in/validator/${IDX}"
                recovery_alert "vd-proposal-${IDX}-${SLOT}" "$(node_label)
✅ <b>Missed Proposal Slot Recovered</b>

Validator : <code>${IDX}</code> (<code>${LABEL}</code>)
Slot      : <b>${SLOT}</b> — block IS present (may have been included late)
Explorer  : https://beaconcha.in/slot/${SLOT}"
            else
                echo "❌ MISSED"
                LOCK_KEY="vd-proposal-${IDX}-${SLOT}"
                lock_alert "$LOCK_KEY" "$(node_label)
🚨 <b>Missed Block Proposal</b>

Validator : <code>${IDX}</code> (<code>${LABEL}</code>)
Slot      : <b>${SLOT}</b>  (epoch ${EPOCH})

This validator was scheduled to propose a block but the slot is empty.

A missed proposal means loss of significant MEV + block rewards.

Possible causes:
• Validator client was offline at proposal time
• Beacon node was not synced or had a connectivity issue
• MEV boost relay timeout (block not received in time)

Check:
• Validator logs: <code>sudo journalctl -u ${VALIDATOR_SERVICE:-validator} -n 100</code>
• Beacon logs  : <code>sudo journalctl -u ${BEACON_SERVICE:-beacon} -n 50</code>
• Slot on explorer     : https://beaconcha.in/slot/${SLOT}
• Validator on explorer: https://beaconcha.in/validator/${IDX}"
            fi
        done <<< "$OUR_DUTIES"
    done
fi

echo ""
echo "=== Done — $(date) ==="