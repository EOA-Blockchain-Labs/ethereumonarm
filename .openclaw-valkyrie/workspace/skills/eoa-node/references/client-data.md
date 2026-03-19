# Client Data Directories — Ethereum on ARM

This file defines where each client stores its blockchain data.
The agent uses this to calculate disk usage per client and to delete
old data when the user switches clients or wants to free disk space.

---

## Directory Naming Convention

For most clients, the home directory depends on the network:
- Mainnet   → base home directory (e.g. `/home/ethereum/.nimbus-beacon`)
- Hoodi     → base home + `-hoodi`  (e.g. `/home/ethereum/.nimbus-beacon-hoodi`)
- Sepolia   → base home + `-sepolia` (e.g. `/home/ethereum/.nimbus-beacon-sepolia`)

Lighthouse is the exception — it always uses `/home/ethereum/.lighthouse`
regardless of network, with networks separated inside:
- `/home/ethereum/.lighthouse/mainnet/`
- `/home/ethereum/.lighthouse/hoodi/`
- `/home/ethereum/.lighthouse/sepolia/`

---

## Consensus Clients

| Client     | Mainnet Home                      | Testnet Home                          | Database Path                                          |
|------------|-----------------------------------|---------------------------------------|--------------------------------------------------------|
| Nimbus     | `/home/ethereum/.nimbus-beacon`   | `<home>-<network>`                    | `<home>/db/`                                           |
| Lighthouse | `/home/ethereum/.lighthouse`      | `/home/ethereum/.lighthouse`          | `/home/ethereum/.lighthouse/<network>/beacon/`         |
| Prysm      | `/home/ethereum/.prysm-beacon`    | `<home>-<network>`                    | `<home>/beaconchaindata/` and `<home>/blobs/`          |
| Teku       | `/home/ethereum/.teku`            | `<home>-<network>`                    | `<home>/beacon/`                                       |
| Lodestar   | `/home/ethereum/.lodestar-beacon` | `<home>-<network>`                    | `<home>/chain-db/`                                     |
| Grandine   | `/home/ethereum/.grandine-beacon` | `<home>-<network>`                    | `<home>/<network>/beacon/`                             |

### Resolved examples (consensus)

| Client     | Network  | Home Directory                              | Database Path                                                    |
|------------|----------|---------------------------------------------|------------------------------------------------------------------|
| Nimbus     | mainnet  | `/home/ethereum/.nimbus-beacon`             | `/home/ethereum/.nimbus-beacon/db/`                              |
| Nimbus     | hoodi    | `/home/ethereum/.nimbus-beacon-hoodi`       | `/home/ethereum/.nimbus-beacon-hoodi/db/`                        |
| Nimbus     | sepolia  | `/home/ethereum/.nimbus-beacon-sepolia`     | `/home/ethereum/.nimbus-beacon-sepolia/db/`                      |
| Lighthouse | mainnet  | `/home/ethereum/.lighthouse`               | `/home/ethereum/.lighthouse/mainnet/beacon/`                     |
| Lighthouse | hoodi    | `/home/ethereum/.lighthouse`               | `/home/ethereum/.lighthouse/hoodi/beacon/`                       |
| Lighthouse | sepolia  | `/home/ethereum/.lighthouse`               | `/home/ethereum/.lighthouse/sepolia/beacon/`                     |
| Prysm      | mainnet  | `/home/ethereum/.prysm-beacon`             | `/home/ethereum/.prysm-beacon/beaconchaindata/` + `/blobs/`      |
| Prysm      | hoodi    | `/home/ethereum/.prysm-beacon-hoodi`       | `/home/ethereum/.prysm-beacon-hoodi/beaconchaindata/` + `/blobs/`|
| Teku       | mainnet  | `/home/ethereum/.teku`                     | `/home/ethereum/.teku/beacon/`                                   |
| Teku       | hoodi    | `/home/ethereum/.teku-hoodi`               | `/home/ethereum/.teku-hoodi/beacon/`                             |
| Lodestar   | mainnet  | `/home/ethereum/.lodestar-beacon`          | `/home/ethereum/.lodestar-beacon/chain-db/`                      |
| Lodestar   | sepolia  | `/home/ethereum/.lodestar-beacon-sepolia`  | `/home/ethereum/.lodestar-beacon-sepolia/chain-db/`              |
| Grandine   | mainnet  | `/home/ethereum/.grandine-beacon`          | `/home/ethereum/.grandine-beacon/mainnet/beacon/`                |
| Grandine   | hoodi    | `/home/ethereum/.grandine-beacon-hoodi`    | `/home/ethereum/.grandine-beacon-hoodi/hoodi/beacon/`            |

---

## Execution Clients

| Client     | Mainnet Home                 | Testnet Home       | Database Path         |
|------------|------------------------------|--------------------|-----------------------|
| Geth       | `/home/ethereum/.ethereum`   | `<home>-<network>` | `<home>/geth/`        |
| Nethermind | `/home/ethereum/.nethermind` | `<home>-<network>` | `<home>/nethermind_db/` |
| Besu       | `/home/ethereum/.besu`       | `<home>-<network>` | `<home>/database/`    |
| Erigon     | `/home/ethereum/.erigon`     | `<home>-<network>` | `<home>/`             |
| Reth       | `/home/ethereum/.reth`       | `<home>-<network>` | `<home>/`             |

### Resolved examples (execution)

| Client     | Network  | Home Directory                          | Database Path                                    |
|------------|----------|-----------------------------------------|--------------------------------------------------|
| Geth       | mainnet  | `/home/ethereum/.ethereum`              | `/home/ethereum/.ethereum/geth/`                 |
| Geth       | hoodi    | `/home/ethereum/.ethereum-hoodi`        | `/home/ethereum/.ethereum-hoodi/geth/`           |
| Geth       | sepolia  | `/home/ethereum/.ethereum-sepolia`      | `/home/ethereum/.ethereum-sepolia/geth/`         |
| Nethermind | mainnet  | `/home/ethereum/.nethermind`            | `/home/ethereum/.nethermind/nethermind_db/`      |
| Nethermind | hoodi    | `/home/ethereum/.nethermind-hoodi`      | `/home/ethereum/.nethermind-hoodi/nethermind_db/`|
| Besu       | mainnet  | `/home/ethereum/.besu`                  | `/home/ethereum/.besu/database/`                 |
| Besu       | sepolia  | `/home/ethereum/.besu-sepolia`          | `/home/ethereum/.besu-sepolia/database/`         |
| Erigon     | mainnet  | `/home/ethereum/.erigon`                | `/home/ethereum/.erigon/`                        |
| Erigon     | hoodi    | `/home/ethereum/.erigon-hoodi`          | `/home/ethereum/.erigon-hoodi/`                  |
| Reth       | mainnet  | `/home/ethereum/.reth`                  | `/home/ethereum/.reth/`                          |
| Reth       | sepolia  | `/home/ethereum/.reth-sepolia`          | `/home/ethereum/.reth-sepolia/`                  |

---

## Checking Disk Usage for a Client

To check how much space a client database is using:

    du -sh <database path>

Examples:

    du -sh /home/ethereum/.ethereum/geth/
    du -sh /home/ethereum/.nimbus-beacon/db/
    du -sh /home/ethereum/.lighthouse/mainnet/beacon/

To check total home directory usage for a client:

    du -sh <home directory>

---

## Switching Clients — Disk Space Procedure

When the user wants to switch from one client to another, always:

1. Check disk space currently used by the old client database:

       du -sh <old client database path>

2. Check free disk space available:

       df -h /home/ethereum

3. If free space is insufficient to sync the new client, inform the
   user and ask if they want to delete the old client data to free
   space. Always ask — never delete data without explicit confirmation.

4. If the user confirms deletion, stop the old client service first,
   then delete only the database path (not the entire home directory
   unless the user specifically asks):

       sudo systemctl stop <old service>
       rm -rf <old client database path>

5. Proceed with starting the new client.

Always take the network into account — if the user is switching clients
on hoodi, use the hoodi home and database paths, not mainnet paths.
Never delete data for a different network than the one being switched.
