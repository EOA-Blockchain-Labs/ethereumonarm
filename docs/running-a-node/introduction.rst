.. _operation-introduction:

Running a Node
==============

This guide explains how to run and manage Ethereum nodes on your ARM device using systemd services.

.. important::
   You need to run **both** an Execution Layer client and a Consensus Layer client simultaneously. 
   Choose any EL+CL combination (we recommend minority clients), but keep them running together.

Quick Navigation
----------------

.. grid:: 1 2 2 3
   :gutter: 3

   .. grid-item-card:: 🔧 Managing Clients
      :link: /running-a-node/managing-clients
      :link-type: doc
      :class-card: sd-border-primary

      Start, stop, and monitor your node services with systemd.
      
      +++
      :bdg-info:`Essential`

   .. grid-item-card:: 📊 Node Types
      :link: /running-a-node/node-types
      :link-type: doc
      :class-card: sd-border-secondary

      Full nodes, archive nodes, light clients—understand the differences.

   .. grid-item-card:: ⚡ Layer 1 Clients
      :link: /running-a-node/layer-1
      :link-type: doc
      :class-card: sd-border-success

      Run Ethereum mainnet with Geth, Nethermind, Lighthouse, Teku, and more.
      
      +++
      :bdg-success:`Production Ready`

   .. grid-item-card:: 🚀 Layer 2 Clients
      :link: /running-a-node/layer-2
      :link-type: doc
      :class-card: sd-border-info

      Arbitrum, Optimism, Starknet, and other L2 scaling solutions.
      
      +++
      :bdg-success:`Production Ready`

   .. grid-item-card:: 🌐 Web3 Stack
      :link: /running-a-node/web3-stack
      :link-type: doc
      :class-card: sd-border-warning

      IPFS, Swarm, and decentralized storage solutions.

   .. grid-item-card:: 🧪 Testnets
      :link: /running-a-node/testnets
      :link-type: doc
      :class-card: sd-border-secondary

      Practice on Sepolia, Hoodi, and other test networks.

What You'll Learn
-----------------

.. dropdown:: Managing Systemd Services
   :icon: terminal
   :open:

   Learn to control your Ethereum clients with systemd:

   .. code-block:: bash

      sudo systemctl start geth          # Start a service
      sudo systemctl stop lighthouse     # Stop a service
      sudo journalctl -u geth -f         # View live logs

   :doc:`Full guide → </running-a-node/managing-clients>`

.. dropdown:: Understanding Node Types
   :icon: server

   Different node types serve different purposes:

   - **Full Node**: Stores recent state, validates new blocks
   - **Archive Node**: Stores complete historical state
   - **Light Client**: Minimal storage, relies on full nodes

   :doc:`Learn more → </running-a-node/node-types>`

.. dropdown:: Running Layer 1 Clients
   :icon: database

   Ethereum mainnet requires two clients working together:

   **Execution Layer** (choose one):
   Geth, Nethermind, Besu, Erigon, Reth

   **Consensus Layer** (choose one):
   Lighthouse, Prysm, Teku, Nimbus, Lodestar, Grandine

   :doc:`Setup guide → </running-a-node/layer-1>`

.. dropdown:: Running Layer 2 Clients
   :icon: rocket

   Scale Ethereum with Layer 2 solutions:

   - **Arbitrum** - Optimistic rollup
   - **Optimism/Base** - OP Stack chains
   - **Starknet** - ZK rollup
   - **Fuel Network** - Modular execution layer

   :doc:`L2 guide → </running-a-node/layer-2>`

Hardware Requirements
---------------------

.. csv-table::
   :align: left
   :header: Setup, RAM, Storage, Use Case

   Full Node, 16 GB, 2 TB NVMe, Standard operation
   Staking Node, 16 GB, 2 TB NVMe, Validator + beacon
   Archive Node, 32 GB, 4+ TB NVMe, Historical queries
   L2 Node, 16-32 GB, 2-4 TB NVMe, Depends on L2

.. tip::
   Start with the :doc:`Managing Clients </running-a-node/managing-clients>` guide if you're new to Ethereum on ARM.

Next Steps
----------

1. **New users**: Start with :doc:`/getting-started/installation`
2. **Run L1**: Follow :doc:`/running-a-node/layer-1`
3. **Run L2**: Follow :doc:`/running-a-node/layer-2`
4. **Stake**: See :doc:`/staking/solo-staking`