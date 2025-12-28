Op-Geth
==================

This package provides op-geth, an execution client for the Optimism protocol, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks. The services are disabled by default.

- ``op-geth.service`` (Generic/Default)
- ``op-geth-base.service`` (Base Mainnet)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- ``/etc/ethereum/op-geth.conf``
- ``/etc/ethereum/op-geth-base.conf``

You can edit these files to customize the arguments passed to the op-geth binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.op-geth``

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://github.com/ethereum-optimism/op-geth
