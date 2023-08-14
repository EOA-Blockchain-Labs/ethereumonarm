.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Managing Clients
================

Systemd Services
----------------

All clients use :guilabel:`Systemd` services for running. :guilabel:`Systemd` 
takes care of the processes and automatically restarts them in case something 
goes wrong. It can enable a service to automatically start it on boot as well.

:guilabel:`Systemd` command ``systemctl`` manages all operations related to 
the services. The available options are as follows:

  * **Enable**: Activate the service to start on boot
  * **Disable**: Remove the service from boot start
  * **Start**: Start the client process
  * **Stop**: Stop the client process
  * **Restart**: Restart the clients process

The general syntax is:

.. prompt:: bash $

  sudo systemctl enable|disable|start|stop|restart service_name

.. note::
  You need the ``sudo`` command as root permissions are necessary. Type your 
  etherereum user password.

For instance, to enable :guilabel:`Nethermind` client on boot and start it, type:

.. prompt:: bash $

  sudo systemctl enable nethermind
  sudo systemctl start nethermind

:guilabel:`Nethermind` will now start in the background and run automatically 
on next boot.

These are the list of services available for all clients:

.. csv-table:: Execution layer Systemd Services
   :header: Client, Systemd Service

   `Geth`, `geth`
   `Nethermind`, `nethermind`
   `Erigon`,`erigon`
   `Reth`, `reth`
   `Hyperledger Besu`, `besu`

.. csv-table:: Consensus Layer Systemd Services
   :header: Client, Systemd Services

   `Lighthouse`, `lighthouse-beacon` `lighthouse-validator` 
   `prysm`, `prysm-beacon` `prysm-validator`
   `Nimbus`, `nimbus`
   `Teku`, `teku`


Changing Parameters
-------------------

:guilabel:`Systemd` services read client variables from ``/etc/ethereum`` directory files. If
you want to change any client parameter you have to edit the correspondent config file. For 
instance, this is the ``/etc/ethereum/geth.conf`` content::

  ARGS="--metrics --metrics.expensive --pprof --http --authrpc.jwtsecret=/etc/ethereum/jwtsecret"

Edit the file by running a text editor (``vim``, ``nano``):

.. prompt:: bash $

  sudo vim /etc/ethereum/geth.conf

For instance, let's change the P2P port to 30304. Add it to the ARGS line and save it::

  ARGS="--metrics --metrics.expensive --pprof --http --authrpc.jwtsecret=/etc/ethereum/jwtsecret --port 30304"

For changes to take effect, you need to restart the client:

.. prompt:: bash $

  sudo systemctl restart geth

.. note::

  All clients have its own config files in ``/etc/ethereum`` except :guilabel:`Nethermind` that 
  has an additional conf directory located in ``/opt/nethermind/configs/``

.. tip::
  Read the clients official documentation in order to learn the specific parameters
  of each client.


Updating Clients
----------------

APT repository
~~~~~~~~~~~~~~

.. note::

  If you see this warning running APT:
  
  ``Key is stored in legacy trusted.gpg keyring (/etc/apt/trusted.gpg), see the DEPRECATION section in apt-key(8) for details``
  
  run the following command:

  .. prompt:: bash $

    wget -q -O - http://apt.ethereumonarm.com/eoa.apt.keyring.gpg| sudo tee 
    /etc/apt/trusted.gpg.d/eoa.apt.keyring.gpg > /dev/null
    

**Ethereum on ARM** comes with a custom ``APT`` repository which allows users to easily
update the Ethereum software. For instance, to update the :guilabel:`Geth` client run:

.. prompt:: bash $

  sudo apt update
  sudo apt install geth

If you want to run the new version, restart the service by running:

.. prompt:: bash $

  sudo systemctl restart geth

**You can downgrade a client as well** by setting a specific version. This is particularly useful if 
a bug is found in the current version and you need to keep running the client. For example:

.. prompt:: bash $

  sudo apt install geth=1.9.25-2

The APT repository is browsable so you can download a package manually:

`https://apt.ethereumonarm.com/pool/main`_

.. _https://apt.ethereumonarm.com/pool/main: https://apt.ethereumonarm.com/pool/main/

Available Packages
~~~~~~~~~~~~~~~~~~

These are the available packages:

**L1 clients**

*Execution Layer clients*

* geth
* nethermind
* erigon
* besu
* reth

*Consensus Layer clients*

* lighthouse
* prysm
* teku
* nimbus

**L2 clients**

*Polygon*

* polygon-heimdall
* polygon-bor

*Optimism*

* optimism-l2geth
* optimism-op-geth
* optimism-op-node

*Arbitrum*

* arbitrum-nitro

*Starknet*

* papyrus
* juno

**Web 3**

* bee
* kubo
* status

**Infra**

* staking-deposit-cli
* mev-boost

.. note::
  The `APT` command will install the last version available in the repository. Most clients 
  provide binaries for ARM64 architecture so this is just a package to handle the software.

  See our developer guide section if you want to build you own packages.

Getting Logs
------------

You can get clients info by using :guilabel:`Systemd` ``journalctl`` command. For instance, 
to get the :guilabel:`Geth` ``output``, run:

.. prompt:: bash $

  sudo journalctl -u geth -f

You can of course take a look at ``/var/log/syslog``:

.. prompt:: bash $

  sudo tail -f /var/log/syslog

Monitoring Dashboards
---------------------

We configured Grafana Dashboards to let users monitor both Execution and Consensus clients. 
To access the dashboards just open your browser and type your ``Raspberry_IP`` followed by the 3000 port::

  http://replace_with_your_IP:3000
  user: admin
  passwd: ethereum


