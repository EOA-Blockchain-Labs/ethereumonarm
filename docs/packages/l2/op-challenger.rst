op-challenger
=============

Package Name: ``optimism-op-challenger``

The Fault Proof Challenger for the Optimism Stack. It monitors the Layer 1 and Layer 2 chains to detect and challenge invalid state transitions.

Configuration
-------------

The configuration file is located at ``/etc/ethereum/op-challenger.conf``.

You can edit this file to change the command line arguments passed to the client. After modifying the file, restart the service:

.. code-block:: bash

    sudo systemctl restart op-challenger

Trace Types
~~~~~~~~~~~

The ``--trace-type`` flag determines which fault proof VMs are used:

*   ``cannon`` - MIPS-based VM (default, recommended)
*   ``cannon-kona`` - Cannon with Kona host
*   ``permissioned`` - Permissioned games (uses Cannon)
*   ``asterisc`` - RISC-V based VM (requires ``asterisc`` binary)
*   ``asterisc-kona`` - Asterisc with Kona host

.. important::

    Recent versions of ``op-challenger`` default to ``cannon,asterisc-kona,cannon-kona``,
    which requires the Asterisc binary. To use only Cannon, explicitly set:

    .. code-block:: bash

        TRACE_TYPE="cannon"

Service Management
------------------

The systemd service name is ``op-challenger``.

.. code-block:: bash

    sudo systemctl start op-challenger
    sudo systemctl stop op-challenger
    sudo systemctl status op-challenger
    sudo systemctl enable op-challenger

Data Directory
--------------

The default configuration suggests using:

*   ``/home/ethereum/.op-challenger``

Maintainer
----------

*   Ethereum on ARM <info@ethereumonarm.com>
*   https://ethereumonarm.com

Upstream Project
----------------

*   https://github.com/ethereum-optimism/optimism

See :doc:`/operation/optimism/challenger` for a detailed operational guide.
