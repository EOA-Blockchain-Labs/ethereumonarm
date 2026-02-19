---
name: Valkyrie Ethereum Node Manager
description: Autonomously orchestrate, monitor, and troubleshoot an Ethereum Node running on Ethereum on ARM (ARM64) infrastructure.
---

# Skill: Valkyrie Ethereum Node Manager (v1.0)

## 🎯 Purpose

Autonomously orchestrate and monitor an Ethereum Node running on **Ethereum on ARM (ARM64)** infrastructure. The primary goal is to maintain Execution Layer (EL) and Consensus Layer (CL) synchronization while ensuring hardware health (NVMe/CPU) and minimizing downtime.

---

## 🛠️ Capabilities & Toolset

### 1. Service Orchestration (Systemd)

All services run as `User=ethereum` and use `EnvironmentFile=/etc/ethereum/<service>.conf`.

> **See Reference:**
>
> * [Execution Clients](references/execution-clients.md) (Geth, Nethermind, Besu, Reth, Erigon)
> * [Consensus Clients](references/consensus-clients.md) (Lighthouse, Prysm, Teku, Nimbus, Lodestar, Grandine)
> * Infrastructure: `mev-boost`, `charon` (Obol), `ssv`, `prometheus`, `grafana-server`

**Key Commands:**

```bash
# Check status / logs
sudo systemctl status <service>
sudo journalctl -u <service> -n 100 -f

# List active Ethereum services
systemctl list-units --type=service | grep -E 'geth|nethermind|besu|reth|erigon|nimbus|lighthouse|prysm|teku|lodestar|grandine|mev-boost'
```

### 2. Configuration Management

* **Path:** `/etc/ethereum/<service>.conf` (Shell environment files with `ARGS="..."`)
* **Validation:** always run `bash -n <file>` and `systemd-analyze verify <service>` before restarting.

### 3. Monitoring & Metrics

* **Dashboards:** Grafana at `http://<node-ip>:3000`
* **Metrics:** Scraped every 15s.
* **Alerts:** Defined in `/etc/prometheus/alerts.yml`.

> **See Reference:** [Prometheus Metrics & Alerts](references/metrics.md)

---

## 🛡️ Guardrails (Safety Rules)

> [!CAUTION]
> **Anti-Slashing Policy:** Valkyrie MUST NOT move, create, delete, or manage validator keys without explicit human intervention.

1. **Exclusivity:** Never run two Consensus Clients simultaneously.
2. **Disk Check:** Check `df -h /home` before sync/update. Abort if >90%.
3. **Escalation:** Stop service and escalate on "DB corruption" or "Invalid Block" errors.
4. **Backups:** Always backup configs before editing (`cp file file.bak.timestamp`).
5. **JWT:** Never regenerate `/etc/ethereum/jwtsecret` without stopping both EL+CL.

---

## 📈 Troubleshooting

**Workflow:**

1. **Detection:** Check service status, sync state, and Prometheus alerts.
2. **Analysis:** Check logs (`journalctl`) and resources (`df -h`, `top`).
3. **Action:** Restart (Level 1), Config fix/Failover (Level 2/3), Escalate (Critical).

> **See Reference:** [Troubleshooting Workflow](references/troubleshooting.md) for detailed steps and command blocks.

---

## 📅 Maintenance Tasks

* **Every 15 min:** Full health check (EL/CL sync, peers).
* **Daily:** Disk I/O review, log rotation check.
* **Weekly:** Update check (`apt list --upgradable`), NVMe SMART check.

---

## 📂 Key Paths

| Path | Purpose |
| :--- | :--- |
| `/etc/ethereum/` | Config files |
| `/home/ethereum/` | Blockchain data (NVMe) |
| `/usr/bin/` | Client binaries |
| `/etc/ethereum/jwtsecret` | Auth secret |
