.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Ethereum on ARM documentation
==============================

.. toctree::
   :maxdepth: 2
   :caption: Contents:


.. figure:: /_static/images/ethnode.jpg
   :figwidth: 200px
   :align: center

Welcome to the Ethereum on ARM documentation.

Ethereum on ARM is a set of custom Linux images for ARM boards
that runs Ethereum clients as a boot service and automatically turns the devices
into full Ethereum 1.0/2.0 nodes.

The image takes care of all the necessary steps to run a node,
from setting up the environment and formatting the SSD disk
to installing, managing and running the Eth1.0 and Eth2.0 clients.

If you are familiar with Ethereum and have already ran
an Ethereum node you can jump to our Quick start guide
and get your node up and running in no time.

If you need more info, please read our user guide carefully
in order to get an idea of what Ethereum is and how to
run a node.

.. note::

  We are currently focusing on the Raspberry Pi 4 image. We will add more 
  devices once we make sure they  are reliable and have enough resources 
  to run both Eth1 and Eth2 nodes.

Quick Start Guide
-----------------

For running a node, follow 

The process is as follows:

* Download and flash the Image into an MicroSD card
* Connect the SSD to the USB port and the Ethernet Cable
* Power on the device
* Wait till the installation script finish all tasks
* Enable and run an Ethereum client

* **About Quick Start**:
  :doc:`About Quick Start </quick-guide/about-quick-start>`
* **Recommended Hardware**:
  :doc:`Recommended Hardware </quick-guide/recommended-hardware>`
* **Download and install the image**:
  :doc:`Download and install the image </quick-guide/download-and-install>`
* **Running Ethereum**:
  :doc:`Log in </quick-guide/running-ethereum>`  
* **What's next**:
  :doc:`What's next </quick-guide/whats-next>`

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

* **Security**:
  :doc:`Security </user-guide/security>`

.. toctree::
  :maxdepth: 2
  :caption: User Guide
  :hidden:

  /user-guide/about-user-guide
  /user-guide/managing-clients
  /user-guide/ethereum1.0
  /user-guide/ethereum2.0
  /user-guide/other-ethereum-software
  /user-guide/storage
  /user-guide/security
  /user-guide/hcl


Deverloper Guide
----------------

* **Ethereum on ARM images**:
  :doc:`Ethereum on ARM images </developer-guide/eoa-images>`
* **Installation script**:
  :doc:`Installation process </developer-guide/installation-script>`
* **Debian packages**:
  :doc:`Debian packages </developer-guide/debian-packages>`
* **Config files**:
  :doc:`Config files </developer-guide/config-files>`
* **Systemd Services**:
  :doc:`Systemd services </developer-guide/systemd-services>`
* **Monitoring tools**:
  :doc:`Monitoring tools </developer-guide/monitoring-tools>`
* **Armbian supported devices**:
  :doc:`Armbian supported devices </developer-guide/armbian>`

.. toctree::
  :maxdepth: 2
  :caption: Developer Guide
  :hidden:
  
  /developer-guide/eoa-images
  /developer-guide/installation-script
  /developer-guide/debian-packages
  /developer-guide/config-files
  /developer-guide/systemd-services
  /developer-guide/monitoring-tools
  /developer-guide/armbian

About Ethereum on ARM
---------------------

Ethereum on ARM is a project

* **Why ARM boards**:
  :doc:`Why ARM boards </ethereum-on-arm/why-arm-boards>`
* **Main Goals**:
  :doc:`Main Goals </ethereum-on-arm/main-goals>`
* **Main features**:
  :doc:`Main features </ethereum-on-arm/main-features>`
* **Developers guide**:
  :doc:`Developers guide </ethereum-on-arm/developers>`
* **Sources**:
  :doc:`Sources </ethereum-on-arm/sources>`

.. toctree::
  :maxdepth: 2
  :caption: Ethereum On ARM
  :hidden:

  /ethereum-on-arm/why-arm-boards
  /ethereum-on-arm/main-goals
  /ethereum-on-arm/main-features
  /ethereum-on-arm/developers
  /ethereum-on-arm/sources

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
