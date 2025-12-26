Madara
=================

This package provides Madara, a hybrid Starknet client written in Rust, packaged for Ethereum on ARM.

Services
--------

This package installs a single systemd service. The service is disabled by default.

- ``madara.service``

To enable the service, run:
    sudo systemctl enable --now madara.service

Configuration
-------------

Configuration arguments are defined in the environment file located in ``/etc/ethereum/madara/``.

- ``/etc/ethereum/madara/madara.conf``

Presets are located in ``/etc/ethereum/madara/presets/``.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``/home/ethereum/.madara``

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <dlosada@ethereumonarm.com>
- **Upstream URL**: https://github.com/madara-alliance/madara
