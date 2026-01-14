Quickstart Cheatsheet
=====================

.. meta::
   :description lang=en: Master your Ethereum on ARM node. One-page reference for diagnostics (eoa_check), service management, security (UFW), sync monitoring, and system maintenance.
   :keywords: eoa_check, ethereum on arm commands, systemctl, ufw firewall, ethereum config sync, node troubleshooting

A comprehensive reference for managing the entire lifecycle of your Ethereum on ARM node, from health checks to emergency recovery.

.. contents:: Table of Contents
   :local:
   :backlinks: none

Diagnostics & Health
--------------------

The **Ethereum on ARM Check Script** is your primary tool for diagnosing issues. It analyzes hardware, network, and client status.

.. code-block:: bash

   # Run full system diagnosis
   sudo eoa_check -l

   # Upload report to share with support (returns a URL)
   sudo eoa_send

   # Check disk space usage (vital for 2TB+ drives)
   df -h

   # Monitor real-time system resources (CPU/RAM)
   htop

Service Management
------------------

Manage your Execution Layer (EL) and Consensus Layer (CL) clients. Replace ``<service>`` with your client name (e.g., ``geth``, ``lighthouse-beacon``, ``nethermind``, ``prysm-beacon``).

.. code-block:: bash

   # Start / Stop / Restart
   sudo systemctl start <service>
   sudo systemctl stop <service>
   sudo systemctl restart <service>

   # Enable auto-start at boot
   sudo systemctl enable <service>

   # Check status (active/failed)
   sudo systemctl status <service>

**Review Logs:**

.. code-block:: bash

   # Follow logs in real-time (Ctrl+C to exit)
   sudo journalctl -u <service> -f

   # View logs solely from the current boot session
   sudo journalctl -u <service> -b

Monitor Sync Status
-------------------

**Execution Layer (Geth example)**

.. code-block:: bash

   geth attach --exec "eth.syncing"

**Consensus Layer**

.. code-block:: bash

   # Check generic sync status (JSON output)
   curl -s http://localhost:5052/eth/v1/node/syncing | jq

**Optimism Layer 2**

.. code-block:: bash

   curl -s -X POST -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
     http://localhost:8547 | jq

Network & Security
------------------

**Firewall (UFW)**

Ethereum on ARM includes custom UFW profiles. Only enable what you need.

.. code-block:: bash

   # 1. Enable SSH (CRITICAL: Do this first!)
   sudo ufw allow "OpenSSH"

   # 2. Allow specific Ethereum traffic
   sudo ufw allow "Ethereum EL P2P"
   sudo ufw allow "Ethereum CL P2P"

   # 3. Enable the firewall
   sudo ufw enable

   # List status and active rules
   sudo ufw status verbose

**Port Checks**

.. code-block:: bash

   # View all listening ports
   sudo ss -tuln

System Maintenance
------------------

**Updates**

.. code-block:: bash

   # Update all Ethereum on ARM packages (clients & tools)
   update-ethereum

   # Standard OS update
   sudo apt update && sudo apt upgrade

**Configuration Backup**

Crucial before performing image upgrades. This saves your ``/etc/ethereum`` configs to the NVMe drive.

.. code-block:: bash

   sudo ethereumonarm-config-sync.sh

**Emergency: Wipe & Reset**

To completely wipe the NVMe disk and reinstall a fresh node (requires a reboot):

.. code-block:: bash

   # Trigger a reformat on next boot
   touch /home/ethereum/.format_me
   sudo reboot

Client Reference
----------------

Standard service names for common clients:

+----------------+--------------------------+-----------------------------+
| Client         | Service Name             | Config Path                 |
+================+==========================+=============================+
| **Geth**       | ``geth``                 | ``/etc/ethereum/geth.conf`` |
+----------------+--------------------------+-----------------------------+
| **Nethermind** | ``nethermind``           | ``/etc/ethereum/nethermind.conf`` |
+----------------+--------------------------+-----------------------------+
| **Besu**       | ``besu``                 | ``/etc/ethereum/besu.conf`` |
+----------------+--------------------------+-----------------------------+
| **Lighthouse** | ``lighthouse-beacon``    | ``/etc/ethereum/lighthouse.conf`` |
+----------------+--------------------------+-----------------------------+
| **Prysm**      | ``prysm-beacon``         | ``/etc/ethereum/prysm.conf``|
+----------------+--------------------------+-----------------------------+
| **Nimbus**     | ``nimbus-beacon``        | ``/etc/ethereum/nimbus.conf``|
+----------------+--------------------------+-----------------------------+
| **Teku**       | ``teku``                 | ``/etc/ethereum/teku.conf`` |
+----------------+--------------------------+-----------------------------+

Need More Help?
---------------

*   **Discord**: `Join the Community <https://discord.gg/ve2Z8fxz5N>`_ (Post your ``eoa_send`` link here)
*   **Troubleshooting Guide**: :doc:`../system/troubleshooting`
