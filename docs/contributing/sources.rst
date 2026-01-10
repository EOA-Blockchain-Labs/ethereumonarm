.. _contributing-sources:

Sources & Upstream Projects
===========================

This page provides links to the Ethereum on ARM source code and all upstream projects we package.

Ethereum on ARM Repository
--------------------------

.. grid:: 1 2 2 2
   :gutter: 3

   .. grid-item-card:: 📦 Main Repository
      :link: https://github.com/EOA-Blockchain-Labs/ethereumonarm
      :class-card: sd-border-primary

      Source code, packages, and image builders.
      
      +++
      :bdg-primary:`GitHub`

   .. grid-item-card:: 📚 Documentation
      :link: https://ethereumonarm.com
      :class-card: sd-border-info

      Official documentation site (you're here!).
      
      +++
      :bdg-info:`Docs`

Repository Structure
~~~~~~~~~~~~~~~~~~~~

.. code-block:: text

   ethereumonarm/
   ├── docs/                    # Sphinx documentation
   ├── fpm-package-builder/     # Package build system
   │   ├── l1-clients/          # L1 execution & consensus clients
   │   ├── l2-clients/          # L2 clients (Arbitrum, Optimism, etc.)
   │   └── infra/               # Monitoring, DVT, MEV tools
   └── image-creation-tool/     # ARM & cloud image builders

Layer 1 Clients
---------------

Execution Layer
~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Client, Language, Repository

   Geth, Go, `ethereum/go-ethereum <https://github.com/ethereum/go-ethereum>`_
   Nethermind, C#, `NethermindEth/nethermind <https://github.com/NethermindEth/nethermind>`_
   Besu, Java, `hyperledger/besu <https://github.com/hyperledger/besu>`_
   Erigon, Go, `ledgerwatch/erigon <https://github.com/ledgerwatch/erigon>`_
   Reth, Rust, `paradigmxyz/reth <https://github.com/paradigmxyz/reth>`_

Consensus Layer
~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Client, Language, Repository

   Lighthouse, Rust, `sigp/lighthouse <https://github.com/sigp/lighthouse>`_
   Prysm, Go, `prysmaticlabs/prysm <https://github.com/prysmaticlabs/prysm>`_
   Teku, Java, `Consensys/teku <https://github.com/Consensys/teku>`_
   Nimbus, Nim, `status-im/nimbus-eth2 <https://github.com/status-im/nimbus-eth2>`_
   Lodestar, TypeScript, `ChainSafe/lodestar <https://github.com/ChainSafe/lodestar>`_
   Grandine, Rust, `grandinetech/grandine <https://github.com/grandinetech/grandine>`_

Layer 2 Clients
---------------

.. csv-table::
   :align: left
   :header: Network, Client, Repository

   Arbitrum, Nitro, `OffchainLabs/nitro <https://github.com/OffchainLabs/nitro>`_
   Optimism, op-geth / op-node, `ethereum-optimism/optimism <https://github.com/ethereum-optimism/optimism>`_
   Starknet, Juno, `NethermindEth/juno <https://github.com/NethermindEth/juno>`_
   Starknet, Madara, `madara-alliance/madara <https://github.com/madara-alliance/madara>`_
   Fuel, fuel-core, `FuelLabs/fuel-core <https://github.com/FuelLabs/fuel-core>`_

Infrastructure & Tools
----------------------

Monitoring
~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Tool, Purpose, Repository

   Prometheus, Metrics collection, `prometheus/prometheus <https://github.com/prometheus/prometheus>`_
   Grafana, Dashboards, `grafana/grafana <https://github.com/grafana/grafana>`_
   Node Exporter, System metrics, `prometheus/node_exporter <https://github.com/prometheus/node_exporter>`_

DVT (Distributed Validator Technology)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Protocol, Client, Repository

   Obol, Charon, `ObolNetwork/charon <https://github.com/ObolNetwork/charon>`_
   SSV, SSV Node, `ssvlabs/ssv <https://github.com/ssvlabs/ssv>`_

MEV & Staking
~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Tool, Purpose, Repository

   MEV-Boost, MEV relay connector, `flashbots/mev-boost <https://github.com/flashbots/mev-boost>`_
   Commit-Boost, PBS sidecar, `Commit-Boost/commit-boost-client <https://github.com/Commit-Boost/commit-boost-client>`_
   ethstaker-deposit-cli, Key generation, `eth-educators/ethstaker-deposit-cli <https://github.com/eth-educators/ethstaker-deposit-cli>`_

Web3 & Storage
~~~~~~~~~~~~~~

.. csv-table::
   :align: left
   :header: Project, Purpose, Repository

   IPFS (Kubo), Decentralized storage, `ipfs/kubo <https://github.com/ipfs/kubo>`_
   Swarm (Bee), Decentralized storage, `ethersphere/bee <https://github.com/ethersphere/bee>`_

Official Resources
------------------

.. grid:: 1 2 2 3
   :gutter: 3

   .. grid-item-card:: 📖 Ethereum.org
      :link: https://ethereum.org/developers
      :class-card: sd-border-primary

      Official Ethereum documentation.

   .. grid-item-card:: 🔬 Ethresear.ch
      :link: https://ethresear.ch
      :class-card: sd-border-info

      Ethereum research forum.

   .. grid-item-card:: 📊 Client Diversity
      :link: https://clientdiversity.org
      :class-card: sd-border-warning

      Track client distribution.

   .. grid-item-card:: 🔍 Etherscan
      :link: https://etherscan.io
      :class-card: sd-border-success

      Block explorer.

   .. grid-item-card:: ⛽ Gas Tracker
      :link: https://etherscan.io/gastracker
      :class-card: sd-border-secondary

      Current gas prices.

   .. grid-item-card:: 📡 Beacon Chain
      :link: https://beaconcha.in
      :class-card: sd-border-info

      Consensus layer explorer.

.. seealso::

   - :doc:`/contributing/guidelines` - How to contribute
   - :doc:`/contributing/building-images` - Development guide
