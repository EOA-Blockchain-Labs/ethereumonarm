---
name: Valkyrie Ethereum Node Manager
description: Autonomously orchestrate, monitor, and troubleshoot an Ethereum Node running on Ethereum on ARM (ARM64) infrastructure.
---

# Skill: Valkyrie Ethereum Node Manager (v1.0)

## 🎯 Purpose

Autonomously orchestrate and monitor an Ethereum Node running on **Ethereum on ARM (ARM64)** infrastructure. The primary goal is to maintain Execution Layer (EL) and Consensus Layer (CL) synchronization while ensuring hardware health (NVMe/CPU) and minimizing downtime.

---

## 📐 Architecture Overview

All services run as the `ethereum` user on ARM64 boards (NanoPC-T6, Rock 5B, Rock 5T, Orange Pi 5 Plus, Raspberry Pi 5). NVMe storage is mounted at `/home` with data under `/home/ethereum/`.

```
┌─────────────────────────────────────────────────────────┐
│  Configuration: /etc/ethereum/<service>.conf             │
│  Binaries:      /usr/bin/<client>                        │
│  Data:          /home/ethereum/                          │
│  Monitoring:    Prometheus (:9090) → Grafana (:3000)     │
│  JWT Secret:    /etc/ethereum/jwtsecret                   │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Capabilities & Toolset

### 1. Service Orchestration (Systemd)

All services use `EnvironmentFile=/etc/ethereum/<service>.conf` and run as `User=ethereum`.

#### Execution Layer (L1)

| Service Unit              | Binary          | Client         |
| :------------------------ | :-------------- | :------------- |
| `geth.service`            | `/usr/bin/geth` | Geth           |
| `nethermind.service`      | `/usr/bin/nethermind` | Nethermind |
| `besu.service`            | `/usr/bin/besu` | Besu           |
| `reth.service`            | `/usr/bin/reth` | Reth           |
| `erigon.service`          | `/usr/bin/erigon` | Erigon       |
| `ethrex.service`          | `/usr/bin/ethrex` | EthRex       |
| `nimbus-ec.service`       | `/usr/bin/nimbus` | Nimbus EL    |

#### Consensus Layer (L1)

Each CL client ships multiple service variants for **mainnet/sepolia/hoodi** and with/without **MEV-boost** support:

| Client       | Base Service Pattern                      | Variant Examples                                       |
| :----------- | :---------------------------------------- | :----------------------------------------------------- |
| **Lighthouse** | `lighthouse-beacon[-<network>][-mev]`   | `lighthouse-beacon-mev`, `lighthouse-beacon-sepolia`   |
| **Prysm**    | `prysm-beacon[-<network>][-mev]`          | `prysm-beacon-mev`, `prysm-beacon-hoodi`              |
| **Nimbus**   | `nimbus-beacon[-<network>][-mev]`          | `nimbus-beacon-mev`, `nimbus-beacon-sepolia`           |
| **Teku**     | `teku-beacon[-<network>][-mev]`            | `teku-beacon-mev`, `teku-beacon-hoodi-mev`             |
| **Lodestar** | `lodestar-beacon[-<network>][-mev]`        | `lodestar-beacon-mev`, `lodestar-beacon-sepolia`       |
| **Grandine** | `grandine-beacon[-<network>][-mev]`        | `grandine-beacon-mev`, `grandine-beacon-hoodi`         |

Corresponding **validator** services follow the same pattern: `<client>-validator[-<network>][-mev].service`.

#### Infrastructure

| Service Unit              | Purpose                        |
| :------------------------ | :----------------------------- |
| `mev-boost.service`       | MEV-Boost relay (mainnet)      |
| `mev-boost-sepolia.service` | MEV-Boost relay (Sepolia)    |
| `mev-boost-hoodi.service` | MEV-Boost relay (Hoodi)        |
| `charon.service`          | Obol DVT middleware            |
| `ssv.service`             | SSV Network node               |
| `anchor.service`          | Anchor DVT (Sigp)              |
| `commit-boost.service`    | Commit-Boost client            |
| `vero.service`            | Vero validator                 |
| `vouch.service`           | Vouch validator                |

#### Layer 2

| Service Unit                 | L2 Network     |
| :--------------------------- | :------------- |
| `op-node.service`            | Optimism       |
| `op-geth.service`            | Optimism       |
| `op-reth.service`            | Optimism       |
| `arbitrum-nitro.service`     | Arbitrum       |
| `juno.service`               | Starknet       |
| `madara.service`             | Starknet       |
| `pathfinder.service`         | Starknet       |
| `zksync-era.service`         | zkSync         |
| `ethrex-l2.service`          | EthRex L2      |
| `fuel-core.service`          | Fuel           |
| `linea-besu.service`         | Linea          |

#### System

| Service Unit                        | Purpose                  |
| :---------------------------------- | :----------------------- |
| `ethereum-backup.service`           | Scheduled data backup    |
| `ethereum-backup.timer`             | Backup timer             |
| `ethereum-swappiness-enforce.service` | Enforce swap settings  |
| `prometheus.service`                | Metrics collection       |
| `prometheus-node-exporter.service`  | System metrics           |
| `grafana-server.service`            | Dashboard UI             |
| `nginx.service`                     | Reverse proxy            |

**Monitoring commands:**

```bash
# Check one service
sudo systemctl status geth.service

# View recent logs (last 100 lines, follow)
sudo journalctl -u geth -n 100 -f

# Restart a service
sudo systemctl restart geth.service

# List all ethereum-related services
systemctl list-units --type=service | grep -E 'geth|nethermind|besu|reth|erigon|ethrex|nimbus|lighthouse|prysm|teku|lodestar|grandine|mev-boost|charon|ssv|anchor'
```

### 2. Configuration Management

* **Config path:** `/etc/ethereum/<service>.conf`
* **Format:** Shell environment file sourced by systemd. Each contains an `ARGS` variable:

  ```bash
  # Example: /etc/ethereum/geth.conf
  ARGS="--metrics \
  --metrics.expensive \
  --pprof \
  --http \
  --authrpc.jwtsecret=/etc/ethereum/jwtsecret"
  ```

* **DVT configs** are under `/etc/ethereum/dvt/` (e.g., `charon.conf`, `*-validator-obol.conf`).
* **Validation:** Always verify configuration syntax before applying changes:

  ```bash
  # Validate config is a proper shell env file
  bash -n /etc/ethereum/geth.conf
  
  # Dry-run: verify the ExecStart resolves correctly
  systemd-analyze verify geth.service
  ```

### 3. Storage & Hardware Monitoring

* **NVMe data disk** is mounted at `/home` (label: `ethereum_data`, filesystem: `ext4`)
* **Critical threshold:** 90% utilization on `/home`
* **Swap** at `/home/ethereum/swapfile` (2× RAM, max 64 GB)

```bash
# Disk utilization
df -h /home

# NVMe health
sudo smartctl -a /dev/nvme0n1

# I/O stats
iostat -x /dev/nvme0n1 1 5

# Swap usage
free -h
```

### 4. Network & Sync Diagnostics

#### Execution Layer (JSON-RPC on port 8545)

```bash
# Check sync status
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq

# Peer count
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | jq

# Latest block number
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq
```

#### Consensus Layer (Beacon API on port 5052)

```bash
# Node health (returns HTTP 200 if synced, 206 if syncing, 503 if not initialized)
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5052/eth/v1/node/health

# Sync status
curl -s http://127.0.0.1:5052/eth/v1/node/syncing | jq

# Peer count
curl -s http://127.0.0.1:5052/eth/v1/node/peer_count | jq

# Node version
curl -s http://127.0.0.1:5052/eth/v1/node/version | jq
```

#### MEV-Boost (port 18550)

```bash
curl -s http://127.0.0.1:18550/eth/v1/builder/status
```

### 5. Prometheus Metrics Endpoints

The monitoring stack scrapes these endpoints every 15s (see `prometheus.yml`):

| Client/Exporter                    | Metrics Port | Metrics Path                          |
| :--------------------------------- | :----------- | :------------------------------------ |
| Geth                               | 6060         | `/debug/metrics/prometheus`           |
| Erigon                             | 5050         | `/debug/metrics/prometheus`           |
| Nethermind                         | 7070         | `/metrics`                            |
| Besu                               | 9545         | `/metrics`                            |
| Reth                               | 9001         | `/`                                   |
| EthRex                             | 3701         | `/metrics`                            |
| Nimbus EC                          | 8018         | `/metrics`                            |
| Lighthouse (beacon)                | 5054         | `/metrics`                            |
| Lighthouse (validator)             | 5064         | `/metrics`                            |
| Prysm (beacon)                     | 8080         | `/metrics`                            |
| Prysm (validator)                  | 8081         | `/metrics`                            |
| Teku                               | 8009         | `/metrics`                            |
| Teku (validator)                   | 8010         | `/metrics`                            |
| Nimbus CL                          | 8008         | `/metrics`                            |
| Lodestar (beacon)                  | 4040         | `/metrics`                            |
| Lodestar (validator)               | 4041         | `/metrics`                            |
| Grandine (beacon)                  | 5054         | `/metrics`                            |
| Grandine (validator)               | 8009         | `/metrics`                            |
| Obol Charon                        | 3620         | `/metrics`                            |
| SSV                                | 15000        | `/metrics`                            |
| Optimism op-node                   | 7300         | `/metrics`                            |
| Optimism op-geth                   | 7301         | `/debug/metrics/prometheus`           |
| Node Exporter                      | 9100         | `/metrics`                            |
| Prometheus                         | 9090         | `/metrics`                            |
| Ethereum Metrics Exporter          | 9095         | `/metrics`                            |
| Validator Metrics Exporter         | 9096         | `/metrics`                            |
| Commit-Boost                       | 10000        | `/metrics`                            |

### 6. Grafana Dashboards

Pre-built dashboards are installed via the `ethereumonarm-monitoring-extras` package:

* `01-Home.json` — Overview
* `02-Ethereum Dashboard.json` — Combined EL/CL view
* `03-EoA OS Status.json` — System health
* `04-Prometheus Stats.json` — Prometheus self-monitoring
* Per-client dashboards: `Execution/{Geth,Nethermind,Besu,Reth,Erigon,Ethrex}.json`, `Consensus/{Lighthouse,Prysm,Teku,Nimbus,Lodestar}.json`
* DVT: `DVT/{Obol - cluster,Obol - node,SSV - node}.json`
* L2: `L2/Op - *.json`

Access Grafana at `http://<node-ip>:3000`.

---

## 🛡️ Guardrails (Safety Rules)

> [!CAUTION]
> **Anti-Slashing Policy:** Valkyrie MUST NOT move, create, delete, or manage validator keys (`validator_keys`) without explicit human intervention. Its scope is strictly limited to Beacon and Execution infrastructure.

1. **Exclusivity Rule:** Never run two Consensus Clients (CL) simultaneously on the same network. Before starting a new CL service, verify no other CL service is active:

   ```bash
   systemctl list-units --type=service --state=active | grep -E 'beacon|nimbus-beacon'
   ```

2. **Disk Verification:** Always check available space (`df -h /home`) before attempting a re-sync, client switch, or major client update. Abort if utilization exceeds 90%.

3. **Least Privilege:** All services run as `User=ethereum`. Execute privileged actions only via a pre-approved `sudo` whitelist for specific Ethereum services and config paths under `/etc/ethereum/`.

4. **Error Escalation:** If persistent "Invalid Block", "Critical Database Error", or "DB corruption" messages occur, **stop the service immediately and escalate to a human operator**. Do not attempt automated recovery for data-corruption class errors.

5. **Config Backup:** Before modifying any file in `/etc/ethereum/`, create a timestamped backup:

   ```bash
   sudo cp /etc/ethereum/geth.conf /etc/ethereum/geth.conf.bak.$(date +%Y%m%d%H%M%S)
   ```

6. **JWT Integrity:** The shared JWT secret at `/etc/ethereum/jwtsecret` is critical for EL↔CL authentication. Never regenerate it without stopping **both** EL and CL services first.

---

## 📈 Troubleshooting Workflow

### Step 1: Detection

Identify issues via any of these signals:

* Service in `inactive`/`failed` state: `systemctl is-active <service>`
* Extended `syncing: true` on EL or CL
* Beacon health returning `503`: `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5052/eth/v1/node/health`
* Prometheus alert firing (`InstanceDown`, `HostHighDiskUsage`, `HostHighCpuLoad`, `HostOutOfMemory`)
* Peer count at zero: `curl -s http://127.0.0.1:5052/eth/v1/node/peer_count | jq`

### Step 2: Analysis

```bash
# Get recent logs for the affected service
sudo journalctl -u <service> -n 200 --no-pager

# Look for specific error patterns
sudo journalctl -u <service> --since "1 hour ago" | grep -iE 'error|fatal|corrupt|panic|refused|timeout|jwt'

# Check system resources
df -h /home
free -h
top -bn1 | head -20
```

Determine root cause category:

* **External:** Network issues, upstream chain problems
* **Local Hardware:** NVMe failure, memory exhaustion, CPU thermal throttling
* **Local Software:** Config error, client bug, stale database

### Step 3: Progressive Action

| Level | Condition                              | Action                                                     |
| :---- | :------------------------------------- | :--------------------------------------------------------- |
| **1** | Service crashed, no error pattern match | `sudo systemctl restart <service>` — wait 2 min, verify    |
| **2** | JWT auth failures between EL↔CL       | Re-generate JWT secret, restart **both** EL and CL         |
| **2** | Stale cache / pruning issues           | Clear local cache dirs, restart service                    |
| **3** | Known client consensus bug             | Client failover (e.g., Geth → Nethermind or Lighthouse → Nimbus). Update config, restart |
| **3** | Persistent DB corruption               | **Stop service, escalate to human operator**                |

#### JWT Re-authentication Procedure

```bash
# 1. Stop both layers
sudo systemctl stop <el-service>
sudo systemctl stop <cl-service>

# 2. Regenerate JWT
sudo openssl rand -hex 32 | sudo tee /etc/ethereum/jwtsecret > /dev/null

# 3. Restart both layers
sudo systemctl start <el-service>
sudo systemctl start <cl-service>
```

#### Client Failover Procedure (EL Example: Geth → Nethermind)

```bash
# 1. Verify disk space for new client data
df -h /home

# 2. Stop current EL
sudo systemctl stop geth.service
sudo systemctl disable geth.service

# 3. Enable and start new EL
sudo systemctl enable nethermind.service
sudo systemctl start nethermind.service

# 4. Monitor sync progress
sudo journalctl -u nethermind -f
```

### Step 4: Verification

Confirm recovery by checking:

```bash
# Service is running
systemctl is-active <service>

# EL: syncing == false
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# CL: health 200
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5052/eth/v1/node/health

# Peer count rising
curl -s http://127.0.0.1:5052/eth/v1/node/peer_count | jq '.data.connected'

# Prometheus targets healthy
curl -s http://127.0.0.1:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

---

## 📅 Maintenance Tasks

| Cadence        | Task                                                                 | Command / Check                                          |
| :------------- | :------------------------------------------------------------------- | :------------------------------------------------------- |
| **Every 15 min** | Full health check (EL sync, CL health, MEV-Boost, peer counts)     | See Detection step above                                 |
| **Daily**      | Disk I/O performance summary                                         | `iostat -x /dev/nvme0n1`                                 |
| **Daily**      | Log rotation audit                                                    | `journalctl --disk-usage`, `sudo journalctl --vacuum-time=7d` |
| **Daily**      | Check for active Prometheus alerts                                    | `curl -s http://127.0.0.1:9090/api/v1/alerts \| jq`     |
| **Weekly**     | Check for package updates in the Ethereum on ARM APT repository       | `sudo apt update && apt list --upgradable 2>/dev/null \| grep -i ethereum` |
| **Weekly**     | NVMe SMART health check                                              | `sudo smartctl -a /dev/nvme0n1`                          |
| **Monthly**    | Review and apply pending security updates                             | `sudo apt upgrade`                                       |

---

## 📂 Key Project Paths Reference

| Path                                  | Purpose                                           |
| :------------------------------------ | :------------------------------------------------ |
| `/etc/ethereum/`                      | All client configuration files (`.conf`)          |
| `/etc/ethereum/jwtsecret`             | Shared EL↔CL authentication secret                |
| `/etc/ethereum/dvt/`                  | DVT-specific configs (Obol, SSV)                  |
| `/home/ethereum/`                     | All blockchain data (NVMe mount)                  |
| `/home/ethereum/swapfile`             | Swap file (2× RAM, max 64 GB)                     |
| `/usr/bin/`                           | Client binaries                                   |
| `/usr/lib/ethereumonarm/`             | Prometheus config, alerts, Grafana dashboards      |
| `/etc/prometheus/alerts.yml`          | Prometheus alerting rules (deployed from package)  |
| `/home/prometheus/`                   | Prometheus data directory                          |

---

## 🔒 Active Prometheus Alerts

The `alerts.yml` defines these rules (deployed via `ethereumonarm-monitoring-extras`):

| Alert                 | Expression                                         | Duration | Severity |
| :-------------------- | :------------------------------------------------- | :------- | :------- |
| `InstanceDown`        | `up == 0`                                          | 1m       | critical |
| `HostHighCpuLoad`     | CPU idle < 20% (averaged)                          | 5m       | warning  |
| `HostOutOfMemory`     | Available memory < 10%                             | 2m       | warning  |
| `HostHighDiskUsage`   | Available disk < 10% (non-readonly)                | 2m       | warning  |

---

## 🖥️ Supported Devices

| Device             | Target Disk       | Partition     | Hostname Seed |
| :----------------- | :---------------- | :------------ | :------------ |
| Rock 5T (ITX)      | `/dev/nvme0n1`    | `p1`          | `rock5t`      |
| Rock 5B            | `/dev/nvme0n1`    | `p1`          | `rock5b`      |
| Raspberry Pi 5     | `/dev/nvme0n1`    | `p1`          | `rpi5`        |
| Orange Pi 5 Plus   | `/dev/nvme0n1`    | `p1`          | `opi5plus`    |
| NanoPC-T6          | `/dev/nvme0n1`    | `p1`          | `nanopct6`    |
