.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Running Ethereum
================

Great, all ready. Now it is time to run an Ethereum node. You 
can run an Ethereum 1.0 client, an Ethereum 2.0 one, or both.

In this Quick Start Guide we will enable and start the :guilabel:`Geth` Eth1 client 
and the :guilabel:`Lighthouse` Eth2 Beacon Chain client, both running at the same time.

.. note::
  The Beacon Chain is the Eth2 Blockchain but this is not what is call 
  Staking. For this, you will need a **Validator** which is a more complicated
  process. If you want to run a Validator you will need 32 ETH and some
  knowledge of how Ethereum2.0 works.

  See more info in our :doc:`User Guide </quick-guide/about-quick-start>` section.


Ethereum 1.0
------------

The original Ethereum chain (with a proof of work consensus algorithm). 
Everything happens here right now, from transactions to smart contracts 
executions.

.. note::
  You can **not** mine Ethereum 1.0 with an ARM device as it depends on CPU
  power and these devices are quite limited. So, you can run an Ethereum node 
  in order to achieve the following goals:

  * Run as an Eth1 provider for the Eth2 Beacon chain (this means running both Eth1 and Eth2 nodes).
  * For contributing to the Ethereum network health and decentralization.

For enabling and starting :guilabel:`Geth` eth1.0 client, follow these steps:

1. **Open the 30303 port in your router** so :guilabel:`Geth` can discover and connect 
to other peers (both UDP and TCP protocols).

2. **Enable the service and start** it:

.. prompt:: bash $

  sudo systemctl enable geth
  sudo systemctl start geth

That’s it, **you are running an Eth1 node** and it is now syncing the Blockchain.

For checking the client logs, run:

.. prompt:: bash $

  sudo journalctl -u geth -f

You can access Grafana's :guilabel:`Geth` Dashboard to get further info of the client.

.. note::
  Ethereum on ARM supports 4 Eth1 clients: Geth, Hyperledger Besu, Openethereum
  and Nethermind (already installed in your image)

  We recommend running Geth as default as it is the most reliable and tested
  client for ARM devices. Other clients such as Nethermind and Openethereum performs 
  great on these boards so you can give them a try.

Ethereum 2.0
------------

Ethereum 2.0 is the transition of **Proof of Work** to **Proof of Stake** consensus algorithm. It is
currently on Phase 0 (since December 2020) and you can run an Eth2.0 node on your 
Raspberry Pi 4.

In this Quick Guide we are going to take the first step on running an Ethereum 2.0 node, 
enable the Beacon Chain through the :guilabel:`Lighthouse` client. If you want to run the 
validator, please see our :doc:`User Guide </quick-guide/about-quick-start>` to get a step by step 
explanation.

For enabling and starting the :guilabel:`Lighthouse` Eth2.0 Beacon Chain, follow these steps:

1. **Open the 9000  port in your router** so :guilabel:`Lighthouse` can discover and connect
to other peers (both ``UDP`` and ``TCP`` protocols).

2. **Enable the service and start** it:

.. prompt:: bash $

  sudo systemctl enable lighthouse-beacon
  sudo systemctl start lighthouse-beacon

Now, :guilabel:`Lighthouse` will connect to the :guilabel:`Geth` Eth1.0 client and start syncing the
Beacon chain.

You can get the client logs by running:

.. prompt:: bash $

  sudo journalctl -u ligthouse-beacon -f

.. tip::
  You can run both Eth1.0 and Eth2.0 nodes on you Raspberry Pi 4 (8 GB RAM model). We've been 
  staking since day zero with Geth as Eth1.0 provider and Lighthouse as Eth2.0 client.

