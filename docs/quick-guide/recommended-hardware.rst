.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Recommended Hardware
====================

In order to run an Ethereum node with our images, you will need a Raspberry Pi 4, an Odroid M1 or A
Rock 5B Board with some additional components.

This is the recommended hardware to run an **Ethereum 1.0 node**, An **Ethereum 2.0 node** or **both**. 
If you don't know what an Ethereum node is, please visit the :doc:`User Guide section </user-guide/about-user-guide>`.

.. tabs::

  .. tab:: Ethereum 1.0 node

    Recommended hardware and settings for running an Ethereum 1.0 node

    * **Raspberry 4** (8GB RAM), **Odroid M1** or **Rock 5B (8GB/16GB RAM)** board
    * **MicroSD Card** (16 GB Class 10 minimum)
    * Storage

      * Raspberry Pi 4 **2 TB SSD minimum** USB 3.0 disk or an SSD with an USB to SATA case (see :doc:`Storage </user-guide/storage>` section).
      * Odroid M1 **NVMe disk 2 TB minimum**
      * Rock 5B **NVMe disk 2 TB minimum**
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with heatsink and fan**
    * USB keyboard, Monitor and HDMI cable (micro-HDMI) (Optional)

    We strongly recomend a 8 GB RAM board.

  .. tab:: Ethereum 2.0 node

    Recommended hardware and settings for running an Ethereum 2.0 node (Beacon Chain and Validator).

    * **Raspberry 4** (8GB RAM), **Odroid M1** or **Rock 5B (8GB/16GB RAM)** board
    * **MicroSD Card** (16 GB Class 10 minimum)
    * Storage

      * Raspberry Pi 4 **512 GB SSD minimum** USB 3.0 disk or an SSD with an USB to SATA case (see :doc:`Storage </user-guide/storage>` section).
      * Odroid M1 **NVMe disk 512 GB minimum**
      * Rock 5B **NVMe disk 512 GB minimum**
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with heatsink and fan**
    * USB keyboard, Monitor and HDMI cable (micro-HDMI) (Optional)

    .. warning::

      You need an Ethereum 1.0 provider to create blocks (see :doc:`User Guide </user-guide/about-user-guide>` for further info)
    
  .. tab:: Ethereum 1.0 + Ethereum 2.0 nodes
    
    Recommended hardware and settings for running an Ethereum 1.0 
    + Ethereum 2.0 node (both running in the same Raspberry Pi 4).

    * **Raspberry 4** (8GB RAM), **Odroid M1** or **Rock 5B (8GB/16GB RAM)** board
    * **MicroSD Card** (16 GB Class 10 minimum)
    * Storage

      * Raspberry Pi 4 **2 TB SSD minimum** USB 3.0 disk or an SSD with an USB to SATA case (see :doc:`Storage </user-guide/storage>` section).
      * Odroid M1 **NVMe disk 2 TB minimum**
      * Rock 5B **NVMe disk 2 TB minimum**
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with heatsink and fan**
    * USB keyboard, Monitor and HDMI cable (micro-HDMI) (Optional)

The key components are the SDD disk and the RAM memory. Try to buy an 8 GB board and a decent SSD.

.. note::
  For running an Ethereum 2.0 validator you need 32 ETH
