Obol DVT Setup Guide
====================

This guide explains how to set up and run a Distributed Validator (DV) cluster using Obol's Charon middleware on Ethereum on ARM.

.. note::

   Distributed Validator Technology (DVT) allows multiple operators to run a single validator together,
   eliminating single points of failure and improving resilience.

Prerequisites
-------------

Before starting, ensure you have:

- **Hardware**: ARM64 device running Ethereum on ARM
- **Full Ethereum Node**: Running execution layer + consensus layer clients
- **Network**: Port 3610 open for P2P communication (TCP/UDP)
- **Storage**: Additional ~1GB for Charon data
- **Cluster Members**: Contact information for other cluster operators

Install the ``dvt-obol`` package:

.. prompt:: bash $

   sudo apt-get update && sudo apt-get install dvt-obol

For package details, installation paths, and service names, see :doc:`/packages/dvt/dvt-obol`.

Understanding Distributed Validators
-------------------------------------

A distributed validator cluster consists of:

- **Charon Middleware**: Sits between your validator client and beacon node
- **Threshold Signing**: Each operator holds a key share, not the full key
- **Consensus**: Operators must reach agreement to sign attestations/proposals
- **Fault Tolerance**: Cluster continues operating if some operators go offline

.. warning::

   Losing access to your key share without proper backups may make your validator deposit unrecoverable.
   Always backup the ``.charon`` directory.

Charon Architecture
-------------------

Charon acts as a middleware between your validator client and your beacon node. It intercepts the validator duties, coordinates with other Charon nodes to reach consensus, and then submits the signed duties to the beacon node.

.. code-block:: text

    +------------------+       +------------------+       +------------------+
    | Validator Client | <---> |      Charon      | <---> |    Beacon Node   |
    +------------------+       +------------------+       +------------------+
                                        ^
                                        | P2P Network (TCP/UDP 3610)
                                        v
                               +------------------+
                               | Other Charon Nodes|
                               +------------------+

Networking & Connectivity
-------------------------

Charon networking consists of two distinct layers:

1.  **Internal Validator Stack**: The communication between your Validator Client, Charon, and Beacon Node. This should strictly be private (localhost or local private network).
2.  **External P2P Network**: The communication between Charon nodes. This happens over port **3610** (TCP/UDP).

**Discovery & Relays:**
Charon uses LibP2P relays to help nodes discover each other and punch through NATs. By default, it uses Obol's public relays. In a VPN setup (like our 3-node example), nodes can communicate directly, but relays still assist in initial discovery if configured.


The size of your cluster determines its fault tolerance—its ability to keep operating when some nodes fail or act maliciously.

There are two types of fault tolerance:

- **Byzantine Fault Tolerance (BFT)**: The cluster can survive malicious or compromised nodes (e.g., hacked nodes sending bad data).
- **Crash Fault Tolerance (CFT)**: The cluster can survive nodes going offline (e.g., power outage, hardware failure).

**To calculate tolerance:**

- **Threshold**: Minimum nodes needed to sign (Quorum) = ``ceil(2n/3)``
- **BFT Tolerance**: Max malicious nodes = ``floor((n-1)/3)``
- **CFT Tolerance**: Max offline nodes = ``n - Threshold``

.. list-table:: Cluster Size & Resilience
   :header-rows: 1
   :widths: 15 20 15 15 35

   * - Nodes
     - Threshold
     - BFT
     - CFT
     - Recommendation
   * - 1
     - 1
     - 0
     - 0
     - Solo Validator (No DVT benefits)
   * - 2
     - 2
     - 0
     - 0
     - ❌ **Not Recommended** (No tolerance)
   * - 3
     - 2
     - 0
     - 1
     - ⚠️ **CFT Only** (1 node can crash, but 0 malicious)
   * - 4
     - 3
     - 1
     - 1
     - ✅ **Optimal Entry** (Tolerates 1 offline OR 1 malicious)
   * - 5
     - 4
     - 1
     - 2
     - ✅ High Availability (Tolerates 2 offline)
   * - 7
     - 5
     - 2
     - 2
     - ✅ High Security (Tolerates 2 malicious)

.. note::
   While a 3-node cluster is easier to organize, it does **not** provide Byzantine Fault Tolerance. It only protects against one node going offline. For full DVT security, start with 4 nodes.

Practical Example: 3-Node Cluster
---------------------------------

For a complete, step-by-step walkthrough of setting up a **3-node cluster** using Ethereum on ARM devices connected via a WireGuard VPN, please refer to our dedicated guide:

:doc:`/advanced/obol-dvt-3-node-example`




Step 1: Generate Your ENR
-------------------------


An Ethereum Node Record (ENR) identifies your Charon node to other cluster members.

.. prompt:: bash $

   charon create enr

This creates:

- ``/home/ethereum/.charon/charon-enr-private-key``: Your private key (backup this!)
- The command outputs your public ENR to share with cluster members

.. important::

   Share your ENR with the cluster leader. Keep the private key secure and backed up.

Step 2: Create Cluster Definition (Leader Only)
-----------------------------------------------

The cluster leader collects ENRs from all operators and creates the **Cluster Definition**.

This file (`cluster-definition.json`) is the **blueprint** for your cluster. It contains:
- The cluster name and size.
- The withdrawal and fee recipient addresses.
- The ENRs of all participating operators.
- The definition hash (to ensure all operators use the exact same file).

Run the following command *only* on the leader's node:


.. prompt:: bash $

   charon create dkg \
     --name="My DV Cluster" \
     --num-validators=1 \
     --fee-recipient-addresses="0xYOUR_FEE_RECIPIENT" \
     --withdrawal-addresses="0xYOUR_WITHDRAWAL_ADDRESS" \
     --operator-enrs="enr:-...,enr:-...,enr:-...,enr:-..."

Replace:

- ``--name``: A descriptive name for your cluster
- ``--num-validators``: Number of validators to create
- ``--fee-recipient-addresses``: Address to receive execution layer rewards
- ``--withdrawal-addresses``: Address for validator withdrawals
- ``--operator-enrs``: Comma-separated ENRs from all cluster operators

This creates ``/home/ethereum/.charon/cluster-definition.json``.

**Distribute this file to all cluster operators.**

Step 3: Run the DKG Ceremony
----------------------------

All operators must run the DKG ceremony simultaneously using the *exact same* `cluster-definition.json` file.

This process establishes a secure channel between operators to generate the distributed private keys without any single entity ever knowing the full key.


.. prompt:: bash $

   charon dkg --definition-file=/home/ethereum/.charon/cluster-definition.json

.. note::

   All operators must be online and run this command at the same time.
   The ceremony typically takes 1-5 minutes.

Upon completion, each operator receives:

- ``cluster-lock.json``: Cluster configuration for Charon
- ``validator_keys/``: Your share of the validator keystores
- ``deposit-data.json``: Deposit data for activating the validator

Step 4: Configure Charon
------------------------

Edit the Charon configuration:

.. prompt:: bash $

   sudo nano /etc/ethereum/dvt/charon.conf

Example configuration:

.. code-block:: bash

   ARGS="--beacon-node-endpoints http://localhost:5052 \
         --private-key-file /home/ethereum/.charon/charon-enr-private-key \
         --lock-file /home/ethereum/.charon/cluster-lock.json \
         --p2p-tcp-addresses 0.0.0.0:3610 \
         --p2p-udp-addresses 0.0.0.0:3610 \
         --monitoring-address 0.0.0.0:3620"

Key configuration options:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Option
     - Description
   * - ``--beacon-node-endpoints``
     - Your beacon node URL (port 5052 for most clients)
   * - ``--private-key-file``
     - Path to your ENR private key
   * - ``--lock-file``
     - Path to cluster-lock.json from DKG
   * - ``--p2p-tcp-addresses``
     - P2P listening address (open port 3610)
   * - ``--monitoring-address``
     - Prometheus metrics endpoint

Step 5: Start Services
----------------------

Start Charon first:

.. prompt:: bash $

   sudo systemctl enable --now charon.service

Verify Charon is running:

.. prompt:: bash $

   sudo journalctl -u charon -f

Then start your preferred validator client's Obol service:

**Lighthouse:**

.. prompt:: bash $

   sudo systemctl enable --now lighthouse-validator-obol.service

**Prysm:**

.. prompt:: bash $

   sudo systemctl enable --now prysm-validator-obol.service

**Nimbus:**

.. prompt:: bash $

   sudo systemctl enable --now nimbus-validator-obol.service

**Lodestar:**

.. prompt:: bash $

   sudo systemctl enable --now lodestar-validator-obol.service

**Teku:**

.. prompt:: bash $

   sudo systemctl enable --now teku-validator-obol.service

**Grandine:**

.. prompt:: bash $

   sudo systemctl enable --now grandine-validator-obol.service

Step 6: Verify Cluster Health
-----------------------------

Check the Charon health endpoint:

.. prompt:: bash $

   curl http://localhost:3620/readyz

A healthy response returns ``OK``.

Monitor cluster peers:

.. prompt:: bash $

   curl http://localhost:3620/metrics | grep p2p_peer

All cluster members should show as connected.

Backup Procedures
-----------------

.. warning::

   Losing your ``.charon`` directory means losing your validator key share.
   Regular backups are essential.

Critical files to backup:

- ``/home/ethereum/.charon/charon-enr-private-key``: **Identity Key**. Without this, your node cannot participate in the cluster.
- ``/home/ethereum/.charon/cluster-lock.json``: **Cluster Definition**. Defines the cluster configuration and peers.
- ``/home/ethereum/.charon/validator_keys/``: **Validator Key Shares**. Your slice of the private key.

The ``ethereumonarm-utils`` package includes ``.charon`` in its backup configuration.

To manually backup:

.. prompt:: bash $

   tar -czvf charon-backup-$(date +%Y%m%d).tar.gz /home/ethereum/.charon

Voluntary Exit
--------------

Exiting a distributed validator requires coordination among cluster operators.

**Step 1: All operators sign the exit**

Each operator runs:

.. prompt:: bash $

   charon exit sign \
     --beacon-node-url http://localhost:5052 \
     --validator-public-key 0xYOUR_VALIDATOR_PUBKEY

.. important::

   All operators must use the same ``EXIT_EPOCH``. Coordinate with your cluster members.

**Step 2: Broadcast the exit**

Once a threshold of operators have signed, the exit is automatically broadcast.

To manually broadcast:

.. prompt:: bash $

   charon exit broadcast

**Step 3: Wait for exit completion**

The exit process takes approximately 27+ hours depending on the exit queue.
Validators must continue performing duties until fully exited.

Monitor exit status:

.. prompt:: bash $

   curl -s http://localhost:5052/eth/v1/beacon/states/head/validators/0xYOUR_PUBKEY | jq '.data.status'

Lido CSM Integration
--------------------

For Lido Community Staking Module operators, use the Lido-specific DVT services which include the correct fee recipient addresses:

- ``lighthouse-validator-obol-lido.service``
- ``prysm-validator-obol-lido.service``
- ``nimbus-validator-obol-lido.service``
- ``grandine-validator-obol-lido.service``

See :doc:`/advanced/lido` for complete Lido CSM setup instructions including withdrawal addresses for DKG.

Troubleshooting
---------------

**Charon won't start**

- Check ENR private key exists: ``ls -la /home/ethereum/.charon/charon-enr-private-key``
- Verify cluster-lock.json is present
- Check beacon node is accessible

**Peers not connecting**

- Verify port 3610 is open: ``sudo ufw allow 3610``
- Check firewall/router port forwarding
- Ensure all operators are online

**Validator not attesting**

- Verify Charon is healthy: ``curl http://localhost:3620/readyz``
- Check validator client logs: ``journalctl -u lighthouse-validator-obol -f``
- Ensure keystore files are in the correct location

**Clock synchronization issues**

DVT requires tight clock synchronization (< 2 seconds). Install chrony:

.. prompt:: bash $

   sudo apt-get install chrony

Monitoring
----------

Grafana dashboards for Obol Charon are included in the ``ethereumonarm-monitoring-extras`` package:

- **Obol - Charon Node**: Individual node metrics
- **Obol - Charon Cluster**: Cluster-wide metrics

Access at: ``http://YOUR_NODE_IP:3000``

Further Resources
-----------------

- `Obol Documentation <https://docs.obol.tech>`_
- `Charon GitHub <https://github.com/ObolNetwork/charon>`_
- `Distributed Validator Launchpad <https://launchpad.obol.tech>`_
