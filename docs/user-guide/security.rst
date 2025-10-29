.. _node-security:

Node Security
=============

User account
------------

To maintain a minimal and secure environment, the Ethereum on ARM image removes
the default ``ubuntu`` user and automatically creates a dedicated system account
called ``ethereum`` during installation. SSH access is enabled by default.

On the first login, the system prompts you to **set a new password** for the
``ethereum`` user. This ensures no weak or default credentials remain on the device.

You can log in to your device in one of two ways:

- **Locally:** using a keyboard and monitor connected to the board.
- **Remotely:** using :command:`ssh` from another system, e.g.::

    ssh ethereum@<device-ip>


UFW Firewall
------------

Ethereum on ARM includes the **UFW (Uncomplicated Firewall)** with modular
application profiles tailored for Ethereum clients and supporting services.

The firewall is **disabled by default** (most devices run behind a router or NAT),
but you can enable it safely at any time.

.. prompt:: bash $

   sudo systemctl enable ufw
   sudo systemctl start ufw
   sudo ufw enable

You can list the currently available UFW profiles with:

.. prompt:: bash $

   sudo ufw app list

By default, you’ll see ``Nginx`` and ``OpenSSH`` profiles.
After installing the ``ethereumonarm-firewall`` package, you will also see
the full set of **Ethereum** profiles.

Example output::

   Available applications:
     Nginx Full
     Nginx HTTP
     Nginx HTTPS
     OpenSSH
     Ethereum EL P2P
     Ethereum CL P2P
     Ethereum EL P2P Alt
     Lighthouse QUIC
     Prysm P2P
     Prysm QUIC
     OP Stack P2P
     OP Node P2P
     Erigon Snap
     Consensus Beacon REST
     Execution RPC HTTP
     Execution RPC WS
     Engine API
     Besu Metrics
     Erigon Metrics
     Erigon pprof
     Reth Metrics


Enabling Profiles
-----------------

Each profile is **disabled until explicitly allowed**.  
Enable only the ports you actually need.

For a typical node:

.. prompt:: bash $

   sudo ufw allow "OpenSSH"
   sudo ufw allow "Nginx HTTPS"
   sudo ufw allow "Ethereum EL P2P"
   sudo ufw allow "Ethereum CL P2P"
   sudo ufw enable

Optional examples:

.. prompt:: bash $

   # Enable QUIC support for Lighthouse or Prysm
   sudo ufw allow "Lighthouse QUIC"
   sudo ufw allow "Prysm QUIC"

   # Temporary: open Erigon Snap sync
   sudo ufw allow "Erigon Snap"
   # After sync
   sudo ufw delete allow "Erigon Snap"


SSH Access
~~~~~~~~~~~

Always keep SSH accessible before enabling the firewall:

.. prompt:: bash $

   sudo ufw allow "OpenSSH"

You can enable rate limiting to protect against brute-force attacks:

.. prompt:: bash $

   sudo ufw limit ssh comment 'Limit SSH login attempts'


Nginx Proxy
~~~~~~~~~~~

The image includes a preconfigured **Nginx reverse proxy** for Ethereum JSON-RPC.
This proxy terminates HTTPS on port 443 and forwards requests securely to the
local Execution Layer client (port 8545).

You do **not** need to modify the Nginx configuration manually.
For certificate setup and usage with MetaMask or wallets, see:
:doc:`using-your-node`


Recommended Practices
~~~~~~~~~~~~~~~~~~~~~~

- Enable only the required profiles.
- Never expose the RPC or Engine API (8545/8546/8551) directly.
- Use HTTPS through Nginx for all wallet or API connections.
- Restrict metrics and profiling ports to localhost or trusted subnets.
- Forward ports 30303 (TCP/UDP) and 9000 (TCP/UDP) on your router if behind NAT.
- Enable SSH and rate-limit it before enabling UFW.
- If using IPv6, ensure ``IPV6=yes`` in :file:`/etc/default/ufw`.

For examples of wallet setup and blockchain queries, continue to:
:doc:`using-your-node`