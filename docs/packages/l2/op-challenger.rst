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

See :doc:`/operation/optimism-challenger` for a detailed operational guide.
