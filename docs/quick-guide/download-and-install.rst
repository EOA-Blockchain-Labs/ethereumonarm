.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Download and Install
====================

There are 4 images available for **NanoPC T6**,  **Rock 5B**, **Orange Pi 5 Plus** and **Raspberry Pi 5**

Getting the hardware
--------------------

NanoPC T6
~~~~~~~~~

You can acquire the NanoPC T6 from the Friendly Elec official site:

* `NanoPC T6 board 16 GB`_

You will need a **MicroSD** and a M2.2280 **NVME disk** as well.

.. _NanoPC T6 board 16 GB: https://www.friendlyelec.com/index.php?route=product/product&product_id=292

Rock 5B
~~~~~~~

You can acquire the Rock 5B from several distributors. These are the recommended components (from Allnetchina):

* `Rock 5B board 16 GB`_
* `Acrylic protector with passive heatsink`_
* `Radxa power supply`_

You will need a **MicroSD** and an M2.2280 **NVME disk** as well.

.. _Rock 5B board 16 GB: https://shop.allnetchina.cn/products/rock5-model-b?variant=39514839515238
.. _Acrylic protector with passive heatsink: https://shop.allnetchina.cn/products/rock5-b-acrylic-protector?variant=39877626396774
.. _Radxa power supply: https://shop.allnetchina.cn/products/radxa-power-pd-30w?variant=39929851904102

Orange Pi 5 Plus
~~~~~~~~~~~~~~~~

You can acquire the Orange Pi 5 plus from several distributors. Go to the official page and pick one at the top right corner 
(make sure you are getting the 16 GB RAM model at least. If you are running a Supernode, pick the 32 GB RAM one).

* `Orange Pi 5 Plus 16 GB RAM`_
* `Orange Pi 5 Plus 32 GB RAM`_

Try to find a set that includes the power supply as well. It is also recommended to get a proper case with a heatsink. 
For example:

* `Orange Pi 5 Plus Case with heatsink`_

You will need a **MicroSD** and an M2.2280 **NVME** disk as well.

.. _Orange Pi 5 Plus 16 GB RAM: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus.html
.. _Orange Pi 5 Plus 32 GB RAM: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus-32GB.html
.. _Orange Pi 5 Plus Case with heatsink: https://aliexpress.com/item/1005005728553439.html

Raspberry Pi 5
~~~~~~~~~~~~~~

You can acquire a Raspberry Pi 5 from multiples sources. This is the official website.

* `Raspberry Pi 5 (16 GB RAM)`_

.. _Raspberry Pi 5 (16 GB RAM): https://www.raspberrypi.com/products/raspberry-pi-5/

For Nvme Hat, case and cooling, we recommend the following (you can find them in several providers)

* **Geekworm** P579 case and X1001 NVMe Hat
* **GeeekPi** Raspberry Pi 5 case and N04 M.2 2280 NVMe Hat.

Make sure you get the 16 GB RAM version.

You will need a **MicroSD** and an **NVMe disk** as well. A case with heathsink and 
the official Raspberry Pi 5 power supply is recommended.

.. warning::
  Again, make sure to buy an NVMe disk that **doesn't use a Phison controller**. Take a look at the SSD list below and check the 
  Controller column of each disk. A High-end or Mid-Range disk is recommended.

* `SSD list <https://docs.google.com/spreadsheets/d/1B27_j9NDPU3cNlj2HKcrfpJKHkOf-Oi1DbuuQva2gT4/edit>`_

Images download
---------------

NanoPC T6
~~~~~~~~~

Download link:

ethonarm_nanopct6_25.11.00.img.zip_

.. _ethonarm_nanopct6_25.11.00.img.zip: https://github.com/EOA-Blockchain-Labs/ethereumonarm/releases/download/v25.11.00/ethonarm_nanopct6_25.11.00.img.zip

You can verify the file with the following ``SHA256`` Hash:

``SHA256 f60ca9cdef2bd0815761f61b497f655dd5486c53da67e6e2487d33264a173664``

By running:

.. prompt:: bash $

  sha256sum ethonarm_nanopct6_25.11.00.img.zip

Rock 5B
~~~~~~~

Download link:

ethonarm_rock5b_25.11.00.img.zip_

.. _ethonarm_rock5b_25.11.00.img.zip: https://github.com/EOA-Blockchain-Labs/ethereumonarm/releases/download/v25.11.00/ethonarm_rock5b_25.11.00.img.zip


You can verify the file with the following ``SHA256`` Hash:

``SHA256 a61a0cd5bd41bfcb1528e527878c15c158aedad6f745eeeb02975d300b3d2b42``

By running:

.. prompt:: bash $

  sha256sum ethonarm_rock5b_25.11.00.img.zip

Orange Pi 5 Plus
~~~~~~~~~~~~~~~~

Download link:

ethonarm_orangepi5-plus_25.11.00.img.zip_

.. _ethonarm_orangepi5-plus_25.11.00.img.zip: https://github.com/EOA-Blockchain-Labs/ethereumonarm/releases/download/v25.11.00/ethonarm_orangepi5-plus_25.11.00.img.zip

You can verify the file with the following ``SHA256`` Hash:

``SHA256 1c28775acbe529e7cc31d1a819e76477820fea04c7e30a53a95488bf195ff8e0``

By running:

.. prompt:: bash $

  sha256sum ethonarm_orangepi5-plus_25.11.00.img.zip

Raspberry Pi 5
~~~~~~~~~~~~~~

Download link:

ethonarm_rpi5_25.11.00.img.zip_

.. _ethonarm_rpi5_25.11.00.img.zip: https://github.com/EOA-Blockchain-Labs/ethereumonarm/releases/download/v25.11.00/ethonarm_rpi5_25.11.00.img.zip

You can verify the file with the following ``SHA256`` Hash:

``SHA256 4cc62f68376bec1dca1cee6ec5b1cb284202de084f046559ac5cb32eb2c647c8``

By running:

.. prompt:: bash $

  sha256sum ethonarm_rpi5_25.11.00.img.zip

Image installation
==================

Once you have the Image download and decompressed you need to flash it

Flashing the image
------------------

Insert the microSD in your Desktop / Laptop and flash the image.

.. note::
  If you are not comfortable with command line or if you are 
  running Windows, you can use Etcher_

.. _Etcher: https://www.balena.io/etcher/

Open a terminal and check your MicroSD device name running:

.. prompt:: bash $

   sudo fdisk -l

You should see a device named ``mmcblk0`` or ``sd(x)``.

.. warning::
  The ``dd`` command will completely erase your MicroSD device so make sure you are targeting 
  the correct one.

Unzip and flash the image (we are using here the NanoPc T6 image):

.. prompt:: bash $

   unzip ethonarm_nanopct6_25.11.00.img.zip
   sudo dd bs=1M if=ethonarm_nanopct6_25.11.00.img of=/dev/mmcblk0 conv=fdatasync status=progress

Insert MicroSD
--------------

Insert the MicroSD into the board. Make sure you have your SSD disk and Ethernet cable connected.

Power on
--------

The Ubuntu OS will boot up in less than one minute and the installation script will start to perform the necessary tasks
to turn the device into a full Ethereum node.

.. warning::

  You need to wait for about 10-15 minutes to allow the script to install and configure all the software.

Log in
------

Once the device is available, You can log in through SSH or using the console (if you have a monitor 
and keyboard attached) using the ``ethereum`` account::

  User: ethereum
  Password: ethereum

Through SSH:

.. prompt:: bash $

  ssh ethereum@your_board_IP

.. tip::
  If you don't have a monitor with a keyboard you can get your board ``IP`` address by looking into your router 
  or using some kind of network tool such as ``fping`` or ``nmap``. For instance (assuming you are in the 192.168.1.0 network)).

  In your Linux Desktop / Laptop, run:

  Using Nmap

  .. prompt:: bash $
  
     sudo apt-get install nmap
     nmap -sP 192.168.1.0/24
  
  Using Fping

  .. prompt:: bash $

     sudo apt-get install fping
     fping -a -g 192.168.1.0/24
  
.. note::
  You will be prompted to change the password on first login, so you will need to log in twice.

Image Upgrade
=============

If you are already running an Ethereum on ARM node you can upgrade to the new image by following these steps:

1. Install the package ethereumonarm-config-sync:

.. prompt:: bash $

  sudo apt-get update && sudo apt-get install ethereumonarm-config-sync

2. Run the config sync script

.. prompt:: bash $

  ethereumonarm-config-sync.sh

3. Flash the image as described in the above section and power on the device.

The installer will detect a previous installation (if present) and restore the /etc/ethereum 
clients config.

Once logged in, restart the clients you were running.

Image re-installation
=====================

If you are already running an Ethereum on ARM node and you want a fresh install (disk wipe out), follow these steps:

1. Log into you node and run the following command:

.. prompt:: bash $

  touch /home/ethereum/.format_me

2. Follow the steps described in the "Image installation" section

