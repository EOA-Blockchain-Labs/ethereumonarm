.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Recommended Hardware
====================

In order to run an Ethereum node with our images, you will need one of these devices:

* NanoPC T6
* Rock 5B
* Orange Pi 5 Plus
* Raspberry Pi 5

.. tip::
  We strongly recommend **NanoPC T6, Rock 5B or Orange Pi 5 Plus** boards to run an Ethereum full/staking node. 

This is the recommended hardware to run an **Execution Layer client** + **Consensus Layer client**. 
If you don't know what an Ethereum node is, please visit the :doc:`Operation Introduction </running-a-node/introduction>`.

.. warning::
  The Raspberry Pi 5 doesn't have native NVMe disk support. If you own a Raspberry Pi 5 with 16 GB of RAM and want to run 
  a node, you can use our image to do so. If not, we strongly recommend to acquire one of the above devices.


.. tabs::

  .. tab:: NanoPC T6

    Recommended hardware and settings for running an Ethereum full/staking node on a NanoPC T6 board    

    * **NanoPC T6** (16GB RAM)
    * **MicroSD Card** (16 GB Class 10 minimum)
    * **NVMe disk** 2 TB minimum, 4 TB recommended (M2.2280)
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with passive heatsink**
    * USB keyboard, Monitor and HDMI cable (Optional)

    **Buy links**

    `NanoPC T6 board 16 GB <https://www.friendlyelec.com/index.php?route=product/product&product_id=292>`_

  .. tab:: Radxa Rock 5B

    Recommended hardware and settings for running an Ethereum full/staking node on a Rock 5B board    

    * **Rock 5B board** (16GB to 32GBRAM)
    * **MicroSD Card** (16 GB Class 10 minimum)
    * **NVMe disk** 2 TB minimum, 4 TB recommended (M2.2280)
    * **Power supply** (Radxa official)
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with passive heatsink**
    * USB keyboard, Monitor and HDMI cable (Optional)

    **Buy Links**

    BOARD

    * `Rock 5B board 16 GB <https://shop.allnetchina.cn/products/rock5-model-b?variant=39514839515238>`_
    * `Radxa power supply <https://shop.allnetchina.cn/products/radxa-power-pd-30w?variant=39929851904102>`_

    CASES (Choose one)

    * `Acrylic protector with passive heatsink <https://shop.allnetchina.cn/products/rock5-b-acrylic-protector?variant=39877626396774>`_
    * `Aluminum case with passive/active cooling <https://shop.allnetchina.cn/collections/rock5-model-b/products/ecopi-5b-aluminum-housing-for-rock5-model-b?variant=47101353361724>`_

  .. tab:: Orange Pi 5 Plus

    Recommended hardware and settings for running an Ethereum full/staking node on a Orange Pi 5 Plus board

    * **Orange Pi 5 Plus board** (16GB to 32GB RAM)
    * **MicroSD Card** (16 GB Class 10 minimum)
    * **NVMe disk** 2 TB minimum, 4 TB recommended (M2.2280)
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with passive heatsink**
    * USB keyboard, Monitor and HDMI cable (Optional)

    **Buy Links**

    * `Orange Pi 5 Plus official page <http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus.html>`_
    * `Orange Pi 5 Plus Case with heatsink <https://aliexpress.com/item/1005005728553439.html>`_

  .. tab:: Raspberry Pi 5

    Recommended hardware and settings for running an Ethereum full/staking node on a Raspberry Pi 5 board

    * **Raspberry Pi 5 board** (16GB RAM)
    * **MicroSD Card** (16 GB Class 10 minimum)
    * **NVMe disk** 2 TB minimum, 4 TB recommended (depends on Hat)
    * **NVMe Hat**
    * **Power supply**
    * **Ethernet cable**
    * **Port forwarding** (see clients for further info)
    * **A case with passive heatsink**
    * USB keyboard, Monitor and HDMI cable (Optional)

    **Buy Links**
    
    * `Raspberry Pi 5 official page <https://www.raspberrypi.com/products/raspberry-pi-5/>`_
    * **NVMe Hat** (tested in our labs): GeeekPi N04 and Geekworm X1001
    * **Case with Heatsink**: GeekPi and Geekworm cases

.. warning::
  **IMPORTANT for Raspberry Pi 5**
  
  Make sure to buy a disk that doesn't use a Phison controller. Take a look at the SSD list below and see the 
  Controller column of each disk.

The key components are the NVMe disk and the RAM memory. Please, make sure **you get a board with 16 GB of RAM**.

**Before getting the NVMe disk**, please check these 2 sites and look for Mid-Range or High-End :

* `SSD list <https://docs.google.com/spreadsheets/d/1B27_j9NDPU3cNlj2HKcrfpJKHkOf-Oi1DbuuQva2gT4/edit>`_
* `Great and less great SSDs for Ethereum nodes <https://gist.github.com/yorickdowne/f3a3e79a573bf35767cd002cc977b038>`_
