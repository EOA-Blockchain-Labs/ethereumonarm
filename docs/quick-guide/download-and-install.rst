.. Ethereum on ARM documentation documentation master file, created by
   sphinx-quickstart on Wed Jan 13 19:04:18 2021.

Download and Install
====================

Download
--------

Download the image here:

ethonarm_21.03.00.img.zip_

.. _ethonarm_21.03.00.img.zip: http://www.ethereumonarm.com/downloads/ethonarm_21.03.00.img.zip

You can verify the file with the following ``SHA512`` Hash:

``SHA256 725359703b7c321f56a0e193be61c1f0102a23463549285e8f286e9fb6cc522f``

By running:

.. prompt:: bash $

  sha256sum ethonarm_21.03.00.img.zip

Flash 
-----

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

Unzip and flash the image:

.. prompt:: bash $

   unzip ethonarm_21.03.00.img.zip
   sudo dd bs=1M if=ethonarm_21.03.00.img of=/dev/mmcblk0 conv=fdatasync status=progress

Insert MicroSD
--------------

.. warning::
  The image will wipe out your USB SSD disk, so be careful if you already have data
  on it.

Insert de MicroSD into the Raspberry Pi 4. Connect an Ethernet cable and attach 
the USB SSD disk (make sure you are using a blue port which corresponds to USB 3).

Power on
--------

The Ubuntu OS will boot up in less than one minute and will start to perform the necessary tasks
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

  ssh ethereum@your_raspberrypi_IP

.. tip::
  If you don't have a monitor with a keyboard you can get your Raspberry Pi ``IP`` address by looking into your router 
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
