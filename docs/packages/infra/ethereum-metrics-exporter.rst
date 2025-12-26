Ethereum Metrics Exporter
====================================

This package provides the Ethereum Metrics Exporter, a client-agnostic tool for monitoring Ethereum nodes, packaged for Ethereum on ARM.

Services
--------

This package installs a single systemd service. The service is disabled by default.

- ``ethereum-metrics-exporter.service``

To enable the service, run:
    sudo systemctl enable --now ethereum-metrics-exporter.service

Configuration
-------------

Configuration arguments are defined in the YAML file located in ``/etc/ethereum/``.

- ``/etc/ethereum/eth-metrics.yml``

You can edit this file to configure the exporter, including endpoints and metrics settings.

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://github.com/ethpandaops/ethereum-metrics-exporter
