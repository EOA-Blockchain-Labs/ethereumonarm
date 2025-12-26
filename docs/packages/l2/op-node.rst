Op-Node
==================

This package provides op-node, the rollup client for the Optimism protocol, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks. The services are disabled by default.

- ``op-node.service`` (Generic/Default)
- ``op-node-base.service`` (Base Mainnet)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- ``/etc/ethereum/op-node.conf``
- ``/etc/ethereum/op-node-base.conf``

You can edit these files to customize the arguments passed to the op-node binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.op-node``

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://github.com/ethereum-optimism/optimism
