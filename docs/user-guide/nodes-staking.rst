.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Full / Archive / Staking nodes
==============================

If you run an Ethereum node **you are contributing to the health and decentralization of 
the network.**

You can use your own node to **verify** all the Ethereum transactions (no need to trust a third party), 
**send your own transactions** or query the blockchain for further info.

There are three node setups you can run with your ARM board:

* A **Full** Ethereum node (Execution Layer + Consensus Layer Beacon Chain)
* An **Archive** Ethereum node (Execution Layer + Consensus Layer Beacon Chain)
* A **Staking** node (Full/Archive node + Consensus Layer Validator + 32 ETH)

Full Ethereum node
------------------

Definitions from `ethereum.org`_

* Stores full blockchain data (although this is periodically pruned so 
a full node does not store all state data back to genesis)
* Participates in block validation, verifies all blocks and states.
* All states can be derived from a full node (although very old states 
are reconstructed from requests made to archive nodes).
* Serves the network and provides data on request.

This is the default mode for all clients. **In order to run a Full node you 
need an Execution Layer Client and a Consensus Layer Client** ( just the Beacon Node part).

.. note::

  :guilabel:`Erigon` includes a light Consensus Client by default so if you use this client 
  and you are not going to stake **you can run a full node just by starting the Erigon 
  service.**

Archive Ethereum node
---------------------

Definitions from `ethereum.org`_

* Stores everything kept in the full node and builds an archive of historical states. 
It is needed if you want to query something like an account balance at block #4,000,000, 
or simply and reliably test your own transactions set without mining them using tracing.
* This data represents units of terabytes, which makes archive nodes less attractive for 
average users but can be handy for services like block explorers, wallet vendors, and chain analytics.

If you want to start an archive node you need to run the :guilabel:`Erigon` client. Take into account 
that you will need 4 TB of SSD disk and the sync time will be about 2 weeks.

Staking node
------------

If you want to **contribute to the Ethereum security** you can become a Validator and stake your 
ETH. You can do so by depositing 32 ETH into the mainnet staking contract and creating a pair of 
keys to run a Consensus Layer Validator. The CL Validator will propose new blocks and make attestations on 
blocks created by other validators.

You will need:

* A synced Execution Layer Client + A synced Consensus Layer Beacon Chain Client == Full/Archive node
* A Consensus Layer Validator
* 32 ETH

.. _ethereum.org: https://ethereum.org