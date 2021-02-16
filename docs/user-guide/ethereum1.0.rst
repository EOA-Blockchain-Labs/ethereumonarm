.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum 1.0
============

Ethereum 1.0 is the first Ethereum implementation and uses a Proof of 
Work algorithm.

you can run an Ethereum node in order to achieve the following goals:

  * Run as an **Ethereum 1.0 provider** for the Ethereum 2.0 Beacon chain 
    (this means running both Ethereum 1.0 and Ethereum 2.0 nodes).

  * Contribute to the Ethereum network **health and decentralization**.

Supported clients
-----------------

Ethereum on ARM supports all functional clients that works on the ARM64 
architecture.

.. csv-table:: Ethereum 1.0 Supported Clients
   :header: Client, Official Binary, Language, Home

   `Geth`, `Yes`, `Go`, geth.ethereum.org_
   `Nethermind`, `Yes`, `.NET`, nethermind.io_
   `Openethereum`,`No`, `Rust`, openethereum.github.io_
   `Hyperledger Besu`, `Yes`, `Java`, hyperledger.org_

.. _geth.ethereum.org: https://geth.ethereum.org
.. _nethermind.io: https://nethermind.io
.. _openethereum.github.io: https://openethereum.github.io
.. _hyperledger.org: https://hyperledger.org/use/besu

Geth
~~~~

.. tip::
  :guilabel:`Geth` is the only client that runs by default so when you 
  boot up the device for the first time it is already syncing the blockchain 
  in the background.

:guilabel:`Geth` is the reference node client for Ethereum 1.0. It 
is the most reliable and rock solid client out there and the performance 
on ARM64 is outstanding. It is capable of syncing the whole blockchain 
in less than 2 days on a Raspberry Pi 4 with 8 GB RAM and a SSD.

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `geth`, `/home/ethereum/.geth`, `/etc/ethereum/geth.conf`, `30303`

You are already running :guilabel:`Geth` so you don't need to do anything to 
run the client.

For further info of how the node is doing you can use Systemd journal or connect 
to the Grafana dashboard. 

.. prompt:: bash $

  sudo systemctl disable geth
  sudo systemctl stop geth

The Grafana Dashboard is accessible through your web browser::

  http://replace_with_your_IP:3000
  user: admin
  passwd: ethereum

.. note::
  
  If you want to try another client use the ``systemctl`` command to stop and 
  disable it as seen on :doc:`Managing Clients </user-guide/managing-clients>` section:

.. prompt:: bash $

  sudo systemctl disable geth
  sudo systemctl stop geth

Now choose another client and start it through Systemd service.

Nethermind
~~~~~~~~~~

:guilabel:`Nethermind` is a .NET enterprise-friendly full Ethereum 1.0 client.

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

Openethereum
~~~~~~~~~~~~

.. csv-table::
  :header: Systemd Service, Home Directory, Config File, Default TCP/UDP Port

  `openethereum`, `/home/ethereum/.openethereum`, `/etc/ethereum/openethereum.conf`, `30303`

In order to start the client run:

.. prompt:: bash $

  sudo systemctl start openethereum
