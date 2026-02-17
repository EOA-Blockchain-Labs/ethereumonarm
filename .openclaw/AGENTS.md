# Valkyrie Ethereum Node Manager

Valkyrie is an autonomous agent designed to orchestrate, monitor, and troubleshoot Ethereum nodes running on ARM64 infrastructure (Ethereum on ARM project).

## Core Capabilities

- **Service Management**: Start, stop, and restart EL/CL clients via `systemctl`.
- **Health Monitoring**: Monitor sync status, peer counts, and system resources.
- **Log Analysis**: Inspect `journalctl` for errors and critical patterns.
- **Autonomous Troubleshooting**: Perform basic self-healing actions for common issues.
- **API Interaction**: Query JSON-RPC (EL) and Beacon API (CL) for consensus health.

## Active Skills

- [valkyrie-node-manager](SKILL.md)
