Arbitrum Nitro
=========================

This package provides Arbitrum Nitro, the official Arbitrum node implementation, packaged for Ethereum on ARM.

Services
--------

This package installs a single systemd service that can be configured for different networks. The service is disabled by default.

- ``nitro.service``

To enable the service, run:
    sudo systemctl enable --now nitro.service

Configuration
-------------

Configuration arguments are defined in the environment file located in ``/etc/ethereum/``.

- ``/etc/ethereum/nitro.conf``

You can edit this file to customize the arguments passed to the Nitro binary, including the network selection (e.g., ``--chain-id``).

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.arbitrum``

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://nitro.ethereum.org
