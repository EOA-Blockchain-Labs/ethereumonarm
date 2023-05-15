.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum nodes
==============

There are 2 types of Ethereum nodes:

* Layer 1 nodes
* Layer 2 nodes

A **Layer 1** Ethereum node is responsible for validating and propagating transactions and blocks across the main network. 
Layer 1 nodes play a key role in maintaining the security and decentralization of the Ethereum network.

**Layer 2** Ethereum nodes, or L2 nodes, refer to **off-chain scaling solutions** built on top of the Ethereum blockchain to 
improve its scalability, throughput, and transaction speed.

Layer 1 node
------------

If you run an Ethereum L1 node **you are contributing to the health and decentralization of 
the network.**

You can use your own node to **verify** all the Ethereum transactions (no need to trust a third party), 
**send your own transactions** or query the blockchain for further info.

There are three node setups that you can run with your ARM board:

* A **Full** Ethereum node (Execution Layer + Consensus Layer Beacon Chain)
* An **Archive** Ethereum node (Execution Layer + Consensus Layer Beacon Chain)
* A **Staking** node (Full/Archive node + Consensus Layer Validator node + 32 ETH deposit)

Full Ethereum node
~~~~~~~~~~~~~~~~~~

Definitions from `ethereum.org`_

* Stores full blockchain data (although this is periodically pruned so 
a full node does not store all state data back to genesis)
* Participates in block validation, verifies all blocks and states.
* All states can be derived from a full node (although very old states 
are reconstructed from requests made to archive nodes).
* Serves the network and provides data on request.

This is the default mode for all clients. **In order to run a Full node you 
need an Execution Layer Client and a Consensus Layer Client** (just the Beacon Node part).

.. note::

  :guilabel:`Erigon` includes a light Consensus Client by default so if you use this client 
  and you are not going to stake **you can run a full node just by starting the Erigon 
  service.**

Archive Ethereum node
~~~~~~~~~~~~~~~~~~~~~

Definitions from `ethereum.org`_

* Stores everything kept in the full node and builds an archive of historical states. 
It is needed if you want to query something like an account balance at block #4,000,000, 
or simply and reliably test your own transactions set without mining them using tracing.
* This data represents units of terabytes, which makes archive nodes less attractive for 
average users but can be handy for services like block explorers, wallet vendors, and chain analytics.

If you want to start an archive node you need to run the :guilabel:`Erigon` client. Take into account 
that you will need a 4 TB SSD disk and the sync time will take several days.

Staking node
~~~~~~~~~~~~

If you want to **contribute to the Ethereum security** you can become a Validator and stake your 
ETH. You can do so by depositing 32 ETH into the mainnet staking contract and creating a pair of 
keys to run a Consensus Layer Validator. The CL Validator will propose new blocks and make attestations on 
blocks created by other validators.

You will need:

* A synced Ethereum node (Execution Layer Client + Consensus Layer Beacon Chain Client)
* A Consensus Layer Validator
* 32 ETH

.. _ethereum.org: https://ethereum.org

Layer 2 node
------------

Layer 2 solutions include various technologies, such as **state channels, sidechains and 
rollups** (like Optimistic Rollups and ZK-Rollups). These solutions offload some of the 
computational load from the main Ethereum blockchain, allowing for **faster and cheaper transactions**. 

Layer 2 nodes are responsible for maintaining the integrity and security of the off-chain transactions 
and state changes. They ensure that these transactions are valid and follow the rules of the Layer 2 
protocol before they are eventually committed back to the Ethereum Layer 1 blockchain.

Ethereum on ARM supports the following L2 solutions:

* Polygon_
* Arbitrum_
* Optimism_
* Starknet_
* Gnosis_

.. _Polygon: https://polygon.technology/
.. _Arbitrum: https://arbitrum.io/
.. _Optimism: https://www.optimism.io/
.. _Starknet: https://www.starknet.io/
.. _Gnosis: https://www.gnosis.io/