Ethereum on ARM
===============

**Powering Decentralization with Low-Cost, Efficient Hardware**

.. meta::
   :description lang=en: Ethereum on ARM provides custom Linux images to turn ARM boards like NanoPC T6, Rock 5B, and Raspberry Pi into full Ethereum nodes. Supports Geth, Nethermind, Lighthouse, Teku, and more.

.. figure:: /_static/images/ethereum-node-light.png
   :class: only-light
   :figwidth: 90%
   :align: center
   :alt: Ethereum on ARM Devices

.. figure:: /_static/images/ethereum-node-dark.png
   :class: only-dark
   :figwidth: 90%
   :align: center
   :alt: Ethereum on ARM Devices

Welcome to the official documentation for **Ethereum on ARM**.

We provide custom, high-performance Linux images that turn affordable ARM Single Board Computers (SBCs) into full-featured Ethereum nodes. 

.. tip::
   **Ready to start?**
   
   If you have a supported board, jump straight to our :doc:`Getting Started </getting-started/introduction>` guide to be up and running in minutes.

Supported Hardware
------------------

Our images are optimized for the most powerful and efficient ARM boards available today.

.. important::
   **Recommended Boards for Full/Staking Nodes:**
   
   *   **NanoPC T6** (16GB)
   *   **Rock 5B** (16GB)
   *   **Orange Pi 5 Plus** (16GB)
   
   *Also Supported:*
   *   **Raspberry Pi 5** (16GB + NVMe HAT)

Documentation
-------------

Select a topic to get started:

*   :doc:`🚀 Getting Started </getting-started/introduction>`: Step-by-step installation guide.
*   :doc:`ℹ️ Supported Hardware </overview/supported-hardware>`: List of compatible ARM boards.
*   :doc:`⚙️ Operation Guide </operation/introduction>`: How to run and manage your node.
*   :doc:`📦 Packages </packages/index>`: Reference for all supported software packages.
*   :doc:`💻 Contributing </contributing/guidelines>`: Help us improve the project.

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: 🚀 Getting Started

   /getting-started/introduction
   /getting-started/installation
   /getting-started/starting-node
   /getting-started/post-install
   /getting-started/quickstart-cheatsheet

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: ℹ️ Overview

   /overview/introduction
   /overview/why-arm
   /overview/supported-hardware
   /overview/features

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: ⚙️ Operation

   /operation/introduction
   /operation/managing-clients
   /operation/node-types
   /operation/layer-1
   /operation/layer-2
   /operation/optimism-l2
   /operation/web3-stack
   /operation/storage-management
   /operation/rpi5-storage

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: 🛠️ System Utilities

   /system/network-vpn
   /system/backup-restore
   /system/security
   /system/troubleshooting

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: ⚡ Advanced

   /advanced/mev-boost
   /advanced/commit-boost
   /advanced/obol-dvt-setup
   /advanced/testnets
   /advanced/gnosis
   /advanced/using-node-rpc
   /advanced/lido
   /advanced/manual-verification
   /advanced/migrate-validator

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: 💻 Contributing

   /contributing/guidelines
   /contributing/building-images
   /reference/sources

.. toctree::
   :maxdepth: 2
   :hidden:
   :caption: 📦 Packages

   packages/index
