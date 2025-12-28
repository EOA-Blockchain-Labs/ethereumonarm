Geth
===============

This package provides Geth, the official Go implementation of the Ethereum protocol, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks. The services are disabled by default.

- ``geth.service`` (Mainnet)
- ``geth-gnosis.service`` (Gnosis Chain)
- ``geth-sepolia.service`` (Sepolia Testnet)
- ``geth-hoodi.service`` (Hoodi Testnet)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- **Mainnet**: ``/etc/ethereum/geth.conf``
- **Gnosis**: ``/etc/ethereum/geth-gnosis.conf``
- **Sepolia**: ``/etc/ethereum/geth-sepolia.conf``
- **Hoodi**: ``/etc/ethereum/geth-hoodi.conf``

You can edit these files to customize the generic arguments passed to the Geth binary.

JWT Secret
----------

The systemd services automatically generate a JWT secret if one does not exist.
The default location is ``/etc/ethereum/jwtsecret``. This secret is required for the Consensus Layer client to authenticate with Geth.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.ethereum`` (Mainnet)
- ``/home/ethereum/.geth-gnosis`` (Gnosis Chain)
- ``/home/ethereum/.geth-sepolia`` (Sepolia Testnet)
- ``/home/ethereum/.geth-hoodi`` (Hoodi Testnet)

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://geth.ethereum.org
