.. _advanced-configuration:

.. meta::
   :description lang=en: Advanced Ethereum node configuration on ARM. MEV-Boost setup, Commit-Boost PBS, RPC access, and manual binary verification guides.
   :keywords: MEV-Boost ARM, PBS sidecar, node RPC, binary verification, advanced Ethereum

Advanced Configuration
======================

Advanced features for power users: MEV extraction, PBS sidecars, and node customization.

.. grid:: 1 2 2 2
   :gutter: 3

   .. grid-item-card:: ⚡ MEV-Boost
      :link: /advanced/mev-boost
      :link-type: doc
      :class-card: sd-border-primary

      Connect to MEV relays for extra rewards.
      
      +++
      :bdg-success:`Popular`

   .. grid-item-card:: 🚀 Commit-Boost
      :link: /advanced/commit-boost
      :link-type: doc
      :class-card: sd-border-info

      PBS sidecar for proposer commitments.
      
      +++
      :bdg-warning:`New`

   .. grid-item-card:: 🔌 Using Node RPC
      :link: /advanced/using-node-rpc
      :link-type: doc
      :class-card: sd-border-success

      Query your node via JSON-RPC.

   .. grid-item-card:: ✅ Manual Verification
      :link: /advanced/manual-verification
      :link-type: doc
      :class-card: sd-border-secondary

      Verify your node is working correctly.

MEV Overview
------------

**Maximal Extractable Value (MEV)** allows validators to earn additional rewards by including optimally ordered transactions in blocks.

.. important::
   MEV-Boost is optional but recommended for validators who want to maximize rewards.

How it works:

1. **Block Builders** - Create optimized blocks with MEV
2. **Relays** - Connect validators to builders
3. **MEV-Boost** - Sidecar that requests blocks from relays
4. **Proposer** - Your validator proposes the winning block

.. dropdown:: MEV Relay Options
   :icon: broadcast

   Popular relays for Ethereum mainnet:

   - **Flashbots** - ``https://0xac6...@boost-relay.flashbots.net``
   - **bloXroute** - Multiple options (ethical, regulated, max profit)
   - **Ultrasound** - ``https://0xa1d...@relay.ultrasound.money``
   - **Aestus** - ``https://0xa15...@mainnet.aestus.live``

   :doc:`Full MEV-Boost setup → </advanced/mev-boost>`

RPC Access
----------

Your node exposes JSON-RPC endpoints for queries and transactions:

.. csv-table::
   :align: left
   :header: Client, Default Port, Documentation

   Execution Layer, 8545, `Ethereum JSON-RPC <https://ethereum.org/developers/docs/apis/json-rpc>`_
   Consensus Layer, 5052, `Beacon API <https://ethereum.github.io/beacon-APIs/>`_
   Optimism, 8547, `OP Stack RPC <https://docs.optimism.io/builders/node-operators/json-rpc>`_
   Arbitrum, 8547, `Arbitrum RPC <https://docs.arbitrum.io/build-decentralized-apps/reference/node-interface>`_

Example query:

.. code-block:: bash

   curl -X POST http://localhost:8545 \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

.. seealso::

   - :doc:`/staking/solo-staking` - Validator setup
   - :doc:`/running-a-node/layer-1` - L1 client configuration
