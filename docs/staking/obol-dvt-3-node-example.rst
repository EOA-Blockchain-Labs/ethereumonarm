:orphan:

Practical Example: 3-Node Cluster
=================================

This example demonstrates a complete walkthrough for creating a **3-node cluster** using Ethereum on ARM devices connected via a WireGuard VPN (using PiVPN as described in :doc:`/system/network-vpn`).

**Scenario:**

- **3 Nodes**: Node 0 (Leader), Node 1, Node 2.
- **Network**: All nodes are connected via WireGuard VPN (see :doc:`/system/network-vpn`).
- **Goal**: Create a Distributed Validator with 1 faulty node tolerance (CFT).

**Prerequisites:**

Ensure all 3 nodes have the ``dvt-obol`` package installed and are reachable via their VPN IPs:

- **Node 0**: ``10.1.25.10``
- **Node 1**: ``10.1.25.11``
- **Node 2**: ``10.1.25.12``

Cluster Diagram
~~~~~~~~~~~~~~~

.. code-block:: text

    +----------------+          +----------------+          +----------------+
    |     Node 0     |          |     Node 1     |          |     Node 2     |
    |   (Leader)     |          |   (Operator)   |          |   (Operator)   |
    |                |          |                |          |                |
    | VPN: 10.1.25.10| <------> | VPN: 10.1.25.11| <------> | VPN: 10.1.25.12|
    +----------------+          +----------------+          +----------------+

Step 1: Generate ENRs on All Nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Run this command on **Node 0**, **Node 1**, and **Node 2**:

.. prompt:: bash $

   charon create enr --p2p-tcp-address=10.1.25.X:3610 --p2p-udp-address=10.1.25.X:3610

*Replace `10.1.25.X` with the specific VPN IP of that node.*

This command outputs an ENR string starting with ``enr:-...``. **Copy this ENR.**
Send your ENR to the **Cluster Leader (Node 0)**.

Step 2: Create Cluster Definition (Node 0 Only)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On **Node 0**, collect the ENRs from Node 1 and Node 2. Then run:

.. prompt:: bash $

   charon create dkg \
     --name="ARM Cluster" \
     --num-validators=1 \
     --fee-recipient-addresses="0xYOUR_FEE_RECIPIENT_ADDRESS" \
     --withdrawal-addresses="0xYOUR_WITHDRAWAL_ADDRESS" \
     --operator-enrs="<ENR_NODE_0>,<ENR_NODE_1>,<ENR_NODE_2>"

*Replace `<ENR_NODE_X>` with the actual ENR strings, separated by commas (no spaces).*

This creates the ``cluster-definition.json`` file.
**Transfer this file to Node 1 and Node 2** (e.g., using ``scp`` via the VPN IPs).

Step 3: Run DKG Ceremony (All Nodes)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once every node has the ``cluster-definition.json`` file, run this command **simultaneously** on all 3 nodes:

.. prompt:: bash $

   charon dkg --definition-file=/path/to/cluster-definition.json

Wait for the process to complete. It will generate:
- ``cluster-lock.json``
- ``validator_keys/``
- ``deposit-data.json``

Step 4: Configure Charon on Each Node
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

On each node, edit the configuration file ``/etc/ethereum/dvt/charon.conf`` to ensure it listens on the VPN interface or all interfaces:

**Node 0 (10.1.25.10):**

.. code-block:: bash

   ARGS="...
         --p2p-tcp-addresses 10.1.25.X:3610 \
         --p2p-udp-addresses 10.1.25.X:3610 \
         --p2p-relays=\"\" \
         --monitoring-address 0.0.0.0:3620 \
         ..."

*Note: We bind P2P addresses to the VPN IP (10.1.25.X) to ensure traffic flows over the VPN. We also set `--p2p-relays=""` to disable public relays, ensuring a fully private cluster.*




**Step 5: Start Services**

On all nodes:

.. prompt:: bash $

   sudo systemctl enable --now charon.service
   sudo systemctl enable --now lighthouse-validator-obol.service

*(Replace `lighthouse` with your consensus client if different)*

Step 6: Centralized Monitoring
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To monitor the cluster from a single dashboard (e.g., on Node 0), add all nodes to your ``prometheus.yml``:

.. code-block:: yaml

  - job_name: "charon_cluster"
    metrics_path: "/metrics"
    static_configs:
      - targets: ["10.1.25.10:3620"]
        labels:
          dvt_provider: "obol"
          node_id: "0"
      - targets: ["10.1.25.11:3620"]
        labels:
          dvt_provider: "obol"
          node_id: "1"
      - targets: ["10.1.25.12:3620"]
        labels:
          dvt_provider: "obol"
          node_id: "2"
