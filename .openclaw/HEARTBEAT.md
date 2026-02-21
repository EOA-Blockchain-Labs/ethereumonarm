# Heartbeat — Valkyrie Autonomous Monitoring

Step-by-step health checklist. Report results using the Standard Alert Format.

---

## Pre-Check: Detect Active Services

Identify running EL, CL, Validator, and MEV-Boost services.

> [!NOTE]
> Most CL clients use P2P port `9000` TCP/UDP. **Prysm** is the exception:
> it uses `13000/TCP` and `12000/UDP`. Keep this in mind when troubleshooting
> peer connectivity.

```bash
# Detect EL
systemctl list-units --type=service --state=active | grep -E 'geth|nethermind|besu|reth|erigon'
# Detect CL/Validator
systemctl list-units --type=service --state=active | grep -E 'lighthouse|prysm|teku|nimbus|lodestar|grandine'
```

## Check 1: Service Status

* Verify all detected services are `active`.
* **Action:** Restart if `inactive` (except Validator). Check logs if `failed`.

## Check 2: Execution Layer Sync

```bash
# Syncing false?
curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
# Peer count > 3?
curl -s -X POST http://127.0.0.1:8545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'
```

## Check 3: Consensus Layer Sync (Port 5052)

```bash
# Health 200? (206=syncing, 503=init)
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5052/eth/v1/node/health
# Peer count > 3?
curl -s http://127.0.0.1:5052/eth/v1/node/peer_count
# Finality?
curl -s http://127.0.0.1:5052/eth/v1/beacon/states/head/finality_checkpoints
```

## Check 4: MEV-Boost (If Active)

* `curl http://127.0.0.1:18550/eth/v1/builder/status` returns 200 OK.

## Check 5: Resources

> **See:** [Metrics Reference](references/metrics.md) for per-client port details.

* **Disk:** `df -h /home` (Alert if > 90%)
* **Memory:** `free -h` (Alert if < 10% free)
* **CPU:** `cat /proc/loadavg` (Alert if load > 12.0)
* **Temp:** `/sys/class/thermal/thermal_zone*/temp` (Alert if > 90°C)

## Check 6: Log Analysis (Last 15m)

Scan for `error`, `fatal`, `panic`, `corrupt`, `db.corruption`.

* **Critical:** `DB corruption` or `Invalid block` -> **STOP SERVICE & ESCALATE**.

## Check 7: Validator Duties (If Active)

* Scan logs for `miss` or `skip`.
* **NEVER** auto-restart a validator service.

---

## Alert Format

```text
🛡️ Valkyrie Alert — [SEVERITY]
Issue:       [Brief description]
Service:     [Service]
Details:     [Metrics/Logs]
Action:      [Action taken]
Next Step:   [Next steps]
```
