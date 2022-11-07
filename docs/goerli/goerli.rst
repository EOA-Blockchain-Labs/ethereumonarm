About Goerli/Prater fork
========================

**Goerli/Prater** hardfork is the last test before the mainnet upgrade known as **The Merge** that is schedule for the second
week of August 2022.

We are supporting this fork by including config files and Systemd services along with the mainnet clients packages. 
**Execution Layer clients run on the Goerli testnet** and **Consensus clients on Prater**.

What's included
===============

* Goerli/Prater configuration: **Goerli/Prater** config files and Systemd services
* **Execution Layer** clients: :guilabel:`Geth`, :guilabel:`Nethermind` and :guilabel:`Besu`
* **Consensus Layer** clients: :guilabel:`Lighthouse`, :guilabel:`Prysm`, :guilabel:`Nimbus` and :guilabel:`Teku`

The image includes all Consensus Layer clients and Execution Layer binaries **ready
to run through Systemd services** and all necessary tools to make a deposit in the staking 
contract and generate the keys to enable a Validator.

Installation
============

Packages are already included in the mainnet clients so you need to install an **Ethereum on ARM image** for your device or update 
your mainnet clients if you already have an Ethereum on ARM node running. 
Please se the section `Download and install`_

.. _Download and install: https://ethereum-on-arm-documentation.readthedocs.io/en/latest/quick-guide/download-and-install.html

.. warning::
  
  Please check here the `recommended-hardware`_ section as you need to comply with some requirements for the 
  installer to work such as an USB-SSD Disk.

.. _recommended-hardware: https://ethereum-on-arm-documentation.readthedocs.io/en/latest/quick-guide/recommended-hardware.html

.. tip::

  Remember that you will need to forward/open the following ports for the clients to work as expected:

  * **30303**: For the Execution Layer clients
  * **9000**: For Consensus Layer clients except :guilabel:`Prysm` (:guilabel:`Lighthouse`, :guilabel:`Nimbus`)
  * **12000 (UDP) & 13000 (TCP)**: for Consensus Layer :guilabel:`Prysm`


Goerli/Prater configuration
===========================

The **network configuration** depends upon ``merge-config`` package. It contains all necessary files to 
provide **info to the Execution and Consensus clients**. Particularly, it creates the ``jwtsecret`` file 
which EC and CL use to communicate. The config files are located on ``/etc/ethereum/``.


Quick start guide
=================

If you already have an **Ethereum on ARM image** installed you can update your clients with the ``apt-get`` commnand. In order
to update all Execution and Consensus Clients, run:

.. prompt:: bash $

  sudo apt-get update
  sudo apt-get install geth besu nethermind lighthouse prysm teku nimbus

If you installed a fresh image, everything is ready.

.. note::
  For :guilabel:`Lighthouse` and :guilabel:`Prysm` you will need to start an additional service 
  to run a Validator. We'll get to that in the `"Enabling a Validator"` section

In it important to remark that you will need to run **both Execution and Consensus Layer clients** at the same time
in order to run an Ethereum node after The Merge. This means that **we need 2 Systemd services 
for every EL+CL combination** (and 3 if you are running a validator with :guilabel:`Lighthouse` or :guilabel:`Prysm`).


Starting the clients
~~~~~~~~~~~~~~~~~~~~

As said, in order to get ready for the Goerli/Prater merge **you need to start 2 clients**, an **Execution Layer** and a 
**Consensus Layer**. For instance, for starting :guilabel:`Geth` and :guilabel:`Lighthouse`, run:

.. prompt:: bash $

  sudo systemctl start geth-goerli
  sudo systemctl start lighthouse-beacon-prater

To access the logs, use ``journalctl`` for each service, for instance:

.. prompt:: bash $

  sudo journalctl -u geth -f
  sudo journalctl -u lighthouse-beacon-prater -f


For stopping a client, use the Systemctl stop directive.

.. note::
  All config files are located in the **/etc/ethereum/** with the ``goerli`` suffix for **EL clients** 
  and ``prater`` suffix for **CL clients**.

  
.. note::
  Please note that **Consensus clients** (except :guilabel:`Nimbus`) are configured to use the **CheckPoint sync** 
  so they will get in sync very quickly.


Enabling a Validator
====================

Coming Soon.