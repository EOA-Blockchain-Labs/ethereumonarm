.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum on ARM documentation
==============================

.. toctree::
   :maxdepth: 2
   :caption: Contents:


.. figure:: /_static/images/ethereum_node.jpg
   :figwidth: 400px
   :align: center

Welcome to the Ethereum on ARM documentation.

Ethereum on ARM is a set of custom Linux images for ARM boards
that run Ethereum clients as a Systemd service and automatically turns such devices
into full/staking Ethereum nodes.

**The image takes care of all the necessary steps to run a node,
from setting up the environment and formatting the disk
to installing, managing and running the Execution and Consensus clients.**

If you are familiar with Ethereum and have already ran
an Ethereum node you can jump to our :doc:`Quick Start </quick-guide/about-quick-start>` 
guide and get your node up and running in minutes.

If you need more info, please use the Quick Start to install the image 
and visit the :doc:`User Guide </user-guide/about-user-guide>` 
in order to get further info on Ethereum and how to manage the clients.

.. note::

  We are currently supporting 5 devices:

  * **NanoPC T6 (16 GB RAM). RECOMMENDED** 
  * **Radxa Rock 5B (16 GB RAM). RECOMMENDED**
  * **Orange Pi 5 Plus (16 GB RAM). RECOMMENDED**
  * Orange Pi 5 (16 GB RAM).
  * Raspberry Pi 4 (8 GB RAM + external USB Disk). Currently outdated.

Quick Start Guide
-----------------

For running a node, follow the step-by-step guide. 

The process is as follows:

* Download and flash the Image into an MicroSD card
* Connect the SSD (NVMe or USB depending on device) and the Ethernet Cable
* Power on the device
* Wait till the installation script finish all tasks (about 10-15 minutes)
* Run an Ethereum clients (one Execution client + one Consensus client)

.. toctree::
  :maxdepth: 2
  :caption: Quick Start Guide
  :hidden:

  /quick-guide/about-quick-start
  /quick-guide/recommended-hardware
  /quick-guide/download-and-install
  /quick-guide/running-ethereum
  /quick-guide/whats-next

User Guide
----------

This section describes in detail how to configure and run the Ethereum nodes as well as other
information regarding the image and other Ethereum related software.

.. toctree::
  :maxdepth: 2
  :caption: User Guide
  :hidden:

  /user-guide/about-user-guide
  /user-guide/managing-clients
  /user-guide/node-types
  /user-guide/running-l1-clients
  /user-guide/running-l2-clients
  /user-guide/running-a-supernode
  /user-guide/running-web3-stack
  /user-guide/using-your-node
  /user-guide/mev-boost
  /user-guide/storage
  /user-guide/security
  /user-guide/troubleshooting
  /user-guide/PiVPNandWireGuard

Developers Guide
----------------

Coming soon

.. toctree::
  :maxdepth: 2
  :caption: Developer Guide
  :hidden:

  /developer-guide/about
  /developer-guide/howto
  
About Ethereum on ARM
---------------------

Get further info about our project and why you should run an Ethereum node on ARM boards.

.. toctree::
  :maxdepth: 2
  :caption: Ethereum On ARM
  :hidden:

  /ethereum-on-arm/why-arm-boards
  /ethereum-on-arm/main-goals
  /ethereum-on-arm/main-features
  /ethereum-on-arm/sources
