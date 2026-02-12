kona
=================

Portable implementation of the OP Stack's fault proof verification logic (kona-host).

This package provides the ``kona-host`` binary, which serves as the host program for the fault proof VM (e.g., in ``cannon-kona`` trace types).

Installation
------------

.. code-block:: bash

    sudo apt install kona

Usage
-----

The binary is installed at ``/usr/bin/kona-host``.

It is typically not run manually but invoked by **op-challenger** when configured for ``cannon-kona`` traces.

Integration with Op-Challenger
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To use Kona with Op-Challenger:

1.  Ensure ``kona`` is installed.
2.  Edit ``/etc/ethereum/op-challenger.conf``.
3.  Set ``TRACE_TYPE="cannon-kona"``.
4.  Ensure ``CANNON_KONA_SERVER="/usr/bin/kona-host"`` is set (default in new configs).

Package Details
---------------

- **Maintainer**: Ethereum on ARM <info@ethereumonarm.com>
- **Upstream URL**: https://github.com/ethereum-optimism/optimism/tree/develop/kona
