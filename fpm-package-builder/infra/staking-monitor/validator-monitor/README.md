# validator-monitor

Standalone Telegram alerting for Ethereum validator duties — missed attestations,
missed block proposals, and successful proposals. Works on any validator node
with a local beacon client, independent of any DVT setup.

## Install

```bash
bash install.sh
```

Installs to /home/ethereum/.validator-monitor/

## What it monitors

- Missed attestations per validator (with recovery alerts)
- Mass missed attestations (≥ MASS_MISS_THRESHOLD, 6h lock)
- Missed block proposals
- Successful block proposals (🎉)

See the parent staking-monitor/README.md for full threshold reference.
