Ethereum nodes
==============

.. meta::
   :description lang=en: Ethereum node types explained. Understand full nodes vs archive nodes vs light clients. Storage requirements and use cases for ARM hardware.
   :keywords: full node vs archive node, light client, Ethereum node storage, pruned node, historical state

There are 2 main categories of Ethereum nodes you can run:

* **Layer 1 nodes** (Mainnet)
* **Layer 2 nodes** (Scaling solutions)

Layer 1 Node
------------

Running a Layer 1 node is the most direct way to contribute to the Ethereum network. You can participate in two main ways: by choosing your **Data Strategy** (how much data you store) and your **Role** (what you do with that data).

Data Strategies: Full vs Archive
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This choice determines your storage requirements and how far back you can easily query historical states.

**1. Full Ethereum Node (Default)**

*   **Stores**: Full blockchain data, but periodically prunes old state data.
*   **Validation**: Verifies all blocks and states.
*   **Storage**: Efficient (~1-2 TB).
*   **Usage**: Ideal for most users, staking, and standard RPC requests.
*   **Requirements**: Execution Client + Consensus Client (Beacon Node).
    *   *Note*: :guilabel:`Erigon` includes an embedded Consensus Client (Caplin), allowing you to run a full node with a single service.

**2. Archive Ethereum Node**

*   **Stores**: Everything kept in a full node **plus** an archive of all historical states.
*   **Validation**: Verifies all blocks and states.
*   **Storage**: Heavy (~3 TB for Erigon/Reth, >10 TB for Geth/Nethermind).
*   **Usage**: Required for querying historical balances (e.g., "What was my balance at block #4,000,000?") or deep chain analytics.
*   **Recommendation**: If you need an archive node, we highly recommend :guilabel:`Erigon` or :guilabel:`Reth` due to their storage efficiency. A 4 TB SSD is required.

.. list-table:: Full vs Archive Node Comparison
   :widths: 25 35 40
   :header-rows: 1

   * - Feature
     - Full Node
     - Archive Node
   * - **Data Stored**
     - Current state + recent history
     - All historical states from Genesis
   * - **Storage (ARM)**
     - ~1-2 TB
     - ~3-4 TB (Erigon/Reth only)
   * - **Sync Time**
     - Days
     - Days to Weeks
   * - **Best For**
     - Staking, Personal Use, DApps
     - Block Explorers, Analytics, Debugging

Roles: Observer vs Validator
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Once you have your node (Full or Archive), you decide its role.

**1. Observer / RPC Node**
You run the node passively to verify the chain, submit your own transactions, and query data without trusting third parties. No ETH is required. This contributes to the network's specialized decentralization and health.

**2. Validator (Staking) Node**
You actively participate in securing the network by proposing and attesting to blocks.

*   **Requirement**: Full or Archive Node + **Validator Client** + **32 ETH**.
*   **Responsibility**: You must keep your node online and functioning to earn rewards.

Layer 2 Node
------------

Layer 2 (L2) nodes support off-chain scaling solutions that improve Ethereum's speed and cost. They periodically commit proofs or data back to Layer 1.

Ethereum on ARM supports the following L2 solutions:

*   Optimism_
*   Base_ (built on the OP Stack)
*   Arbitrum_
*   Starknet_
*   Fuel_
*   Ethrex_ (L2 mode)

.. _Optimism: https://www.optimism.io/
.. _Base: https://base.org/
.. _Arbitrum: https://arbitrum.io/
.. _Starknet: https://www.starknet.io/
.. _Fuel: https://fuel.network/
.. _Ethrex: https://ethrex.xyz