# Consensus Layer Clients — Reference

Quick-reference for all CL clients packaged by Ethereum on ARM.
All clients run as `User=ethereum` via systemd, sourcing their config from
`/etc/ethereum/<service>.conf` as an `ARGS="..."` environment variable.

> [!IMPORTANT]
> All Ethereum on ARM CL clients are configured with the Beacon REST API on
> port **5052** by default. This is the standard port for health checks and
> sync queries regardless of which CL client is active.

---

## Lighthouse

| Property           | Value                                        |
| :----------------- | :------------------------------------------- |
| **Package**        | `lighthouse`                                  |
| **Binary**         | `/usr/bin/lighthouse`                          |
| **Beacon service** | `lighthouse-beacon[-<network>][-mev].service`  |
| **Validator**      | `lighthouse-validator[-<network>][-mev].service` |
| **Config dir**     | `/etc/ethereum/`                               |
| **Data dir**       | Default (`/home/ethereum/.lighthouse`)         |
| **Beacon API**     | `http://127.0.0.1:5052` (default)              |
| **Auth-RPC EL**    | `http://127.0.0.1:8551`                       |
| **JWT**            | `--execution-jwt /etc/ethereum/jwtsecret`      |
| **Metrics port**   | `5054` (beacon), `5064` (validator)            |
| **Metrics path**   | `/metrics`                                    |
| **P2P port**       | `9000` TCP/UDP                                |
| **MEV-Boost**      | `--builder http://localhost:18550`             |

### Default Config (Mainnet + MEV)

```bash
ARGS="beacon \
    --http \
    --execution-endpoint http://127.0.0.1:8551 \
    --execution-jwt /etc/ethereum/jwtsecret \
    --metrics \
    --checkpoint-sync-url https://sync-mainnet.beaconcha.in \
    --prune-payloads false \
    --builder http://localhost:18550"
```

### Service Variants

| Variant                          | Network  | MEV   |
| :------------------------------- | :------- | :---- |
| `lighthouse-beacon`              | Mainnet  | No    |
| `lighthouse-beacon-mev`          | Mainnet  | Yes   |
| `lighthouse-beacon-sepolia`      | Sepolia  | No    |
| `lighthouse-beacon-sepolia-mev`  | Sepolia  | Yes   |
| `lighthouse-beacon-hoodi`        | Hoodi    | No    |
| `lighthouse-beacon-hoodi-mev`    | Hoodi    | Yes   |
| `lighthouse-beacon-gnosis`       | Gnosis   | No    |

Corresponding `lighthouse-validator-*` services exist for each variant.

### Key Log Patterns

```bash
# Sync progress
sudo journalctl -u lighthouse-beacon-mev --since "5 min ago" | grep -i 'synced'
# Attestations
sudo journalctl -u lighthouse-validator-mev --since "5 min ago" | grep -i 'attestation'
# Errors
sudo journalctl -u lighthouse-beacon-mev --since "1 hour ago" | grep -iE 'error|crit|warn'
# Builder/MEV
sudo journalctl -u lighthouse-beacon-mev --since "1 hour ago" | grep -i 'builder'
```

---

## Nimbus

| Property           | Value                                        |
| :----------------- | :------------------------------------------- |
| **Package**        | `nimbus`                                      |
| **Binary**         | `/usr/bin/nimbus_beacon_node`                  |
| **Beacon service** | `nimbus-beacon[-<network>][-mev].service`      |
| **Validator**      | `nimbus-validator[-<network>][-mev].service`   |
| **Data dir**       | `/home/ethereum/.nimbus-beacon`                |
| **Beacon API**     | `http://127.0.0.1:5052` (`--rest`)             |
| **Auth-RPC EL**    | `http://127.0.0.1:8551`                       |
| **JWT**            | `--jwt-secret=/etc/ethereum/jwtsecret`         |
| **Metrics port**   | `8008`                                        |
| **Metrics path**   | `/metrics`                                    |
| **P2P port**       | `9000` TCP/UDP                                |
| **MEV-Boost**      | `--payload-builder=true --payload-builder-url=http://localhost:18550` |

### Default Config (Mainnet + MEV)

```bash
ARGS="--network=mainnet \
--data-dir=/home/ethereum/.nimbus-beacon \
--web3-url=http://127.0.0.1:8551 \
--rest \
--jwt-secret=/etc/ethereum/jwtsecret \
--payload-builder=true \
--payload-builder-url=http://localhost:18550 \
--metrics"
```

### Key Log Patterns

```bash
# Sync
sudo journalctl -u nimbus-beacon-mev --since "5 min ago" | grep -i 'slot'
# Attestations
sudo journalctl -u nimbus-beacon-mev --since "5 min ago" | grep -i 'attestation'
# Errors
sudo journalctl -u nimbus-beacon-mev --since "1 hour ago" | grep -iE 'error|crit|fatal'
```

> [!NOTE]
> Nimbus combines beacon and validator in a single process by default.
> The separate `nimbus-validator-*` services are for DVT configurations (Obol/SSV).

---

## Teku

| Property           | Value                                        |
| :----------------- | :------------------------------------------- |
| **Package**        | `teku`                                        |
| **Binary**         | `/usr/bin/teku`                                |
| **Beacon service** | `teku-beacon[-<network>][-mev].service`        |
| **Validator**      | `teku-validator[-<network>][-mev].service`     |
| **Data dir**       | `/home/ethereum/.teku`                         |
| **Beacon API**     | `http://127.0.0.1:5052` (`--rest-api-port=5052`) |
| **Auth-RPC EL**    | `http://127.0.0.1:8551`                       |
| **JWT**            | `--ee-jwt-secret-file=/etc/ethereum/jwtsecret` |
| **Metrics port**   | `8009` (beacon), `8010` (validator)            |
| **Metrics path**   | `/metrics`                                    |
| **P2P port**       | `9000` TCP/UDP                                |
| **MEV-Boost**      | `--builder-endpoint=http://localhost:18550`     |

### Default Config (Mainnet + MEV)

```bash
ARGS="--network=mainnet \
--data-path=/home/ethereum/.teku \
--ee-endpoint=http://127.0.0.1:8551 \
--ee-jwt-secret-file=/etc/ethereum/jwtsecret \
--metrics-enabled \
--metrics-port=8009 \
--initial-state=https://sync-mainnet.beaconcha.in \
--rest-api-enabled=true \
--rest-api-port=5052 \
--builder-endpoint=http://localhost:18550"
```

### Key Log Patterns

```bash
# Sync
sudo journalctl -u teku-beacon-mev --since "5 min ago" | grep -i 'slot'
# Validator
sudo journalctl -u teku-validator-mev --since "5 min ago" | grep -i 'attestation'
# Errors
sudo journalctl -u teku-beacon-mev --since "1 hour ago" | grep -iE 'error|warn|exception'
```

---

## Prysm

| Property           | Value                                        |
| :----------------- | :------------------------------------------- |
| **Package**        | `prysm`                                       |
| **Binary**         | `/usr/bin/beacon-chain` / `/usr/bin/validator`  |
| **Beacon service** | `prysm-beacon[-<network>][-mev].service`       |
| **Validator**      | `prysm-validator[-<network>][-mev].service`    |
| **Data dir**       | `/home/ethereum/.prysm-beacon`                 |
| **Beacon API**     | `http://127.0.0.1:5052` (`--grpc-gateway-port=5052`) |
| **gRPC port**      | `4000`                                        |
| **Auth-RPC EL**    | `http://127.0.0.1:8551`                       |
| **JWT**            | `--jwt-secret=/etc/ethereum/jwtsecret`         |
| **Metrics port**   | `8080` (beacon), `8081` (validator), `8082` (slasher) |
| **Metrics path**   | `/metrics`                                    |
| **P2P port**       | `13000` TCP, `12000` UDP                      |
| **MEV-Boost**      | `--http-mev-relay=http://localhost:18550`       |

### Default Config (Mainnet + MEV)

```bash
ARGS="--datadir=/home/ethereum/.prysm-beacon \
--execution-endpoint=http://127.0.0.1:8551 \
--jwt-secret=/etc/ethereum/jwtsecret \
--accept-terms-of-use \
--checkpoint-sync-url=https://sync-mainnet.beaconcha.in \
--genesis-beacon-api-url=https://sync-mainnet.beaconcha.in \
--grpc-gateway-port=5052 \
--http-mev-relay=http://localhost:18550"
```

### Key Log Patterns

```bash
# Sync
sudo journalctl -u prysm-beacon-mev --since "5 min ago" | grep -i 'synced'
# Attestations
sudo journalctl -u prysm-validator-mev --since "5 min ago" | grep -i 'attestation'
# Errors
sudo journalctl -u prysm-beacon-mev --since "1 hour ago" | grep -iE 'error|crit|fatal'
```

---

## Lodestar

| Property           | Value                                        |
| :----------------- | :------------------------------------------- |
| **Package**        | `lodestar`                                    |
| **Binary**         | `/usr/bin/lodestar`                            |
| **Beacon service** | `lodestar-beacon[-<network>][-mev].service`    |
| **Validator**      | `lodestar-validator[-<network>][-mev].service`  |
| **Data dir**       | `/home/ethereum/.lodestar-beacon`              |
| **Beacon API**     | `http://127.0.0.1:5052` (`--rest.port 5052`)   |
| **Auth-RPC EL**    | `http://127.0.0.1:8551`                       |
| **JWT**            | `--jwt-secret /etc/ethereum/jwtsecret`         |
| **Metrics port**   | `4040` (beacon), `4041` (validator)            |
| **Metrics path**   | `/metrics`                                    |
| **P2P port**       | `9000` TCP/UDP                                |
| **MEV-Boost**      | `--builder --builder.url http://localhost:18550` |

### Default Config (Mainnet + MEV)

```bash
ARGS="beacon \
    --network mainnet \
    --dataDir /home/ethereum/.lodestar-beacon \
    --execution.urls http://127.0.0.1:8551 \
    --jwt-secret /etc/ethereum/jwtsecret \
    --checkpointSyncUrl https://sync-mainnet.beaconcha.in \
    --rest true \
    --rest.port 5052 \
    --metrics \
    --metrics.port 4040 \
    --builder \
    --builder.url http://localhost:18550"
```

### Key Log Patterns

```bash
# Sync
sudo journalctl -u lodestar-beacon-mev --since "5 min ago" | grep -i 'synced'
# Attestations
sudo journalctl -u lodestar-validator-mev --since "5 min ago" | grep -i 'attestation'
# Errors
sudo journalctl -u lodestar-beacon-mev --since "1 hour ago" | grep -iE 'error|crit|fatal'
```

---

## Grandine

| Property           | Value                                        |
| :----------------- | :------------------------------------------- |
| **Package**        | `grandine`                                    |
| **Binary**         | `/usr/bin/grandine`                            |
| **Beacon service** | `grandine-beacon[-<network>][-mev].service`    |
| **Validator**      | `grandine-validator[-<network>][-mev].service`  |
| **Data dir**       | `/home/ethereum/.grandine-beacon`              |
| **Beacon API**     | `http://127.0.0.1:5052` (default)              |
| **Auth-RPC EL**    | `http://localhost:8551`                        |
| **JWT**            | `--jwt-secret /etc/ethereum/jwtsecret`         |
| **Metrics port**   | `5054` (beacon), `8009` (validator)            |
| **Metrics path**   | `/metrics`                                    |
| **P2P port**       | `9000` TCP/UDP                                |
| **MEV-Boost**      | `--builder-url http://localhost:18550`          |

### Default Config (Mainnet + MEV)

```bash
ARGS="--data-dir /home/ethereum/.grandine-beacon \
--eth1-rpc-urls http://localhost:8551 \
--jwt-secret /etc/ethereum/jwtsecret \
--checkpoint-sync-url https://sync-mainnet.beaconcha.in \
--builder-url http://localhost:18550 \
--metrics"
```

### Key Log Patterns

```bash
# Sync
sudo journalctl -u grandine-beacon-mev --since "5 min ago" | grep -i 'slot'
# Errors
sudo journalctl -u grandine-beacon-mev --since "1 hour ago" | grep -iE 'error|crit|fatal'
```

---

## MEV-Boost

| Property           | Value                                        |
| :----------------- | :------------------------------------------- |
| **Package**        | `mev-boost`                                   |
| **Binary**         | `/usr/bin/mev-boost`                           |
| **Service**        | `mev-boost.service`                            |
| **Config**         | `/etc/ethereum/mev-boost.conf`                 |
| **Listen port**    | `18550`                                       |
| **Status check**   | `curl http://127.0.0.1:18550/eth/v1/builder/status` |

### Service Variants

| Variant                | Config                       |
| :--------------------- | :--------------------------- |
| `mev-boost`            | `mev-boost.conf` (mainnet)   |
| `mev-boost-sepolia`    | `mev-boost-sepolia.conf`     |
| `mev-boost-hoodi`      | `mev-boost-hoodi.conf`       |

All CL clients connect to MEV-Boost on `http://localhost:18550`.

---

## Common Beacon API Commands (Any CL Client, Port 5052)

```bash
# Health check (200=synced, 206=syncing, 503=not initialized)
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5052/eth/v1/node/health

# Sync status
curl -s http://127.0.0.1:5052/eth/v1/node/syncing | jq '.data'

# Peer count
curl -s http://127.0.0.1:5052/eth/v1/node/peer_count | jq '.data'

# Node version
curl -s http://127.0.0.1:5052/eth/v1/node/version | jq '.data'

# Node identity
curl -s http://127.0.0.1:5052/eth/v1/node/identity | jq '.data'

# Head slot
curl -s http://127.0.0.1:5052/eth/v1/beacon/headers/head | jq '.data.header.message.slot'

# Finality checkpoints
curl -s http://127.0.0.1:5052/eth/v1/beacon/states/head/finality_checkpoints | jq '.data'

# Validator duties (epoch)
EPOCH=$(curl -s http://127.0.0.1:5052/eth/v1/beacon/headers/head | jq -r '.data.header.message.slot' | awk '{print int($1/32)}')
echo "Current epoch: ${EPOCH}"
```

---

## DVT Services

### Obol Charon

| Property        | Value                                |
| :-------------- | :----------------------------------- |
| **Service**     | `charon.service`                      |
| **Config**      | `/etc/ethereum/dvt/charon.conf`       |
| **Metrics port**| `3620`                               |
| **Metrics path**| `/metrics`                           |

Obol validator service variants: `<client>-validator[-<network>]-obol[-lido].service`

### SSV

| Property        | Value                                |
| :-------------- | :----------------------------------- |
| **Service**     | `ssv.service`                         |
| **Config**      | `/etc/ethereum/ssv.conf`              |
| **Metrics port**| `15000`                              |
| **Metrics path**| `/metrics`                           |

### Anchor (Sigp)

| Property        | Value                                |
| :-------------- | :----------------------------------- |
| **Service**     | `anchor.service`                      |
| **Config**      | `/etc/ethereum/anchor.conf`           |
