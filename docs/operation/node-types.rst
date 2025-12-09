.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum nodes
==============

There are 2 main categories of Ethereum nodes you can run:

* Layer 1 nodes (Mainnet)
* Layer 2 nodes (Scaling solutions)

A **Layer 1** Ethereum node is responsible for validating and propagating transactions and blocks across the main network. 
Layer 1 nodes play a key role in maintaining the security and decentralization of the Ethereum network.

**Layer 2** Ethereum nodes, or L2 nodes, refer to **off-chain scaling solutions** built on top of the Ethereum blockchain to 
improve its scalability, throughput, and transaction speed. This category often includes sidechains and other scaling protocols supported by Ethereum on ARM.

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
  a full node does not store all state data back to genesis).
* Participates in block validation, verifies all blocks and states.
* All states can be derived from a full node (although very old states 
  are reconstructed from requests made to archive nodes).
* Serves the network and provides data on request.

This is the default mode for all clients. **In order to run a Full node you 
need an Execution Layer Client and a Consensus Layer Client** (just the Beacon Node part).

.. note::

  :guilabel:`Erigon` includes an embedded Consensus Client (Caplin) by default. If you use this client 
  and you are not going to stake, **you can run a full node just by starting the Erigon 
  service** without a separate Beacon Node.

Archive Ethereum node
~~~~~~~~~~~~~~~~~~~~~

Definitions from `ethereum.org`_

* Stores everything kept in the full node and builds an archive of historical states. 
  It is needed if you want to query something like an account balance at block #4,000,000, 
  or simply and reliably test your own transactions set without mining them using tracing.
* This data represents several terabytes, which makes archive nodes less attractive for 
  average users due to high storage requirements, but they are handy for services like block explorers, 
  wallet vendors, and chain analytics.

If you want to start an archive node, we highly recommend using :guilabel:`Erigon` or :guilabel:`Reth` clients due to their efficient storage usage. 
Take into account that you will need a 4 TB SSD disk (or larger) and the sync time will take several days.

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

Ethereum on ARM supports the following L2 and scaling solutions:

* Optimism_
* Base_ (built on the OP Stack)
* Arbitrum_
* Starknet_
* Fuel_
* Ethrex_ (L2 mode)

.. _Optimism: https://www.optimism.io/
.. _Base: https://base.org/
.. _Arbitrum: https://arbitrum.io/
.. _Starknet: https://www.starknet.io/
.. _Fuel: https://fuel.network/
.. _Ethrex: https://ethrex.xyz