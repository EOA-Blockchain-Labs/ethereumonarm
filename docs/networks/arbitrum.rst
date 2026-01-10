Arbitrum
========

Arbitrum is a Layer 2 scaling solution for Ethereum that uses Optimistic Rollups to increase transaction throughput while reducing gas costs. By processing transactions off-chain and posting compressed data to Ethereum mainnet, Arbitrum provides a secure and efficient scaling solution.

Ethereum on ARM provides the **Arbitrum Nitro** client, enabling you to run your own Arbitrum node on ARM-based devices.

.. important::
   Running an Arbitrum node requires access to a **synced Ethereum L1 node** (Execution Layer). You must have a local or remote Ethereum node available.

Arbitrum Node Support
---------------------

Setting up an Arbitrum node on Ethereum on ARM is straightforward. The images ship with the pre-installed Nitro client—you only need to configure your L1 endpoint and start the service.

1. Install the OS
~~~~~~~~~~~~~~~~~

Follow the :doc:`Installation Guide </getting-started/installation>` to flash the Ethereum on ARM image to your device and complete the initial boot process.

2. Configure L1 Connection
~~~~~~~~~~~~~~~~~~~~~~~~~~

Before starting the Arbitrum node, you must configure the L1 (Ethereum mainnet) endpoint.

Edit the configuration file:

.. code-block:: bash

    sudo nano /etc/ethereum/nitro.conf

Update the ``--l1.url`` parameter with your L1 node's address:

.. code-block:: bash

    ARGS="--l1.url http://YOUR_L1_NODE_IP:8545 \
        --l2.chain-id=42161 \
        --http.api=net,web3,eth,debug \
        --http.corsdomain=* \
        --http.addr=0.0.0.0 \
        --http.vhosts=*"

Replace ``YOUR_L1_NODE_IP`` with the IP address of your synced Ethereum node (e.g., ``192.168.1.100``).

.. tip::
   If running the L1 node on the same machine, use ``http://localhost:8545`` or ``http://127.0.0.1:8545``.

3. Download Initial Snapshot (Recommended)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To significantly speed up synchronization, download an initial database snapshot from Arbitrum's official source.

.. code-block:: bash

    # Create the data directory
    mkdir -p /home/ethereum/.arbitrum/arb1/nitro

    # Download and extract the latest snapshot (this can take several hours)
    cd /home/ethereum/.arbitrum/arb1/nitro
    wget -O - https://snapshot.arbitrum.foundation/arb1/nitro-pruned.tar | tar -xvf -

.. warning::
   The snapshot is very large (2+ TB). Ensure you have sufficient disk space and use ``screen`` or ``tmux`` to prevent disconnection during download.

4. Start the Service
~~~~~~~~~~~~~~~~~~~~

Once configured, start the Nitro client:

.. code-block:: bash

    sudo systemctl start nitro
    sudo journalctl -u nitro -f

The node will begin syncing with the Arbitrum network. Initial sync time depends on whether you used a snapshot.

5. Enable on Boot (Optional)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To automatically start the Arbitrum node on system boot:

.. code-block:: bash

    sudo systemctl enable nitro

Configuration
-------------

Configuration File
~~~~~~~~~~~~~~~~~~

The main configuration file is located at:

* ``/etc/ethereum/nitro.conf``

This file contains the command-line arguments passed to the Nitro binary.

Data Directory
~~~~~~~~~~~~~~

By default, data is stored in:

* ``/home/ethereum/.arbitrum/arb1/nitro``

This path is automatically created on first startup.

Service Details
~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Component, Value

   Service Name, ``nitro.service``
   Binary Path, ``/usr/bin/nitro``
   Configuration, ``/etc/ethereum/nitro.conf``
   Data Directory, ``/home/ethereum/.arbitrum/arb1/nitro``
   Default RPC Port, ``8547``
   User, ``ethereum``

RPC Access
----------

Once synced, you can query the Arbitrum node via JSON-RPC:

.. code-block:: bash

    curl -X POST http://localhost:8547 \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

Hardware Requirements
---------------------

.. csv-table::
   :align: left
   :header: Component, Minimum, Recommended

   Storage, 2 TB NVMe SSD, 4 TB NVMe SSD
   RAM, 16 GB, 32 GB
   L1 Access, Required, Local node preferred

For monitoring, logs, and lifecycle management, refer to the
:doc:`Managing Clients </running-a-node/managing-clients>` guide.

Official Documentation
~~~~~~~~~~~~~~~~~~~~~~

For advanced configuration and architectural details, refer to the official Arbitrum documentation:

`Arbitrum Node Documentation <https://docs.arbitrum.io/run-arbitrum-node/run-full-node>`_
