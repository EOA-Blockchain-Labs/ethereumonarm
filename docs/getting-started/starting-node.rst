.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

.. meta::
   :description lang=en: Start your Ethereum node on ARM hardware. Learn how to run Geth, Lighthouse, and other clients with systemd on NanoPC T6, Rock 5B, and RPi5.
   :keywords: start Ethereum node, systemd blockchain, run Geth ARM, Lighthouse beacon chain, consensus client

Running an Ethereum node
========================

Great, all set. Now it is time to run an Ethereum full node. You 
need to **run an Execution Layer client and a Consensus Layer client at the same time**.

In this Quick Start Guide we will run the :guilabel:`Geth` EL
and the :guilabel:`Lighthouse` CL client.

.. note::

  The **Beacon Chain** is the Consensus Layer part that guides the Execution Layer on how to follow the head of the chain. 
  You need to run both, the **Consensus Layer Beacon Chain and the Execution Layer to run a full Ethereum node**. If you want 
  to **stake** (create blocks, formerly known as mining) you will need to run a **Consensus Layer Validator** as well which 
  is a more complicated process (besides you need to own 32 ETH).

Consensus Layer
---------------

Let's start by **running a Consensus Layer Beacon chain**. This client is the responsible of following the chain and telling
the Execution Layer where the chain head is. We will run :guilabel:`Lighthouse`.

.. tip::
  All CL clients are configured to use **CheckPoint Sync** that will get the 
  Beacon Chain in sync in just a few minutes. Take a look to our :doc:`Layer 1 Guide <../running-a-node/layer-1>` for 
  more info.

For starting the :guilabel:`Lighthouse` CL Beacon Chain, follow these steps:

1. **Open the 9000  port in your router** so :guilabel:`Lighthouse` can discover and connect
to other peers (both ``UDP`` and ``TCP`` protocols).

2. **Start** the service:

.. prompt:: bash $

  sudo systemctl start lighthouse-beacon

Now, :guilabel:`Lighthouse` will start syncing the Beacon Chain and try to connect to the Execution Layer client. The 
Beacon Chain will get in sync quite fast as it uses Checkpoint Sync so we can move on and start the Execution Layer client

You can get the client logs by running:

.. prompt:: bash $

  sudo journalctl -u lighthouse-beacon -f

.. note::
  Ethereum on ARM supports 6 CL clients: :guilabel:`Lighthouse`, :guilabel:`Prysm`, 
  :guilabel:`Teku`, :guilabel:`Nimbus`, :guilabel:`Lodestar` and :guilabel:`Grandine` (all already installed in your system).

Execution Layer
---------------

It is the former Ethereum 1.0 node and the original Ethereum chain. It needs to communicate with a Consensus Layer Beacon chain
to follow the chain. This client validates and executes all transactions and stores the chain state.

We will use the :guilabel:`Geth`. Follow these steps to start the client:

1. **Open the 30303 port in your router** so :guilabel:`Geth` can discover and connect 
to other peers (both ``UDP`` and ``TCP`` protocols).

2. **Start the service**

.. prompt:: bash $

  sudo systemctl start geth

For checking the client logs, run:

.. prompt:: bash $

  sudo journalctl -u geth -f

You can access Grafana's Dashboard as well to get further info of the clients.

.. note::
  Ethereum on ARM supports 6 EL clients: :guilabel:`Geth`, :guilabel:`Nethermind`, 
  :guilabel:`Erigon`, :guilabel:`Reth`, :guilabel:`Besu` and :guilabel:`EthRex` (all already installed in your system).

What's Next
-----------

Awesome! You are now running an Ethereum node!

The next step is to get your client synced and become more familiar with your node.
For more info about how the node works and to check sync status, please visit
our :doc:`Operation Guide <../running-a-node/introduction>`.

.. tip::
   Remember that you can stake with your ARM board. If you have
   32 ETH check out our **Consensus clients** section and get your validator up
   and running.