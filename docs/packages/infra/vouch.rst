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

The service runs with ``--base-dir /etc/ethereum/vouch``, so it looks for configuration. You can edit this file to customize the Vouch configuration.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/etc/ethereum/vouch``

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://github.com/attestantio/vouch
