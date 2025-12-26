Nethermind
=====================

This package provides the Nethermind Ethereum execution client, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks. The services are disabled by default.

- ``nethermind.service`` (Mainnet)
- ``nethermind-gnosis.service`` (Gnosis Chain)
- ``nethermind-sepolia.service`` (Sepolia Testnet)
- ``nethermind-hoodi.service`` (Holesky Testnet)
- ``nethermind-op.service`` (Optimism Mainnet)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- **Mainnet**: ``/etc/ethereum/nethermind.conf``
- **Gnosis**: ``/etc/ethereum/nethermind-gnosis.conf``
- **Sepolia**: ``/etc/ethereum/nethermind-sepolia.conf``
- **Holesky**: ``/etc/ethereum/nethermind-hoodi.conf``
- **Optimism**: ``/etc/ethereum/nethermind-op.conf``

You can edit these files to customize the generic arguments passed to the Nethermind binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.nethermind`` (Mainnet)
- ``/home/ethereum/.nethermind-gnosis`` (Gnosis Chain)
- ``/home/ethereum/.nethermind-sepolia`` (Sepolia Testnet)
- ``/home/ethereum/.nethermind-hoodi`` (Holesky Testnet)
- ``/home/ethereum/.nethermind-op`` (Optimism)

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://nethermind.io
