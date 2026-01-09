.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Introduction
============

Welcome to the **Ethereum on ARM** Quick Start Guide. This guide will walk you through the steps to turn your ARM board into a powerful Ethereum node.

The process is straightforward, but basic Linux and networking skills are helpful.

.. tip::
   If you prefer a plug-and-play hardware solution with a graphical interface, consider `Dappnode <https://dappnode.io/>`_ or `Avado <https://ava.do/>`_.

Start Your Journey
------------------

Choose the path that best fits your goals:

.. grid:: 1 1 3 3
   :gutter: 3

   .. grid-item-card:: 🚀 Standard Node
      :link: installation
      :link-type: doc
      :text-align: center
      :class-card: sd-border-primary

      **Best for beginners**
      
      Run a full Ethereum L1 node.
      
      +++
      Start Here

   .. grid-item-card:: ⚡ Supernode
      :link: ../operation/optimism/supernode
      :link-type: doc
      :text-align: center
      :class-card: sd-border-warning

      **For power users**
      
      Run L1 + Optimism L2 on the same board (Requires 32GB RAM).
      
      +++
      Go to Guide

   .. grid-item-card:: 🌐 Layer 2 Only
      :link: ../operation/layer-2
      :link-type: doc
      :text-align: center
      :class-card: sd-border-info

      **Scaling solutions**
      
      Run Arbitrum, Starknet, or other L2s.
      
      +++
      Explore L2s

Installation Steps
------------------

The general process for all paths is:

1.  **Get Hardware**: Acquire a supported ARM Board (Rock 5B, Orange Pi 5 Plus, etc.).
2.  **Flash Image**: Download and write our custom Linux image to a MicroSD card.
3.  **Assemble**: Connect NVMe SSD, Ethernet, and Power.
4.  **Auto-Install**: Power on and let the automated script configure your system (10-15 mins).
5.  **Run Clients**: Enable and start your chosen Ethereum software.

Ready to begin?

:doc:`Proceed to Installation > <installation>`
