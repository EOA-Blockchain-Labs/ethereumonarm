---
name: eoa-node
description: >
  Manage an Ethereum full node or archive node on this ARM64 board running
  Ethereum on ARM. Start, stop, restart, check status, get logs, update
  clients, check sync status, or switch client combinations. Use when asked
  to run, start, stop, restart, fix, update or check an Ethereum node,
  consensus client, execution client, or MEV Boost.
version: 1.0.0
---

# EOA Node Management

## Before Any Action

1. Run `scripts/running-clients.sh` to know current state.
2. Load `references/execution-clients.md` and `references/consensus-clients.md`
   to resolve the exact systemd service name and APT package name for any
   client the user mentions. Always use these files as the source of truth
   for service names — never guess them.

---

## Service Name Resolution

Before starting, stopping, restarting, or checking any client, resolve
the correct systemd service name using these rules:

**Execution clients:**
- Mainnet  → `<client>`              e.g. `geth`
- Hoodi    → `<client>-hoodi`        e.g. `geth-hoodi`
- Sepolia  → `<client>-sepolia`      e.g. `geth-sepolia`

**Archive node (mainnet only):**
- Erigon archive → `erigon-archive`

**Consensus clients:**
- Mainnet, no MEV   → `<client>-beacon`              e.g. `lighthouse-beacon`
- Mainnet, MEV      → `<client>-beacon-mev`          e.g. `lighthouse-beacon-mev`
- Hoodi, no MEV     → `<client>-beacon-hoodi`        e.g. `lighthouse-beacon-hoodi`
- Hoodi, MEV        → `<client>-beacon-hoodi-mev`    e.g. `lighthouse-beacon-hoodi-mev`
- Sepolia, no MEV   → `<client>-beacon-sepolia`      e.g. `lighthouse-beacon-sepolia`
- Sepolia, MEV      → `<client>-beacon-sepolia-mev`  e.g. `lighthouse-beacon-sepolia-mev`

**MEV Boost services:**
- Mainnet  → `mev-boost`
- Hoodi    → `mev-boost-hoodi`
- Sepolia  → `mev-boost-sepolia`

**MEV Boost rule:** MEV Boost and -mev consensus variants are ONLY for
users who are staking ETH as validators. Never use them for full nodes
or archive nodes. If the user has not explicitly confirmed they are
staking, ask before using any MEV-related service.

If the user does not specify a network, default to mainnet.
If the user does not specify MEV, default to no MEV.
Always confirm the resolved service name with the user before executing
any start, stop or restart command.

---

## MEV Boost

For full details read `references/mev-boost.md` before taking any
action involving mev-boost services.

**Rule:** Only use MEV Boost if the user has explicitly confirmed they
are setting up a validator to stake ETH. For full nodes and archive
nodes always use the standard non-MEV service names. If unsure, ask.

**Start order when MEV Boost is involved:**

    sudo systemctl start <MEV_BOOST_SERVICE>
    sleep 5
    sudo systemctl start <CLIENT>-beacon-mev
    sleep 10
    sudo systemctl start <EXECUTION_SERVICE>

**Stop order with MEV Boost:**

    sudo systemctl stop <EXECUTION_SERVICE>
    sudo systemctl stop <CLIENT>-beacon-mev
    sudo systemctl stop <MEV_BOOST_SERVICE>

**Status and logs:**

    sudo systemctl status mev-boost
    sudo journalctl -u mev-boost -n 30

---

## Archive Node

An archive node stores the complete historical state of Ethereum —
every account balance, every contract storage value, at every block
since genesis. This makes it possible to query the state of the chain
at any point in history, which is essential for blockchain explorers,
analytics tools, and dApps that need deep historical data. A full node
only keeps recent state and cannot answer historical queries.

**Before starting an archive node:**

- Explain briefly to the user what an archive node is and what it is
  used for (see above)
- Warn the user that archive nodes require at least 4 TB of free disk
  space on /home/ethereum
- Check available disk space before proceeding:

        df -h /home/ethereum

- If free space is less than 4 TB, warn the user and do not proceed
  until they confirm they want to continue anyway
- Erigon is the only supported archive client on Ethereum on ARM due
  to its highly efficient storage format
- The archive node service name is `erigon-archive` — always use this,
  never plain `erigon`, when the user asks for an archive node
- Archive nodes are mainnet only — there is no archive service for
  testnets

---

## Pre-Start Resource Check

ALWAYS run this check before starting any node, whether the user asked
for automatic, manual, or archive. Never skip it.

### Step 1 — Check available disk space

    df -h /home/ethereum

Minimum free space required:
- Full node: 1.7 TB
- Archive node: 4 TB

If free space is sufficient, proceed to Start a Full Node or Archive Node.
If free space is insufficient, do NOT proceed. Go to Step 2.

### Step 2 — Search for old client data

If disk space is insufficient, check for leftover client databases
from previous runs. Read `references/client-data.md` to resolve the
correct database path for every client, then check each one:

    du -sh /home/ethereum/.ethereum/geth 2>/dev/null
    du -sh /home/ethereum/.nethermind/nethermind_db 2>/dev/null
    du -sh /home/ethereum/.erigon 2>/dev/null
    du -sh /home/ethereum/.besu/database 2>/dev/null
    du -sh /home/ethereum/.reth 2>/dev/null
    du -sh /home/ethereum/.lighthouse/mainnet/beacon 2>/dev/null
    du -sh /home/ethereum/.prysm-beacon/beaconchaindata 2>/dev/null
    du -sh /home/ethereum/.nimbus-beacon/db 2>/dev/null
    du -sh /home/ethereum/.teku/beacon 2>/dev/null
    du -sh /home/ethereum/.lodestar-beacon/chain-db 2>/dev/null
    du -sh /home/ethereum/.grandine-beacon/mainnet/beacon 2>/dev/null

Also check testnet paths for any clients that have hoodi or sepolia
data using the paths in `references/client-data.md`.

### Step 3 — Report findings to user

List every client database found with its size. Example:

    Found old client data:
    • Geth (mainnet): 420 GB
    • Lighthouse (mainnet): 120 GB
    • Nethermind (mainnet): 380 GB

Then tell the user:
- How much space is currently free
- How much space is needed
- Which old databases could be deleted to free enough space
- Ask the user which ones they want to delete

Never delete anything without explicit user confirmation.

### Step 4 — Delete confirmed databases

For each database the user confirms, delete only the database path —
not the entire client home directory:

    rm -rf <database path>

After deletion re-run `df -h /home/ethereum` and confirm whether
enough space has been freed. If still not enough, report back and ask
the user how to proceed.

Only proceed to start the node once sufficient disk space is confirmed.

---

## Start a Full Node or Archive Node

A node requires exactly 1 consensus client + 1 execution client.

**If the user does not specify clients**, randomly pick one from each list:
- Consensus: lighthouse, prysm, nimbus, teku, lodestar, grandine
- Execution: geth, nethermind, erigon, besu, reth
- For archive nodes use `erigon-archive` as the execution service —
  not `erigon`. Always follow the Archive Node section above before
  proceeding.

**Steps:**

1. Run the Pre-Start Resource Check above. Do not proceed until
   sufficient disk space is confirmed.

2. Run `scripts/running-clients.sh` — if a pair is already running,
   inform the user and ask if they want to stop it first. Never stop
   a running client without explicit user confirmation.

3. Resolve the correct service names using the Service Name Resolution
   rules above for the chosen network (default: mainnet).

4. Tell the user exactly which services you are about to start and
   wait for confirmation before proceeding:
   "I'm going to start <CONSENSUS_SERVICE> and <EXECUTION_SERVICE>.
   Shall I proceed?"

5. Stop any conflicting running services after user confirmation:

        sudo systemctl stop <EXECUTION_SERVICE>
        sudo systemctl stop <CONSENSUS_SERVICE>

6. **Special case — Nimbus only**: before starting the nimbus beacon
   service, run the appropriate trustedNodeSync command from
   `references/consensus-clients.md` for the target network.
   Wait for completion before proceeding.

7. Start consensus client first, then execution client:

        sudo systemctl start <CONSENSUS_SERVICE>
        sleep 10
        sudo systemctl start <EXECUTION_SERVICE>

8. Verify both are active:

        sudo systemctl is-active <CONSENSUS_SERVICE>
        sudo systemctl is-active <EXECUTION_SERVICE>

9. Run both status check scripts and report to user:

        bash /home/ethereum/.openclaw/workspace/skills/eoa-node/scripts/synced-clients.sh
        bash
