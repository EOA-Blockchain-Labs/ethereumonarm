Reth
===============

This package provides Reth, the Rust implementation of the Ethereum protocol by Paradigm, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks. The services are disabled by default.

- ``reth.service`` (Mainnet)
- ``reth-gnosis.service`` (Gnosis Chain)
- ``reth-sepolia.service`` (Sepolia Testnet)
- ``reth-hoodi.service`` (Holesky Testnet)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- **Mainnet**: ``/etc/ethereum/reth.conf``
- **Gnosis**: ``/etc/ethereum/reth-gnosis.conf``
- **Sepolia**: ``/etc/ethereum/reth-sepolia.conf``
- **Holesky**: ``/etc/ethereum/reth-hoodi.conf``

You can edit these files to customize the generic arguments passed to the Reth binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.reth`` (Mainnet)
- ``/home/ethereum/.reth-gnosis`` (Gnosis Chain)
- ``/home/ethereum/.reth-sepolia`` (Sepolia Testnet)
- ``/home/ethereum/.reth-hoodi`` (Holesky Testnet)

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://paradigmxyz.github.io/reth/
