Ethereum Validator Metrics Exporter
==============================================

This package provides the Ethereum Validator Metrics Exporter, a Prometheus exporter for Ethereum validator metrics, packaged for Ethereum on ARM.

Services
--------

This package installs a single systemd service. The service is disabled by default.

- ``ethereum-validator-metrics-exporter.service``

To enable the service, run:
    sudo systemctl enable --now ethereum-validator-metrics-exporter.service

Configuration
-------------

Configuration arguments are defined in the YAML file located in ``/etc/ethereum/``.

- ``/etc/ethereum/validator-metrics-exporter.yaml``

You can edit this file to configure the exporter, including endpoints and metrics settings.

Data Directories
----------------

This package does not store persistent data.

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://github.com/ethpandaops/ethereum-validator-metrics-exporter
