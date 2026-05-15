# staking-monitor

Telegram health monitoring and alerting for Ethereum staking infrastructure
running on **Ethereum on ARM** (Rock 5B/5B+, Orange Pi 5 Plus and NanoPC-T6).

```
staking-monitor/
├── obol-monitor/        # DVT cluster monitoring for Obol + control nodes
└── validator-monitor/   # Standalone validator duty monitoring
```

## obol-monitor

Full monitoring stack for an Obol DVT cluster (Obol nodes + control nodes).

```bash
cd obol-monitor
bash install.sh obol              # on each Obol node
bash install.sh control           # on the active control node
bash install.sh control-failover  # on the failover control node
```

See obol-monitor/README.md for full documentation.

## validator-monitor

Standalone validator duty monitor for any Ethereum validator node with a
local beacon client. Does not require an Obol cluster.

```bash
cd validator-monitor
bash install.sh
```

See validator-monitor/README.md for full documentation.
