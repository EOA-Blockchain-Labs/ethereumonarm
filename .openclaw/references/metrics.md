# Prometheus Metrics Endpoints — Reference

The monitoring stack scrapes these endpoints every 15s (see `prometheus.yml`):

| Client/Exporter         | Metrics Port | Metrics Path                |
| :---------------------- | :----------- | :-------------------------- |
| Geth                    | 6060         | `/debug/metrics/prometheus` |
| Erigon                  | 5050         | `/debug/metrics/prometheus` |
| Nethermind              | 7070         | `/metrics`                  |
| Besu                    | 9545         | `/metrics`                  |
| Reth                    | 9001         | `/`                         |
| Lighthouse (beacon)     | 5054         | `/metrics`                  |
| Lighthouse (validator)  | 5064         | `/metrics`                  |
| Prysm (beacon)          | 8080         | `/metrics`                  |
| Prysm (validator)       | 8081         | `/metrics`                  |
| Teku                    | 8009         | `/metrics`                  |
| Teku (validator)        | 8010         | `/metrics`                  |
| Nimbus CL               | 8008         | `/metrics`                  |
| Lodestar (beacon)       | 4040         | `/metrics`                  |
| Lodestar (validator)    | 4041         | `/metrics`                  |
| Grandine (beacon) ⚠️    | 5054         | `/metrics`                  |
| Grandine (validator) ⚠️ | 8009         | `/metrics`                  |

> | Obol Charon | 3620 | `/metrics` |
> | SSV | 15000 | `/metrics` |
> | Node Exporter | 9100 | `/metrics` |
> | Prometheus | 9090 | `/metrics` |
> | Ethereum Metrics Exporter | 9095 | `/metrics` |
> | Validator Metrics Exporter | 9096 | `/metrics` |
> | Commit-Boost | 10000 | `/metrics` |

## Active Prometheus Alerts

The `alerts.yml` defines these rules (deployed via `ethereumonarm-monitoring-extras`):

| Alert               | Expression                          | Duration | Severity |
| :------------------ | :---------------------------------- | :------- | :------- |
| `InstanceDown`      | `up == 0`                           | 1m       | critical |
| `HostHighCpuLoad`   | CPU idle < 20% (averaged)           | 5m       | warning  |
| `HostOutOfMemory`   | Available memory < 10%              | 2m       | warning  |
| `HostHighDiskUsage` | Available disk < 10% (non-readonly) | 2m       | warning  |
