{{PKG_NAME}}
=================

{{PKG_DESCRIPTION}}

Services
--------

This package installs systemd services. The services are disabled by default.

- ``{{SERVICE_NAME}}.service``

To enable a service, run:
    sudo systemctl enable --now {{SERVICE_NAME}}.service

Configuration
-------------

Configuration arguments are defined in environment files located in ``/etc/ethereum/``.

- ``/etc/ethereum/{{CONFIG_FILE}}``

You can edit these files to customize the generic arguments passed to the binary.

Data Directories
----------------

By default, this package stores data in the ``ethereum`` user's home directory:

- ``{{DATA_DIR}}``

User and Group
--------------

All services run as the ``ethereum`` user and group.

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: {{UPSTREAM_URL}}
