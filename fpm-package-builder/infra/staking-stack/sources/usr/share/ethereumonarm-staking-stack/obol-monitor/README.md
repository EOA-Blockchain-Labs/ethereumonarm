# obol-monitor

Health monitoring and Telegram alerting for an Obol DVT Ethereum cluster
running on **Ethereum on ARM** (ARM64, Rock 5B+).

---

## Architecture

```
obol-node-1 ──┐
obol-node-2 ──┤── Tailscale VPN ──── control-node-1 ──── Telegram bot
obol-node-3 ──┘                 └─── control-node-2
```

Each **Obol node** monitors itself and sends alerts directly.
Each **Control node** monitors itself AND polls all Obol nodes remotely
over Tailscale using Charon's HTTP API on port 3620. No SSH required.

---

## Files

```
obol-monitor/
├── install.sh                   # Installer — run first
├── conf/
│   ├── obol-node.env            # Config template for Obol nodes
│   └── control-node.env         # Config template for control nodes
├── lib/
│   └── common.sh                # Shared helpers (Telegram, locks, beacon API)
├── scripts/
│   ├── obol-health.sh           # Obol node cron health check
│   ├── obol-status.sh           # Obol node status report (on demand / daily)
│   ├── control-health.sh        # Control node cron health check
│   ├── control-status.sh        # Cluster-wide status report (on demand / daily)
│   ├── validator-duties.sh      # Missed attestation and missed proposal checker
│   └── sync-indices.sh          # Resolve validator pubkeys to beacon indices
└── crontabs/
    ├── obol-crontab             # Crontab for Obol nodes
    └── control-crontab          # Crontab for control nodes
```

After installation everything lives under:
```
/home/ethereum/.obol-monitor/
├── conf/node.env                # Your filled-in config
├── lib/common.sh
├── scripts/
├── cache/
│   ├── validator-indices.json   # Validator index cache (control node)
│   ├── head-miss-rate.json      # Rolling head-miss rate state (control node)
│   ├── charon-disrupt-sync.json # CL sync event timestamps (obol node)
│   ├── cluster-state.sig        # Last known cluster up/down signature (control node)
│   └── ctrl-takeover.sig        # Last known primary reachability state (failover node)
├── locks/                       # Alert deduplication lock files
└── logs/                        # Cron output logs
```

---

## Installation

### On each Obol node (run once per node)

```bash
git clone <this-repo> obol-monitor   # or scp the folder
cd obol-monitor
bash install.sh obol
```

`install.sh` auto-detects running Ethereum clients and writes `node.env`.
Review and adjust if needed:

| Variable | Description |
|---|---|
| `NODE_ID` | 1, 2, or 3 |
| `NODE_NAME` | Human-readable name (shown in alerts) |
| `TELEGRAM_BOT_TOKEN` | From @BotFather |
| `TELEGRAM_CHAT_ID` | Your group or user chat ID |
| `EL_CLIENT` | `geth` / `nethermind` / `erigon` / `besu` / `reth` |
| `CL_CLIENT` | `lighthouse` / `prysm` / `nimbus` / `teku` / `lodestar` / `grandine` |
| `VPN_IP` | This node's Tailscale IP (optional, shown in alerts) |

---

### On each control node (run once per node)

```bash
bash install.sh control           # primary control node
bash install.sh control-failover  # backup control node
```

`install.sh` will prompt for Obol node IPs and names, then write `node.env`.
Key variables set automatically:

| Variable | Description |
|---|---|
| `OBOL_NODE_N_IP` | Tailscale IP of each Obol node |
| `OBOL_NODE_N_NAME` | Human-readable label for alerts |
| `OBOL_NODE_N_BASE` | Charon API base URL (`http://<ip>:3620`) |
| `CLUSTER_SIZE` | Total number of Obol nodes |
| `PEER_CONTROL_IP` | Primary node's IP (failover only — leave empty on primary) |

Allow Charon port 3620 from the control nodes on each Obol node:

```bash
sudo ufw allow from <control-node-1-tailscale-ip> to any port 3620
sudo ufw allow from <control-node-2-tailscale-ip> to any port 3620
```

---

## Alert levels

Alerts are grouped into three tiers. Set `ALERT_LEVEL` in `node.env` to
control which ones are sent to Telegram.

| Level | What fires |
|---|---|
| `critical` | Node/Charon down, missed block proposal, mass missed attestations, low disk `/home/ethereum` |
| `info` *(default)* | All critical + service outages, sync issues, latency, swap, CPU temp, root disk |
| `detailed` | All of the above + low EL/CL peers, metrics gaps, backup sync issues, index cache misses |

Setting `ALERT_LEVEL=critical` gives you silence-until-it-really-matters.
Setting `ALERT_LEVEL=detailed` gives you everything.

---

## Alerts reference

### Obol node (`obol-health.sh`, every 5 min)

| Condition | Level | Alert |
|---|---|---|
| Charon or validator service down | critical | 🚨 Service DOWN |
| `/home/ethereum` free < `DISK_ETH_ALERT_GB` GB | critical | 🚨 Low disk |
| Charon DVT peers < `CHARON_PEERS_MIN` | critical | 🚨 Charon low peers |
| Swap > `CHARON_STOP_SWAP_GB` GB, OR load avg > `CHARON_STOP_CPU_LOAD_AVG`, OR CL sync events > `CHARON_STOP_SYNC_EVENTS` in 1 h | critical | 🛑 Cluster Disruption Risk — stop Charon |
| EL / CL / MEV service down | info | 🚨 Service DOWN |
| EL not synced | info | ⚠️ EL not synced |
| CL sync distance ≥ `CL_SYNC_DISTANCE_ALERT` slots | info | ⚠️ CL not synced |
| EL RPC unreachable | info | ⚠️ EL RPC unreachable |
| CL API unreachable | info | ⚠️ CL API unreachable |
| Charon peer latency > `CHARON_LATENCY_ALERT_MS` ms | info | ⚠️ High latency |
| ≥ `BCAST_DELAY_COUNT_MIN` attestation submissions with delay > `BCAST_DELAY_ALERT_MS` ms | info | ⚠️ Charon slow attestation submissions |
| Swap > `SWAP_ALERT_GB` GB | info | ⚠️ High swap (early warning) |
| `/` used > `DISK_ROOT_ALERT_PCT` % | info | ⚠️ Low root disk |
| CPU temp > `CPU_TEMP_ALERT_C` °C | info | 🌡 High CPU temp |
| EL peer count < `EL_PEERS_MIN` | detailed | ⚠️ EL low peers |
| CL peer count < `CL_PEERS_MIN` | detailed | ⚠️ CL low peers |

The **Cluster Disruption Risk** alert fires when any of these are true simultaneously on the same node — a node that is swapping heavily, CPU-saturated, or repeatedly falling behind the chain degrades QBFT consensus for the whole cluster. The alert recommends `sudo systemctl stop charon` and clears automatically once all conditions resolve. The CL sync condition uses a 1-hour sliding-window counter (`charon-disrupt-sync.json`) so a single brief slip does not trigger it.

### Control node (`control-health.sh`, every 5 min)

| Condition | Level | Alert / Message |
|---|---|---|
| Obol node unreachable (Charon /livez) | critical | 🚨 Node UNREACHABLE |
| Charon peer count < minimum (remote) | critical | 🚨 Charon low peers |
| `/home/ethereum` free < threshold | critical | 🚨 Low disk |
| Any node's reachability changes (up→down or down→up) | — | ⚠️ Cluster status changed (or ✅ Cluster fully healthy) |
| Primary control node unreachable → failover takes over | — | 🚨 Primary control node unreachable |
| Primary control node recovers → failover stands down | — | ✅ Primary control node restored |
| Failover control node unreachable (primary only, requires `PEER_FAILOVER_IP`) | info | ⚠️ Failover control node unreachable |
| Charon peer latency > threshold (remote) | info | ⚠️ High latency |
| One Charon peer avg latency >3× others (outlier) | info | ⚠️ Charon peer outlier |
| Swap / root disk / CPU temp | info | ⚠️ (same thresholds) |
| Charon metrics endpoint empty | detailed | ⚠️ Metrics unavailable |
| Local backup services down | detailed | 🚨 Service DOWN |
| Local backup EL / CL not synced | detailed | ⚠️ Not synced |

The **Cluster status changed** message is not lock-gated — it fires exactly once per state transition (e.g. node goes down, or recovers) using `cluster-state.sig` as the deduplication mechanism. It lists every node with a ✅ or 🔴 marker and shows whether the cluster still meets the 2/3 signing quorum.

The **control node mutual monitoring** alerts use two different mechanisms: the takeover alert (failover → primary) uses a state file (`ctrl-takeover.sig`) so it fires exactly once when the primary goes down and once when it comes back; the failover reachability alert (primary → failover) uses a standard lock so it respects `LOCK_EXPIRY`. Set `PEER_FAILOVER_IP` on the primary and `PEER_CONTROL_IP` + `PEER_CONTROL_NAME` on the failover to enable both directions.

### Validator duties (`validator-duties.sh`, every 7 min — control node)

| Condition | Level | Alert |
|---|---|---|
| Missed block proposal | critical | 🚨 Missed Block Proposal |
| ≥ `MASS_MISS_THRESHOLD` validators missed an epoch | critical | 🚨 Mass Missed Attestations |
| Single validator missed attestation | info | ❌ Missed Attestation |
| Rolling head-miss rate ≥ `HEAD_MISS_RATE_PCT` % over `HEAD_MISS_WINDOW_HOURS` h | info | 📉 Degraded Attestation Performance |
| Validator index cache missing | detailed | ⚠️ Cache missing |

---

## Alert deduplication

Each alert uses a lock file keyed by condition. Once fired it will not fire
again for `LOCK_EXPIRY` seconds (default 24 h). When the condition clears
the lock is removed immediately, so the next occurrence fires a fresh alert.
Suppressed alerts (filtered by `ALERT_LEVEL`) never create a lock, so they
are re-evaluated on every run.

---

## Daily reports

A full status digest is sent every day at 08:00 by:
- `obol-status.sh` on Obol nodes (single-node summary)
- `control-status.sh` on control nodes (full cluster overview)

Run either script manually to get a status report on demand:
```bash
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/obol-status.sh
sudo -u ethereum bash /home/ethereum/.obol-monitor/scripts/control-status.sh
```

---

## Firewall / network requirements

| Port | Protocol | Direction | Purpose |
|---|---|---|---|
| 3620 | TCP | control → obol | Charon HTTP API (reachability + metrics) |
| 8545 | TCP | localhost only | EL JSON-RPC |
| 5052 | TCP | localhost only | CL Beacon API |
| 3600 | TCP | localhost only | Charon API |

---

## Thresholds reference

All thresholds are set in `node.env` and can be adjusted per node.

| Variable | Default | Description |
|---|---|---|
| `ALERT_LEVEL` | `info` | Alert tier: `critical` / `info` / `detailed` |
| `EL_PEERS_MIN` | 5 | Minimum EL peers before alert |
| `CL_PEERS_MIN` | 10 | Minimum CL peers before alert |
| `CL_SYNC_DISTANCE_ALERT` | 2 | CL slot distance that triggers the "not synced" alert (1 = strict, 2 = default) |
| `CHARON_PEERS_MIN` | cluster−1 | Minimum Charon cluster peers |
| `CHARON_PEERS_EXPECTED` | cluster−1 | Expected Charon peers (control node) |
| `CHARON_LATENCY_ALERT_MS` | 500 | Max acceptable peer RTT in ms |
| `BCAST_DELAY_ALERT_MS` | 3000 | Attestation bcast delay threshold (ms) — obol node only |
| `BCAST_DELAY_COUNT_MIN` | 4 | Min high-delay submissions in 5 min to fire alert — obol node only |
| `SWAP_ALERT_GB` | 6 | Swap usage early-warning threshold (GB) |
| `CHARON_STOP_SWAP_GB` | 10 | Swap threshold that triggers the Cluster Disruption Risk alert — must be > `SWAP_ALERT_GB` |
| `CHARON_STOP_CPU_LOAD_AVG` | 6 | 1-min load average threshold for Cluster Disruption Risk alert |
| `CHARON_STOP_SYNC_EVENTS` | 1 | Fire Cluster Disruption Risk after this many CL out-of-sync detections in 1 h (`>` this value) |
| `DISK_ETH_ALERT_GB` | 150 | Free space alert on /home/ethereum (GB) |
| `DISK_ROOT_ALERT_PCT` | 85 | Root disk used% alert |
| `CPU_TEMP_ALERT_C` | 80 | CPU temperature alert (°C) |
| `MASS_MISS_THRESHOLD` | 10 | Number of validators that triggers mass-miss alert |
| `HEAD_MISS_RATE_PCT` | 1.0 | Rolling head-miss rate % that triggers performance alert |
| `HEAD_MISS_WINDOW_HOURS` | 1 | Rolling window for head-miss rate calculation (hours) |
| `PEER_CONTROL_IP` | _(empty)_ | VPN IP of the primary control node — set on the failover node only |
| `PEER_CONTROL_NAME` | _(empty)_ | Human-readable name of the primary — shown in takeover alerts |
| `PEER_FAILOVER_IP` | _(empty)_ | VPN IP of the failover control node — set on the primary to enable failover reachability check |
| `PEER_FAILOVER_NAME` | _(empty)_ | Human-readable name of the failover — shown in alerts |
| `LOCK_EXPIRY` | 86400 | Alert cooldown in seconds (24 h) |
| `CHARON_API_TIMEOUT` | 8 | Timeout for Charon HTTP calls (seconds) |