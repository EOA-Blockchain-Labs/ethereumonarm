.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Managing Clients
================

Systemd Services
----------------

All clients use :guilabel:`Systemd` services for running. :guilabel:`Systemd` 
takes care of the processes and automatically restarts them in case something 
goes wrong. It can enable a service to automatically start on boot as well.

:guilabel:`Systemd` command ``systemctl`` manages all operations related to 
the services. The available options are as follows:

  * **`Enable`**: Activate the service to start on boot
  * **`Disable`**: Remove the service from boot start
  * **`Start`**: Start the client process
  * **`Stop`**: Stop the client process
  * **`Restart`**: Restart the clients process

The general syntax is:

.. prompt:: bash $

  sudo systemctl enable|disable|start|stop|restart service name

.. note::
  You need the ``sudo`` command as root permissions are necessary. Type your 
  etherereum user password.

For instance, to enable and run :guilabel:`Nethermind` client, type:

.. prompt:: bash $

  sudo systemctl enable nethermind
  sudo systemctl start nethermind

:guilabel:`Nethermind` will now start in the background and run automatically 
on next boot.

These are the list of the services available for all clients:

.. csv-table:: Ethereum 1.0 Systemd Services
   :header: Client, Systemd Service

   `Geth`, `geth`
   `Nethermind`, `nethermind`
   `Openethereum`,`openethereum`
   `Hyperledger Besu`, `besu`

.. csv-table:: Ethereum 2.0 Systemd Services
   :header: Client, Systemd Services

   `Lighthouse`, `lighthouse-beacon` `ligthouse-validator` 
   `prysm`, `prysm-beacon` `prysm-beacon`
   `Nimbus`, `nimbus`
   `Teku`, `teku`

.. tip::
  :guilabel:`Geth` is the only service that is enabled by default, so when you 
  boot up the device for the first time :guilabel:`Geth` will automatically
  start in the background and start syncing the Ethereum 1.0 blockchain.


Changing Parameters
-------------------

:guilabel:`Systemd` services read client variables from ``/etc/ethereum`` directory. If
you want to change any client parameter you have to edit the correspondent file. For 
instance, this is the ``/etc/ethereum/geth.conf`` content::

  ARGS="--http --metrics --metrics.expensive --pprof --maxpeers 100"

Edit the file by running a text editor (``vim``, ``nano``):

.. prompt:: bash $

  sudo vim /etc/ethereum/geth.conf

Let's change the P2P port to 30304. Add it to the ARGS line and save it::

  ARGS="--port 30304 --http --metrics --metrics.expensive --pprof --maxpeers 100"

For changes to take effect, you will need to restart the client:

.. prompt:: bash $

  sudo systemctl restart geth

.. tip::
  Consult the clients official documentation in order to change the parameters.

Updating Clients
----------------

Getting Logs
------------

Monitoring Dashboards
---------------------






