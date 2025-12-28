Status Node
======================

This package provides a Status Node (``statusd``), serving as a messenger, crypto wallet, and Web3 browser backend, packaged for Ethereum on ARM.

Services
--------

This package installs a single systemd service. The service is disabled by default.

- ``statusd.service``

To enable the service, run:
    sudo systemctl enable --now statusd.service

Configuration
-------------

Configuration arguments are defined in the environment file and JSON configuration located in ``/etc/ethereum/``.

- ``/etc/ethereum/statusd.conf``: Environment variables for the service.
- ``/etc/ethereum/statusd.json``: Main JSON configuration file for the node.

You can edit this file to customize the generic arguments passed to the statusd binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.status/status-go-mail``

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://status.im
