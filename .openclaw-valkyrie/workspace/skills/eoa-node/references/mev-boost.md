# MEV Boost — Ethereum on ARM

## What is MEV Boost

MEV Boost is an implementation of proposer-builder separation (PBS) for
Ethereum validators. Instead of building blocks locally, the validator
outsources block building to a competitive marketplace of builders via
relays. Builders optimize blocks for maximum extractable value (MEV) and
share the proceeds with the validator as higher block rewards.

PoS node operators running MEV Boost must run it as a sidecar alongside
their beacon node. The consensus client proposes the most profitable block
received from MEV Boost to the Ethereum network. 

## Important: Full Node vs Validator

MEV Boost is only relevant for **validators (staking)**. If the user is
running a full node or archive node without validating, do not start the
mev-boost service — it serves no purpose and wastes resources.

## EOA Service Names

| Network  | Service name     |
|----------|------------------|
| Mainnet  | `mev-boost`      |
| Hoodi    | `mev-boost-hoodi`|
| Sepolia  | `mev-boost-sepolia`|

## How it Works on EOA

On Ethereum on ARM, MEV Boost is pre-installed and pre-configured with
relays. No manual relay configuration is needed. The service connects
the consensus client (running with a `-mev` service variant) to the
relay network.

MEV Boost listens on `localhost:18550` by default. The consensus client
connects to it via the Builder API. 

## Starting MEV Boost

Always start mev-boost BEFORE the consensus client:
```bash
# Mainnet
sudo systemctl start mev-boost
sleep 5
sudo systemctl start <CLIENT>-beacon-mev

# Hoodi testnet
sudo systemctl start mev-boost-hoodi
sleep 5
sudo systemctl start <CLIENT>-beacon-mev-hoodi

# Sepolia testnet
sudo systemctl start mev-boost-sepolia
sleep 5
sudo systemctl start <CLIENT>-beacon-mev-sepolia
```

## Stopping MEV Boost

Stop the consensus client first, then mev-boost:
```bash
sudo systemctl stop <CLIENT>-beacon-mev
sudo systemctl stop mev-boost
```

## Full Start Order (with MEV Boost)

When starting a validator setup with MEV Boost the correct order is:

1. mev-boost service
2. consensus client (-mev variant)
3. execution client

## Check MEV Boost Status
```bash
sudo systemctl status mev-boost
sudo journalctl -u mev-boost -n 30
```

## Config File

`/etc/ethereum/mev-boost.conf`

Relays are pre-configured by EOA. To view configured relays:
```bash
sudo systemctl cat mev-boost
```

## Relay Information

Adding more relays increases the chance of getting a high-bid block but
also increases the risk of adding a problematic relay. More relays means
more competition and potentially higher rewards, but also more trust
assumptions. 

EOA pre-configures a curated set of public relays per network. The user
can edit `/etc/ethereum/mev-boost.conf` to add or remove relays if
needed, then restart the service.

## APT Package
```bash
sudo apt-get install mev-boost
```
