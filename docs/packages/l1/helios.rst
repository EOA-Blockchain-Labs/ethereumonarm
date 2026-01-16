Helios
======

.. meta::
   :description: Helios Ethereum Light Client package documentation.
   :keywords: helios, ethereum, light client, arm, aarch64

This package provides Helios Ethereum Light Client, packaged for Ethereum on ARM.

Services
--------

This package installs systemd services. The services are disabled by default.

- ``helios.service``

To enable a service, run::

    sudo systemctl enable --now helios.service

Configuration
-------------

Configuration arguments are defined in the environment file located in ``/etc/ethereum/``.

- ``/etc/ethereum/helios.env``

You can edit this file to customize the arguments passed to the binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``~/.helios``

User and Group
--------------

The service runs as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://github.com/a16z/helios
