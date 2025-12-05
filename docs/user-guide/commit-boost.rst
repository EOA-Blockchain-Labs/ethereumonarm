.. Ethereum on ARM documentation documentation master file

Commit-Boost
============

Commit-Boost is a new standard for Ethereum validators that safely requests blocks from multiple relays. It acts as a sidecar to your consensus client, similar to MEV-Boost, but with enhanced features for proposer commitments.

We are including a default configuration file at ``/etc/ethereum/commit-boost.conf``.

Using Commit-Boost
------------------

First step is to start the ``commit-boost`` service. If you have an old Ethereum image you may need 
to install the package:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install commit-boost

To start the service, type:

.. prompt:: bash $

  sudo systemctl start commit-boost

Configuration
-------------

The configuration file is located at ``/etc/ethereum/commit-boost.conf``. You can edit it to change relays or other settings.

.. prompt:: bash $

  sudo vim /etc/ethereum/commit-boost.conf

By default, it is configured for **Mainnet** with a set of relays that maximize profit.

Configuring CL clients
----------------------

You need to configure your **Consensus Layer** clients to use Commit-Boost. It listens on port ``18550`` by default, which is the same as MEV-Boost.

**If you are replacing MEV-Boost with Commit-Boost, you might not need to change your CL client configuration if they are already pointing to port 18550.**

Edit the CL config files and ensure they point to the Commit-Boost endpoint.

.. note::
  You need to change the address depending on where you are running the service (on the same 
  node or on an external node). Choose ``localhost`` if you are running the service along with your 
  validator or **the external node** ``IP`` (such as 192.168.0.20) if you are using an external device.

  **We will be using** ``localhost`` **in the examples.**

Lighthouse
~~~~~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lighthouse-beacon.conf

Add or update the flag ``--builder http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lighthouse-validator.conf

Add the flag ``--builder-proposals`` at the end of the file.

Teku
~~~~

Edit the Teku config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/teku.conf

Add or update the flags ``--validators-builder-registration-default-enabled=true --builder-endpoint=http://localhost:18550`` 
at the end of the file.

Prysm
~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/prysm-beacon.conf

Add or update the flag ``--http-mev-relay=http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/prysm-validator.conf

Add the flag ``--enable-builder`` at the end of the file.

Nimbus
~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/nimbus-beacon.conf

Add or update the flags ``--payload-builder=true --payload-builder-url=http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/nimbus-validator.conf

Add the flag ``--payload-builder=true`` at the end of the file.

Lodestar
~~~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lodestar-beacon.conf

Add or update the flags ``--builder --builder.url http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lodestar-validator.conf

Add the flag ``--builder`` at the end of the file.

Grandine
~~~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/grandine-beacon.conf

Add or update the flag ``--builder-url http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/grandine-validator.conf

Add or update the flag ``--builder-api-url http://localhost:18550`` at the end of the file.
