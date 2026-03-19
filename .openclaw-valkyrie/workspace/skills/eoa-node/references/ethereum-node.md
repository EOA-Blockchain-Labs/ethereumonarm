# What is an Ethereum Node

## Overview

An Ethereum node is a computer running Ethereum client software that
participates in the Ethereum peer-to-peer network. Nodes verify
transactions, maintain the blockchain ledger, and serve data to
applications and other nodes.

Since The Merge (September 2022), running an Ethereum node requires
two pieces of software running simultaneously:

- **Execution Layer (EL) client** — processes transactions, executes
  smart contracts, maintains the state database, serves JSON-RPC.
- **Consensus Layer (CL) client** — follows the Proof-of-Stake beacon
  chain, determines the canonical head of the chain, guides the EL.

Neither client works alone. They communicate via the Engine API over
an authenticated connection secured by a shared JWT secret located at
`/etc/ethereum/jwtsecret`.

## Full Node vs Archive Node

### Full Node

A full node validates and follows the live chain but only retains a
recent window of historical state (the last ~8,192 blocks after the
Pectra upgrade, May 2025). Older state is pruned to save disk space.

**What it can do:**
- Validate all new blocks and transactions
- Serve current account balances and contract state
- Answer most JSON-RPC queries
- Participate in the network and support decentralization

**What it cannot do:**
- Answer queries about account balances or contract state at arbitrary
  historical blocks older than the retained window

**Disk requirements (EL only, approximate):**
- Geth: ~1.1 TB
- Nethermind: ~900 GB
- Besu: ~1.1 TB
- Reth: ~1.2 TB
- Erigon (pruned): ~2 TB

**Best for:** solo staking, interacting with Ethereum, supporting the
network, running a validator.

---

### Archive Node

An archive node is a full node with pruning disabled. It retains every
historical state since the genesis block, making it possible to query
any account balance or contract state at any block in history.

**What it adds over a full node:**
- Complete historical state for every block since genesis
- Immediate responses to historical queries (no re-execution needed)
- Useful for block explorers, analytics, wallets, dApp backends

**Disk requirements (EL only, approximate as of 2025):**
- Geth: ~13–14 TB
- Besu: ~14 TB
- Nethermind: ~12 TB
- Erigon: ~2.5 TB ← most efficient for archive on ARM64
- Reth: ~2.5 TB

**Best for:** block explorers, chain analytics, dApp infrastructure,
historical data queries.

---

## Which Clients to Choose

### For a Full Node
Any EL + any CL combination works. Recommended on ARM64:
- **Lowest RAM:** nimbus-beacon + nethermind
- **Most tested:** lighthouse-beacon + geth
- **Good alternative:** lighthouse-beacon + besu

### For an Archive Node
The execution client choice is critical — it determines disk usage:
- **Recommended:** erigon (~2.5 TB, most practical on ARM64)
- **Alternative:** reth (~2.5 TB, newer, Rust-based)
- **Avoid for archive on ARM64:** geth (~14 TB, impractical)

Any consensus client works with an archive execution client.
The consensus layer data is the same regardless of node type (~200 GB).

---

## Testnets

Ethereum on ARM supports two testnets:

- **Hoodi** — current long-term testnet, recommended for testing
- **Sepolia** — stable testnet, widely supported

Testnet nodes use the same client software but different service names
and data directories. See execution-clients.md and consensus-clients.md
for testnet service name conventions.

---

## JWT Secret

All client pairs communicate via JWT authentication.
Location on Ethereum on ARM: `/etc/ethereum/jwtsecret`

All EOA systemd unit files are pre-configured to use this path.
No manual JWT setup is required on a fresh EOA installation.

---

## Config Files

All client configuration is in `/etc/ethereum/`:
- `/etc/ethereum/geth.conf`
- `/etc/ethereum/lighthouse-beacon.conf`
- `/etc/ethereum/geth-hoodi.conf`
- `/etc/ethereum/lighthouse-beacon-hoodi.conf`
- etc.

Edit the relevant `.conf` file to change client parameters, then
restart the service for changes to take effect.
