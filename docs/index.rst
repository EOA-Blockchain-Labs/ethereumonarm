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
an Ethereum node you can jump to our :doc:`Getting Started </getting-started/introduction>` 
guide and get your node up and running in minutes.

If you need more info, please use the Getting Started to install the image 
and visit the :doc:`Operation & Management </operation/introduction>` 
in order to get further info on Ethereum and how to manage the clients.

.. note::

  We are currently supporting 4 devices:

  * **NanoPC T6 (16 GB RAM). RECOMMENDED** 
  * **Radxa Rock 5B (16 GB RAM). RECOMMENDED**
  * **Orange Pi 5 Plus (16 GB RAM). RECOMMENDED**
  * **Raspberry Pi 5 (16 GB RAM + NVMe Disk)**

Overview
--------

.. toctree::
  :maxdepth: 2
  :caption: Overview

  /overview/introduction
  /overview/why-arm
  /overview/supported-hardware
  /overview/features

Getting Started
---------------

For running a node, follow the step-by-step guide.

.. toctree::
  :maxdepth: 2
  :caption: Getting Started

  /getting-started/introduction
  /getting-started/installation
  /getting-started/starting-node
  /getting-started/post-install

Node Operation & Management
---------------------------

.. toctree::
  :maxdepth: 2
  :caption: Node Operation

  /operation/introduction
  /operation/managing-clients
  /operation/node-types
  /operation/layer-1
  /operation/layer-2
  /operation/optimism-l2
  /operation/supernode
  /operation/web3-stack
  /operation/storage-management
  /operation/rpi5-storage
  /operation/security
  /operation/network-vpn
  /operation/backup-restore
  /operation/troubleshooting

Advanced Features
-----------------

.. toctree::
  :maxdepth: 2
  :caption: Advanced Features

  /advanced/mev-boost
  /advanced/commit-boost
  /advanced/testnets
  /advanced/using-node-rpc

Developer & Contributor Guide
-----------------------------

.. toctree::
  :maxdepth: 2
  :caption: Developer Guide

  /contributing/guidelines
  /contributing/building-images

Appendix / Reference
--------------------

.. toctree::
  :maxdepth: 2
  :caption: Reference

  /reference/sources
