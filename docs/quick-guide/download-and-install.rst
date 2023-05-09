.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Download and Install
====================

There are 4 images available for  **Rock 5B**, **Orange Pi 5**, **Raspberry Pi 4** and **Odroid M1** boards.

Getting the hardware
--------------------

Rock 5B
~~~~~~~

You can acquire the Rock 5B from several distributors. These are the recommended components (from Allnetchina):

* `Rock 5B board 16 GB`_
* `Acrylic protector with passive heatsink`_
* `Radxa power supply`_

You will need a **MicroSD** and an **NVME** or **USB3 disk** as well (we recommend an NVMe disk).

.. _Rock 5B board 16 GB: https://shop.allnetchina.cn/products/rock5-model-b?variant=39514839515238
.. _Acrylic protector with passive heatsink: https://shop.allnetchina.cn/products/rock5-b-acrylic-protector?variant=39877626396774
.. _Radxa power supply: https://shop.allnetchina.cn/products/radxa-power-pd-30w?variant=39929851904102

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
  Due to the electronic components outage, the Raspberry Pi 4 is hard to purchase and the price is usually very high.

  Post-merge, it is still possible to run a node on a Raspberry Pi 4 but the hardware is quite limited. Run **Nimbus+Geth** 
  clients combo as this is the best option in terms of performance.

Odroid M1
~~~~~~~~~

You can get the Odroid M1 from the official Hardkernel store.

* `Odroid M1 8 GB board`_ (choose your power supply here)
* `Odroid metal case`_

.. _Odroid M1 8 GB board: https://www.hardkernel.com/shop/odroid-m1-with-8gbyte-ram/
.. _Odroid metal case: https://www.hardkernel.com/shop/m1-metal-case-kit/

.. warning::
  Post-merge, it is still possible to run a node on an Odroid M1 but the hardware is quite limited. Run **Nimbus+Geth** 
  clients combo as this is the best option in terms of performance.

Images download
---------------

Rock 5B
~~~~~~~

Download link:

ethonarm_rock5b_22.12.00.img.zip_

.. _ethonarm_rock5b_22.12.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/EbpQq90lW4ZGv0h_89z6hMUBklyJCDEI7bBuBpFXUvucaQ?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 a7f57f83d4c90c998b69fdd628850ea7a56a2efb2f78c914015b0fd630d3e407``

By running:

.. prompt:: bash $

  sha256sum ethonarm_rock5b_22.12.00.img.zip

Orange Pi 5
~~~~~~~~~~~

Download link:

ethonarm_orangepi5_23.04.00.img.zip_

.. _ethonarm_orangepi5_23.04.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/ERnQkdoTs8lLmifXFI2vVK0BCW-16R764yr_2pxX7QIrqg?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 6b3a1e2cb55465a9076a7b57a21e23ce1c2e9e5e5852b9a7b6d925f68470f520``

By running:

.. prompt:: bash $

  sha256sum ethonarm_orangepi5_23.04.00.img.zip

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

Odroid M1
~~~~~~~~~

Download link:

ethonarm_odroid_22.07.00.img.zip_

.. _ethonarm_odroid_22.07.00.img.zip: https://ethereumonarm-my.sharepoint.com/:u:/p/dlosada/EejUgF6sH55EoUY3Pc34jwEBMIwIxYmJYDUqfGp0TJ1Eyw?download=1

You can verify the file with the following ``SHA256`` Hash:

``SHA256 0be26b4ec9a3e8c0a328fdc175650daf1cd9ef339da2759a7b1601c3d6258cbb``

By running:

.. prompt:: bash $

  sha256sum ethonarm_odroid_22.07.00.img.zip


Installing the image (Flashing) 
-------------------------------

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

   unzip ethonarm_rock5b_22.12.02.img.zip
   sudo dd bs=1M if=ethonarm_rock5b_22.12.02.img of=/dev/mmcblk0 conv=fdatasync status=progress

Insert MicroSD
--------------

.. warning::
  The image will wipe out your NVME/USB SSD disk, so be careful if you already have data
  on it.

Insert the MicroSD into the board. Connect an Ethernet cable and attach 
the disk (make sure you are using a blue port which if your connecting a USB disk).

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
