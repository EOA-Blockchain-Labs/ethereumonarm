Vouch
================

This package provides Vouch, a tool for managing validator keys and acting as a multi-node validator client, packaged for Ethereum on ARM.

Services
--------

This package installs a single systemd service. The service is disabled by default.

- ``vouch.service``

To enable the service, run:
    sudo systemctl enable --now vouch.service

Configuration
-------------

Configuration files are located in ``/etc/ethereum/vouch/``.

- ``/etc/ethereum/vouch/vouch.yml`` (Main configuration file)

The service runs with ``--base-dir /etc/ethereum/vouch``, so it looks for configuration and certificates in that directory.

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://github.com/attestantio/vouch
