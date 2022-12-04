.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Recommended Hardware
====================

In order to run an Ethereum node with our images, you will need a Raspberry Pi 4, an Odroid M1 or a
Rock 5B Board with some additional components.

.. tip::
We strongly recommend the **Rock 5B** board to run an Ethereum full/staking node.

This is the recommended hardware to run an **Execution Layer client** + **Consensus Layer client**. 
If you don't know what an Ethereum node is, please visit the :doc:`User Guide section </user-guide/about-user-guide>`.


.. tabs::

  .. tab:: Radxa Rock 5B

    Recommended hardware and settings for running an Ethereum full/staking node on a Rock 5B board
    

    * **Rock 5B board** (16GB RAM)
    * **MicroSD Card** (16 GB Class 10 minimum)
    * Storage
      * **NVMe disk** 2 TB minimum
    * **Power supply** (Radxa official)
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with passive heatsinkn**
    * USB keyboard, Monitor and HDMI cable (micro-HDMI) (Optional)

  .. tab:: Raspberry Pi 4

    Recommended hardware and settings for running an Ethereum full/staking node on a Raspberry Pi 4

    * **Raspberry 4 board** (8GB RAM)
    * **MicroSD Card** (16 GB Class 10 minimum)
    * Storage
      * **USB 3.0 disk** or a SSD with an USB to SATA case (2 TB Minimum) (see :doc:`Storage </user-guide/storage>` section).
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with heatsink and fan**
    * USB keyboard, Monitor and HDMI cable (micro-HDMI) (Optional)

    .. warning::

      You need an Execution layer provider to create blocks (see :doc:`User Guide </user-guide/about-user-guide>` for further info)
    
  .. tab:: Odroid M1
    
    Recommended hardware and settings for running an Ethereum 1.0 
    + Ethereum 2.0 node (both running in the same Raspberry Pi 4).

    * **Odroid M1 board** (8 GB RAM)
    * **MicroSD Card** (16 GB Class 10 minimum)
    * Storage
      * Odroid M1 **NVMe disk (2 TB minimum)**
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with heatsink and fan**
    * USB keyboard, Monitor and HDMI cable (micro-HDMI) (Optional)

The key components are the SDD disk and the RAM memory. Try to buy an 8 GB board and a decent SSD.

.. note::
  For running an Ethereum 2.0 validator you need 32 ETH
