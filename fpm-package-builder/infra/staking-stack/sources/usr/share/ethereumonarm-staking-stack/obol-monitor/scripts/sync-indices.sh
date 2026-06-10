#!/bin/bash
# =============================================================================
# sync-indices.sh — Extract full validator public keys and resolve them to
# validator indices via the local Beacon API.
#
# Supports two cluster types:
#   - Group cluster (Obol DKG): reads full pubkeys from cluster-lock.json
#   - Solo cluster (single operator): reads pubkeys from EIP-2335 keystore files
#
# Writes a JSON cache file:
#   { "0xpubkey": "index", ... }
#
# Run manually after adding or removing validators:
#   bash sync-indices.sh
#
# Also run from cron daily to keep the cache fresh (new activations).
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

echo "=== Validator Index Sync — $(date) ==="
echo ""

# =============================================================================
# STEP 1 — Extract full validator public keys.
#
# Two sources depending on cluster type:
#
#   A) GROUP CLUSTER (Obol DKG with multiple operators):
#      Keystore files in .charon/validator_keys/ contain PARTIAL public keys
#      (key shares from Shamir's Secret Sharing). These are NOT the validator
#      public keys registered on the beacon chain.
#      The FULL validator public keys are in cluster-lock.json under
#      .distributed_validators[].distributed_public_key
#
#   B) SOLO CLUSTER (single operator, own keystore):
#      Keystore files contain the FULL validator public key directly.
#
# Detection: if cluster-lock.json exists alongside the keystores, use it.
# Otherwise fall back to reading pubkeys from keystore files.
# =============================================================================

PUBKEY_TMP=$(mktemp)

# Determine the cluster-lock path (same dir as KEYSTORE_DIR or one level up)
CLUSTER_LOCK=""
for _lock_candidate in     "${KEYSTORE_DIR}/cluster-lock.json"     "$(dirname "${KEYSTORE_DIR}")/cluster-lock.json"     "/home/ethereum/.charon/cluster-lock.json"; do
    if [ -f "$_lock_candidate" ]; then
        CLUSTER_LOCK="$_lock_candidate"
        break
    fi
done

if [ -n "$CLUSTER_LOCK" ]; then
    # ── GROUP CLUSTER ── read distributed_public_key from cluster-lock.json
    echo "Group cluster detected."
    echo "Reading full validator public keys from: ${CLUSTER_LOCK}"
    python3 -c "
import sys, json, re
try:
    with open(sys.argv[1]) as f:
        lock = json.load(f)
    dvs = lock.get('distributed_validators', [])
    for dv in dvs:
        pubkey = str(dv.get('distributed_public_key', '')).strip().lower()
        if not pubkey.startswith('0x'):
            pubkey = '0x' + pubkey
        if re.fullmatch(r'0x[0-9a-f]{96}', pubkey):
            print(pubkey)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" "$CLUSTER_LOCK" > "$PUBKEY_TMP" 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to read cluster-lock.json" >&2
        rm -f "$PUBKEY_TMP"
        exit 1
    fi
else
    # ── SOLO CLUSTER ── read pubkeys from EIP-2335 keystore files
    echo "Solo cluster detected (no cluster-lock.json found)."
    echo "Scanning keystore directory: ${KEYSTORE_DIR}"

    if [ ! -d "$KEYSTORE_DIR" ]; then
        echo "ERROR: KEYSTORE_DIR '${KEYSTORE_DIR}' does not exist." >&2
        rm -f "$PUBKEY_TMP"
        exit 1
    fi

    # NOTE: python3 -c (inline script) is used deliberately instead of a heredoc.
    # A heredoc inside a piped while loop causes a stdin conflict: bash feeds
    # the find|sort pipeline into "read" and the heredoc into python3 at the
    # same time, making python3 silently exit without output.
    while IFS= read -r keyfile; do
        python3 -c "
import sys, json, re
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    pubkey = str(data.get('pubkey', '')).strip().lower()
    if not pubkey.startswith('0x'):
        pubkey = '0x' + pubkey
    if re.fullmatch(r'0x[0-9a-f]{96}', pubkey):
        print(pubkey)
except Exception:
    pass
" "$keyfile" 2>/dev/null
    done < <(find "$KEYSTORE_DIR" -name "*.json" -type f | sort) > "$PUBKEY_TMP"
fi

TOTAL=$(wc -l < "$PUBKEY_TMP" | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
    echo "ERROR: No valid validator public keys found." >&2
    if [ -n "$CLUSTER_LOCK" ]; then
        echo "       Check that cluster-lock.json has distributed_validators entries." >&2
    else
        echo "       Check that ${KEYSTORE_DIR} contains valid EIP-2335 keystore files." >&2
    fi
    rm -f "$PUBKEY_TMP"
    exit 1
fi

echo "Found ${TOTAL} validator(s)."
echo ""

# =============================================================================
# STEP 2 — Query beacon API for validator indices
# Batch all pubkeys in one POST request.
# Endpoint: POST /eth/v1/beacon/states/head/validators
# Body: {"ids": ["0xpubkey1", "0xpubkey2", ...]}   ← object wrapper required by spec
# Response data[].index and data[].validator.pubkey
# =============================================================================
echo "Querying beacon API: ${CL_API}/eth/v1/beacon/states/head/validators"

# Build JSON body: {"ids": [...]}  — the spec requires an object, not a bare array
PUBKEY_JSON=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    keys = [line.strip() for line in f if line.strip()]
print(json.dumps({'ids': keys}))
" "$PUBKEY_TMP")

# Guard: abort if the ids list came out empty (extraction silently failed)
IDS_COUNT=$(echo "$PUBKEY_JSON" | python3 -c "
import sys, json
try:
    print(len(json.load(sys.stdin).get('ids', [])))
except:
    print(0)
")
if [ "${IDS_COUNT:-0}" -eq 0 ]; then
    echo "ERROR: No pubkeys were extracted from keystores." >&2
    echo "       Check that the files in ${KEYSTORE_DIR} are valid EIP-2335 keystores." >&2
    rm -f "$PUBKEY_TMP"
    exit 1
fi

echo "Sending ${IDS_COUNT} pubkey(s) to beacon API..."

RESPONSE=$(beacon_post "/eth/v1/beacon/states/head/validators" "$PUBKEY_JSON")

if [ -z "$RESPONSE" ]; then
    echo "ERROR: Beacon API did not respond. Is the beacon node running at ${CL_API}?" >&2
    echo "       Verify with: curl -s ${CL_API}/eth/v1/node/syncing" >&2
    rm -f "$PUBKEY_TMP"
    exit 1
fi

# Check for API error
API_STATUS=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('code', 'ok'))
except:
    print('parse_error')
" 2>/dev/null)

if [ "$API_STATUS" != "ok" ] && [ "$API_STATUS" != "200" ]; then
    echo "ERROR: Beacon API returned an error (code=${API_STATUS})." >&2
    echo "Response: $(echo "$RESPONSE" | head -c 300)" >&2
    rm -f "$PUBKEY_TMP"
    exit 1
fi

# =============================================================================
# STEP 3 — Parse response and build index cache
# =============================================================================
echo ""
echo "Resolving validator indices..."
echo ""

INDEX_MAP=$(echo "$RESPONSE" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin).get('data', [])
except Exception as e:
    print(f'PARSE_ERROR: {e}', file=sys.stderr)
    sys.exit(1)

result = {}
active = pending = exited = other = 0

for v in data:
    try:
        idx    = str(v['index'])
        pubkey = v['validator']['pubkey'].lower()
        status = v.get('status', 'unknown')
        if not pubkey.startswith('0x'):
            pubkey = '0x' + pubkey
        result[pubkey] = {'index': idx, 'status': status}
        if 'active'   in status: active  += 1
        elif 'pending' in status: pending += 1
        elif 'exited'  in status or 'withdrawal' in status: exited += 1
        else: other += 1
        print(f'  [{idx:>7}]  {status:<25}  {pubkey[:14]}...{pubkey[-8:]}', file=sys.stderr)
    except KeyError:
        continue

print(json.dumps(result), end='')
print('', file=sys.stderr)
print(f'  Active   : {active}', file=sys.stderr)
print(f'  Pending  : {pending}', file=sys.stderr)
print(f'  Exited   : {exited}', file=sys.stderr)
print(f'  Other    : {other}', file=sys.stderr)
print(f'  Total    : {len(result)}', file=sys.stderr)
")

PYRC=$?
if [ "$PYRC" -ne 0 ] || [ -z "$INDEX_MAP" ]; then
    echo "ERROR: Failed to parse beacon API response." >&2
    rm -f "$PUBKEY_TMP"
    exit 1
fi

# =============================================================================
# STEP 4 — Write cache file
# =============================================================================
mkdir -p "$(dirname "$INDEX_CACHE")"
echo "$INDEX_MAP" > "$INDEX_CACHE"
chown -R ethereum:ethereum "$(dirname "$INDEX_CACHE")" 2>/dev/null || true

echo ""
echo "✅ Index cache written to: ${INDEX_CACHE}"
echo ""

# Warn about any pubkeys that were not resolved (not yet on-chain / pending deposit)
UNRESOLVED=$(python3 -c "
import json
with open('$PUBKEY_TMP') as f:
    keys_file = {line.strip().lower() for line in f if line.strip()}
with open('$INDEX_CACHE') as f:
    cache = json.load(f)
for k in sorted(keys_file - set(cache.keys())):
    print(f'  {k[:14]}...{k[-8:]}')
")

if [ -n "$UNRESOLVED" ]; then
    echo "⚠️  The following pubkeys were NOT resolved by the beacon API:"
    echo "   (validators may still be in deposit queue or not yet activated)"
    echo "$UNRESOLVED"
    echo ""
fi

rm -f "$PUBKEY_TMP"
echo "Sync complete at $(date)."
