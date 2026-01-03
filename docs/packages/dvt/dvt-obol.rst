Obol Charon
======================

This package provides Charon, the Obol Distributed Validator Technology (DVT) client, packaged for Ethereum on ARM.

Services
--------

This package installs the main Charon service and several validator service overrides to work with DVT. The services are disabled by default.

- ``charon.service`` (Main DVT middleware)

Validator Services:

- ``lighthouse-validator-obol.service``
- ``lighthouse-validator-obol-lido.service``
- ``lighthouse-validator-hoodi-obol.service``
- ``lodestar-validator-obol.service``
- ``lodestar-validator-hoodi-obol.service``
- ``nimbus-validator-obol.service``
- ``nimbus-validator-obol-lido.service``
- ``nimbus-validator-hoodi-obol.service``
- ``prysm-validator-obol.service``
- ``prysm-validator-obol-lido.service``
- ``prysm-validator-hoodi-obol.service``
- ``teku-validator-obol.service``
- ``teku-validator-hoodi-obol.service``
- ``grandine-validator-obol.service``
- ``grandine-validator-obol-lido.service``
- ``grandine-validator-hoodi-obol.service``

To enable a service, run:
    sudo systemctl enable --now <service_name>

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/dvt/``.

- ``/etc/ethereum/dvt/charon.conf``
- Validators use corresponding files in ``/etc/ethereum/dvt/`` (e.g., ``/etc/ethereum/dvt/lighthouse-validator-obol.conf``)

You can edit these files to customize the arguments passed to Charon and the validator clients.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.charon``

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://github.com/ObolNetwork/charon
