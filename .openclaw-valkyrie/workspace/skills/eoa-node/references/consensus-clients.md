# Consensus Layer Clients — Ethereum on ARM

## Service Name Convention

| Network         | MEV Boost | Service name pattern            | Example                         |
|-----------------|-----------|---------------------------------|---------------------------------|
| Mainnet         | No        | `<client>-beacon`               | `lighthouse-beacon`             |
| Mainnet         | Yes       | `<client>-beacon-mev`           | `lighthouse-beacon-mev`         |
| Hoodi testnet   | No        | `<client>-beacon-hoodi`         | `lighthouse-beacon-hoodi`       |
| Hoodi testnet   | Yes       | `<client>-beacon-mev-hoodi`     | `lighthouse-beacon-mev-hoodi`   |
| Sepolia testnet | No        | `<client>-beacon-sepolia`       | `lighthouse-beacon-sepolia`     |
| Sepolia testnet | Yes       | `<client>-beacon-mev-sepolia`   | `lighthouse-beacon-mev-sepolia` |

## Client Reference Table

| Client     | Mainnet Service     | APT Package  | RAM Usage | Special Notes                         |
|------------|---------------------|--------------|-----------|---------------------------------------|
| Lighthouse | `lighthouse-beacon` | `lighthouse` | Medium    | Most tested on ARM64, checkpoint sync |
| Prysm      | `prysm-beacon`      | `prysm`      | Medium    | Checkpoint sync                       |
| Nimbus     | `nimbus-beacon`     | `nimbus`     | Low ✅     | Requires trustedNodeSync before start |
| Teku       | `teku-beacon`       | `teku`       | High      | Java-based, checkpoint sync           |
| Lodestar   | `lodestar-beacon`   | `lodestar`   | Medium    | TypeScript, checkpoint sync           |
| Grandine   | `grandine-beacon`   | `grandine`   | Low ✅     | Rust-based, newer client              |

## Service Name Resolution

To resolve the correct service name, combine the base service name
with network and MEV suffixes:
```
mainnet, no MEV  → lighthouse-beacon
mainnet, MEV     → lighthouse-beacon-mev
hoodi, no MEV    → lighthouse-beacon-hoodi
hoodi, MEV       → lighthouse-beacon-mev-hoodi
sepolia, no MEV  → lighthouse-beacon-sepolia
sepolia, MEV     → lighthouse-beacon-mev-sepolia
```

Same pattern applies to all consensus clients.

## MEV Boost

MEV Boost variants (`-mev` suffix) are only for validator/staking setups.
Never use MEV variants for full nodes or archive nodes.

When using a `-mev` consensus service, the `mev-boost` service must be
running first. See `references/mev-boost.md` for full details.

## Checkpoint Sync

All CL clients on EOA are pre-configured with checkpoint sync.
This means the beacon chain syncs in minutes, not days.

Checkpoint sync URLs:
- Mainnet : `https://sync-mainnet.beaconcha.in`
- Hoodi   : `https://checkpoint-sync.hoodi.ethpandaops.io`
- Sepolia : `https://checkpoint-sync.sepolia.ethpandaops.io`

EOA configures the appropriate URL automatically per network.

## Nimbus Special Procedure

Nimbus requires a trusted node sync before the first start.
Do not skip this step for Nimbus. Run before starting the nimbus
beacon service:

Mainnet:
```bash
nimbus_beacon_node trustedNodeSync \\
  --network=mainnet \\
  --data-dir=/home/ethereum/.nimbus-beacon \\
  --trusted-node-url=https://sync-mainnet.beaconcha.in \\
  --backfill=false
```

Hoodi testnet:
```bash
nimbus_beacon_node trustedNodeSync \\
  --network=hoodi \\
  --data-dir=/home/ethereum/.nimbus-beacon-hoodi \\
  --trusted-node-url=https://checkpoint-sync.hoodi.ethpandaops.io \\
  --backfill=false
```

Sepolia testnet:
```bash
nimbus_beacon_node trustedNodeSync \\
  --network=sepolia \\
  --data-dir=/home/ethereum/.nimbus-beacon-sepolia \\
  --trusted-node-url=https://checkpoint-sync.sepolia.ethpandaops.io \\
  --backfill=false
```

## Beacon API Ports (default)

All CL clients expose REST API on `http://localhost:5052`

## Config Files Location

`/etc/ethereum/<service-name>.conf`

Examples:
- `/etc/ethereum/lighthouse-beacon.conf`
- `/etc/ethereum/lighthouse-beacon-hoodi.conf`
- `/etc/ethereum/lighthouse-beacon-mev.conf`
- `/etc/ethereum/nimbus-beacon.conf`
