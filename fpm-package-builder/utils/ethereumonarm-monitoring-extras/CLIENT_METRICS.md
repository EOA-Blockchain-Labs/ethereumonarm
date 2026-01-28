# Ethereum Client Monitoring Configuration

This document lists the Prometheus metrics configuration for all supported Ethereum execution and consensus clients.

## Execution Layer Clients

| Client | Service Name | Default Metrics Port | Prometheus Job Name | Metrics Path | Config File | Metrics Enable Flag |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Geth** | `geth.service` | `6060` | `geth` | `/debug/metrics/prometheus` | `/etc/ethereum/geth.conf` | `--metrics` |
| **Erigon** | `erigon.service` | `5050` | `erigon` | `/debug/metrics/prometheus` | `/etc/ethereum/erigon.conf` | `--metrics` (port: `--metrics.port=5050`) |
| **Nethermind** | `nethermind.service` | `7070` | `nethermind` | `/metrics` | `/etc/ethereum/nethermind.conf` | `--Metrics.Enabled true` (port: `--Metrics.ExposePort 7070`) |
| **Besu** | `besu.service` | `9545` | `besu` | `/metrics` | `/etc/ethereum/besu.conf` | `--metrics-enabled` |
| **Reth** | `reth.service` | `9001` | `reth` | `/` | `/etc/ethereum/reth.conf` | `--metrics` |
| **Ethrex** | `ethrex.service` | `3701` | `ethrex` | `/metrics` | `/etc/ethereum/ethrex.conf` | `--metrics` (port: `--metrics.port 3701`) |
| **Nimbus** | `nimbus-execution` | `8008` | `nimbus_execution` | `/metrics` | N/A | Default |

## Consensus Layer Clients

| Client | Service Name | Default Metrics Port | Prometheus Job Name | Metrics Path | Config File | Metrics Enable Flag |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lighthouse** | `lighthouse-beacon.service` | `5054` | `lighthouse_beacon` | `/metrics` | `/etc/ethereum/lighthouse-beacon.conf` | `--metrics` |
| **Lighthouse** | `lighthouse-validator.service` | `5064` | `lighthouse_validator` | `/metrics` | `/etc/ethereum/lighthouse-validator.conf` | `--metrics` |
| **Prysm** | `prysm-beacon.service` | `8080` | `prysm_beacon` | `/metrics` | `/etc/ethereum/prysm-beacon.conf` | Default (port: 8080) |
| **Prysm** | `prysm-validator.service` | `8081` | `prysm_validator` | `/metrics` | `/etc/ethereum/prysm-validator.conf` | Default (port: 8081) |
| **Teku** | `teku-beacon.service` | `8009` | `teku` | `/metrics` | `/etc/ethereum/teku-beacon.conf` | `--metrics-enabled` (port: `--metrics-port=8009`) |
| **Teku** | `teku-validator.service` | `8010` | `teku_validator` | `/metrics` | `/etc/ethereum/teku-validator.conf` | `--metrics-enabled` (port: `--metrics-port=8010`) |
| **Nimbus** | `nimbus-beacon.service` | `8008` | `nimbus` | `/metrics` | `/etc/ethereum/nimbus-beacon.conf` | `--metrics` |
| **Lodestar** | `lodestar-beacon.service` | `4040` | `lodestar_beacon` | `/metrics` | `/etc/ethereum/lodestar-beacon.conf` | `--metrics` (port: `--metrics.port 4040`) |
| **Lodestar** | `lodestar-validator.service` | `4041` | `lodestar_validator` | `/metrics` | `/etc/ethereum/lodestar-validator.conf` | `--metrics` (port: `--metrics.port 4041`) |
| **Grandine** | `grandine-beacon.service` | `5054` | `grandine_beacon` | `/metrics` | `/etc/ethereum/grandine-beacon.conf` | `--metrics` |
| **Grandine** | `grandine-validator.service` | `8009` | `grandine_validator` | `/metrics` | `/etc/ethereum/grandine-validator.conf` | `--metrics` (port: `--metrics-port 8009`) |

## System Monitoring

| Component | Default Metrics Port | Prometheus Job Name | Metrics Path |
| :--- | :--- | :--- | :--- |
| **Node Exporter** | `9100` | `node_exporter` | `/metrics` |
| **Prometheus** | `9090` | `prometheus` | `/metrics` |
| **Ethereum Metrics Exporter** | `9095` | `ethereum_metrics_exporter` | `/metrics` |
| **Validator Metrics Exporter** | `9096` | `ethereum_validator_metrics_exporter` | `/metrics` |
