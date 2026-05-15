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
system resources (swap, disk, CPU temperature).

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
├── obol-monitor-README.pdf
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
```

---

## Alerts sent

### Obol node (`obol-health.sh`, every 5 min)

| Condition | Alert | Recovery |
|---|---|---|
| Any service down | 🚨 Service DOWN | ✅ Service RESTORED |
| EL not synced | ⚠️ EL not synced | ✅ EL sync resolved |
| CL not synced | ⚠️ CL not synced | ✅ CL sync resolved |
| EL peer count < `EL_PEERS_MIN` | ⚠️ EL low peers | ✅ EL peers restored |
| CL peer count < `CL_PEERS_MIN` | ⚠️ CL low peers | ✅ CL peers restored |
| Charon DVT peers < `CHARON_PEERS_MIN` | 🚨 Charon low peers | ✅ Peers restored |
| Charon peer latency > `CHARON_LATENCY_ALERT_MS` ms | ⚠️ High latency | ✅ Latency resolved |
| Swap > `SWAP_ALERT_GB` GB | ⚠️ High swap | ✅ Swap resolved |
| `/home/ethereum` free < `DISK_ETH_ALERT_GB` GB | 🚨 Low disk | ✅ Disk restored |
| `/` used > `DISK_ROOT_ALERT_PCT` % | ⚠️ Low root disk | ✅ Root disk resolved |
| CPU temp > `CPU_TEMP_ALERT_C` °C | 🌡 High CPU temp | ✅ Temp normalized |

### Control node (`control-health.sh`, every 5 min)

All of the above checked remotely for each Obol node via HTTP, plus:

| Condition | Alert | Recovery |
|---|---|---|
| Obol node unreachable (livez = 000) | 🚨 Node UNREACHABLE | ✅ Node back online |
| Charon readyz 500 — VC not connected | 🚨 VC not connected | ✅ VC connected |
| Charon readyz 500 — beacon node down | 🚨 Beacon node DOWN | ✅ Charon ready |
| Charon readyz 500 — beacon syncing | ⚠️ Beacon syncing | ✅ Charon ready |
| Charon readyz 500 — insufficient peers | ⚠️ Insufficient peers | ✅ Charon ready |
| `core_scheduler_validators_active` = 0 | 🚨 VC inactive | ✅ VC reconnected |
| Charon peer count < minimum | 🚨 Charon low peers | ✅ Peers restored |
| Charon peer latency > threshold | ⚠️ High latency | ✅ Latency resolved |
| DVT threshold broken | 🚨 Cluster FAILED + status report | ✅ Cluster restored + status report |
| Cluster failed AND backup validator not running | 🚨 NO VALIDATOR COVERAGE | — |
| Failover EL + relay both down (ping ok) | ⚠️ Failover services down | — |
| Failover node completely unreachable | 🚨 Failover node DOWN | — |
| Primary EL + relay both down (ping ok) | ⚠️ Primary services down | ✅ Primary restored |
| Local backup services down | 🚨 Service DOWN | ✅ Service RESTORED |

**Failover node additional behaviour** — when the cluster is detected as failed,
the failover queries its own local beacon node for validator liveness. If
validators are attesting despite the cluster being down, the primary backup is
already covering them and the failover stays passive. If no validators are
attesting, a 🚨 `Cluster FAILED — validators have NO coverage` alert fires
recommending the failover operator to start their own backup validator.

### Validator duties (`validator-duties.sh`, every 7 min)

| Condition | Alert | Recovery |
|---|---|---|
| Single validator missed attestation | ❌ Missed Attestation (per validator) | ✅ Attestation restored |
| ≥ `MASS_MISS_THRESHOLD` missed in one epoch | 🚨 Mass Missed Attestations (6h lock) | ✅ Mass issue resolved |
| Validator missed block proposal | 🚨 Missed Block Proposal | — |
| Validator proposed a block | 🎉 Block Proposal SUCCESS | — |

The validator duties check runs on the **active control node only** — the failover
node defers this check to the primary while the primary is reachable.

---

## Alert deduplication

Each alert uses a lock file keyed by condition. Once fired it will not repeat
for `LOCK_EXPIRY` seconds (default 24 h). Some alerts use custom expiry:

| Alert | Lock key | Expiry |
|---|---|---|
| All standard alerts | per-condition key | 24 h (`LOCK_EXPIRY`) |
| Mass missed attestations | `vd-att-mass-global` | 6 h |
| Cluster status report trigger | `ctrl-status-report` | per incident |

---

## Weekly reports

A full status digest is sent every **Monday at 08:00**:
- `obol-status.sh` on Obol nodes — single node summary
- `control-status.sh` on control nodes — full cluster overview including a
  cluster health line (🟢 all nodes up / 🟡 validators missing / 🔴 nodes down)

A status report is also sent automatically when a significant incident starts
and again when it resolves — no need to wait for the weekly report.

Run on demand:
```bash
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/obol-status.sh
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/control-status.sh
```

---

## Firewall / network requirements

| Port | Protocol | Direction | Purpose |
|---|---|---|---|
| 3620 | TCP | control → obol | Charon HTTP API (livez, readyz, metrics) |
| 3640 | TCP | failover → active control | Charon relay liveness check |
| 80 | TCP | failover → active control | EL API liveness check (nginx proxy) |
| 8545 | TCP | localhost only | EL JSON-RPC |
| 5052 | TCP | localhost only | CL Beacon API |

On each Obol node, allow VPN access to port 3620 from both control nodes:

```bash
sudo ufw allow from <active-control-vpn-ip>  to any port 3620
sudo ufw allow from <failover-control-vpn-ip> to any port 3620
```

---

## Thresholds reference

All thresholds are in `node.env` and can be adjusted per node.

### Obol node thresholds

| Variable | Default | Description |
|---|---|---|
| `EL_PEERS_MIN` | 5 | Minimum EL peers before alert |
| `CL_PEERS_MIN` | 10 | Minimum CL peers before alert |
| `CHARON_PEERS_MIN` | cluster_size − 1 | Minimum Charon DVT peers |
| `CHARON_LATENCY_ALERT_MS` | 500 | Max acceptable peer avg RTT (ms) |
| `SWAP_ALERT_GB` | 10 | Swap usage threshold (GB) |
| `DISK_ETH_ALERT_GB` | 150 | Free space threshold on /home/ethereum (GB) |
| `DISK_ROOT_ALERT_PCT` | 85 | Root disk used % threshold |
| `CPU_TEMP_ALERT_C` | 80 | CPU temperature threshold (°C) |
| `LOCK_EXPIRY` | 86400 | Alert cooldown (seconds, default 24 h) |

### Control / failover node thresholds

All Obol node thresholds above, plus:

| Variable | Default | Description |
|---|---|---|
| `CHARON_PEERS_EXPECTED` | cluster_size − 1 | Expected Charon peers per node |
| `PEER_CHECK_TIMEOUT` | 5 | Seconds for each peer probe (EL, relay, ping) |
| `PEER_RETRY_DELAY` | 10 | Seconds to wait before ping after EL+relay fail |
| `PEER_RELAY_PORT` | 3640 | Charon relay port used as secondary liveness probe |
| `VC_INACTIVE_EPOCHS` | 2 | Epochs without duty before VC inactive alert |
| `MISSED_ATT_THRESHOLD` | 1 | Missed attestations before per-validator alert |
| `MASS_MISS_THRESHOLD` | 10 | Validators missing same epoch before global alert |
| `PROPOSAL_CHECK_EPOCHS` | 3 | Past epochs to check for missed proposals |

---

## Connectivity diagnostic

If you experience false alerts due to transient inter-node connectivity
failures, run the diagnostic tool from either control node:

```bash
bash /home/ethereum/.obol-monitor/scripts/diagnose-connectivity.sh
# or with explicit peer IP:
bash /home/ethereum/.obol-monitor/scripts/diagnose-connectivity.sh <peer-vpn-ip>
```

It runs 8 checks: network interfaces, routing table, ping, Tailscale direct
path, EL API response time, relay response time, concurrent probe simulation,
and WireGuard interference detection (including custom-named interfaces). Useful
for diagnosing VPN routing conflicts, WireGuard `AllowedIPs` overlap with the
Tailscale CGNAT range (`100.64.0.0/10`), and DERP relay switches.

---

## Standalone validator duties monitor

If you run validators outside the Obol cluster context (solo staking,
Lido CSM on a separate machine, etc.) the `vm-` scripts provide a
self-contained validator duty monitor that works on any validator node
with a local beacon client.

**Files** (rename by removing the `vm-` prefix when deploying):

| File | Deploy as |
|---|---|
| `vm-install.sh` | `install.sh` |
| `vm-validator-monitor.env` | `conf/validator-monitor.env` |
| `vm-common.sh` | `lib/common.sh` |
| `vm-sync-indices.sh` | `scripts/sync-indices.sh` |
| `vm-validator-duties.sh` | `scripts/validator-duties.sh` |
| `vm-validator-crontab` | `crontabs/validator-crontab` |

**Install:**

```bash
bash install.sh
```

Installs to `/home/ethereum/.validator-monitor/`. The installer asks for your
Telegram credentials, keystore directory, beacon API endpoint, and
validator/beacon service names. It builds the initial validator index cache from
your keystore files automatically.

**What it checks (every 7 min):**
- Missed attestations per validator via `POST /eth/v1/beacon/rewards/attestations/{epoch}`
  using `finalized_epoch − 1` to ensure all late attestations are included.
  Falls back to `/validator/liveness/{epoch}` for clients without historical
  state (Nimbus, Lighthouse checkpoint sync).
- Missed block proposals via `/validator/duties/proposer/{epoch}` +
  `/beacon/headers/{slot}`
- Successful block proposals (🎉 notification)

Alerts include the validator index, shortened pubkey, epoch/slot, and a direct
link to `https://beaconcha.in/validator/{index}`. Recovery notifications are
sent when missed validators return to normal attestation.
