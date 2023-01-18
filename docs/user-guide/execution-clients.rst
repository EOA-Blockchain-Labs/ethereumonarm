.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Execution Clients
=================

The **Execution Clients** (formerly known as Ethereum 1.0) are the clients responsible for 
executing transactions and store the global state among other operations.

Supported clients
-----------------

Ethereum on ARM supports all available Execution Layer clients.

.. csv-table:: Execution Layer Supported Clients
   :header: Client, Official Binary, Language, Home

   `Geth`, `Yes`, `Go`, geth.ethereum.org_
   `Nethermind`, `Yes`, `.NET`, nethermind.io_
   `Erigon`,`No (crosscompiled)`, `Go`, `github.com/ledgerwatch/erigon`_
   `Hyperledger Besu`, `Yes`, `Java`, hyperledger.org_

.. _geth.ethereum.org: https://geth.ethereum.org
.. _nethermind.io: https://nethermind.io
.. _github.com/ledgerwatch/erigon: https://github.com/ledgerwatch/erigon
.. _hyperledger.org: https://hyperledger.org/use/besu

.. warning::

  Remember that you need to run a Consensus Layer client along with the Execution Layer client.

Geth
~~~~

:guilabel:`Geth` is the most used EL client. It is developed by the Ethereum Foundation team
and the performance on ARM64 devices is outstanding. It is capable of syncing the whole blockchain 
in 2 days on a **Raspberry Pi 4 with 8 GB RAM** and in less that 1 day on the 
**Radxa Rock 5B**.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `geth`, `/home/ethereum/.geth`, `/etc/ethereum/geth.conf`, `30303`

You can start the client by running:

.. prompt:: bash $

  sudo systemctl start geth

For further info of how the node is doing you can use Systemd journal or connect 
to the Grafana dashboard. 

.. prompt:: bash $

  sudo journalctl -u geth -f

The Grafana Dashboard is accessible through your web browser::

  http://replace_with_your_IP:3000
  user: admin
  passwd: ethereum

Nethermind
~~~~~~~~~~

:guilabel:`Nethermind` is a .NET enterprise-friendly full Execution Layer client.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `nethermind`, `/home/ethereum/.nethermind`, `/opt/nethermind/configs/mainnet.json`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start nethermind  

Hyperledger Besu
~~~~~~~~~~~~~~~~

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `besu`, `/home/ethereum/.besu`, `/etc/ethereum/besu.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start besu

Erigon
~~~~~~

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `erigon`, `/home/ethereum/.erigon`, `/etc/ethereum/erigon.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start erigon

.. note::
  :guilabel:`Erigon` is the only client that includes a Light Consensus Client. You can 
  run a full Ethereum node just by starting the Erigon service.
