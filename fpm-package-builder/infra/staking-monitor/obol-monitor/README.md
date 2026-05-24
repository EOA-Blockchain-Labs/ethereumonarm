# obol-monitor

Health monitoring and Telegram alerting for an Obol DVT Ethereum cluster
running on **Ethereum on ARM** (Rock 5B/5B+, Orange Pi 5 Plus and NanoPC-T6).

---

## Architecture

```
obol-node-1 ──┐
obol-node-2 ──┤── VPN ──── control-node-1 (active)  ──── Telegram bot
obol-node-3 ──┘       └─── control-node-2 (failover)
```

### Obol nodes

Each Obol node monitors itself and sends Telegram alerts directly. It checks
its own services, sync status, peer counts, Charon DVT connectivity, and
system resources (swap, disk, CPU temperature). It also checks daily for
new package versions of its running clients in the Ethereum on ARM APT repository.

### Control nodes

Control nodes serve two purposes:

1. **Cluster monitoring** — check the health of all Obol nodes every 5 minutes:
   Charon reachability, DVT peer connections, peer latency, validator client
   status, and local system resources. They also run the validator duties monitor
   every 7 minutes, querying the local beacon API to detect missed attestations
   and missed block proposals per validator, with per-validator Telegram alerts
   including a direct link to the validator's beaconcha.in page.

2. **Staking failover** — both control nodes are **staking backup nodes** — fully
   synced Ethereum full nodes running an Execution client, Consensus client, MEV
   Boost, and a standard (non-DVT) validator client. They are kept in sync and
   ready to take over all Obol cluster validators immediately if the DVT cluster
   fails.

Under normal operation the backup validator client on both control nodes is
**intentionally stopped**. The monitoring system is aware of this — no alert is
sent for a stopped validator unless the Obol cluster has simultaneously lost
enough nodes to break the DVT threshold. When that condition is detected, an
alert fires specifically if the backup validator is also down, prompting the
operator to start it manually.

Each control node also monitors itself AND queries all Obol nodes remotely over
VPN using Charon's HTTP API on port 3620. No SSH required — all remote checks
are done via HTTP.

**Active control node** (`control`) always runs its full check cycle every
5 minutes. It also monitors the failover node and alerts if it goes down.

**Failover control node** (`control-failover`) is passive by default. On every
cron cycle it probes the active node using three checks in sequence:

1. **Execution Layer API query** — sends `eth_getBlockByNumber` to the active
   node's EL via its nginx proxy (port 80). If a valid response comes back, the
   active node is healthy and the failover skips its cycle silently.
2. **Charon relay query** (port 3640) — if the EL fails, the relay is queried as
   a second liveness check. Any HTTP response means the node is up but the EL
   may be temporarily behind or restarting — the failover defers silently.
3. **VPN ping** — only reached if both EL and relay fail. A 10-second delay is
   applied before the ping to absorb transient VPN re-keying windows. If the ping
   responds, both services crashed but the node is up — alert sent, failover
   defers. If the ping also fails, the active node is considered down and the
   failover takes over immediately.

**All peer alerts require two consecutive failing cycles** to confirm the
condition is genuine, absorbing single-cycle transients (VPN re-keying, EL
momentarily behind). The first failure is written to a state file but produces
no alert or action. Only a second consecutive failure triggers an alert or
failover takeover.

### Alert locks and recovery notifications

All alerts use per-condition lock files to prevent duplicate messages. Once an
alert fires it will not repeat for 24 hours (configurable via `LOCK_EXPIRY`).

**Recovery alerts** — when a condition resolves, a recovery notification is
sent automatically. Examples: service restored, Charon peers recovered, sync
resolved, attestations back to normal. Recovery alerts are sent once per
condition and only if an alert was previously fired for that condition.

**Status report on incident** — when an Obol node goes down or the cluster
crosses the DVT failure threshold, a full cluster status report is sent
immediately. A second status report is sent when the cluster recovers. The
report is not repeated while the condition persists.

For missed attestations, locks are **per validator per epoch** — two validators
missing the same epoch produce two independent alerts. If `MASS_MISS_THRESHOLD`
(default 10) or more validators miss the same epoch, individual alerts are
suppressed and a single global cluster/ISP outage alert is sent instead. The
mass-miss lock uses a **6-hour expiry** and clears (with recovery notification)
only when all validators are attesting correctly again.

---

## Files

```
obol-monitor/
├── install.sh                        # Installer — run this first
├── README.md
├── conf/
│   ├── obol-node.env                 # Config template for Obol nodes
│   └── control-node.env              # Config template for control/failover nodes
├── lib/
│   └── common.sh                     # Shared helpers (Telegram, locks, beacon API)
├── scripts/
│   ├── obol-health.sh                # Obol node: health check (every 5 min)
│   ├── obol-status.sh                # Obol node: weekly status report
│   ├── control-health.sh             # Control node: cluster + local health check
│   ├── control-status.sh             # Control node: full cluster status report
│   ├── sync-indices.sh               # Build validator index cache from keystores
│   ├── validator-duties.sh           # Missed attestation + proposal checker
│   ├── check-updates.sh              # APT package update alert (daily 09:00)
│   └── diagnose-connectivity.sh      # Inter-node connectivity diagnostic tool
└── crontabs/
    ├── obol-crontab                  # Crontab for Obol nodes
    └── control-crontab               # Crontab for control/failover nodes
```

After installation everything lives under:
```
/home/ethereum/.obol-monitor/
├── conf/node.env
├── lib/common.sh
├── scripts/
├── cache/                            # Validator index cache
├── locks/                            # Alert deduplication lock files
└── logs/                             # Cron output logs
```

---

## Installation

Copy the `obol-monitor` folder to the target node and run the installer.
It detects running Ethereum clients automatically and asks for all required
values interactively — no manual config file editing needed.

### On each Obol node

```bash
bash install.sh obol
```

The installer will ask for:
- Node number and name
- Telegram bot token and chat ID
- VPN IP (optional)
- Cluster size
- Whether you are using Lido CSM

---

### On the active control node

```bash
bash install.sh control
```

The installer will ask for:
- Node number and name
- Telegram bot token and chat ID
- Cluster size
- VPN IP of each Obol node and labels
- Failover control node VPN IP (to monitor it)
- Keystore directory for validator duty monitoring

---

### On the failover control node

```bash
bash install.sh control-failover
```

The installer will ask for:
- Node number and name
- Telegram bot token and chat ID
- Cluster size
- VPN IP of each Obol node and labels
- **Primary control node VPN IP** (required — used to decide when to take over)
- Keystore directory for validator duty monitoring

The failover node is **passive by default**. It defers all checks to the active
node as long as the active node responds to the EL API or relay probe. Both the
validator duties check and all health checks are skipped while the primary is up.

---

### Install crontab (all node types, after setup)

```bash
bash install.sh obol crontab
bash install.sh control crontab
bash install.sh control-failover crontab
```

---

### Manual test before enabling cron

```bash
# Obol node
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/obol-health.sh
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/obol-status.sh

# Control / failover node
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/control-health.sh
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/control-status.sh
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/validator-duties.sh

# Package update check (any node)
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/check-updates.sh
```

---

## Alerts sent

### Obol node (`obol-health.sh`, every 5 min)

| Condition | Alert | Recovery |
|---|---|---|
| Any service down | 🚨 Service DOWN | ✅ Service RESTORED |
| EL not synced | ⚠️ EL not synced | ✅ Resolved |
| CL not synced | ⚠️ CL not synced | ✅ Resolved |
| EL peers < `EL_PEERS_MIN` | ⚠️ EL low peers | ✅ Restored |
| CL peers < `CL_PEERS_MIN` | ⚠️ CL low peers | ✅ Restored |
| Charon DVT peers < min | 🚨 Charon low peers | ✅ Restored |
| Charon latency > threshold | ⚠️ High latency | ✅ Resolved |
| Swap > `SWAP_ALERT_GB` | ⚠️ High swap | ✅ Resolved |
| /home/ethereum low disk | 🚨 Low disk | ✅ Restored |
| / used > `DISK_ROOT_ALERT_PCT` | ⚠️ Low root disk | ✅ Resolved |
| CPU temp > threshold | 🌡 High CPU temp | ✅ Normalized |

### Package update check (`check-updates.sh`, daily 09:00)

Checks only clients actually **installed and running** on the node, identified
from `EL_CLIENT` and `CL_CLIENT` in `node.env`.

| Condition | Alert |
|---|---|
| New EL client version in APT repo | 📦 Execution client update available |
| New CL client version in APT repo | 📦 Consensus client update available |
| New `mev-boost` version in APT repo | 📦 MEV-Boost update available |
| New `dvt-obol` version in APT repo (obol nodes only) | 📦 Charon DVT update available |

Lock key is `pkg-update-<package>-<version>` — fires once per available version
and clears naturally when the package is installed (new candidate version = new
lock key).

### Control node (`control-health.sh`, every 5 min)

All Obol node conditions checked remotely via HTTP, plus:

| Condition | Alert | Recovery |
|---|---|---|
| Obol node unreachable (livez = 000) | 🚨 Node UNREACHABLE | ✅ Back online |
| Charon readyz — VC not connected | 🚨 VC not connected | ✅ VC connected |
| Charon readyz — beacon node down | 🚨 Beacon DOWN | ✅ Charon ready |
| Charon readyz — beacon syncing | ⚠️ Beacon syncing | ✅ Charon ready |
| Charon readyz — insufficient peers | ⚠️ Insufficient peers | ✅ Charon ready |
| `core_scheduler_validators_active` = 0 | 🚨 VC inactive | ✅ VC reconnected |
| DVT threshold broken | 🚨 Cluster FAILED + status report | ✅ Cluster restored + report |
| Cluster failed + backup VC down | 🚨 NO VALIDATOR COVERAGE | — |
| Failover EL+relay both down (ping ok, 2 cycles) | ⚠️ Failover services down | — |
| Failover node unreachable (2 cycles) | 🚨 Failover node DOWN | — |
| Primary EL+relay both down (ping ok, 2 cycles) | ⚠️ Primary services down | ✅ Primary restored |
| Primary node unreachable (2 cycles) | 🚨 Primary DOWN → failover takes over | — |
| Local backup services down | 🚨 Service DOWN | ✅ Restored |

**Two-cycle confirmation** — all peer-related alerts (primary down, failover
down, EL+relay down) require two consecutive failing cron cycles (~10 minutes)
before firing. A single transient failure produces no alert.

**Failover node additional behaviour** — when the cluster is detected as failed,
the failover queries its own local beacon node for validator liveness. If
validators are attesting, the primary backup is already covering them and the
failover stays passive. If no validators are attesting, a
🚨 `Cluster FAILED — validators have NO coverage` alert fires.

### Validator duties (`validator-duties.sh`, every 7 min)

| Condition | Alert | Recovery |
|---|---|---|
| Single validator missed attestation | ❌ Missed Attestation | ✅ Attestation restored |
| ≥ `MASS_MISS_THRESHOLD` missed in one epoch | 🚨 Mass Missed Attestations (6h lock) | ✅ All attesting again |
| Missed block proposal | 🚨 Missed Block Proposal | — |
| Successful block proposal | 🎉 Block Proposal SUCCESS | — |

Validator duties run on the **active control node only** — the failover defers
while the primary is reachable.

---

## Alert deduplication

| Alert | Lock key | Expiry |
|---|---|---|
| All standard alerts | per-condition key | 24 h (`LOCK_EXPIRY`) |
| Mass missed attestations | `vd-att-mass-global` | 6 h |
| Package updates | `pkg-update-<pkg>-<version>` | 24 h (auto-clears on install) |
| Cluster status report trigger | `ctrl-status-report` | per incident |

---

## Weekly reports

A full status digest is sent every **Monday at 08:00**:
- `obol-status.sh` on Obol nodes — single node summary
- `control-status.sh` on control nodes — full cluster overview

A status report is also triggered automatically on incident start and recovery.

Run on demand:
```bash
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/obol-status.sh
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/control-status.sh
```

---

## Recommended Charon configuration

Add these flags to `charon run` on all Obol nodes for optimal performance
and safety:

```bash
# Increase beacon API timeout — gives ARM hardware more room than the 2s default
--beacon-node-timeout=4s

# Use local beacon as primary; VPN/fallback beacon only when local is unavailable
--beacon-node-endpoints=http://localhost:5052
--fallback-beacon-node-endpoints=http://<control-node-vpn-ip>:5052

# Verify FFG votes (target/source) match local beacon view before attesting
# Prevents signing on the wrong fork in a chain split scenario
--feature-set-enable=chain_split_halt

# Required when running Nimbus as the validator client
--distributed    # add to nimbus_validator_client flags (not charon)
```

**Why `--beacon-node-timeout=4s`:** the default 2-second timeout is too tight
for ARM hardware under load. The `produceAttestationData(best)` call queries
all configured beacon endpoints and waits for all to respond — on a VPN-connected
fallback endpoint this can exceed 2 seconds on busy slots.

**Why local-only primary endpoint:** when multiple endpoints are in
`--beacon-node-endpoints`, Charon waits for ALL of them for `(best)` strategy
calls, adding VPN latency to every attestation slot. Using
`--fallback-beacon-node-endpoints` instead reserves the remote beacon for
genuine outages only.

---

## Firewall / network requirements

| Port | Protocol | Direction | Purpose |
|---|---|---|---|
| 3620 | TCP | control → obol | Charon HTTP API (livez, readyz, metrics) |
| 3640 | TCP | failover → active control | Charon relay liveness check |
| 80 | TCP | failover → active control | EL API liveness (nginx proxy) |
| 5052 | TCP | localhost / obol → control | CL Beacon API |
| 8545 | TCP | localhost only | EL JSON-RPC |

```bash
# On each Obol node — allow control nodes to reach Charon metrics
sudo ufw allow from <active-control-vpn-ip>   to any port 3620
sudo ufw allow from <failover-control-vpn-ip> to any port 3620

# On control nodes — if exposing beacon API to Obol nodes as fallback
sudo ufw allow from <obol-node-vpn-ip> to any port 5052
```

---

## Thresholds reference

### Obol node

| Variable | Default | Description |
|---|---|---|
| `EL_PEERS_MIN` | 5 | Minimum EL peers |
| `CL_PEERS_MIN` | 10 | Minimum CL peers |
| `CHARON_PEERS_MIN` | cluster_size − 1 | Minimum Charon DVT peers |
| `CHARON_LATENCY_ALERT_MS` | 500 | Max peer avg RTT (ms) |
| `SWAP_ALERT_GB` | 10 | Swap threshold (GB) |
| `DISK_ETH_ALERT_GB` | 150 | Free space threshold (GB) |
| `DISK_ROOT_ALERT_PCT` | 85 | Root disk used % threshold |
| `CPU_TEMP_ALERT_C` | 80 | CPU temperature threshold (°C) |
| `LOCK_EXPIRY` | 86400 | Alert cooldown (s, 24 h) |

### Control / failover node (additional)

| Variable | Default | Description |
|---|---|---|
| `PEER_CHECK_TIMEOUT` | 5 | Seconds per probe (EL, relay, ping) |
| `PEER_RETRY_DELAY` | 10 | Delay before ping after EL+relay fail |
| `PEER_RELAY_PORT` | 3640 | Charon relay port for liveness check |
| `VC_INACTIVE_EPOCHS` | 2 | Epochs without duty before VC alert |
| `MISSED_ATT_THRESHOLD` | 1 | Missed attestations before per-validator alert |
| `MASS_MISS_THRESHOLD` | 10 | Validators missing same epoch for global alert |
| `PROPOSAL_CHECK_EPOCHS` | 3 | Past epochs to check for proposals |

---

## Connectivity diagnostic

Run from either control node to debug inter-node connectivity issues:

```bash
bash /home/ethereum/.obol-monitor/scripts/diagnose-connectivity.sh
bash /home/ethereum/.obol-monitor/scripts/diagnose-connectivity.sh <peer-vpn-ip>
```

Runs 8 checks: network interfaces, routing table, ping, Tailscale direct path,
EL API timing, relay timing, concurrent probe simulation, and WireGuard
interference detection (including custom-named interfaces like `nanopct6`).

---

## Standalone validator duties monitor

For validators outside the Obol cluster (solo staking, Lido CSM on a separate
machine). Located in `staking-monitor/validator-monitor/`.

```bash
cd validator-monitor
bash install.sh
```

Installs to `/home/ethereum/.validator-monitor/`. Checks missed attestations
(`finalized_epoch − 1`, liveness fallback for Nimbus/checkpoint-sync), missed
proposals, and successful proposals. Recovery notifications sent automatically.