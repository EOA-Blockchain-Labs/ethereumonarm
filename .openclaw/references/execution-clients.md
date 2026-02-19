# Execution Layer Clients — Reference

Quick-reference for all EL clients packaged by Ethereum on ARM.
All clients run as `User=ethereum` via systemd, sourcing their config from
`/etc/ethereum/<service>.conf` as an `ARGS="..."` environment variable.

---

## Geth

| Property          | Value                                        |
| :---------------- | :------------------------------------------- |
| **Package**       | `geth`                                       |
| **Binary**        | `/usr/bin/geth`                               |
| **Service**       | `geth.service`                                |
| **Config**        | `/etc/ethereum/geth.conf`                     |
| **Data dir**      | Default (`/home/ethereum/.ethereum`)          |
| **JSON-RPC**      | `http://127.0.0.1:8545` (`--http`)            |
| **Auth-RPC**      | `http://127.0.0.1:8551`                       |
| **JWT**           | `--authrpc.jwtsecret=/etc/ethereum/jwtsecret` |
| **Metrics port**  | `6060` (pprof)                                |
| **Metrics path**  | `/debug/metrics/prometheus`                   |
| **P2P port**      | `30303` TCP/UDP                               |

### Default Config

```bash
ARGS="--metrics \
--metrics.expensive \
--pprof \
--http \
--authrpc.jwtsecret=/etc/ethereum/jwtsecret"
```

### Key Log Patterns

```bash
# Sync progress
sudo journalctl -u geth --since "5 min ago" | grep -i 'imported new'
# Peer connections
sudo journalctl -u geth --since "5 min ago" | grep -i 'peer'
# Errors
sudo journalctl -u geth --since "1 hour ago" | grep -iE 'error|fatal|panic'
# State pruning
sudo journalctl -u geth --since "1 hour ago" | grep -i 'prune'
```

### Network Variants

| Network  | Service       | Config                  |
| :------- | :------------ | :---------------------- |
| Mainnet  | `geth`        | `geth.conf`             |
| Sepolia  | `geth-sepolia`| `geth-sepolia.conf`     |
| Hoodi    | `geth-hoodi`  | `geth-hoodi.conf`       |

---

## Nethermind

| Property          | Value                                        |
| :---------------- | :------------------------------------------- |
| **Package**       | `nethermind`                                  |
| **Binary**        | `/usr/bin/nethermind`                          |
| **Service**       | `nethermind.service`                           |
| **Config**        | `/etc/ethereum/nethermind.conf`                |
| **Data dir**      | `/home/ethereum/.nethermind`                   |
| **JSON-RPC**      | `http://127.0.0.1:8545`                       |
| **Auth-RPC**      | `http://127.0.0.1:8551`                       |
| **JWT**           | `--JsonRpc.JwtSecretFile /etc/ethereum/jwtsecret` |
| **Metrics port**  | `7070`                                        |
| **Metrics path**  | `/metrics`                                    |
| **P2P port**      | `30303` TCP/UDP                               |

### Default Config

```bash
ARGS="--config mainnet \
--loggerConfigSource /opt/nethermind/NLog.config \
-dd /home/ethereum/.nethermind \
--JsonRpc.JwtSecretFile /etc/ethereum/jwtsecret \
--Metrics.Enabled true \
--Metrics.ExposePort 7070"
```

### Key Log Patterns

```bash
# Sync progress
sudo journalctl -u nethermind --since "5 min ago" | grep -i 'processed'
# Peers
sudo journalctl -u nethermind --since "5 min ago" | grep -i 'peer'
# Errors
sudo journalctl -u nethermind --since "1 hour ago" | grep -iE 'error|exception|fatal'
# DB operations
sudo journalctl -u nethermind --since "1 hour ago" | grep -i 'rocksdb'
```

---

## Besu

| Property          | Value                                        |
| :---------------- | :------------------------------------------- |
| **Package**       | `besu`                                        |
| **Binary**        | `/usr/bin/besu`                                |
| **Service**       | `besu.service`                                 |
| **Config**        | `/etc/ethereum/besu.conf`                      |
| **Data dir**      | `/home/ethereum/.besu`                         |
| **JSON-RPC**      | `http://127.0.0.1:8545` (`--rpc-http-enabled`) |
| **Auth-RPC**      | `http://127.0.0.1:8551`                       |
| **JWT**           | `--engine-jwt-secret=/etc/ethereum/jwtsecret`  |
| **Metrics port**  | `9545`                                        |
| **Metrics path**  | `/metrics`                                    |
| **P2P port**      | `30303` TCP/UDP                               |
| **Sync mode**     | `SNAP`                                        |
| **Storage**       | `BONSAI`                                      |

### Default Config

```bash
ARGS="--network=mainnet \
--data-path=/home/ethereum/.besu \
--sync-mode=SNAP \
--data-storage-format=BONSAI \
--rpc-http-enabled \
--engine-jwt-secret=/etc/ethereum/jwtsecret \
--metrics-enabled"
```

### Key Log Patterns

```bash
# Sync progress
sudo journalctl -u besu --since "5 min ago" | grep -i 'block'
# Errors
sudo journalctl -u besu --since "1 hour ago" | grep -iE 'error|exception'
# Bonsai storage
sudo journalctl -u besu --since "1 hour ago" | grep -i 'bonsai'
```

---

## Reth

| Property          | Value                                        |
| :---------------- | :------------------------------------------- |
| **Package**       | `reth`                                        |
| **Binary**        | `/usr/bin/reth`                                |
| **Service**       | `reth.service`                                 |
| **Config**        | `/etc/ethereum/reth.conf`                      |
| **Data dir**      | `/home/ethereum/.reth`                         |
| **JSON-RPC**      | `http://127.0.0.1:8545` (`--http`)             |
| **Auth-RPC**      | `http://127.0.0.1:8551`                       |
| **JWT**           | `--authrpc.jwtsecret /etc/ethereum/jwtsecret`  |
| **Metrics port**  | `9001`                                        |
| **Metrics path**  | `/`                                           |
| **P2P port**      | `30303` TCP/UDP                               |

### Default Config

```bash
ARGS="node \
--datadir /home/ethereum/.reth \
--authrpc.jwtsecret /etc/ethereum/jwtsecret \
--metrics \
--http \
--ws"
```

### Key Log Patterns

```bash
# Sync progress
sudo journalctl -u reth --since "5 min ago" | grep -i 'stage'
# Pipeline
sudo journalctl -u reth --since "5 min ago" | grep -i 'pipeline'
# Errors
sudo journalctl -u reth --since "1 hour ago" | grep -iE 'error|fatal|panic'
```

---

## Erigon

| Property          | Value                                        |
| :---------------- | :------------------------------------------- |
| **Package**       | `erigon`                                      |
| **Binary**        | `/usr/bin/erigon`                              |
| **Service**       | `erigon.service`                               |
| **Config**        | `/etc/ethereum/erigon.conf`                    |
| **Data dir**      | `/home/ethereum/.erigon`                       |
| **JSON-RPC**      | `http://0.0.0.0:8545` (`--http --http.addr=0.0.0.0`) |
| **Auth-RPC**      | `http://0.0.0.0:8551` (`--authrpc.addr=0.0.0.0`) |
| **JWT**           | `--authrpc.jwtsecret=/etc/ethereum/jwtsecret`  |
| **Metrics port**  | `5050`                                        |
| **Metrics path**  | `/debug/metrics/prometheus`                   |
| **P2P port**      | `30303` TCP/UDP                               |
| **WebSocket**     | `ws://0.0.0.0:8546`                           |
| **Private API**   | `localhost:8092`                               |

### Default Config

```bash
ARGS="--chain=mainnet \
--datadir=/home/ethereum/.erigon \
--prune.mode=full \
--authrpc.jwtsecret=/etc/ethereum/jwtsecret \
--authrpc.addr=0.0.0.0 \
--authrpc.port=8551 \
--http \
--http.addr=0.0.0.0 \
--http.port=8545 \
--http.api=engine,eth,net,web3 \
--ws \
--ws.port=8546 \
--metrics \
--metrics.port=5050 \
--private.api.addr=localhost:8092 \
--torrent.download.rate=40mb \
--torrent.upload.rate=4mb"
```

### Key Log Patterns

```bash
# Sync stages
sudo journalctl -u erigon --since "5 min ago" | grep -i 'stage'
# Torrent downloads
sudo journalctl -u erigon --since "5 min ago" | grep -i 'torrent'
# Errors
sudo journalctl -u erigon --since "1 hour ago" | grep -iE 'error|fatal|panic'
```

---

## Common API Commands (Any EL Client)

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

# Client version
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' | jq

# Chain ID
curl -s -X POST http://127.0.0.1:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' | jq
```
