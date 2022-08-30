.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Execution Clients
=================

The **Execution Clients** (formerly Ethereum 1.0)

Supported clients
-----------------

Ethereum on ARM supports all available EL clients.

.. csv-table:: Execution Layer Supported Clients
   :header: Client, Official Binary, Language, Home

   `Geth`, `Yes`, `Go`, geth.ethereum.org_
   `Nethermind`, `Yes`, `.NET`, nethermind.io_
   `Erigon`,`No`, `Go`, github.com/ledgerwatch/erigon_
   `Hyperledger Besu`, `Yes`, `Java`, hyperledger.org_

.. _geth.ethereum.org: https://geth.ethereum.org
.. _nethermind.io: https://nethermind.io
.. _github.com/ledgerwatch/erigon: https://github.com/ledgerwatch/erigon
.. _hyperledger.org: https://hyperledger.org/use/besu

Geth
~~~~

:guilabel:`Geth` is the most used EL client. It is develope by the Ethereum Foundation team
nd the performance on ARM64 is outstanding. It is capable of syncing the whole blockchain 
in 2 days on a **Raspberry Pi 4 with 8 GB RAM** and in less that a day on the 
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

.. note::
  
  If you want to try another client use the ``systemctl`` command to stop and 
  disable :guilabel:`Geth` as seen on :doc:`Managing Clients </user-guide/managing-clients>` section:

.. prompt:: bash $

  sudo systemctl disable geth
  sudo systemctl stop geth

Now choose another client and start it through its Systemd service.

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
