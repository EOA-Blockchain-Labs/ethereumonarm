Quickstart Cheatsheet
=====================

.. meta::
   :description lang=en: Ethereum on ARM command cheatsheet. Quick reference for node operations, systemd service management, sync status, and troubleshooting commands.
   :keywords: Ethereum node commands, systemctl blockchain, node management cheatsheet, ARM Ethereum CLI, sync status

A quick reference for common Ethereum on ARM operations.

.. tip::
   Keep this page bookmarked for easy access during node management.

Service Management
------------------

.. code-block:: bash

   # Start/Stop/Restart a client
   sudo systemctl start geth
   sudo systemctl stop geth
   sudo systemctl restart geth

   # Enable at boot
   sudo systemctl enable geth

   # Check status
   sudo systemctl status geth

View Logs
---------

.. code-block:: bash

   # Follow logs in real-time
   sudo journalctl -u geth -f

   # Last 100 lines
   sudo journalctl -u geth -n 100

   # Logs since boot
   sudo journalctl -u geth -b

Check Sync Status
-----------------

**Geth (Execution Layer)**

.. code-block:: bash

   geth attach --exec "eth.syncing"

**Lighthouse (Consensus Layer)**

.. code-block:: bash

   curl -s http://localhost:5052/eth/v1/node/syncing | jq

**op-node (Optimism L2)**

.. code-block:: bash

   curl -s -X POST -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
     http://localhost:8547 | jq

Disk Usage
----------

.. code-block:: bash

   # Check overall disk usage
   df -h

   # Check Ethereum data directories
   du -sh /home/ethereum/.ethereum
   du -sh /home/ethereum/.lighthouse

Configuration Files
-------------------

All client configurations are stored in ``/etc/ethereum/``:

.. code-block:: bash

   # List all configs
   ls -la /etc/ethereum/

   # Edit a config (example: Geth)
   sudo nano /etc/ethereum/geth.conf

   # After editing, restart the service
   sudo systemctl restart geth

Common Client Pairs
-------------------

+-------------------+-------------------+
| Execution Layer   | Consensus Layer   |
+===================+===================+
| ``geth``          | ``lighthouse``    |
+-------------------+-------------------+
| ``nethermind``    | ``prysm``         |
+-------------------+-------------------+
| ``besu``          | ``teku``          |
+-------------------+-------------------+
| ``reth``          | ``nimbus``        |
+-------------------+-------------------+

Quick Install Commands
----------------------

**L1 Node (Geth + Lighthouse)**

.. code-block:: bash

   sudo apt update
   sudo apt install geth lighthouse

**Optimism L2 Node**

.. code-block:: bash

   sudo apt install optimism-op-geth optimism-op-node

**Starknet Node (Juno)**

.. code-block:: bash

   sudo apt install starknet-juno

Useful Ports
------------

+-------------------+-------+---------------------------+
| Service           | Port  | Description               |
+===================+=======+===========================+
| Geth RPC          | 8545  | HTTP JSON-RPC             |
+-------------------+-------+---------------------------+
| Geth WS           | 8546  | WebSocket RPC             |
+-------------------+-------+---------------------------+
| Geth P2P          | 30303 | Peer discovery            |
+-------------------+-------+---------------------------+
| Lighthouse API    | 5052  | Beacon API                |
+-------------------+-------+---------------------------+
| Prometheus        | 9090  | Metrics server            |
+-------------------+-------+---------------------------+
| Grafana           | 3000  | Dashboard UI              |
+-------------------+-------+---------------------------+

Backup Validator Keys
---------------------

.. warning::
   Always back up your validator keys to a secure offline location.

.. code-block:: bash

   # Example: Copy Lighthouse validator keys
   sudo cp -r /home/ethereum/.lighthouse/validators /path/to/backup/

Need More Help?
---------------

- :doc:`Full Installation Guide </getting-started/installation>`
- :doc:`Managing Clients </running-a-node/managing-clients>`
- :doc:`Troubleshooting </system/troubleshooting>`
- `Discord Community <https://discord.gg/ve2Z8fxz5N>`_
