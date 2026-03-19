# Execution Layer Clients — Ethereum on ARM

## Service Name Convention

| Network  | Service name pattern         | Example       |
|----------|------------------------------|---------------|
| Mainnet  | `<client>`                   | `geth`        |
| Hoodi    | `<client>-hoodi`             | `geth-hoodi`  |
| Sepolia  | `<client>-sepolia`           | `geth-sepolia`|

## Client Reference Table

| Client      | Mainnet Service | APT Package  | Full Node Disk | Archive Disk | Archive Recommended |
|-------------|-----------------|--------------|----------------|--------------|---------------------|
| Geth        | `geth`          | `geth`       | ~1.1 TB        | ~13–14 TB    | ❌ too large         |
| Nethermind  | `nethermind`    | `nethermind` | ~900 GB        | ~12 TB       | ❌ too large         |
| Erigon      | `erigon`        | `erigon`     | ~2 TB          | ~2.5 TB      | ✅ best choice       |
| Besu        | `besu`          | `besu`       | ~1.1 TB        | ~14 TB       | ❌ too large         |
| Reth        | `reth`          | `reth`       | ~1.2 TB        | ~2.5 TB      | ✅ good alternative  |

## Service Name Resolution

To resolve the correct service name, combine client name + network suffix:
```
mainnet  → geth
hoodi    → geth-hoodi
sepolia  → geth-sepolia
```

Same pattern applies to all execution clients.

## RPC Ports (default)

All EL clients expose JSON-RPC on `http://localhost:8545`
Engine API (CL↔EL): `http://localhost:8551`

## Config Files Location

`/etc/ethereum/<service-name>.conf`

Examples:
- `/etc/ethereum/geth.conf`
- `/etc/ethereum/geth-hoodi.conf`
