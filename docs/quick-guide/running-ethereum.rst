.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Running Ethereum
================

Great, you are all set. Now it is time to run an Ethereum node. You 
can run an Eth1 client, an Eth2 one, or both.

For this Quick Start Guide we will enable and start the Geth Eth1 client 
and the Lighthouse Eth2 client, both running at the same time. 

This is the way we are running our Eth2 validator and using Geth as 
Eth1 provider in our Raspberry Pi 4.


Ethereum 1.0
------------

The original Proof of Work chain. Everything happens here right now, 
from transactions to smart contracts executions.

For enabling and starting Geth eth1 client, follow these steps:

**Open the 30303 port in your router** so Geth can discover and connect 
to other peers (both UDP and TCP protocols).

Enable the service and start it:

.. prompt:: bash $

  sudo systemctl enable geth
  sudo systemctl start geth

That’s it, you are running an Eth1 node and it is syncing the Blockchain.

If you want to check the client logs, run:

.. prompt:: bash $

  sudo journalctl -u geth -f

You can access Grafana's Geth Dashboard. Please see 

Ethereum 2.0
------------

You can both run a Beacon node and a Validator.
