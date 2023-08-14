.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Download and Install
====================

There are 5 images available for **NanoPC T6**,  **Rock 5B**, **Orange Pi 5 Plus**, **Orange Pi 5** and **Raspberry Pi 4**

.. warning::
  The Raspberry Pi 4 image is outdated and you may run into issues running the clients. While we will try to
  update it soon, it is not our priority as this device can barely run an Ethereum node because of hardware limitations.

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
(make sure you are getting the 16 GB RAM model).

* `Orange Pi 5 Plus official page`_

Try to find a set that includes the power supply as well. It is also recommended to get a proper case with a heatsink. 
For example:

* `Orange Pi 5 Plus Case with heatsink`_

You will need a **MicroSD** and an M2.2280 **NVME** disk as well.

.. _Orange Pi 5 Plus official page: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5-plus.html
.. _Orange Pi 5 Plus Case with heatsink: https://aliexpress.com/item/1005005728553439.html

Orange Pi 5
~~~~~~~~~~~

You can acquire the Orange Pi 5 from several distributors. Go to the official page and pick one at the top right corner 
(make sure you are getting the 16 GB RAM model).

* `Orange Pi 5 official page`_

Try to find a set that includes the power supply as well. It is also recommended to get a proper case with a heatsink. 
For example:

* `Case with heatsink`_

You will need a **MicroSD** and an **NVME** as well.

Regarding the NVMe disk, take into account there are 2 NVME M.2 types that fit perfectly into the board: 2230 and 2242. 
You can use a M.2 2280 as well but keep in mind that you will need a hollow enclosure because the drive does not fit on the board.

.. _Orange Pi 5 official page: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-5.html
.. _Case with heatsink: https://aliexpress.com/item/1005005115126370.html


Raspberry Pi 4
~~~~~~~~~~~~~~

You can acquire a Raspberry Pi 4 from multiples sources. This is the official website.

* `Raspberry Pi 4 (8 GB)`_

.. _Raspberry Pi 4 (8 GB): https://www.raspberrypi.com/products/raspberry-pi-4-model-b/?variant=raspberry-pi-4-model-b-8gb

Make sure you get the 8 GB RAM version.

You will need a **MicroSD** and an **USB3 disk** as well. A case with heathsink and 
the official Raspberry Pi 4 power supply is recommended.


.. warning::
  Again, the image is currently outdated and Post-merge, while it is still possible running a node, the hardware is quite limited. Run **Nimbus+Geth** 
  clients combo as this is the best option in terms of performance.

Images download
---------------

NanoPC T6
~~~~~~~~~

Download link:

ethonarm_nanopct6_23.08.00.img.zip_

.. _ethonarm_nanopct6_23.08.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/EW_PBKG-fcVCjh7KLcXwfAYBlIIHylm-5G1hvSwZH72fXw?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 64578960015dfd2d7823d36f3c37d63282a88438556b48f24782dc3765621cff``

By running:

.. prompt:: bash $

  sha256sum ethonarm_nanopct6_23.08.00.img.zip

Rock 5B
~~~~~~~

Download link:

ethonarm_rock5b_23.08.00.img.zip_

.. _ethonarm_rock5b_23.08.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/EZsKrimlPNBNr1bobHgGxFMBFIOHFt1SqtRqaLvWwc4jBQ?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 b55024b6600f847c36cb74ea7ad1ad0a4591c6ecac47eb35afb947ad853c6013``

By running:

.. prompt:: bash $

  sha256sum ethonarm_rock5b_23.08.00.img.zip

Orange Pi 5 Plus
~~~~~~~~~~~~~~~~

Download link:

ethonarm_orangepi5-plus_23.08.00.img.zip_

.. _ethonarm_orangepi5-plus_23.08.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/EVYrc6lFvsVLoRidgO-9LVABYVQ6n4c_rrm8bGyn4nOZ9g?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 6142f08d344b454b7d929fa669db5f11a6328ee1aa55543310d62290a35f0837``

By running:

.. prompt:: bash $

  sha256sum ethonarm_orangepi5-plus_23.08.00.img.zip


Orange Pi 5
~~~~~~~~~~~

Download link:

ethonarm_orangepi5_23.08.00.img.zip_

.. _ethonarm_orangepi5_23.08.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/EeBrc8qsdIBGl2XNlR-aY3oBA3ipXYT79s8HVjQp4m18Vg?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 cd1506ce81915d1c1ff745b1ba8a5cdcf5d5444bb9d5f5a509d14896e6eb3575``

By running:

.. prompt:: bash $

  sha256sum ethonarm_orangepi5_23.08.00.img.zip

Raspberry Pi 4
~~~~~~~~~~~~~~

Download link:

ethonarm_22.04.00.img.zip_

.. _ethonarm_22.04.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/Ec_VmUvr80VFjf3RYSU-NzkBmj2JOteDECj8Bibde929Gw?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 fb497e8f8a7388b62d6e1efbc406b9558bee7ef46ec7e53083630029c117444f``

By running:

.. prompt:: bash $

  sha256sum ethonarm_22.04.00.img.zip

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

Unzip and flash the image (we are using here the Rock 5B image):

.. prompt:: bash $

   unzip ethonarm_nanopct6_23.08.00.img.zip
   sudo dd bs=1M if=ethonarm_nanopct6_23.08.00.img of=/dev/mmcblk0 conv=fdatasync status=progress

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

