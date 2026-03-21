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

1. Run `scripts/node-status.sh` to know current state.
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

2. Run `scripts/node-status.sh` — if a pair is already running,
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

9. Run node-status.sh and health-check.sh and report to user:

        bash /home/ethereum/.openclaw/workspace/skills/eoa-node/scripts/node-status.sh
        bash /home/ethereum/.openclaw/workspace/skills/eoa-node/scripts/health-check.sh

---

## Stop a Node

Always ask the user for confirmation before stopping any service.
Tell the user exactly which services you are about to stop and wait
for confirmation:
"I'm going to stop <EXECUTION_SERVICE> and <CONSENSUS_SERVICE>.
Shall I proceed?"

After confirmation, stop execution first, then consensus:

    sudo systemctl stop <EXECUTION_SERVICE>
    sudo systemctl stop <CONSENSUS_SERVICE>

If MEV Boost is running, stop it last:

    sudo systemctl stop <MEV_BOOST_SERVICE>

---

## Restart a Client

Always ask the user for confirmation before restarting any service.
Tell the user exactly which service you are about to restart and wait
for confirmation.

Resolve the correct service name first, then:

    sudo systemctl restart <CONSENSUS_SERVICE>

or

    sudo systemctl restart <EXECUTION_SERVICE>

---

## Check Service Status

Resolve the correct service name first, then:

    sudo systemctl status <EXECUTION_SERVICE>
    sudo systemctl status <CONSENSUS_SERVICE>
    sudo systemctl status <MEV_BOOST_SERVICE>

The status output includes:
- Whether the service is active, inactive, or failed
- How long the service has been running (uptime)
- The last few log lines
- Whether the service is enabled (starts on boot) or disabled

Report all of this to the user in a clear human-readable summary.

---

## Enable or Disable a Service (start on boot)

By default services on Ethereum on ARM are not enabled — they do not
start automatically after a reboot. The user must explicitly ask to
enable a service.

Enable a service to start automatically on boot:

    sudo systemctl enable <SERVICE_NAME>

Disable a service from starting automatically on boot:

    sudo systemctl disable <SERVICE_NAME>

**Important:** enabling a service does not start it immediately, and
disabling does not stop it. These commands only affect boot behaviour.
If the user wants to both enable AND start, run both commands:

    sudo systemctl enable <SERVICE_NAME>
    sudo systemctl start <SERVICE_NAME>

Always confirm with the user which services they want enabled. If the
user asks to enable the node, enable both the execution and consensus
client services for the currently running pair.

Never enable MEV Boost services unless the user has explicitly
confirmed they are staking ETH as a validator.

---

## Get Logs

Default: last 30 lines. User can request more.
Resolve the correct service name first, then:

    sudo journalctl -u <CONSENSUS_SERVICE> -n 30
    sudo journalctl -u <EXECUTION_SERVICE> -n 30
    sudo journalctl -u <MEV_BOOST_SERVICE> -n 30

For live streaming:

    sudo journalctl -u <CONSENSUS_SERVICE> -f
    sudo journalctl -u <EXECUTION_SERVICE> -f

---

## Update a Client

Ethereum on ARM provides a custom APT repository.
Look up the APT package name in the reference files before running.
The APT package name is the same regardless of network or MEV variant.

Update a single client:

    sudo apt-get update
    sudo apt-get install <PACKAGE_NAME>

**Important: never restart a service after updating.** On Ethereum on
ARM, systemd is configured to automatically restart running services
when their package is updated. If the agent manually restarts a service
after an update it may restart clients that were intentionally stopped,
which can cause conflicts or unexpected syncing on multiple networks.

If the user asks whether the update was applied, check the running
service status instead:

    sudo systemctl status <SERVICE_NAME>

Update all clients at once:

    sudo apt-get update && sudo apt-get install \
      geth nethermind erigon besu reth \
      lighthouse prysm nimbus teku lodestar grandine \
      mev-boost

---

## Check Node Status and Sync

When the user asks about the node in any form — "how is the node?",
"node status", "is it synced?", "what is the node doing?", "check the
node", "clients report", "sync report", "clients status", "sync status",
or any similar question — ALWAYS run both scripts regardless of whether
the node is synced or not:

    bash /home/ethereum/.openclaw/workspace/skills/eoa-node/scripts/node-status.sh
    bash /home/ethereum/.openclaw/workspace/skills/eoa-node/scripts/health-check.sh

Never skip either script based on assumptions about the node state.
Always run both and report the full picture to the user.

The node-status.sh script reports:
- Which clients are running and their service names
- Network and MEV Boost status
- Overall STATUS (RUNNING, STOPPED, INCOMPLETE)
- If RUNNING: whether EL and CL are synced or syncing
- If syncing: how far behind and current block/slot
- EL peer count

The health-check.sh script reports:
- CPU load, RAM, swap, disk usage with warnings
- All active and failed service states
- Recent error log entries (last 15 min)
- System uptime

Read the full output of both scripts and give the user a clear
human-readable summary. Highlight any WARN lines. If there are no
issues, tell the user everything looks healthy.

---

## Switch Client Pair

If the user wants to change the running client pair:

1. Run `scripts/node-status.sh` to identify currently running
   services.

2. Check disk usage of the old client database using
   `references/client-data.md` to resolve the correct database path:

        du -sh <old client database path>

3. Check free disk space:

        df -h /home/ethereum

4. Before stopping the current pair, ask the user explicitly:
   "Would you like me to delete the old client data after stopping?
   Leftover data from [old client] may consume significant disk space
   and could prevent [new client] from syncing properly."
   Wait for confirmation before proceeding. Note the answer and act
   on it in Step 7.

5. Tell the user exactly which services you are about to stop and
   wait for confirmation before stopping anything:
   "I'm going to stop <EXECUTION_SERVICE> and <CONSENSUS_SERVICE>.
   Shall I proceed?"

6. Stop the current pair following the Stop a Node procedure above.

7. If the user confirmed deletion, remove only the database path of
   the old client (not the entire home directory unless explicitly
   asked):

        rm -rf <old client database path>

8. Resolve the new service names using the Service Name Resolution
   rules.

9. Start the new pair following the Start a Full Node procedure above.

10. Run both scripts and report to user:

        bash /home/ethereum/.openclaw/workspace/skills/eoa-node/scripts/node-status.sh
        bash /home/ethereum/.openclaw/workspace/skills/eoa-node/scripts/health-check.sh

Always take the network into account — use the correct database path
for the network being switched, never delete data for a different
network.
