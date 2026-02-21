# Troubleshooting Workflow — Reference

## Step 1: Detection

Identify issues via any of these signals:

- Service in `inactive`/`failed` state: `systemctl is-active <service>`
- Extended `syncing: true` on EL or CL
- Beacon health returning `503`: `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5052/eth/v1/node/health`
- Prometheus alert firing (`InstanceDown`, `HostHighDiskUsage`, `HostHighCpuLoad`, `HostOutOfMemory`)
- Peer count at zero: `curl -s http://127.0.0.1:5052/eth/v1/node/peer_count | jq`

## Step 2: Analysis

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

- **External:** Network issues, upstream chain problems
- **Local Hardware:** NVMe failure, memory exhaustion, CPU thermal throttling
- **Local Software:** Config error, client bug, stale database

## Step 3: Progressive Action

| Level | Condition                               | Action                                                                                   |
| :---- | :-------------------------------------- | :--------------------------------------------------------------------------------------- |
| **1** | Service crashed, no error pattern match | `sudo systemctl restart <service>` — wait 2 min, verify                                  |
| **2** | JWT auth failures between EL↔CL         | Re-generate JWT secret, restart **both** EL and CL                                       |
| **2** | Stale cache / pruning issues            | Clear local cache dirs, restart service                                                  |
| **3** | Known client consensus bug              | Client failover (e.g., Geth → Nethermind or Lighthouse → Nimbus). Update config, restart |
| **3** | Persistent DB corruption                | **Stop service, escalate to human operator**                                             |

### JWT Re-authentication Procedure

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

### Client Failover Procedure (EL Example: Geth → Nethermind)

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

## Step 4: Verification

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
