.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

MEV boost
=========

MEV stands for Maximal Extractable Value and, basically, it's a way of maximizing 
your validator profits by proposing a block that was built by a 3rd party. 
This block includes more rewards than the standard block created locally by your validator.

there has been a lot of controversy about MEV as some relays comply 
with OFAC sanctions which means that some transactions are in the end censored by this relays.

We are including in our default config file ``/etc/ethereum/mev-boost.conf`` **NO censorship** relays only.

As a point of reference, we use the `EthStaker relay list`_

.. _EthStaker relay list: https://github.com/eth-educators/ethstaker-guides/blob/main/MEV-relay-list.md

Using MEV
---------

First step is to start the ``mev-boost`` service. If you have an old Ethereum image you may need 
to install the package:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install mev-boost

You can run the service on your node or on another ARM board. If you have a Raspberry Pi or an Odroid it may 
be more convenient to run it outside your node.

To start the service, type:

.. prompt:: bash $

  sudo systemctl start mev-boost

You need to configure your **Consensus Layer** clients to use MEV.

Configuring CL clients
----------------------

Edit the CL config files and add the data described below.

.. note::
  You need to change the Mev Boost address depending on where you are running the service (on the same 
  node or on an external node). Choose ``localhost`` if you are running the service along with your 
  validator or **the external node** ``IP`` (such as 192.168.0.20) if you are using an external device.

  **We will be using** ``localhost`` **in the examples.**

Lighthouse
~~~~~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lighthouse-beacon.conf

Add the flag ``--builder http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lighthouse-validator.conf

Add the flag ``--builder-proposals`` at the end of the file.

Teku
~~~~

Edit the Teku config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/teku.conf

Add the flags ``--validators-builder-registration-default-enabled=true --builder-endpoint=http://localhost:18550`` 
at the end of the file.

Prysm
~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/prysm-beacon.conf

Add the flag ``--http-mev-relay=http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/prysm-validator.conf

Add the flag ``--enable-builder`` at the end of the file.

Nimbus
~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/nimbus-beacon.conf

Add the flags ``--payload-builder=true --payload-builder-url=http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/nimbus-validator.conf

Add the flag ``--payload-builder=true`` at the end of the file.

Lodestar
~~~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lodestar-beacon.conf

Add the flags ``--builder --builder.url http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/lodestar-validator.conf

Add the flag ``--builder`` at the end of the file.

Grandine
~~~~~~~~

Edit the Beacon config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/grandine-beacon.conf

Add the flag ``--builder-url http://localhost:18550`` at the end of the file.

Edit the Validator config file:

.. prompt:: bash $

  sudo vim /etc/ethereum/grandine-validator.conf

Add the flag ``--builder-api-url http://localhost:18550`` at the end of the file.
