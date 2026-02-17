# Heartbeat — Valkyrie Autonomous Monitoring

This document defines the monitoring checklist that Valkyrie executes on
every scheduled health check. Follow these steps in order and report results
using the alert format defined at the bottom.

---

## Pre-Check: Detect Active Services

Before running diagnostics, determine which EL + CL pair is currently
running. Only one of each layer should be active at any time.

```bash
# Detect active Execution Layer service
for svc in geth nethermind besu reth erigon ethrex nimbus-ec; do
  if systemctl is-active --quiet "${svc}.service" 2>/dev/null; then
    echo "EL_ACTIVE=${svc}"
    break
  fi
done

# Detect active Consensus Layer service (check all beacon variants)
for client in lighthouse nimbus prysm teku lodestar grandine; do
  for variant in "" "-mev" "-sepolia" "-sepolia-mev" "-hoodi" "-hoodi-mev"; do
    svc="${client}-beacon${variant}"
    if systemctl is-active --quiet "${svc}.service" 2>/dev/null; then
      echo "CL_ACTIVE=${svc}"
      break 2
    fi
  done
done

# Detect active Validator service (if any)
for client in lighthouse nimbus prysm teku lodestar grandine; do
  for variant in "" "-mev" "-sepolia" "-sepolia-mev" "-hoodi" "-hoodi-mev"; do
    svc="${client}-validator${variant}"
    if systemctl is-active --quiet "${svc}.service" 2>/dev/null; then
      echo "VALIDATOR_ACTIVE=${svc}"
      break 2
    fi
  done
done

# Detect MEV-Boost
for variant in mev-boost mev-boost-sepolia mev-boost-hoodi; do
  if systemctl is-active --quiet "${variant}.service" 2>/dev/null; then
    echo "MEV_ACTIVE=${variant}"
    break
  fi
done

# Detect DVT services
systemctl is-active --quiet charon.service 2>/dev/null && echo "DVT_CHARON=active"
systemctl is-active --quiet ssv.service 2>/dev/null && echo "DVT_SSV=active"
```

---

## Check 1: Service Status

Verify all detected services are running:

```bash
# Check each detected service
systemctl is-active ${EL_ACTIVE}.service
systemctl is-active ${CL_ACTIVE}.service
[ -n "${VALIDATOR_ACTIVE}" ] && systemctl is-active ${VALIDATOR_ACTIVE}.service
[ -n "${MEV_ACTIVE}" ] && systemctl is-active ${MEV_ACTIVE}.service

# Monitoring stack
systemctl is-active prometheus.service
systemctl is-active prometheus-node-exporter.service
systemctl is-active grafana-server.service
```

| Result     | Action                                                                |
| :--------- | :-------------------------------------------------------------------- |
| `active`   | ✅ OK — proceed                                                       |
| `inactive` | ⚠️ Service stopped — attempt one auto-restart (Level 1 action)       |
| `failed`   | 🔴 Check logs immediately (`journalctl -u <svc> -n 100 --no-pager`) |

> [!CAUTION]
> **Validator services** (`*-validator*`) must **NEVER** be auto-restarted.
> Always escalate to user. Running two validator instances risks slashing.

---

## Check 2: Execution Layer Sync

```bash
# Sync status (false = fully synced)
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' | jq '.result'

# Peer count (hex → decimal)
PEERS_HEX=$(curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | jq -r '.result')
echo "EL peers: $((${PEERS_HEX}))"

# Latest block
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq '.result'
```

| Condition                       | Severity | Action                                   |
| :------------------------------ | :------- | :--------------------------------------- |
| `syncing == false`              | OK       | Fully synced                             |
| `syncing == true` for < 24h     | INFO     | Initial sync in progress, monitor        |
| `syncing == true` for > 24h     | WARNING  | Check logs for stall, consider restart   |
| Peer count == 0                 | CRITICAL | Network issue, check firewall/NAT        |
| Peer count < 3                  | WARNING  | Low peers, monitor                       |
| RPC not responding              | CRITICAL | EL service likely crashed, check systemd |

---

## Check 3: Consensus Layer Sync

All Ethereum on ARM CL clients expose the Beacon REST API on port **5052** by default.

```bash
# Health endpoint
# 200 = synced, 206 = syncing, 503 = not initialized
CL_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5052/eth/v1/node/health)
echo "CL health: ${CL_HEALTH}"

# Sync details
curl -s http://127.0.0.1:5052/eth/v1/node/syncing | jq '.data'

# Peer count
CL_PEERS=$(curl -s http://127.0.0.1:5052/eth/v1/node/peer_count | jq -r '.data.connected')
echo "CL peers: ${CL_PEERS}"

# Head slot and finality
curl -s http://127.0.0.1:5052/eth/v1/beacon/headers/head | jq '.data.header.message.slot'
curl -s http://127.0.0.1:5052/eth/v1/beacon/states/head/finality_checkpoints | jq '.data'
```

| Condition                    | Severity | Action                                      |
| :--------------------------- | :------- | :------------------------------------------ |
| Health `200`                 | OK       | Fully synced                                |
| Health `206`                 | INFO     | Syncing in progress                         |
| Health `503`                 | CRITICAL | Not initialized, check logs                 |
| CL peers == 0               | CRITICAL | P2P issue, check port 9000/UDP forwarding   |
| CL peers < 3                | WARNING  | Low peers, monitor                          |
| No finality for > 3 epochs  | CRITICAL | Chain finality issue, escalate to user      |

---

## Check 4: MEV-Boost

Only run if an MEV-Boost service was detected:

```bash
# Status endpoint
curl -s http://127.0.0.1:18550/eth/v1/builder/status
echo "MEV-Boost: $?"
```

| Condition       | Action                                     |
| :-------------- | :----------------------------------------- |
| Responds OK     | ✅ MEV-Boost healthy                        |
| Not responding  | ⚠️ Restart MEV-Boost, alert if persists    |

---

## Check 5: Disk Space

```bash
# NVMe is mounted at /home (label: ethereum_data)
DISK_USAGE=$(df -h /home --output=pcent | tail -1 | tr -d ' %')
DISK_AVAIL=$(df -h /home --output=avail | tail -1 | tr -d ' ')
echo "Disk usage: ${DISK_USAGE}% (${DISK_AVAIL} available)"

# Swap usage
free -h | grep -i swap
```

| Condition | Severity | Action                                         |
| :-------- | :------- | :--------------------------------------------- |
| < 80%     | OK       | Healthy                                        |
| 80–90%    | WARNING  | Alert user, suggest pruning or log rotation    |
| > 90%     | CRITICAL | Alert immediately, suggest `journalctl --vacuum-time=3d` |

---

## Check 6: CPU & Temperature

```bash
# CPU load average
LOAD=$(cat /proc/loadavg | awk '{print $1}')
echo "Load average (1m): ${LOAD}"

# ARM board temperature
for zone in /sys/class/thermal/thermal_zone*/temp; do
  TEMP=$(awk '{print $1/1000}' "$zone")
  ZONE_NAME=$(cat "${zone%temp}type" 2>/dev/null || echo "unknown")
  echo "Temperature (${ZONE_NAME}): ${TEMP}°C"
done

# Memory
free -h
```

| Metric      | Warning    | Critical   | Action                                      |
| :---------- | :--------- | :--------- | :------------------------------------------ |
| CPU load    | > 8.0      | > 12.0     | Check runaway processes, consider restart    |
| Temperature | > 80°C     | > 90°C     | Alert, check cooling                         |
| Memory      | < 10% free | < 5% free  | Alert, check for memory leaks               |

---

## Check 7: Log Analysis

Scan recent logs for error patterns:

```bash
# Last 15 minutes of EL logs
sudo journalctl -u ${EL_ACTIVE} --since "15 min ago" --no-pager | \
  grep -ciE 'error|fatal|panic|crit|corrupt' || echo "0 errors"

# Last 15 minutes of CL logs
sudo journalctl -u ${CL_ACTIVE} --since "15 min ago" --no-pager | \
  grep -ciE 'error|fatal|panic|crit|corrupt' || echo "0 errors"

# Specific critical patterns to escalate immediately
sudo journalctl -u ${EL_ACTIVE} -u ${CL_ACTIVE} --since "15 min ago" --no-pager | \
  grep -iE 'db.corruption|invalid.block|database.error|jwt.auth|slashing'
```

### Critical Log Patterns (Escalate Immediately)

| Pattern                      | Service      | Action                              |
| :--------------------------- | :----------- | :---------------------------------- |
| `DB corruption`              | Any          | **Stop service, escalate to user**  |
| `Invalid block`              | EL           | **Stop EL, escalate to user**       |
| `database error`             | Any          | **Stop service, escalate to user**  |
| `JWT authentication failure` | EL or CL     | Re-check `/etc/ethereum/jwtsecret`  |
| `P2P connection refused`     | Any          | Check firewall and port forwarding  |
| `slashing`                   | Validator    | **Escalate immediately to user**    |
| `missed attestation`         | Validator    | Log + alert, do not restart         |

---

## Check 8: Validator Duties (If Active)

Only run if a validator service was detected in Pre-Check:

```bash
# Recent attestation performance
sudo journalctl -u ${VALIDATOR_ACTIVE} --since "15 min ago" --no-pager | \
  grep -iE 'attestation|propose|duty|miss|skip'

# Check for missed duties
sudo journalctl -u ${VALIDATOR_ACTIVE} --since "1 hour ago" --no-pager | \
  grep -ci 'miss' || echo "0 missed duties"
```

> [!CAUTION]
> **NEVER auto-restart the validator service.** If the validator is down or
> missing duties, alert the user immediately with full context. The user
> must decide how to recover.

---

## Escalation Policy Summary

| Component              | Auto-Restart? | Max Retries | Escalate After         |
| :--------------------- | :------------ | :---------- | :--------------------- |
| EL client              | ✅ Yes         | 1           | 2nd failure in 1 hour  |
| CL beacon              | ✅ Yes         | 1           | 2nd failure in 1 hour  |
| **Validator client**   | ❌ **NEVER**   | 0           | **Immediately**        |
| MEV-Boost              | ✅ Yes         | 1           | 2nd failure in 1 hour  |
| DVT (Charon/SSV)       | ✅ Yes         | 1           | 2nd failure in 1 hour  |
| Prometheus/Grafana     | ✅ Yes         | 1           | 2nd failure in 1 hour  |
| NVMe disk > 90%        | ❌ No          | —           | **Immediately**        |
| Temperature > 90°C     | ❌ No          | —           | **Immediately**        |
| DB corruption          | ❌ No          | —           | **Immediately**        |

---

## Alert Format

All alerts must use this format:

```
🛡️ Valkyrie Alert — [SEVERITY]

Issue:       [Brief description]
Service:     [affected service name]
Details:     [relevant metrics, log excerpts, or error messages]
Action:      [what Valkyrie did or recommends]
Next Step:   [what happens next — monitoring, user action needed, etc.]
```

Severity levels:

| Level        | Symbol | Meaning                                   |
| :----------- | :----- | :---------------------------------------- |
| **OK**       | ✅      | All checks passed                         |
| **INFO**     | ℹ️      | Noteworthy but not actionable             |
| **WARNING**  | ⚠️      | Approaching threshold, monitoring closely |
| **CRITICAL** | 🔴      | Immediate attention required              |
