# 🦄 Ethereum Validator Metrics Exporter 🦄

A Prometheus metrics exporter for Ethereum validators to track balance, last attested slot and total withdrawn via the [beaconcha.in API](https://beaconcha.in/api/v1/docs/index.html).

## Usage

Ethereum Validator Metrics Exporter requires a config file. An example file can be found in the [example_config.yaml](https://github.com/ethpandaops/ethereum-validator-metrics-exporter/blob/master/example_config.yaml).

```text
A tool to export the ethereum validator state

Usage:
  ethereum-validator-metrics-exporter [flags]

Flags:
      --config string   config file (default is config.yaml) (default "config.yaml")
  -h, --help            help for ethereum-validator-metrics-exporter
```

## Requirements

If you're requesting a large number of validators or lowering the `global.checkInterval` config, you may need need to signup for a paid plan on [beaconcha.in](https://beaconcha.in/pricing).

## Configuration

Ethereum Validator Metrics Exporter relies entirely on a single `yaml` config file.

| Name | Default | Description |
| --- | --- | --- |
| global.logging | `warn` | Log level (`panic`, `fatal`, `warn`, `info`, `debug`, `trace`) |
| global.metricsAddr | `:9090` | The address the metrics server will listen on |
| global.namespace | `eth_validator` | The prefix added to every metric |
| global.checkInterval | `24h` | How often the service should check the beaconcha.in API |
| global.labels[] | | Key value pair of labels to add to every metric (optional) |
| beaconcha_in.endpoint | `https://beaconcha.in` | The endpoint of the beaconcha.in API |
| beaconcha_in.apikey | | The API key for the beaconcha.in API |
| beaconcha_in.maxRequestsPerMinute | `10` | The maximum number of requests per minute to the beaconcha.in API. Raise higher if on paid plan. |
| beaconcha_in.batchSize | `50` | The number of validators to request per batch. Max is `100` but may run into 414 URI too long on requests. |
| validators[] | | List of validators |
| validators[].pubkey | | The validator public key |
| validators[].labels[] | | Key value pair of labels to add to this validator only (optional) |

### Example

```yaml
global:
  logging: "debug" # panic,fatal,warn,info,debug,trace
  metricsAddr: ":9090"
  namespace: eth_validator
  checkInterval: 24h
  # optional labels applied to all metrics
  labels:
    extra: label

# Add your beaconcha.in API key here
# beaconcha_in:
#   apikey: 123

validators:
  - pubkey: 0x1234
    labels:
      type: acquaintance
      company: NSA
  - pubkey: 0x2345
    labels:
      extra: something
```

## Getting Started

### Download a release

Download the latest release from the [Releases page](https://github.com/ethpandaops/ethereum-validator-metrics-exporter/releases). Extract and run with:

```bash
./ethereum-validator-metrics-exporter --config your-config.yaml
```

### Docker

Available as a docker image at [ethpandaops/ethereum-validator-metrics-exporter](https://hub.docker.com/r/ethpandaops/ethereum-validator-metrics-exporter/tags)

#### Images

- `latest` - distroless, multiarch
- `latest-debian` - debian, multiarch
- `$version` - distroless, multiarch, pinned to a release (i.e. `0.4.0`)
- `$version-debian` - debian, multiarch, pinned to a release (i.e. `0.4.0-debian`)

#### Quick start

```bash
docker run -d  --name ethereum-validator-metrics-exporter -v $HOST_DIR_CHANGE_ME/config.yaml:/opt/ethereum-validator-metrics-exporter/config.yaml -p 9090:9090 -p 5555:5555 -it ethpandaops/ethereum-validator-metrics-exporter:latest --config /opt/ethereum-validator-metrics-exporter/config.yaml;
docker logs -f ethereum-validator-metrics-exporter;
```

### Kubernetes via Helm

[Read more](https://github.com/skylenet/ethereum-helm-charts/tree/master/charts/ethereum-validator-metrics-exporter)

```bash
helm repo add ethereum-helm-charts https://skylenet.github.io/ethereum-helm-charts

helm install ethereum-validator-metrics-exporter ethereum-helm-charts/ethereum-validator-metrics-exporter -f your_values.yaml
```

### Building from Source

Requires Go installed on your system.

1. Clone the repo

   ```sh
   go get github.com/ethpandaops/ethereum-validator-metrics-exporter
   ```

2. Change directories

   ```sh
   cd ./ethereum-validator-metrics-exporter
   ```

3. Build the binary

   ```sh  
    go build -o ethereum-validator-metrics-exporter .
   ```

4. Run the exporter

   ```sh  
    ./ethereum-validator-metrics-exporter
   ```

## Contributing

Contributions are greatly appreciated! Pull requests will be reviewed and merged promptly if you're interested in improving the exporter!

1. Fork the project
2. Create your feature branch:
    - `git checkout -b feat/new-metric-profit`
3. Commit your changes:
    - `git commit -m 'feat(profit): Export new metric: profit`
4. Push to the branch:
    -`git push origin feat/new-metric-profit`
5. Open a pull request

### Running locally

#### Backend

```bash
go run main.go --config your_config.yaml
```
