Ethrex
=================

This package provides Ethrex, a minimalist and modular implementation of the Ethereum protocol, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks. The services are disabled by default.

- ``ethrex.service`` (Mainnet)
- ``ethrex-sepolia.service`` (Sepolia Testnet)
- ``ethrex-hoodi.service`` (Hoodi Testnet)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- **Mainnet**: ``/etc/ethereum/ethrex.conf``
- **Sepolia**: ``/etc/ethereum/ethrex-sepolia.conf``
- **Hoodi**: ``/etc/ethereum/ethrex-hoodi.conf``

You can edit these files to customize the generic arguments passed to the Ethrex binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.ethrex`` (Mainnet)
- ``/home/ethereum/.ethrex-sepolia`` (Sepolia Testnet)
- ``/home/ethereum/.ethrex-hoodi`` (Hoodi Testnet)

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://github.com/lambdaclass/ethrex
