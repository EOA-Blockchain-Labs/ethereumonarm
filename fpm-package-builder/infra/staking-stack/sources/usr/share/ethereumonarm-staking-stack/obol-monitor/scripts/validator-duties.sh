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

# Primary/backup deduplication: skip if peer control node is reachable
if ! is_primary; then
    echo "Peer control node (${PEER_CONTROL_IP}) is reachable — deferring validator duties check to primary."
    exit 0
fi

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
Run <code>bash /home/ethereum/.validator-monitor/scripts/sync-indices.sh</code> to rebuild it." "detailed"
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

CHECK_EPOCH=$(check_epoch)
if [ -z "$CHECK_EPOCH" ]; then
    echo "WARNING: Could not determine current epoch. Skipping attestation check."
else
    CURRENT_EPOCH=$(current_epoch)
    echo "Checking epoch ${CHECK_EPOCH} (head epoch: ${CURRENT_EPOCH}, using head-1)"

    # ------------------------------------------------------------------
    # Method 1 — rewards/attestations endpoint
    # Preferred: head+target+source all ≤ 0 → validator missed attestation.
    # Not supported by all clients (Nimbus closes connection → HTTP 0).
    # ------------------------------------------------------------------
    ATT_RESP=$(beacon_post "/eth/v1/beacon/rewards/attestations/${CHECK_EPOCH}" "$INDICES_JSON")
    ATT_HTTP=$(beacon_http_code)

    if [ "$ATT_HTTP" = "200" ] && [ -n "$ATT_RESP" ]; then
        echo "  Method: rewards/attestations (HTTP 200)"

        PARSE_RESULT=$(echo "$ATT_RESP" | python3 -c "
import sys, json
try:
    rewards = json.load(sys.stdin)['data']['total_rewards']
    missed, head_missed, ok = [], [], []
    for r in rewards:
        idx = str(r.get('validator_index', ''))
        try:
            h = int(r.get('head',   0))
            t = int(r.get('target', 0))
            s = int(r.get('source', 0))
        except:
            h = t = s = 0
        if h <= 0 and t <= 0 and s <= 0:
            missed.append(idx)          # full miss — validator did not participate
        elif h <= 0:
            head_missed.append(idx)     # participated but head vote wrong or late
        else:
            ok.append(idx)
    print('MISSED:'      + ' '.join(missed))
    print('HEAD_MISSED:' + ' '.join(head_missed))
    print('OK:'          + ' '.join(ok))
except Exception as e:
    print(f'ERROR:{e}', file=sys.stderr)
    print('MISSED:')
    print('HEAD_MISSED:')
    print('OK:')
")
        MISSED_ATTESTERS=$(echo "$PARSE_RESULT"      | grep '^MISSED:'      | cut -d: -f2)
        HEAD_MISSED_ATTESTERS=$(echo "$PARSE_RESULT" | grep '^HEAD_MISSED:' | cut -d: -f2)
        OK_ATTESTERS=$(echo    "$PARSE_RESULT"       | grep '^OK:'          | cut -d: -f2)

    else
        # ------------------------------------------------------------------
        # Method 2 — validator/liveness fallback
        # Used when the rewards endpoint is not available (Nimbus, older clients).
        # is_live: false → validator did not participate in the epoch.
        # Less precise than rewards (cannot distinguish head/target/source misses)
        # but reliable and universally supported.
        # ------------------------------------------------------------------
        echo "  Method: validator/liveness fallback (rewards endpoint returned HTTP ${ATT_HTTP:-0})"

        LIVE_RESP=$(beacon_post "/eth/v1/validator/liveness/${CHECK_EPOCH}" "$INDICES_JSON")
        LIVE_HTTP=$(beacon_http_code)

        if [ -z "$LIVE_RESP" ] || [ "$LIVE_HTTP" != "200" ]; then
            echo "WARNING: Both attestation endpoints failed."
            echo "         rewards HTTP=${ATT_HTTP:-0}  liveness HTTP=${LIVE_HTTP:-0}"
            echo "         Skipping attestation check for epoch ${CHECK_EPOCH}."
            MISSED_ATTESTERS=""
            OK_ATTESTERS=""
        else
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
        fi
    fi

    # ------------------------------------------------------------------
    # Alert on any missed validators (same logic regardless of method)
    # ------------------------------------------------------------------
    MISSED_COUNT=$(echo "$MISSED_ATTESTERS" | wc -w | tr -d ' ')
    OK_COUNT=$(echo     "$OK_ATTESTERS"     | wc -w | tr -d ' ')
    echo "  Attested: ${OK_COUNT}  |  Missed: ${MISSED_COUNT}"

    # ------------------------------------------------------------------
    # CRITICAL: mass missed attestation alert
    # Fires when >= MASS_MISS_THRESHOLD validators missed the same epoch —
    # signals a cluster-level outage, not a single-node fault.
    # When this fires, individual per-validator alerts are suppressed
    # to avoid flooding with N messages for the same root cause.
    # ------------------------------------------------------------------
    MASS_MISS_FIRED=false
    if [ "${MISSED_COUNT:-0}" -ge "${MASS_MISS_THRESHOLD:-10}" ]; then
        MISS_PCT=$(( ACTIVE_COUNT > 0 ? MISSED_COUNT * 100 / ACTIVE_COUNT : 0 ))
        lock_alert "vd-mass-miss" "$(node_label)
🚨 <b>Mass Missed Attestations</b>

Epoch     : <b>${CHECK_EPOCH}</b>
Missed    : <b>${MISSED_COUNT} / ${ACTIVE_COUNT}</b> validators (${MISS_PCT}%)
Threshold : ${MASS_MISS_THRESHOLD:-10} validators

This indicates a cluster-level issue, not a single-validator fault.

Possible causes:
• Beacon node down or not synced during this epoch
• Charon not reaching DVT signing quorum
• Network / Tailscale outage affecting multiple nodes

Check:
• Charon    : <code>sudo journalctl -u ${CHARON_SERVICE:-charon} -n 50</code>
• Validator : <code>sudo journalctl -u ${VALIDATOR_SERVICE:-validator} -n 50</code>" "critical"
        MASS_MISS_FIRED=true
    else
        clear_lock_alert "vd-mass-miss" "$(node_label)
✅ <b>Resolved: Mass Missed Attestations</b>

The cluster is attesting normally again.

Epoch  : <b>${CHECK_EPOCH}</b>
Missed : ${MISSED_COUNT} / ${ACTIVE_COUNT} validators (below threshold of ${MASS_MISS_THRESHOLD:-10})" "critical"
    fi

    # Individual per-validator alerts — suppressed when mass-miss already fired,
    # since the critical alert above covers the entire cluster event.
    if [ "$MASS_MISS_FIRED" = "false" ]; then
        for IDX in $MISSED_ATTESTERS; do
            LABEL=$(get_label "$IDX")
            LOCK_KEY="vd-att-${IDX}-${CHECK_EPOCH}"
            lock_alert "$LOCK_KEY" "$(node_label)
❌ <b>Missed Attestation</b>

Validator : <code>${IDX}</code> (<code>${LABEL}</code>)
Epoch     : <b>${CHECK_EPOCH}</b>
Explorer  : https://beaconcha.in/validator/${IDX}

The validator did not participate in duties during this epoch —
its attestation was not included on-chain.

Possible causes:
• Validator client offline or crashed during this epoch
• Beacon node was not synced or unreachable
• Network connectivity issue (P2P port blocked)

Check: <code>sudo journalctl -u ${VALIDATOR_SERVICE:-validator} -n 50</code>" "info"
        done
    fi

    for IDX in $OK_ATTESTERS; do
        clear_lock "vd-att-${IDX}-${CHECK_EPOCH}"
    done

    # ------------------------------------------------------------------
    # Head-miss rolling rate (Method 1 only — rewards endpoint required)
    #
    # Tracks validators that attested correctly (source + target > 0) but
    # cast a wrong or late head vote (head ≤ 0). These are performance
    # misses, not full misses — they reduce rewards slightly but do not
    # appear as full missed attestations.
    #
    # A rolling state file accumulates per-epoch data over the window.
    # Epochs that had full misses are excluded from the rate so a cluster
    # outage does not inflate the head-miss baseline.
    #
    # Alert fires when the rolling rate ≥ HEAD_MISS_RATE_PCT and at least
    # 2 clean epochs have been collected (avoids noise on first run).
    # Lock clears automatically when the rate recovers below threshold.
    # ------------------------------------------------------------------
    if [ "$ATT_HTTP" = "200" ] && [ "$MASS_MISS_FIRED" = "false" ]; then
        HEAD_MISS_COUNT=$(echo "${HEAD_MISSED_ATTESTERS}" | wc -w | tr -d ' ')
        HEAD_MISS_STATE="${INDEX_CACHE%/*}/head-miss-rate.json"
        _HM_NOW=$(date +%s)
        _HM_WINDOW=$(( ${HEAD_MISS_WINDOW_HOURS:-1} * 3600 ))

        HEAD_RATE_DATA=$(python3 -I -c "
import json, sys

state_file = sys.argv[1]
now        = int(sys.argv[2])
window     = int(sys.argv[3])
epoch      = int(sys.argv[4])
head_miss  = int(sys.argv[5])
active     = int(sys.argv[6])
full_miss  = int(sys.argv[7])

try:
    with open(state_file) as f:
        state = json.load(f)
except Exception:
    state = {'epochs': []}

state['epochs'].append({
    'epoch': epoch, 'ts': now,
    'head_missed': head_miss, 'active': active, 'full_missed': full_miss
})

# Prune old entries; deduplicate by epoch (keep last entry per epoch)
state['epochs'] = [e for e in state['epochs'] if now - e['ts'] <= window]
seen = {}
for e in state['epochs']:
    seen[e['epoch']] = e
state['epochs'] = sorted(seen.values(), key=lambda e: e['epoch'])

try:
    with open(state_file, 'w') as f:
        json.dump(state, f)
except Exception as err:
    print(f'SAVE_ERR:{err}', file=sys.stderr)

# Rate: skip epochs with full misses (cluster outage distorts baseline)
clean     = [e for e in state['epochs'] if e['full_missed'] == 0]
total_hm  = sum(e['head_missed'] for e in clean)
total_att = sum(e['active']      for e in clean)
n_epochs  = len(clean)
rate = (total_hm / total_att * 100) if total_att > 0 else 0.0

print(f'RATE:{rate:.3f}')
print(f'EPOCHS:{n_epochs}')
print(f'TOTAL_HM:{total_hm}')
print(f'TOTAL_ATT:{total_att}')
" "$HEAD_MISS_STATE" "$_HM_NOW" "$_HM_WINDOW" \
            "$CHECK_EPOCH" "${HEAD_MISS_COUNT:-0}" \
            "$ACTIVE_COUNT" "${MISSED_COUNT:-0}" 2>/dev/null)

        ROLLING_RATE=$(    echo "$HEAD_RATE_DATA" | grep '^RATE:'      | cut -d: -f2)
        ROLLING_EPOCHS=$(  echo "$HEAD_RATE_DATA" | grep '^EPOCHS:'    | cut -d: -f2)
        ROLLING_TOTAL_HM=$(echo "$HEAD_RATE_DATA" | grep '^TOTAL_HM:'  | cut -d: -f2)
        ROLLING_TOTAL_ATT=$(echo "$HEAD_RATE_DATA" | grep '^TOTAL_ATT:' | cut -d: -f2)

        echo "  Head-only misses: ${HEAD_MISS_COUNT} | Rolling rate (${ROLLING_EPOCHS:-0} clean epochs): ${ROLLING_RATE:-0}%"

        # Float comparison via Python (bash arithmetic is integers only)
        RATE_EXCEEDED=$(python3 -c "
import sys
try:
    rate = float(sys.argv[1])
    thr  = float(sys.argv[2])
    n    = int(sys.argv[3])
    # Require at least 2 clean epochs to avoid false positives on first run
    print('yes' if rate >= thr and n >= 2 else 'no')
except:
    print('no')
" "${ROLLING_RATE:-0}" "${HEAD_MISS_RATE_PCT:-1.0}" "${ROLLING_EPOCHS:-0}")

        if [ "$RATE_EXCEEDED" = "yes" ]; then
            lock_alert "vd-head-rate" "$(node_label)
📉 <b>Degraded Attestation Performance</b>

Head-miss rate : <b>${ROLLING_RATE}%</b>  (threshold: ${HEAD_MISS_RATE_PCT:-1.0}%)
Window         : ${HEAD_MISS_WINDOW_HOURS:-1}h (${ROLLING_EPOCHS} epochs)
Head misses    : ${ROLLING_TOTAL_HM} / ${ROLLING_TOTAL_ATT} attestations

Validators attested correctly (source + target) but cast a wrong or late
head vote. Rewards are slightly reduced — this is a performance issue,
not a full attestation miss.

Typical causes in a DVT cluster:
• A Charon peer with elevated latency causing late head delivery
• Beacon node fork-choice delay (head divergence across nodes)
• Clock skew on one or more Obol nodes

Check:
• Peer latency in control-health alerts
• Charon logs  : <code>sudo journalctl -u charon -n 50</code>
• Beacon logs  : <code>sudo journalctl -u ${CL_SERVICE:-beacon} -n 30</code>" "info"
        else
            clear_lock "vd-head-rate"
        fi
    fi
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
                clear_lock "vd-proposal-${IDX}-${SLOT}"
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
• Validator on explorer: https://beaconcha.in/validator/${IDX}" "critical"
            fi
        done <<< "$OUR_DUTIES"
    done
fi

echo ""
echo "=== Done — $(date) ==="