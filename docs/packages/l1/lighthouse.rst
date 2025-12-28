Lighthouse
=====================

This package provides the Lighthouse Ethereum consensus client, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services for various networks and configurations. The services are disabled by default.

**Beacon Chain Services:**

- ``lighthouse-beacon.service`` (Mainnet)
- ``lighthouse-beacon-mev.service`` (Mainnet + MEV-Boost)
- ``lighthouse-beacon-gnosis.service`` (Gnosis Chain)
- ``lighthouse-beacon-sepolia.service`` (Sepolia Testnet)
- ``lighthouse-beacon-sepolia-mev.service`` (Sepolia + MEV-Boost)
- ``lighthouse-beacon-hoodi.service`` (Hoodi Testnet)
- ``lighthouse-beacon-hoodi-mev.service`` (Hoodi + MEV-Boost)

**Validator Services:**

- ``lighthouse-validator.service`` (Mainnet)
- ``lighthouse-validator-mev.service`` (Mainnet + MEV-Boost)
- ``lighthouse-validator-gnosis.service`` (Gnosis Chain)
- ``lighthouse-validator-sepolia.service`` (Sepolia Testnet)
- ``lighthouse-validator-sepolia-mev.service`` (Sepolia + MEV-Boost)
- ``lighthouse-validator-hoodi.service`` (Hoodi Testnet)
- ``lighthouse-validator-hoodi-mev.service`` (Hoodi + MEV-Boost)

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- **Mainnet**:
    - ``/etc/ethereum/lighthouse-beacon.conf``
    - ``/etc/ethereum/lighthouse-beacon-mev.conf``
    - ``/etc/ethereum/lighthouse-validator.conf``
    - ``/etc/ethereum/lighthouse-validator-mev.conf``

- **Gnosis**:
    - ``/etc/ethereum/lighthouse-beacon-gnosis.conf``
    - ``/etc/ethereum/lighthouse-validator-gnosis.conf``

- **Sepolia**:
    - ``/etc/ethereum/lighthouse-beacon-sepolia.conf``
    - ``/etc/ethereum/lighthouse-beacon-sepolia-mev.conf``
    - ``/etc/ethereum/lighthouse-validator-sepolia.conf``
    - ``/etc/ethereum/lighthouse-validator-sepolia-mev.conf``

- **Hoodi**:
    - ``/etc/ethereum/lighthouse-beacon-hoodi.conf``
    - ``/etc/ethereum/lighthouse-beacon-hoodi-mev.conf``
    - ``/etc/ethereum/lighthouse-validator-hoodi.conf``
    - ``/etc/ethereum/lighthouse-validator-hoodi-mev.conf``

You can edit these files to customize the generic arguments passed to the Lighthouse binary.

Note: The default configuration includes ``--prune-payloads false``. This ensures that the Execution Layer can sync correctly using the payload history. Changing this to ``true`` may cause issues with historical syncing.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- **Beacon Node**: ``/home/ethereum/.lighthouse`` (Mainnet)
- **Validator**: ``/home/ethereum/.lighthouse`` (Mainnet)

Note: For other networks, check the specific service file for the data directory argument.

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://github.com/sigp/lighthouse/
