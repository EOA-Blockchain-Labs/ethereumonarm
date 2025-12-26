Lodestar
===================

This package provides the Lodestar Ethereum consensus client, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks and configurations. The services are disabled by default.

**Beacon Chain Services:**
- ``lodestar-beacon.service`` (Mainnet)
- ``lodestar-beacon-mev.service`` (Mainnet + MEV-Boost)
- ``lodestar-beacon-gnosis.service`` (Gnosis Chain)
- ``lodestar-beacon-sepolia.service`` (Sepolia Testnet)
- ``lodestar-beacon-sepolia-mev.service`` (Sepolia + MEV-Boost)
- ``lodestar-beacon-hoodi.service`` (Holesky Testnet)
- ``lodestar-beacon-hoodi-mev.service`` (Holesky + MEV-Boost)

**Validator Services:**
- ``lodestar-validator.service`` (Mainnet)
- ``lodestar-validator-mev.service`` (Mainnet + MEV-Boost)
- ``lodestar-validator-gnosis.service`` (Gnosis Chain)
- ``lodestar-validator-sepolia.service`` (Sepolia Testnet)
- ``lodestar-validator-sepolia-mev.service`` (Sepolia + MEV-Boost)
- ``lodestar-validator-hoodi.service`` (Holesky Testnet)
- ``lodestar-validator-hoodi-mev.service`` (Holesky + MEV-Boost)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- **Mainnet**:
    - ``/etc/ethereum/lodestar-beacon.conf``
    - ``/etc/ethereum/lodestar-beacon-mev.conf``
    - ``/etc/ethereum/lodestar-validator.conf``
    - ``/etc/ethereum/lodestar-validator-mev.conf``

- **Gnosis**:
    - ``/etc/ethereum/lodestar-beacon-gnosis.conf``
    - ``/etc/ethereum/lodestar-validator-gnosis.conf``

- **Sepolia**:
    - ``/etc/ethereum/lodestar-beacon-sepolia.conf``
    - ``/etc/ethereum/lodestar-beacon-sepolia-mev.conf``
    - ``/etc/ethereum/lodestar-validator-sepolia.conf``
    - ``/etc/ethereum/lodestar-validator-sepolia-mev.conf``

- **Holesky**:
    - ``/etc/ethereum/lodestar-beacon-hoodi.conf``
    - ``/etc/ethereum/lodestar-beacon-hoodi-mev.conf``
    - ``/etc/ethereum/lodestar-validator-hoodi.conf``
    - ``/etc/ethereum/lodestar-validator-hoodi-mev.conf``

You can edit these files to customize the generic arguments passed to the Lodestar binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- **Beacon Node**: ``/home/ethereum/.lodestar-beacon`` (or corresponding suffix for other networks)
- **Validator**: ``/home/ethereum/.lodestar-validator`` (or corresponding suffix for other networks)

Ensure the ``ethereum`` user has permissions to write to these directories if you change them.

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://github.com/ChainSafe/lodestar
