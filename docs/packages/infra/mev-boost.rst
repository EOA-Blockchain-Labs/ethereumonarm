MEV-Boost
====================

This package provides MEV-Boost, open source middleware run by validators to access a competitive block-building market, packaged for Ethereum on ARM.

For a complete guide on how to configure your node and clients to use MEV-Boost, see :doc:`/advanced/mev-boost`.

Services
--------

This package installs systemd services for various networks. The services are disabled by default.

- ``mev-boost.service`` (Mainnet)
- ``mev-boost-sepolia.service`` (Sepolia Testnet)
- ``mev-boost-hoodi.service`` (Hoodi Testnet)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- ``/etc/ethereum/mev-boost.conf``
- ``/etc/ethereum/mev-boost-sepolia.conf``
- ``/etc/ethereum/mev-boost-hoodi.conf``

You can edit these files to customize the arguments passed to the MEV-Boost binary.

Data Directories
----------------

This package does not store persistent data.

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://github.com/flashbots/mev-boost
