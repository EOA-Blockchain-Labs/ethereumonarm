Ethereum on ARM Nginx Proxy Extras
=============================================

This meta-package configures Nginx to act as a reverse proxy for Ethereum execution layer clients, allowing secure RPC access.

Features
--------

- **Dependencies**: Installs ``nginx``.
- **Configuration**:
  - **Sites Enabled**: Configures virtual hosts for RPC proxying in ``/etc/nginx/sites-enabled/``.
  - **Upstreams**: Defines upstream backends for Ethereum clients in ``/etc/nginx/conf.d/``.

Package Details
---------------

- **Maintainer**: Fernando Collado <fcollado@ethereumonarm.com>
- **Upstream URL**: https://github.com/ethereumonarm
