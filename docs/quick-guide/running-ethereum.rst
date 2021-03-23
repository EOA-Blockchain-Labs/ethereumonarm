.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Running an Ethereum node
========================

Great, all set. Now it is time to run an Ethereum node. You 
can run an Ethereum 1.0 client, Ethereum 2.0, or both.

In this Quick Start Guide we will run the :guilabel:`Geth` Ethereum 1.0 client 
and the :guilabel:`Lighthouse` Ethereum 2.0 Beacon Chain client, both running in the same device.

.. note::
  :guilabel:`Geth` is enabled by default so you don't need to do anything to 
  get it up and running.

  The Beacon Chain is part of the Ethereum 2.0 Blockchain but for staking   For this, you will 
  need a **Validator** node which is a more complicated process. If you want to   run a Validator 
  along with the Beacon Chain you will need 32 ETH and some knowledge of how   Ethereum2.0 works.

  See more info in our :doc:`User Guide </user-guide/ethereum2.0>` section.


Ethereum 1.0
------------

The original Ethereum chain (with a Proof of Work consensus algorithm). 
Everything happens here right now, from transactions to smart contract 
executions.

.. note::
  You can **not** mine Ethereum 1.0 with an ARM device as it depends on CPU
  power and these devices are quite limited. So, you can run an Ethereum 1.0 node 
  in order to achieve the following goals:

  * Run as an Ethereum 1.0 provider for the Ethereum 2.0 Beacon chain (this means 
    running both Eth1 and Eth2 nodes).
  * In order to contribute to the Ethereum 1.0 network health and decentralization.

For enabling and starting :guilabel:`Geth` Eth1.0 client, you don't need to take any 
action as the :guilabel:`Systemd` service is already enabled and running. Just 
**Open the 30303 port in your router** so :guilabel:`Geth` can discover and connect 
to other peers (both UDP and TCP protocols).

For checking the client logs, run:

.. prompt:: bash $

  sudo journalctl -u geth -f

You can access Grafana's :guilabel:`Geth` Dashboard as well to get further info of the client.

.. note::
  Ethereum on ARM supports 4 Eth1 clients: :guilabel:`Geth`, :guilabel:`Nethermind`, 
  :guilabel:`Openethereum` and :guilabel:`Besu` (all already installed in your system).

  We recommend running :guilabel:`Geth` as default as it is the most reliable and tested
  client for ARM devices.
 

Ethereum 2.0
------------

Ethereum 2.0 is the transition from **Proof of Work** to **Proof of Stake** consensus algorithm. It is
currently on Phase 0 (since December 2020) and you can runan Eth2.0 node on your
Raspberry Pi 4 as it doesn't depend upon CPU power.

In this Quick Guide we are going to take the first step on running an Ethereum 2.0 node: 
enabling the Beacon Chain through the :guilabel:`Lighthouse` client. If you want to run the 
Validator, please see our :doc:`User Guide </user-guide/ethereum2.0>` to get a step by step 
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

  sudo journalctl -u lighthouse-beacon -f

.. tip::
  It is recommended to wait for :guilabel:`Geth` client to get synced (this will take about 1 day and a half) 
  before enabling and running the Beacon chain.
 
  You can run both Eth1.0 and Eth2.0 nodes on the same Raspberry Pi 4 (8 GB RAM model). We've been 
  staking since day zero with Geth as Eth1.0 provider and Lighthouse as Eth2.0 client on our Raspberry Pi 4.

  It is important to have a backup plan, though. We recommend to setup an spare device with an Ethereum 1.0 node 
  in sync ready for take over if something goes wrong.

