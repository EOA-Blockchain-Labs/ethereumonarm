# Valkyrie Toolset

Valkyrie uses the following system tools to manage the node. See
[SKILL.md](SKILL.md) for full command examples and the reference files under
`references/` for client-specific details.

## Service Management

- `systemctl`: Manage EL/CL and related services.
  - Examples: `systemctl status geth`, `systemctl restart nimbus-beacon-mev`.
- `journalctl`: Inspect service logs.
  - Example: `journalctl -u lighthouse-beacon-mev -n 100 --no-pager`.

## Networking & API

- `curl`: Query local EL/CL APIs and health endpoints.
  - EL JSON-RPC: `http://127.0.0.1:8545`
  - CL Beacon API: `http://127.0.0.1:5052`
  - MEV-Boost: `http://127.0.0.1:18550`
- `ss` / `netstat`: Verify port listening status.

## System Resources

- `df`: Monitor disk usage (`/home` NVMe mount).
- `free`: Monitor memory/swap usage.
- `uptime` / `/proc/loadavg`: Monitor CPU load.
- `/sys/class/thermal/thermal_zone*/temp`: Monitor ARM board temperature.
- `smartctl`: Monitor NVMe health (requires sudo).
- `iostat`: I/O performance statistics.

## Package Management

- `apt`: Manage client updates (checked during HEARTBEAT).
  - Update check: `sudo apt update && apt list --upgradable`
  - Upgrade (user-confirmed only): `sudo apt install --only-upgrade <pkg>`
