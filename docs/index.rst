.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum on ARM documentation
==============================

.. toctree::
   :maxdepth: 2
   :caption: Contents:


.. figure:: /_static/images/merge_node.jpg
   :figwidth: 400px
   :align: center

Welcome to the Ethereum on ARM documentation.

Ethereum on ARM is a set of custom Linux images for ARM boards
that runs Ethereum clients as a boot service and automatically turns the devices
into full Ethereum 1.0/2.0 nodes.

The image takes care of all the necessary steps to run a node,
from setting up the environment and formatting the SSD disk
to installing, managing and running the Eth1.0 and Eth2.0 clients.

If you are familiar with Ethereum and have already ran
an Ethereum node you can jump to our :doc:`Quick Start </quick-guide/about-quick-start>` 
guide and get your node up and running in no time.

If you need more info, please use the Quick Start to install the image 
and visit the :doc:`User Guide </user-guide/about-user-guide>` 
in order to get further info on Ethereum how to manage the clients.

.. note::

  We are now supporting 3 devices:
  * Raspberry Pi 4 (8 GB RAM + external USB Disk)
  * Hardkernel Odroid M1
  * Radxa Rock 5B (16 GB RAM recommended)

Quick Start Guide
-----------------

For running a node, follow the step-by-step guide. 

The process is as follows:

* Download and flash the Image into an MicroSD card
* Connect the SSD to the USB port and the Ethernet Cable
* Power on the device
* Wait till the installation script finish all tasks
* Enable and run an Ethereum client

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
  /user-guide/execution-clients
  /user-guide/consensus-clients
  /user-guide/storage
  /user-guide/security

Goerli
------

Join the Goerli HF (August 2022)

.. toctree::
  :maxdepth: 2
  :caption: Goerli Hard fork
  :hidden:

  /goerli/goerli

Developers Guide
----------------

Coming soon

.. toctree::
  :maxdepth: 2
  :caption: Developer Guide
  :hidden:

  /developer-guide/about
  
About Ethereum on ARM
---------------------

Get further info about our project.

.. toctree::
  :maxdepth: 2
  :caption: Ethereum On ARM
  :hidden:

  /ethereum-on-arm/why-arm-boards
  /ethereum-on-arm/main-goals
  /ethereum-on-arm/main-features
  /ethereum-on-arm/sources
