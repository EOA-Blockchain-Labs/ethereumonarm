Obol DVT Staking
================

.. meta::
   :description lang=en: Obol DVT setup on ARM. Run distributed validators with Charon middleware for fault tolerance. Multi-operator staking on NanoPC T6 and Rock 5B.
   :keywords: Obol DVT, Charon middleware, distributed validator, fault tolerant staking, multi-operator validator

What is Obol DVT solution
-------------------------

This guide explains how to set up and run a Distributed Validator Technology cluster using Obol's Charon middleware on Ethereum on ARM.

Distributed Validator Technology (DVT) allows one/multiple operators to run validator(s) together in several nodes,
eliminating single points of failure and improving resilience.

What you get with Obol DVT
---------------------------

Running an Obol DVT cluster at home provides resilience against the most
common causes of validator downtime:

**No single point of failure**

As long as a threshold of nodes remain online and in sync, the cluster keeps
attesting. This means:

- **ISP outage** — if each node is on a different internet connection, 
  a single provider going down does not affect the cluster
- **Power blackout** — if nodes are geographically distributed, a local power
  cut only affects one node, and the cluster continues signing
- **Maintenance windows** — hardware upgrades, OS updates, client version
  bumps and configuration changes can be applied node by node with zero
  downtime
- **Hardware failure** — a node dying does not stop the cluster. Replace the
  hardware, resync, and rejoin
- **True client diversity** — each node can run a different Execution and
  Consensus client. A critical bug in one client only affects the nodes
  running it — the rest of the cluster continues signing. This also
  contributes to Ethereum network resilience by avoiding concentration in
  any single client implementation

For a deeper understanding of how Charon coordinates the cluster and how the
DVT threshold signing protocol works, refer to the Obol documentation:

https://docs.obol.org/learn/charon/intro

Cluster types
-------------

Obol supports two ways to run a Distributed Validator cluster:

**DV Alone**

A single operator runs all nodes in the cluster across different hardware,
locations and ISPs. The operator controls all nodes and holds all key shares.
This is the simplest setup and the one covered by the step-by-step guide.

**DV as a Group**

Multiple independent operators each run one node. No single operator holds
the full validator key — each holds only a key share generated during a
Distributed Key Generation (DKG) ceremony. A threshold of operators must
cooperate to sign duties, removing single-operator custody risk.

For further details refer to the Obol documentation:

https://docs.obol.org/learn/intro/obol-collective

Prerequisites
^^^^^^^^^^^^^

Obol cluster nodes
~~~~~~~~~~~~~~~~~~

You will need at least 3 nodes for a DV Alone cluster. Each node should meet
the following requirements:

- **Hardware**: ARM64 device with 24 GB RAM running Ethereum on ARM (Rock 5B,
  Orange Pi 5 Plus or NanoPC-T6 recommended)
- **Storage**: 2 TB NVMe SSD minimum (TLC, DRAM cache required)
- **Full Ethereum node**: Execution Layer + Consensus Layer clients fully
  synced on every node
- **Network**: Port 3610 open for P2P communication (TCP and UDP)
- **Validator keys** (DV Alone only): your existing EIP-2335 keystore files
  if you are migrating from solo staking

Control nodes
~~~~~~~~~~~~~

You will need 2 control nodes (active + failover) for monitoring
and backup staking:

- **Hardware**: ARM64 device with 16 GB RAM minimum running Ethereum on ARM
- **Storage**: 2 TB NVMe SSD minimum
- **Full Ethereum node**: Execution Layer + Consensus Layer clients fully
  synced on every node
- **Network**: VPN connectivity to all Obol cluster nodes

Node naming
~~~~~~~~~~~

When setting up each node, choose a hostname that identifies its location, device and
ISP. This makes it easy to trace alerts back to a specific machine and network.
For example: ``rock5b-plus-home-vodafone``, ``rock5b-plus-office-digi``.

The hostname is set during the Ethereum on ARM initial configuration and is
used throughout the monitoring alerts.

Telegram notifications
~~~~~~~~~~~~~~~~~~~~~~

The monitoring solution sends alerts via Telegram. You need a Telegram bot
and a channel or group to receive messages.

**Create a Telegram bot:**

1. Open Telegram and search for ``@BotFather``
2. Send ``/newbot`` and follow the prompts to name your bot
3. Copy the API token provided — you will need it during installation

**Create a Telegram channel or group:**

1. Create a new Telegram group or channel
2. Add your bot as an administrator
3. Send any message in the group
4. Visit the following URL in your browser (replace ``<YOUR_TOKEN>`` with
   your bot token)::

      https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates

5. Copy the ``id`` value from the ``chat`` object in the response — this is
   your ``chat_id``. Note that group and channel IDs are negative numbers
   (e.g. ``-1001234567890``). Copy the full number including the minus sign.

VPN setup
~~~~~~~~~

A VPN is strongly recommended to reduce network latency between nodes,
simplify firewall rules, and allow the control nodes to reach the cluster
nodes over a private network. Tailscale is the easiest option — it requires
no manual port forwarding and works across different ISPs and locations.

Install Tailscale on all nodes (cluster and control) following the official
guide at https://tailscale.com/download, then note down the Tailscale IP
assigned to each node.

Package installation
~~~~~~~~~~~~~~~~~~~~

Once all nodes are prepared, install the required packages on each node:

.. prompt:: bash $

   sudo apt-get update && sudo apt-get install dvt-obol ethereumonarm-staking-stack

Create a cluster Alone
----------------------
 
A solo DVT cluster means a single operator runs all nodes. This section covers
two scenarios: migrating existing validators into a DVT cluster, and creating a
fresh cluster with new validators.
 
Case 1: Migrating existing validators
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
If you are already running validators, you need to split your existing keystores
across the cluster nodes using Charon's key splitting feature.
 
Step 1: Prepare the keystores
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
Charon's ``--split-existing-keys`` option expects keystores named
``keystore-N.json`` with a matching ``keystore-N.txt`` file containing the
password for each keystore. Use the preparation script included with the
``ethereumonarm-staking-stack`` package to rename and prepare your files:
 
.. prompt:: bash $
 
   bash /usr/share/ethereumonarm-staking-stack/tools/prepare-validator-keys.sh
 
The script will ask for the keystores directory (default
``/home/ethereum/validator_keys``) and the keystore password. It renames all
existing keystore JSON files to the required format and creates the matching
password files.
 
Step 2: Create the cluster and split the keys
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
You can run this command on any machine that has the ``charon`` binary
installed — your desktop, a laptop, or one of the cluster nodes. It does not
need to be run on a node that will participate in the cluster.
 
Once the keystores are prepared, use ``charon create cluster`` to split them
across the cluster nodes. Replace the values in angle brackets with your own:
 
.. prompt:: bash $
 
   charon create cluster \
     --nodes=3 \
     --network=mainnet \
     --name="My Obol Cluster" \
     --cluster-dir=/home/ethereum/cluster \
     --split-existing-keys \
     --split-keys-dir=/home/ethereum/validator_keys \
     --fee-recipient-addresses=<0xYOUR_FEE_RECIPIENT> \
     --withdrawal-addresses=<0xYOUR_WITHDRAWAL_ADDRESS>
 
Adjust ``--nodes`` to match the number of nodes in your cluster (minimum 3 for
a DV Alone setup).
 
.. warning::
 
   Back up the entire ``--cluster-dir`` output directory before proceeding.
   This directory contains the ``charon-enr-private-key`` for each node, the
   ``cluster-lock.json``, and the split validator key shares. **This data
   cannot be regenerated.** If it is lost, access to the validators may be
   permanently lost. Store copies in at least two separate secure locations.
 
Step 3: Distribute the node directories
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
After the command completes, the ``--cluster-dir`` will contain one directory
per node (``node0``, ``node1``, ``node2``, etc.). Copy each directory to its
corresponding node and rename it to ``/home/ethereum/.charon``:
 
.. code-block:: bash
 
   # On the machine where you ran charon create cluster:
   scp -r /home/ethereum/cluster/node0/ ethereum@<node1-ip>:/home/ethereum/.charon
   scp -r /home/ethereum/cluster/node1/ ethereum@<node2-ip>:/home/ethereum/.charon
   scp -r /home/ethereum/cluster/node2/ ethereum@<node3-ip>:/home/ethereum/.charon
 
.. warning::
 
   The ``charon-enr-private-key`` file inside each node directory is unique to
   that node. Never copy the same node directory to multiple machines.
 
Step 4: Import the validator keys into the validator client
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
Each node's split keystores are located at
``/home/ethereum/.charon/validator_keys``. Use the import scripts included with
the ``ethereumonarm-staking-stack`` package to import them into your validator
client. The scripts stop the service, import the keystores one by one using
the matching per-keystore password files, and restart the service automatically.
 
All scripts default to ``/home/ethereum/.charon/validator_keys`` as the source
directory and use a dedicated data directory for the Obol validator instance
to keep it separate from any existing solo staking setup.
 
**Lighthouse** — imports into ``/home/ethereum/.lighthouse-validator-obol``:
 
.. prompt:: bash $
 
   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-lighthouse.sh
 
**Nimbus** — imports into ``/home/ethereum/.nimbus-validator-obol``:
 
.. prompt:: bash $
 
   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-nimbus.sh
 
**Prysm** — imports into ``/home/ethereum/.prysm-validator-obol``:
 
.. prompt:: bash $
 
   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-prysm.sh
 
**Teku** — imports into ``/home/ethereum/.teku-validator-obol``:
 
.. prompt:: bash $
 
   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-teku.sh
 
**Lodestar** — imports into ``/home/ethereum/.lodestar-validator-obol``:
 
.. prompt:: bash $
 
   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-lodestar.sh
 
**Grandine** — copies keystores to ``/home/ethereum/.grandine-validator-obol``:
 
.. prompt:: bash $
 
   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-grandine.sh
 
Case 2: Creating a fresh cluster with new validators
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
If you do not have existing validators, you need to generate new validator keys
as part of the cluster creation process. Charon handles this internally — no
separate key generation step is needed.
 
Step 1: Generate the ENR for each node
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
On each node that will be part of the cluster, generate a Charon ENR (a
cryptographic identity used for peer discovery and authentication):
 
.. prompt:: bash $
 
   charon create enr
 
This creates the file ``/home/ethereum/.charon/charon-enr-private-key`` and
prints your ENR to the terminal. It will look like:
 
.. code-block:: text
 
   enr:-JG4QGQpV4qYe32QFUAbY1UyGNtNcrVMip83cvJRhw1brMslPeyELIz3q6dsZ7...
 
.. warning::
 
   Back up ``/home/ethereum/.charon/charon-enr-private-key`` securely on each
   node. If you lose this file you will not be able to participate in the
   cluster.
 
Collect the ENR output from all nodes before proceeding to the next step.
 
Step 2: Create the cluster
^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
As with Case 1, this command can be run on any machine with the ``charon``
binary — it does not need to be one of the cluster nodes.
 
.. prompt:: bash $
 
   charon create cluster \
     --nodes=3 \
     --network=mainnet \
     --name="My Obol Cluster" \
     --cluster-dir=/home/ethereum/cluster \
     --fee-recipient-addresses=<0xYOUR_FEE_RECIPIENT> \
     --withdrawal-addresses=<0xYOUR_WITHDRAWAL_ADDRESS> \
     --operator-enrs=<enr-node1>,<enr-node2>,<enr-node3>
 
Replace ``<enr-node1>``, ``<enr-node2>``, ``<enr-node3>`` with the ENRs
collected in Step 1.
 
.. warning::
 
   Back up the entire ``--cluster-dir`` output directory before proceeding.
   This directory contains the ``charon-enr-private-key`` for each node, the
   ``cluster-lock.json``, and the generated validator key shares. **This data
   cannot be regenerated.** If it is lost, access to the validators may be
   permanently lost. Store copies in at least two separate secure locations.
 
Step 3: Distribute node directories and import keys
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
Follow Steps 3 and 4 from Case 1 above to distribute the node directories to
each cluster node and import the generated keystores into the validator clients.
 
.. note::
 
   The Obol Launchpad at https://launchpad.obol.org provides a web interface
   for creating clusters, sharing ENRs between operators, and coordinating the
   DKG ceremony. It is particularly useful for group clusters where operators
   are geographically distributed. For a DV Alone setup the command-line
   approach above is simpler and does not require the Launchpad.

Create a cluster as a Group
---------------------------

A group DVT cluster involves multiple independent operators, each running one
node. The validator key is never held by any single operator — it is generated
jointly during a **Distributed Key Generation (DKG) ceremony** where each
operator receives only a key share.

This process uses the **Obol DV Launchpad** to coordinate the cluster
configuration and the DKG ceremony between all operators. Unlike a DV Alone
cluster, there is no ``--split-existing-keys`` option — new validator keys are
always generated fresh during the ceremony.

The process has two roles:

- **Creator** — configures the cluster parameters and sends invitations to all
  operators. This role holds no special privilege in the running cluster, it
  only sets the initial terms that all operators agree to.
- **Operator** — accepts the invitation, contributes their ENR to the ceremony,
  and runs a node in the cluster.

In a group cluster each operator follows these steps on their own node.

Step 1: Generate your ENR
^^^^^^^^^^^^^^^^^^^^^^^^^

Each operator must generate a Charon ENR (a cryptographic identity used for
peer discovery and authentication during the DKG ceremony). Run this on the
node that will participate in the cluster:

.. prompt:: bash $

   charon create enr

This creates ``/home/ethereum/.charon/charon-enr-private-key`` and prints your
ENR to the terminal:

.. code-block:: text

   Created ENR private key: /home/ethereum/.charon/charon-enr-private-key
   enr:-JG4QGQpV4qYe32QFUAbY1UyGNtNcrVMip83cvJRhw1brMslPeyELIz3q6dsZ7...

.. warning::

   Back up ``/home/ethereum/.charon/charon-enr-private-key`` immediately and
   store it in a safe place. **If you lose this file you will not be able to
   participate in the DKG ceremony or start the cluster.**

Share your ENR with the cluster creator. They will need the ENR from every
operator before they can configure the cluster on the Launchpad.

Step 2: Creator — configure the cluster on the Launchpad
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::

   Skip this step if you are joining as an operator and someone else is the
   creator.

Before starting, the creator must collect from all operators:

- Their **Ethereum address** (used to sign the cluster configuration via
  MetaMask)
- Their **ENR** (generated in Step 1)

Then:

1. Go to the DV Launchpad at https://launchpad.obol.org
2. Connect your wallet (MetaMask or compatible)
3. Select **Create a Cluster with a group** then **Get Started**
4. Accept the advisories
5. Enter the **Cluster Name** and **Cluster Size** (number of operators). The
   signing threshold updates automatically
6. Enter the **Ethereum address** of each operator. Click **Use My Address**
   for your own entry
7. Select the number of validators (32 ETH each)
8. Enter your own **ENR** in the field provided
9. Choose a **withdrawal configuration**:

   - **Custom**: enter a principal address (receives the 32 ETH + consensus
     rewards on exit) and a fee recipient address (receives execution layer
     rewards). Both can be the same address
   - **Split only rewards**: uses an Obol Validator Manager contract to split
     rewards between a principal address and a splitter. Recommended for
     groups sharing rewards
   - **Split Everything**: both principal and rewards are distributed via
     splitter contracts
   - **Lido CSM**: for Lido Community Staking Module clusters

10. Click **Create Cluster Configuration**, review all details, then click
    **Confirm and Sign**. You will sign up to three transactions:

    - The ``config_hash`` — a hash of the cluster configuration
    - The ``operator_config_hash`` — your acceptance of the operator terms
    - Your ``ENR`` — authorising your private key to act in the cluster

11. Share the **cluster invite link** with all operators

Step 3: Operators — accept the invitation and sign
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Each operator (including the creator if they are also an operator):

1. Open the invite link shared by the creator
2. Connect your wallet
3. Review the cluster configuration
4. Enter your **ENR** generated in Step 1
5. Sign the configuration with your wallet

Once all operators have signed, the Launchpad shows everyone as ready and the
DKG ceremony can begin.

Step 4: Run the DKG ceremony
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All operators must run the DKG ceremony **at the same time**. Coordinate with
all other operators before starting — the ceremony requires all nodes to be
online simultaneously.

On each node, run:

.. prompt:: bash $

   charon dkg --definition-file=<URL_OR_PATH_TO_CLUSTER_DEFINITION>

The ``--definition-file`` value is either:

- The **cluster definition URL** from the Launchpad invite link (starts with
  ``https://api.obol.tech/dv/...``), or
- A local path to the ``cluster-definition.json`` file if distributed manually

Example with a Launchpad URL:

.. prompt:: bash $

   charon dkg \
     --definition-file="https://api.obol.tech/dv/0x..." \
     --data-dir=/home/ethereum/.charon

The ceremony takes a few minutes. When it completes successfully, each node
will have its own key share and a ``cluster-lock.json`` file written to
``/home/ethereum/.charon/``. The output looks like:

.. code-block:: text

   Successfully completed DKG ceremony
   Created /home/ethereum/.charon/cluster-lock.json
   Created /home/ethereum/.charon/validator_keys/keystore-0.json

.. warning::

   Back up the entire ``/home/ethereum/.charon/`` directory immediately after
   the ceremony. This contains your key share, the cluster lock, and the
   ``charon-enr-private-key``. **This data cannot be regenerated.** If it is
   lost you will permanently lose access to your key share.

Step 5: Import the validator keys
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

After the DKG ceremony each operator imports their key share into their
validator client. Use the import scripts included with the
``ethereumonarm-staking-stack`` package. All scripts read from
``/home/ethereum/.charon/validator_keys`` by default.

**Lighthouse** — imports into ``/home/ethereum/.lighthouse-validator-obol``:

.. prompt:: bash $

   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-lighthouse.sh

**Nimbus** — imports into ``/home/ethereum/.nimbus-validator-obol``:

.. prompt:: bash $

   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-nimbus.sh

**Prysm** — imports into ``/home/ethereum/.prysm-validator-obol``:

.. prompt:: bash $

   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-prysm.sh

**Teku** — imports into ``/home/ethereum/.teku-validator-obol``:

.. prompt:: bash $

   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-teku.sh

**Lodestar** — imports into ``/home/ethereum/.lodestar-validator-obol``:

.. prompt:: bash $

   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-lodestar.sh

**Grandine** — copies keystores to ``/home/ethereum/.grandine-validator-obol``:

.. prompt:: bash $

   bash /usr/share/ethereumonarm-staking-stack/tools/import-validators-grandine.sh

.. note::

   For the validator duties monitor on the control node, copy
   ``cluster-lock.json`` from any operator node to the control node and provide
   its path during the ``ethereumonarm-staking-stack`` installation. The monitor
   uses the full validator public keys from ``cluster-lock.json`` to track
   duties on the beacon chain.